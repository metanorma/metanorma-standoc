require "pngcheck"
require "svg_conform"

module Metanorma
  module Standoc
    module Validate
      def image_validate(doc)
        image_exists(doc)
        image_toobig(doc)
        png_validate(doc)
        svg_validate(doc)
      end

      def image_exists(doc)
        doc.xpath("//image").each do |i|
          Vectory::Utils::url?(i["src"]) and next
          Vectory::Utils::datauri?(i["src"]) and next
          expand_path(i["src"]) and next
          @log.add("STANDOC_44", i.parent, params: [i["src"]])
        end
      end

      def expand_path(loc)
        relative_path = File.join(@localdir, loc)
        [loc, relative_path].detect do |p|
          File.exist?(p) ? p : nil
        end
      end

      def png_validate(doc)
        doc.xpath("//image[@mimetype = 'image/png']").each do |i|
          Vectory::Utils::url?(i["src"]) and next
          decoded = if Vectory::Utils::datauri?(i["src"])
                      Vectory::Utils::decode_datauri(i["src"])[:data]
                    else
                      path = expand_path(i["src"]) or next
                      File.binread(path)
                    end
          png_validate1(i, decoded)
        end
      end

      def png_validate1(img, buffer)
        PngCheck.check_buffer(buffer)
      rescue PngCheck::CorruptPngError => e
        @log.add("STANDOC_45", img.parent, params: [e.message])
      end

      def image_toobig(doc)
        @dataurimaxsize.zero? and return
        doc.xpath("//image").each do |i|
          i["src"].size > @dataurimaxsize and
            @log.add("STANDOC_46", i.parent)
        end
      end

      def svg_validate(doc)
        profile = SvgConform::Profiles.get(@svg_conform_profile)
        remediatable = profile.remediation_count.positive?
        engine = SvgConform::RemediationEngine.new(profile)
        doc.xpath("//m:svg", "m" => SVG_NS).each do |s|
          d, result = svg_validate1(profile, s)
          remediatable && !result.valid? and
            svg_validate_fix(profile, engine, d, s, result)
        end
      end

      def svg_validate1(profile, svg)
        d = SvgConform::Document.from_content(svg.to_xml)
        r = profile.validate(d)
        svg_error("STANDOC_55", svg, r.errors)
        svg_error("STANDOC_57", svg, r.warnings)
        [d, r]
      end

      def svg_validate_fix(profile, engine, doc, svg, result)
        remeds = engine.apply_remediations(doc, result)
        svg_remed_log(remeds, svg)
        result = profile.validate(doc)
        svg_error("STANDOC_56", svg, result.errors) # we still have errors
        svg.replace(doc.to_xml)
      end

      def svg_remed_log(remeds, svg)
        remeds.each do |e|
          e.changes_made.each do |c|
            @log.add("STANDOC_58", svg,
                     params: [e.remediation_id, e.message,
                              c[:type], c[:message], c[:node]])
          end
        end
      end

      def svg_error(id, svg, errors)
        errors.each do |err|
          err.respond_to?(:element) && err.element and
            elem = " Element: #{err.element}"
          err.respond_to?(:location) && err.location and
            loc = " Location: #{err.location}"
          @log.add(id, svg, params: [err.rule&.id, err.message, elem, loc])
        end
      end
    end
  end
end
