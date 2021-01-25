require "date"
require "nokogiri"
require "htmlentities"
require "json"
require "pathname"
require "open-uri"
require "isodoc"
require "relaton"
require "fileutils"
require "metanorma-utils"

module Asciidoctor
  module Standoc
    module Base
      XML_ROOT_TAG = "standard-document".freeze
      XML_NAMESPACE = "https://www.metanorma.org/ns/standoc".freeze

      def xml_root_tag
        self.class::XML_ROOT_TAG
      end

      def xml_namespace
        self.class::XML_NAMESPACE
      end

      def content(node)
        node.content
      end

      def skip(node, name = nil)
        name = name || node.node_name
        w = "converter missing for #{name} node in Metanorma backend"
        @log.add("AsciiDoc Input", node, w)
        nil
      end

      def html_extract_attributes(node)
        {
          script: node.attr("script"),
          bodyfont: node.attr("body-font"),
          headerfont: node.attr("header-font"),
          monospacefont: node.attr("monospace-font"),
          i18nyaml: node.attr("i18nyaml"),
          scope: node.attr("scope"),
          htmlstylesheet: node.attr("htmlstylesheet"),
          htmlcoverpage: node.attr("htmlcoverpage"),
          htmlintropage: node.attr("htmlintropage"),
          scripts: node.attr("scripts"),
          scripts_pdf: node.attr("scripts-pdf"),
          datauriimage: node.attr("data-uri-image"),
          htmltoclevels: node.attr("htmltoclevels") || node.attr("toclevels"),
          doctoclevels: node.attr("doctoclevels") || node.attr("toclevels"),
          break_up_urls_in_tables: node.attr("break-up-urls-in-tables"),
        }
      end

      def html_converter(node)
        IsoDoc::HtmlConvert.new(html_extract_attributes(node))
      end

      def doc_extract_attributes(node)
        {
          script: node.attr("script"),
          bodyfont: node.attr("body-font"),
          headerfont: node.attr("header-font"),
          monospacefont: node.attr("monospace-font"),
          i18nyaml: node.attr("i18nyaml"),
          scope: node.attr("scope"),
          wordstylesheet: node.attr("wordstylesheet"),
          standardstylesheet: node.attr("standardstylesheet"),
          header: node.attr("header"),
          wordcoverpage: node.attr("wordcoverpage"),
          wordintropage: node.attr("wordintropage"),
          ulstyle: node.attr("ulstyle"),
          olstyle: node.attr("olstyle"),
          htmltoclevels: node.attr("htmltoclevels") || node.attr("toclevels"),
          doctoclevels: node.attr("doctoclevels") || node.attr("toclevels"),
          break_up_urls_in_tables: node.attr("break-up-urls-in-tables"),
        }
      end

      def doc_converter(node)
        IsoDoc::WordConvert.new(doc_extract_attributes(node))
      end

      def presentation_xml_converter(node)
        IsoDoc::PresentationXMLConvert.new(html_extract_attributes(node))
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
        @keepasciimath = node.attr("mn-keep-asciimath") && node.attr("mn-keep-asciimath") != "false"
        @fontheader = default_fonts(node)
        @files_to_delete = []
        @filename = node.attr("docfile") ?  File.basename(node.attr("docfile")).gsub(/\.adoc$/, "") : ""
        @localdir = Metanorma::Utils::localdir(node)
        @output_dir = outputdir node
        @no_isobib_cache = node.attr("no-isobib-cache")
        @no_isobib = node.attr("no-isobib")
        @sourcecode_markup_start = node.attr("sourcecode-markup-start") || "{{{"
        @sourcecode_markup_end = node.attr("sourcecode-markup-end") || "}}}"
        @bibdb = nil
        @seen_headers = []
        @datauriimage = node.attr("data-uri-image")
        @boilerplateauthority = node.attr("boilerplate-authority")
        @sourcecode_markup_start = node.attr("sourcecode-markup-start") || "{{{"
        @sourcecode_markup_end = node.attr("sourcecode-markup-start") || "}}}"
        @log = Metanorma::Utils::Log.new
        init_bib_caches(node)
        init_iev_caches(node)
        @lang = (node.attr("language") || "en")
        @script = (node.attr("script") || default_script(node.attr("language")))
        @isodoc = isodoc(@lang, @script, node.attr("i18nyaml"))
        @i18n = @isodoc.i18n
      end

      def default_fonts(node)
        b = node.attr("body-font") ||
          (node.attr("script") == "Hans" ? '"Source Han Sans",serif' : '"Cambria",serif')
        h = node.attr("header-font") ||
          (node.attr("script") == "Hans" ? '"Source Han Sans",sans-serif' : '"Cambria",serif')
        m = node.attr("monospace-font") || '"Courier New",monospace'
        "$bodyfont: #{b};\n$headerfont: #{h};\n$monospacefont: #{m};\n"
      end

      def outputs(node, ret)
        File.open(@filename + ".xml", "w:UTF-8") { |f| f.write(ret) }
        presentation_xml_converter(node).convert(@filename + ".xml")
        html_converter(node).convert(@filename + ".presentation.xml", nil, false, "#{@filename}.html")
        doc_converter(node).convert(@filename + ".presentation.xml", nil, false, "#{@filename}.doc")
      end

      def document(node)
        init(node)
        ret = makexml(node).to_xml(indent: 2)
        outputs(node, ret) unless node.attr("nodoc") || !node.attr("docfile")
        clean_exit
        ret
      end

      def version
        flavour = self.class.name.sub(/::Converter$/, "").sub(/^.+::/, "")
        Metanorma.versioned(Metanorma, flavour)[-1]::VERSION
      end

      def clean_exit
        @log.write(@output_dir + @filename + ".err") unless @novalid
        @files_to_delete.each { |f| FileUtils.rm f }
      end

      def makexml1(node)
        result = ["<?xml version='1.0' encoding='UTF-8'?>", "<#{xml_root_tag} type='semantic' version='#{version}'>"]
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

      def default_script(lang)
        case lang
        when "ar", "fa"
          "Arab"
        when "ur"
          "Aran"
        when "ru", "bg"
          "Cyrl"
        when "hi"
          "Deva"
        when "el"
          "Grek"
        when "zh"
          "Hans"
        when "ko"
          "Kore"
        when "he"
          "Hebr"
        when "ja"
          "Jpan"
        else
          "Latn"
        end
      end

      private

      def outputdir(node)
        if node.attr("output_dir").nil_or_empty? then Metanorma::Utils::localdir(node)
        else File.join(node.attr("output_dir"), "")
        end
      end
    end
  end
end
