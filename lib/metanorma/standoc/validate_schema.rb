require "jing"

module Metanorma
  module Standoc
    module Validate
      def schema_location
        self.class.respond_to?(:_file) and ret = self.class::_file
        ret ||= caller_locations(1..1).first.absolute_path
        ret ||= __FILE__
        File.join(File.dirname(ret), schema_file)
      end

      def schema_file
        "isodoc-compile.rng"
      end

      def schema_validate(doc, schema)
        Tempfile.open(["tmp", ".xml"], encoding: "UTF-8") do |f|
          schema_validate1(f, doc, schema)
        rescue Jing::Error => e
          clean_abort("Jing failed with error: #{e}", doc)
        ensure
          f.close!
        end
      end

      def schema_validate1(file, doc, schema)
        file.write(to_xml(doc))
        file.close

        # Force UTF-8 encoding for Java console output to fix Japanese Windows issue
        # See: https://github.com/metanorma/mn-samples-plateau/issues/248
        # The -Dsun.jnu.encoding parameter controls Java's native interface encoding (console I/O)
        old_java_opts = ENV["_JAVA_OPTIONS"]
        ENV["_JAVA_OPTIONS"] = "-Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"

        begin
          errors = Jing.new(schema, encoding: "UTF-8").validate(file.path)
          warn "Syntax Valid!" if errors.none?
          errors.each do |e|
            @log.add("STANDOC_7",
                     "XML Line #{'%06d' % e[:line]}:#{e[:column]}",
                     params: [e[:message]])
          end
        ensure
          # Restore original _JAVA_OPTIONS
          ENV["_JAVA_OPTIONS"] = old_java_opts
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
               "<#{root_tag}\\1 xmlns='#{xml_namespace}'>"))
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

      WILDCARD_ATTRS = "//stem | //metanorma-extension".freeze

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
