require "date"
require "nokogiri"
require "htmlentities"
require "json"
require "pathname"
require "isodoc"
require "relaton"
require "fileutils"
require "metanorma-utils"
require "isodoc/xslfo_convert"
require_relative "render"

module Metanorma
  module Standoc
    module Base
      XML_ROOT_TAG = "standard-document".freeze
      XML_NAMESPACE = "https://www.metanorma.org/ns/standoc".freeze
      FONTS_MANIFEST = "fonts-manifest".freeze

      def xml_root_tag
        self.class::XML_ROOT_TAG
      end

      def xml_namespace
        self.class::XML_NAMESPACE
      end

      def init(node)
        @fn_number ||= 0
        @draft = false
        @refids = Set.new
        @anchors = {}
        @internal_eref_namespaces = []
        @draft = node.attributes.has_key?("draft")
        @novalid = node.attr("novalid")
        @smartquotes = node.attr("smartquotes") != "false"
        @keepasciimath = node.attr("mn-keep-asciimath") &&
          node.attr("mn-keep-asciimath") != "false"
        @fontheader = default_fonts(node)
        @files_to_delete = []
        @filename = if node.attr("docfile")
                      File.basename(node.attr("docfile"))&.gsub(/\.adoc$/, "")
                    else ""
                    end
        @localdir = Metanorma::Utils::localdir(node)
        @output_dir = outputdir node
        @no_isobib_cache = node.attr("no-isobib-cache")
        @no_isobib = node.attr("no-isobib")
        @index_terms = node.attr("index-terms")
        @sourcecode_markup_start = node.attr("sourcecode-markup-start") || "{{{"
        @sourcecode_markup_end = node.attr("sourcecode-markup-end") || "}}}"
        @bibdb = nil
        @seen_headers = []
        @datauriimage = node.attr("data-uri-image") != "false"
        @boilerplateauthority = node.attr("boilerplate-authority")
        @sourcecode_markup_start = node.attr("sourcecode-markup-start") || "{{{"
        @sourcecode_markup_end = node.attr("sourcecode-markup-end") || "}}}"
        @log = Metanorma::Utils::Log.new
        init_bib_caches(node)
        init_iev_caches(node)
        @lang = (node.attr("language") || "en")
        @script = (node.attr("script") ||
                   Metanorma::Utils.default_script(node.attr("language")))
        @isodoc = isodoc(@lang, @script, node.attr("i18nyaml"))
        @i18n = @isodoc.i18n
        @htmltoclevels = node.attr("htmltoclevels")
        @doctoclevels = node.attr("doctoclevels")
        @toclevels = node.attr("toclevels")
        @metadata_attrs = metadata_attrs(node)
      end

      def document(node)
        ret = document1(node)
        clean_exit
        ret
      rescue StandardError => e
        @log.add("Fatal Error", nil, e.message)
        clean_exit
        raise e
      end

      def document1(node)
        init(node)
        ret = insert_xml_cr(makexml(node)
          .to_xml(encoding: "UTF-8", indent: 2,
                  save_with: Nokogiri::XML::Node::SaveOptions::AS_XML))
        outputs(node, ret) unless node.attr("nodoc") || !node.attr("docfile")
        ret
      end

      def insert_xml_cr(doc)
        doc
          .gsub(%r{(</(clause|table|figure|p|bibitem|ul|ol|dl|dt|dd|li|example|
                       sourcecode|formula|quote|references|annex|appendix|title|
                       name|note|thead|tbody|tfoot|th|td|form|requirement|
                       recommendation|permission|imagemap|svgmap|preferred|
                       admitted|related|deprecates|letter-symbol|domain|
                       graphical-symbol|expression|abbreviation-type|subject|
                       pronunciation|grammar|term|terms|termnote|termexample|
                       termsource|origin|termref|modification)>)}x, "\\1\n")
      end

      def version
        flavour = self.class.name.sub(/::Converter$/, "").sub(/^.+::/, "")
        Metanorma.versioned(Metanorma, flavour)[-1]::VERSION
      end

      def clean_exit
        @log.write("#{@output_dir}#{@filename}.err") unless @novalid

        @files_to_delete.each { |f| FileUtils.rm f }
      end

      def clean_abort(msg, file = nil)
        file and
          File.open("#{@filename}.xml.abort", "w:UTF-8") { |f| f.write(file) }
        clean_exit
        abort(msg)
      end

      def makexml1(node)
        result = ["<?xml version='1.0' encoding='UTF-8'?>",
                  "<#{xml_root_tag} type='semantic' version='#{version}'>"]
        result << noko { |ixml| front node, ixml }
        result << noko { |ixml| middle node, ixml }
        result << "</#{xml_root_tag}>"
        textcleanup(result)
      end

      def makexml(node)
        result = makexml1(node)
        ret1 = cleanup(Nokogiri::XML(result))
        ret1.root.add_namespace(nil, xml_namespace)
        validate(ret1) unless @novalid
        ret1
      end

      def draft?
        @draft
      end

      def doctype(node)
        node.attr("doctype")&.gsub(/\s+/, "-")&.downcase
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
        node.attributes.each_with_object([]) do |(k, v), ret|
          %w(presentation semantic).each do |t|
            next unless /^#{t}-metadata-/.match?(k)

            k = k.sub(/^#{t}-metadata-/, "")
            csv_split(v, ",")&.each do |c|
              ret << "<#{t}-metadata><#{k}>#{c}</#{k}></#{t}-metadata>"
            end
          end
        end.join
      end

      private

      def outputdir(node)
        if node.attr("output_dir").nil_or_empty?
          Metanorma::Utils::localdir(node)
        else
          File.join(node.attr("output_dir"), "")
        end
      end
    end
  end
end
