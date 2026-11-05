require "svg_conform"
require "png_conform"
require "yaml"
require "metanorma/standoc/conform_profiles"

module Metanorma
  module Standoc
    class Validate
      module Image
        SVG_NS = "http://www.w3.org/2000/svg".freeze

        def image_validate(doc)
          image_exists(doc)
          image_toobig(doc)
          png_validate(doc)
          svg_validate(doc)
        end

        def image_exists(doc)
          doc.xpath("//image[@src] | //altmedia[@src]").each do |i|
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

        # Metanorma owns the operative profiles; the engines' bundled
        # samples are reachable only through the explicit "svg:"/"png:"
        # prefix (see ConformProfiles). Resolution: the
        # <type>-conform-profile document attribute, then the flavor's
        # shipped profile directory (conform_profile_dir, overridable per
        # flavor), then the standoc default; "none" disables that type's
        # validation for the document.
        def svg_conform_profile
          kind, value = conform_profile_resolution(:svg)
          case kind
          when :disabled then nil
          when :engine then SvgConform::Profiles.get(value)
          when :file then SvgConform::Profile.load_from_file(value)
          end
        end

        # The PNG mirror: returns :disabled (validation skipped), or a
        # descriptor passed to the engine through the service options.
        # png_conform 0.1.5 does not yet read profile selection from
        # options (claricle/png_conform#34); the descriptor is inert
        # until it does.
        def png_conform_profile
          kind, value = conform_profile_resolution(:png)
          case kind
          when :disabled then :disabled
          when :engine then { engine_profile: value }
          else { profile_file: value }
          end
        end

        def conform_profile_resolution(type)
          registry = ConformProfiles::Registry.new(
            type: type,
            standoc_dir: conform_profile_dir(type, own: false),
            flavor_dir: conform_profile_dir(type, own: true),
          )
          registry.resolve(
            instance_variable_get("@#{type}_conform_profile")
          )
        end

        # The flavor seam: flavors define their own requirements
        # collections by shipping a directory per type
        # (lib/metanorma/<flavor>/<type>_conform_profile/) — overridable
        # per type for nonstandard locations.
        def conform_profile_dir(type, own: true)
          if own
            base = Gem::Specification.find_by_name(
              "metanorma-#{validation_flavor}"
            )
            return File.join(base.gem_dir, "lib", "metanorma",
                             validation_flavor, "#{type}_conform_profile")
          end
          File.expand_path("../standoc/#{type}_conform_profile", __dir__)
        rescue Gem::LoadError
          File.expand_path("../standoc/#{type}_conform_profile", __dir__)
        end

        def png_validate(doc)
          return if png_conform_profile == :disabled
          profile = png_conform_engine_profile(png_conform_profile)
          profile.nil? and return
          doc.xpath("//image[@mimetype = 'image/png'][@src]").each do |i|
            Vectory::Utils::url?(i["src"]) and next
            uri = Vectory::Utils::datauri?(i["src"])
            path = uri ? save_dataimage(i["src"]) : expand_path(i["src"])
            path or next
            PngConform::Readers::StreamingReader.open(path) do |reader|
              v = PngConform::Services::ValidationService.new(
                reader, path, { profile: profile }
              )
              png_validate1(i, path, v)
            end
          end
        end

        # png_conform 0.1.6 takes a definition Hash, a built-in/YAML
        # profile name, or nil/"none" (claricle/png_conform#34). Our
        # descriptor is {profile_file:} (an owned YAML file, loaded as an
        # inline definition — the gem reads no consumer directories) or
        # {engine_profile:} (a gem-profile name, resolved loudly there).
        def png_conform_engine_profile(descriptor)
          case descriptor
          when Hash
            if (file = descriptor[:profile_file])
              YAML.safe_load(File.read(file))
            else
              descriptor[:engine_profile]
            end
          else
            descriptor
          end
        end

        def png_validate1(img, _path, validator)
          ret = validator.validate
          ret.error_messages.each do |e|
            @log.add("STANDOC_45", img.parent, params: [e])
          end
          ret.validation_result.warning_messages.each do |e|
            @log.add("STANDOC_63", img.parent, params: [e])
          end
        end

        def image_toobig(doc)
          @dataurimaxsize.zero? and return
          doc.xpath("//image[@src]").each do |i|
            i["src"].size > @dataurimaxsize and
              @log.add("STANDOC_46", i.parent)
          end
        end

        # Use SAX for fast validation
        #
        # Machine-emitted diagram images are skipped: the svgmap blocks
        # emitted for EXPRESS-G and other generated diagrams (e.g. by
        # stepmod2mn) wrap pre-baked placeholder SVG/GIF assets which are
        # not author-authored content, and their eref integrity is
        # enforced separately when svgmap targets are resolved at render
        # time. Validating them through SvgConform costs heavily on
        # diagram-heavy corpora and yields nothing the render does not
        # already catch.
        def svg_validate(doc)
          profile = svg_conform_profile
          profile.nil? and return
          validator = SvgConform::Validator.new(mode: :sax)
          engine = SvgConform::RemediationEngine.new(profile)
          @svg_remediation_cache = {}
          doc.xpath("//m:svg", "m" => SVG_NS).each do |svg_element|
            svgmap_emission?(svg_element) and next
            result = svg_validate1(validator, profile, svg_element)
            if profile.remediation_count.positive? && !result.valid?
              svg_remediate(validator, profile, engine, svg_element,
                            result)
            end
          end
        end

        # Is this inline SVG a machine-generated diagram emission, rather
        # than an author-provided SVG asset? svgmaps that carry eref
        # targets survive cleanup as wrappers of their diagram, so a
        # svgmap ancestor marks the diagram as svgmap-emitted. Author
        # SVGs (plain image elements) have no svgmap ancestor and keep
        # being validated.
        def svgmap_emission?(svg)
          !svg.at_xpath("ancestor::svgmap").nil?
        end

        def svg_validate1(validator, profile, svg)
          result = validator.validate(svg, profile: profile)
          svg_error("STANDOC_55", svg, result.errors, display: false)
          svg_error("STANDOC_57", svg, result.warnings, display: false)
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
            @log.add("STANDOC_59", svg,
                     params: [ref.value, ref.line_number])
          end
        end

        # Apply remediation if needed
        def svg_remediate(validator, profile, engine, svg, result)
          id = svg["id"]
          svg.delete("id") # cache will be tripped up by unique @id
          key = Digest::MD5.hexdigest(svg.to_xml)
          unless ret = @svg_remediation_cache[key]
            ret = svg_validate_fix(validator, profile, engine, svg,
                                   result)
            @svg_remediation_cache[key] = ret
          end
          svg.replace(ret.to_xml)
          svg["id"] = id
        end

        def svg_validate_fix(validator, profile, engine, svg, result)
          # Load DOM only for remediation
          doc = SvgConform::Document.from_content(svg.to_xml)
          remeds = engine.apply_remediations(doc, result)
          svg_remed_log(remeds, svg)
          # Use root to avoid processing instructions that may break SAX parser
          remediated_xml = doc.root
          result = validator.validate(remediated_xml.to_xml,
                                      profile: profile)
          svg_error("STANDOC_56", svg, result.errors) # we still have errors
          remediated_xml
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

        def svg_error(id, svg, errors, options = {})
          errors.each do |err|
            # reference violations are handled separately
            err.violation_type == :reference_violation and next
            elem, loc = svg_error_locations(err)
            @log.add(id, svg, params: [err.rule&.id, err.message, elem, loc],
                              **options)
          end
        end

        def svg_error_locations(err)
          err.respond_to?(:element) && err.element and
            elem = " Element: #{err.element}"
          err.respond_to?(:location) && err.location and
            loc = " Location: #{err.location}"
          err.respond_to?(:node) && err.node.respond_to?(:path_id) and
            loc2 = " Location: #{err.node.path_id}"
          [elem, loc || loc2]
        end

        def save_dataimage(uri, _relative_dir = true)
          imgtype, imgdata = save_dataimage_prep(uri)
          Tempfile.open(["image", ".#{imgtype}"],
                        mode: File::BINARY | File::SHARE_DELETE) do |f|
            f.binmode
            f.write(Base64.strict_decode64(imgdata))
            @files_to_delete << f # persist to the end
            f.path
          end
        end

        def save_dataimage_prep(uri)
          %r{^data:(?:image|application)/(?<imgtype>[^;]+);(?:charset=[^;]+;)?base64,(?<imgdata>.+)$} =~ uri
          # imgtype = "emf" if emf?("#{imgclass}/#{imgtype}")
          imgtype = imgtype.sub(/\+[a-z0-9]+$/, "") # svg+xml
          imgtype = "png" unless /^[a-z0-9]+$/.match? imgtype
          imgtype == "postscript" and imgtype = "eps"
          [imgtype, imgdata]
        end
      end
    end
  end
end
