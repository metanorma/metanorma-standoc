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
require "mn-requirements"

module Metanorma
  module Standoc
    module Base
      XML_ROOT_TAG = "standard-document".freeze
      XML_NAMESPACE = "https://www.metanorma.org/ns/standoc".freeze
      FONTS_MANIFEST = "fonts-manifest".freeze

      attr_accessor :log

      def xml_root_tag
        self.class::XML_ROOT_TAG
      end

      def xml_namespace
        self.class::XML_NAMESPACE
      end

      def document(node)
        ret = document1(node)
        clean_exit
        ret
      rescue StandardError => e
        @log.add("Fatal Error", nil, e.message, severity: 0)
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
            pronunciation|grammar|term|terms|termnote|termexample|termsource|
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
        f = File.read(File.join(File.dirname(__FILE__), "isodoc.rng"))
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
        result = ["<?xml version='1.0' encoding='UTF-8'?>",
                  "<#{xml_root_tag} type='semantic' version='#{version}' " \
                  "schema-version='#{schema_version}'>"]
        result << noko { |ixml| front node, ixml }
        result << noko { |ixml| middle node, ixml }
        result << "</#{xml_root_tag}>"
        textcleanup(result)
      end

      def makexml(node)
        result = makexml1(node)
        ret1 = cleanup(Nokogiri::XML(insert_xml_cr(result)))
        ret1.root.add_namespace(nil, xml_namespace)
        validate(ret1) unless @novalid
        ret1
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
            quoted_csv_split(v)&.each do |c|
              ret << "<#{t}-metadata><#{k}>#{c}</#{k}></#{t}-metadata>"
            end
          end
        end.join
        out + document_scheme_metadata(node)
      end

      def document_scheme_metadata(node)
        a = document_scheme(node) or return ""
        "<presentation-metadata><name>document-scheme</name>" \
          "<value>#{a}</value></presentation-metadata>"
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
