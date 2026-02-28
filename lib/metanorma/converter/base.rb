require "date"
require "nokogiri"
require "htmlentities"
require "pathname"
require "isodoc"
require "relaton"
require "fileutils"
require "metanorma-utils"
require_relative "render"
require_relative "localbib"
require_relative "init"
require_relative "isolated_converter"
require "mn-requirements"

module Asciidoctor
  module Compliance
    ADMONITION_STYLES.add("EDITOR") unless ADMONITION_STYLES.include?("EDITOR")
  end
end

module Metanorma
  module Standoc
    module Base
      FONTS_MANIFEST = "fonts-manifest".freeze

      attr_accessor :log

      def xml_root_tag
        "metanorma"
      end

      def xml_namespace
        "https://www.metanorma.org/ns/standoc"
      end

      def document(node)
        ret = document1(node)
        clean_exit
        ret
      rescue StandardError => e
        @log.add("STANDOC_50", nil, params: [e.message])
        clean_exit
        raise e
      end

      def document1(node)
        init(node)
        ret = to_xml(makexml(node))
        outputs(node, ret) unless node.attr("nodoc") || !node.attr("docfile")
        ret
      end

      def insert_xml_cr(doc)
        doc.gsub(%r{(</(clause|table|figure|p|bibitem|ul|ol|dl|dt|dd|li|example|
            sourcecode|formula|quote|references|annex|appendix|title|name|note|
            thead|tbody|tfoot|th|td|form|requirement|recommendation|permission|
            imagemap|svgmap|preferred|admitted|related|domain|deprecates|
            letter-symbol|graphical-symbol|expression|subject|abbreviation-type|
            pronunciation|grammar|term|terms|termnote|termexample|source|
            origin|termref|modification)>)}x, "\\1\n")
          .gsub(%r{(<(title|name))}, "\n\\1")
          .gsub(%r{(<sourcecode[^<>]*>)\s+(<name[^<>]*>[^<]+</name>)\s+},
                "\\1\\2")
      end

      def version
        flavour = self.class.name.sub(/::Converter$/, "").sub(/^.+::/, "")
        Metanorma.versioned(Metanorma, flavour)[-1]::VERSION
      end

      def schema_version
        f = File.read(File.join(File.dirname(__FILE__), "..", "validate",
                                "isodoc.rng"))
        m = / VERSION (v\S+)/.match(f)
        m[1]
      end

      def clean_exit
        !@novalid && @local_log and
          @log.write("#{@output_dir}#{@filename}.err.html")
        @files_to_delete.each { |f| FileUtils.rm f }
      end

      def clean_abort(msg, file = nil)
        if file
          doc = to_xml(file)
          File.open("#{@filename}.xml.abort", "w:UTF-8") { |f| f.write(doc) }
        end
        clean_exit
        abort(msg)
      end

      def makexml1(node)
        result = [<<~XML,
          <?xml version='1.0' encoding='UTF-8'?>
          <#{xml_root_tag} type='semantic' version='#{version}' schema-version='#{schema_version}' flavor='#{processor.new.asciidoctor_backend}'>
        XML
                  noko { |ixml| front node, ixml },
                  noko { |ixml| middle node, ixml },
                  "</#{xml_root_tag}>"]
        insert_xml_cr(textcleanup(result))
      end

      def makexml(node)
        result = makexml1(node)
        ret1 = cleanup(result)
        unless @novalid || in_isolated_conversion?
          validate_processor = validate_class.new(self)
          validate_processor.validate(ret1)
          @files_to_delete = validate_processor.files_to_delete
        end
        ret1
      end

      def validate_class
        Object.const_get(
          self.class.name.sub(/::Converter$/, "::Validate"),
        )
      end

      def cleanup(result)
        ret1 = Nokogiri::XML(result)
        @nocleanup and return ret1
        cleanup_processor = cleanup_class.new(self)
        ret1 = cleanup_processor.cleanup(ret1)
        @log = cleanup_processor.log # Sync log back from cleanup
        @files_to_delete = cleanup_processor.files_to_delete
        ret1.root.add_namespace(nil, xml_namespace)
        ret1
      end

      def cleanup_class
        Object.const_get(
          self.class.name.sub(/::Converter$/, "::Cleanup"),
        )
      end

      def in_isolated_conversion?
        !@isolated_conversion_stack.empty?
      end

      def draft?
        @draft
      end

      def doctype(node)
        ret = node.attr("doctype")&.gsub(/\s+/, "-")&.downcase ||
          @default_doctype
        ret = @default_doctype if ret == "article"
        ret
      end

      def front(node, xml)
        xml.bibdata **attr_code(type: "standard") do |b|
          metadata node, b
        end
      end

      def middle(node, xml)
        xml.sections do |s|
          s << node.content if node.blocks?
        end
      end

      def metadata_attrs(node)
        out = node.attributes.each_with_object([]) do |(k, v), ret|
          %w(presentation semantic).each do |t|
            /^#{t}-metadata-/.match?(k) or next
            k = k.sub(/^#{t}-metadata-/, "")
            csv_split(v.gsub("&amp;#", "&#"), ",", encode: false)&.each do |c|
              ret << "<#{t}-metadata><#{k}>#{c}</#{k}></#{t}-metadata>"
            end
          end
        end.join
        out + document_scheme_metadata(node)
      end

      def document_scheme_metadata(node)
        a = document_scheme(node) or return ""
        "<presentation-metadata><document-scheme>" \
          "#{a}</document-scheme></presentation-metadata>"
      end

      def document_scheme(node)
        node.attr("document-scheme")
      end

      private

      def outputdir(node)
        if node.attr("output_dir").nil_or_empty?
          Metanorma::Utils::localdir(node)
        else File.join(node.attr("output_dir"), "")
        end
      end
    end
  end
end
