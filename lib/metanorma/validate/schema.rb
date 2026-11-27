require "leptris"
require "leptris/xml/relaxng"
require "tempfile"
require "fileutils"
require "pathname"

module Metanorma
  module Standoc
    class Validate
      module Schema
        def schema_location
          self.class.respond_to?(:_file) and ret = self.class::_file
          ret ||= caller_locations(1..1).first.absolute_path
          ret ||= __FILE__
          File.join(File.dirname(ret), schema_file)
        end

        def schema_file
          "standoc-compile.rng"
        end

        def schema_validate(doc, schema)
          Tempfile.open(["tmp", ".xml"], encoding: "UTF-8") do |f|
            schema_validate1(f, doc, schema)
          rescue Leptris::XML::Error => e
            @conv.clean_abort("Schema validation failed with error: #{e}", doc)
          ensure
            f.close!
          end
        end

        def schema_validate_errors(schema, file_path)
          rng = compiled_schema_rng(schema)
          doc = Leptris::XML.parse(File.read(file_path), readonly: true)
          rng.validate_errors(doc)
        end

        # The packed toolchain serves gem files from a memfs that the
        # native file layer cannot see: parse_file opens the path
        # through libleptris and dies with "cannot open schema file
        # 'A:/...'" (tebako, metanorma-standoc#1416), while bare
        # RelaxNG.parse cannot compile a schema that uses <include>
        # ("include ...: no base URI"). Materialize the schema and its
        # include closure through Ruby IO into a real directory - each
        # href resolves against its own source file's directory, and
        # the staged tree mirrors that geometry - and compile from
        # there.
        def compiled_schema_rng(schema_path)
          Dir.mktmpdir(["metanorma_rng"]) do |dir|
            staged = stage_schema_closure(File.expand_path(schema_path), dir)
            Leptris::XML::RelaxNG.parse_file(staged)
          end
        end

        def stage_schema_closure(schema_path, dir)
          top_dir = File.dirname(schema_path)
          staged = File.join(dir, File.basename(schema_path))
          FileUtils.mkdir_p(File.dirname(staged))
          FileUtils.cp(schema_path, staged)
          copy_include_closure(schema_path, top_dir, dir)
          staged
        end

        def copy_include_closure(source, top_dir, dir)
          pending = [source]
          visited = []
          until pending.empty?
            src = pending.pop
            next if visited.include?(src)

            visited << src
            hrefs(src).each do |href|
              next if href.start_with?("http:", "https:", "file:", "/")

              target = File.expand_path(href, File.dirname(src))
              next unless File.file?(target)

              stage_include_target(target, top_dir, dir)
              pending << target
            end
          end
        end

        def stage_include_target(target, top_dir, dir)
          rel = Pathname.new(target).relative_path_from(Pathname.new(top_dir))
          staged = File.join(dir, rel.to_s)
          FileUtils.mkdir_p(File.dirname(staged))
          FileUtils.cp(target, staged) unless File.exist?(staged)
        end

        def hrefs(path)
          File.read(path).scan(/href="([^"]+)"/).flatten
        end

        def schema_validate1(file, doc, schema)
          file.write(to_xml(doc))
          file.close
          errors = schema_validate_errors(schema, file.path)
          warn "Syntax Valid!" if errors.none?
          errors.each do |e|
            @log.add("STANDOC_7",
                     "XML Line #{'%06d' % e[:line]}:#{e[:column]}",
                     params: [e[:message]])
          end
        end

        def validate_document_fragment(xml_fragment)
          f = add_ns_to_fragment(xml_fragment) or
            return [true,
                    "Fragment is not well-formed XML, not validating"]
          begin
            temp_schema, schema = fragment_schema(f.root.name)
            schema or return [false, "Did not expect element #{f.root.name}"]
            validation_errors = schema.validate(f)
            [validation_errors.none? do |x|
              x.to_s.include?("Did not expect element")
            end, validation_errors]
          ensure
            temp_schema.unlink
          end
        end

        def add_ns_to_fragment(xml_fragment)
          f = Nokogiri::XML(xml_fragment, &:strict)
          f.errors.any? || f.root.nil? and return nil
          root_tag = f.root.name
          f.root.namespace or
            f = Nokogiri::XML(xml_fragment
            .sub(/<#{root_tag}([^>]*)>/,
                 "<#{root_tag}\\1 xmlns='#{@conv.xml_namespace}'>"))
          f
        rescue StandardError
          nil
        end

        def fragment_schema(root_element)
          temp_schema = Tempfile.new(["dynamic_schema", ".rng"])
          temp_schema.write(<<~SCHEMA)
                    <grammar xmlns="http://relaxng.org/ns/structure/1.0">
              <include href="#{schema_location}">
                <start combine="choice">
                    <ref name="#{root_element}"/>
                </start>
            </include>
                    </grammar>
          SCHEMA
          temp_schema.close
          [temp_schema, Nokogiri::XML::RelaxNG(File.open(temp_schema.path))]
        rescue StandardError # error because root_element is not in schema
          [temp_schema, nil]
        end

        SVG_NS = "http://www.w3.org/2000/svg".freeze

        # <stem> is no longer stripped: MathML is now explicitly defined in the
        # grammar (basicdoc-models#35), so its attributes (incl.
        # data-metanorma-numberformat) validate directly. metanorma-extension
        # (UnitsML etc.) and <svg> remain any-element and are still stripped.
        WILDCARD_ATTRS = "//metanorma-extension".freeze

        # RelaxNG cannot cope well with wildcard attributes. So we strip
        # any attributes from FormattedString instances (which can contain
        # xs:any markup, and are signalled with @format) before validation.
        def formattedstr_strip(doc)
          doc.xpath(WILDCARD_ATTRS, "m" => SVG_NS).each do |n|
            n.elements.each do |e|
              e.traverse do |e1|
                e1.element? and e1.each { |k, _v| e1.delete(k) } # rubocop:disable Style/HashEachMethods
              end
            end
          end
          doc.xpath("//m:svg", "m" => SVG_NS).each { |n| n.replace("<svg/>") }
          doc
        end

        include ::Metanorma::Standoc::Utils
      end
    end
  end
end
