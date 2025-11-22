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

      # Use SAX for fast validation
      def svg_validate(doc)
        profile = SvgConform::Profiles.get(@svg_conform_profile)
        validator = SvgConform::Validator.new(mode: :sax)
        engine = SvgConform::RemediationEngine.new(profile)
        doc.xpath("//m:svg", "m" => SVG_NS).each do |svg_element|
          result = svg_validate1(validator, profile, svg_element)
          if profile.remediation_count.positive? && !result.valid?
            svg_validate_fix(validator, profile, engine, svg_element, result)
          end
        end
      end

      def svg_validate1(validator, profile, svg)
        # require "debug"; binding.b
        result = validator.validate(svg.to_xml, profile: profile)
        svg_error("STANDOC_55", svg, result.errors)
        svg_error("STANDOC_57", svg, result.warnings)
        # manifest = result.reference_manifest
        if result.has_external_references?
          puts "External references found: #{result.external_references.size}"

          result.external_references.each do |ref|
            puts "#{ref.class.name}: #{ref.value}"
            puts "  Element: #{ref.element_name} at line #{ref.line_number}"
          end
        end
        puts "IDs defined: #{result.available_ids.map(&:id_value).join(', ')}"

        # Check for unresolved internal references
        unresolved = result.unresolved_internal_references
        if unresolved.any?
          puts "Unresolved references:"
          unresolved.each do |ref|
            puts "  #{ref.value} at line #{ref.line_number}"
          end
        end
        result
      end

      # Apply remediation if needed
      def svg_validate_fix(validator, profile, engine, svg, result)
        # Load DOM only for remediation
        doc = SvgConform::Document.from_content(svg.to_xml)
        remeds = engine.apply_remediations(doc, result)
        svg_remed_log(remeds, svg)

        # Use root element to avoid processing instructions that may break SAX parser
        remediated_xml = doc.root.to_xml

        result = validator.validate(remediated_xml, profile: profile)
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
