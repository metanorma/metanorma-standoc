require "svg_conform"
require "png_conform"

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
          uri = Vectory::Utils::datauri?(i["src"])
          path = uri ? save_dataimage(i["src"]) : expand_path(i["src"])
          path or next
          PngConform::Readers::StreamingReader.open(path) do |reader|
            v = PngConform::Services::ValidationService.new(reader)
            png_validate1(i, path, v)
          end
        end
      end

      def png_validate1(img, _path, validator)
        ret = validator.validate
        ret.error_messages.each do |e|
          @log.add("STANDOC_45", img.parent, params: [e])
        end
        ret.validation_result.warning_messages.each do |e|
          @log.add("STANDOC_62", img.parent, params: [e])
        end
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
        result = validator.validate(svg, profile: profile)
        svg_error("STANDOC_55", svg, result.errors)
        svg_error("STANDOC_57", svg, result.warnings)
        svg_reference_violations(svg, result)
        result
      end

      # we are ignoring external references as out of our scope to resolve;
      # example code just in case this comes up
      #
      #  manifest = result.reference_manifest
      #  if result.has_external_references?
      #    puts "External references found: #{result.external_references.size}"
      #    result.external_references.each do |ref|
      #      puts "#{ref.class.name}: #{ref.value}"
      #      puts "  Element: #{ref.element_name} at line #{ref.line_number}"
      #     end
      #   end
      #   puts "IDs defined: #{result.available_ids.map(&:id_value).join(', ')}"

      # Check for unresolved internal references
      def svg_reference_violations(svg, result)
        result.unresolved_internal_references&.each do |ref|
          val = ref.value.sub(/^#/, "")
          @doc_ids.include?(val) and next
          @doc_anchors.include?(val) and next
          @log.add("STANDOC_59", svg, params: [ref.value, ref.line_number])
        end
      end

      # Apply remediation if needed
      def svg_validate_fix(validator, profile, engine, svg, result)
        # Load DOM only for remediation
        doc = SvgConform::Document.from_content(svg.to_xml)
        remeds = engine.apply_remediations(doc, result)
        svg_remed_log(remeds, svg)
        # Use root to avoid processing instructions that may break SAX parser
        remediated_xml = doc.root.to_xml
        result = validator.validate(remediated_xml, profile: profile)
        svg_error("STANDOC_56", svg, result.errors) # we still have errors
        svg.replace(remediated_xml)
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
          # reference violations are handled separately
          err.violation_type == :reference_violation and next
          err.respond_to?(:element) && err.element and
            elem = " Element: #{err.element}"
          err.respond_to?(:location) && err.location and
            loc = " Location: #{err.location}"
          @log.add(id, svg, params: [err.rule&.id, err.message, elem, loc])
        end
      end

      def save_dataimage(uri, _relative_dir = true)
        %r{^data:(?:image|application)/(?<imgtype>[^;]+);(?:charset=[^;]+;)?base64,(?<imgdata>.+)$} =~ uri
        # imgtype = "emf" if emf?("#{imgclass}/#{imgtype}")
        imgtype = imgtype.sub(/\+[a-z0-9]+$/, "") # svg+xml
        imgtype = "png" unless /^[a-z0-9]+$/.match? imgtype
        imgtype == "postscript" and imgtype = "eps"
        Tempfile.open(["image", ".#{imgtype}"],
                      mode: File::BINARY | File::SHARE_DELETE) do |f|
          f.binmode
          f.write(Base64.strict_decode64(imgdata))
          @files_to_delete << f # persist to the end
          f.path
        end
      end
    end
  end
end
