require "date"
require "nokogiri"
require "htmlentities"
require "json"
require "pathname"
require "open-uri"
require "isodoc"
require "relaton"
require "fileutils"

module Asciidoctor
  module Standoc
    module Base
      XML_ROOT_TAG = "standard-document".freeze
      XML_NAMESPACE = "https://www.metanorma.org/ns/standoc".freeze

      Asciidoctor::Extensions.register do
        preprocessor Asciidoctor::Standoc::Yaml2TextPreprocessor
        inline_macro Asciidoctor::Standoc::AltTermInlineMacro
        inline_macro Asciidoctor::Standoc::DeprecatedTermInlineMacro
        inline_macro Asciidoctor::Standoc::DomainTermInlineMacro
        inline_macro Asciidoctor::Standoc::InheritInlineMacro
        inline_macro Asciidoctor::Standoc::HTML5RubyMacro
        inline_macro Asciidoctor::Standoc::ConceptInlineMacro
        block Asciidoctor::Standoc::ToDoAdmonitionBlock
        treeprocessor Asciidoctor::Standoc::ToDoInlineAdmonitionBlock
        block Asciidoctor::Standoc::PlantUMLBlockMacro
        block Asciidoctor::Standoc::PseudocodeBlockMacro
      end

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
        @log.add("Asciidoctor Input", node, w)
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

      def init(node)
        @fn_number ||= 0
        @draft = false
        @refids = Set.new
        @anchors = {}
        @draft = node.attributes.has_key?("draft")
        @novalid = node.attr("novalid")
        @smartquotes = node.attr("smartquotes") != "false"
        @keepasciimath = node.attr("mn-keep-asciimath") &&
          node.attr("mn-keep-asciimath") != "false"
        @fontheader = default_fonts(node)
        @files_to_delete = []
        @filename = node.attr("docfile") ?
          node.attr("docfile").gsub(/\.adoc$/, "").gsub(%r{^.*/}, "") : ""
        @localdir = Utils::localdir(node)
        @no_isobib_cache = node.attr("no-isobib-cache")
        @no_isobib = node.attr("no-isobib")
        @bibdb = nil
        @seen_headers = []
        @datauriimage = node.attr("data-uri-image")
        @boilerplateauthority = node.attr("boilerplate-authority")
        @log = Asciidoctor::Standoc::Log.new
        init_bib_caches(node)
        init_iev_caches(node)
        lang = (node.attr("language") || "en")
        script = (node.attr("script") || "en")
        i18n_init(lang, script)
      end

      def init_bib_caches(node)
        return if @no_isobib
        global = !@no_isobib_cache && !node.attr("local-cache-only")
        local = node.attr("local-cache") || node.attr("local-cache-only")
        local = nil if @no_isobib_cache
        @bibdb = Relaton::DbCache.init_bib_caches(
          local_cache: local,
          flush_caches: node.attr("flush-caches"),
          global_cache: global)
      end

      def init_iev_caches(node)
        unless (@no_isobib_cache || @no_isobib)
          node.attr("local-cache-only") or
            @iev_globalname = global_ievcache_name
          @iev_localname = local_ievcache_name(node.attr("local-cache") ||
                                               node.attr("local-cache-only"))
          if node.attr("flush-caches")
            FileUtils.rm_f @iev_globalname unless @iev_globalname.nil?
            FileUtils.rm_f @iev_localname unless @iev_localname.nil?
          end
        end
        #@iev = Iev::Db.new(globalname, localname) unless @no_isobib
      end

      def default_fonts(node)
        b = node.attr("body-font") ||
          (node.attr("script") == "Hans" ? '"SimSun",serif' :
           '"Cambria",serif')
        h = node.attr("header-font") ||
          (node.attr("script") == "Hans" ? '"SimHei",sans-serif' :
           '"Cambria",serif')
        m = node.attr("monospace-font") || '"Courier New",monospace'
        "$bodyfont: #{b};\n$headerfont: #{h};\n$monospacefont: #{m};\n"
      end

      def document(node)
        init(node)
        ret = makexml(node).to_xml(indent: 2)
        unless node.attr("nodoc") || !node.attr("docfile")
          File.open(@filename + ".xml", "w:UTF-8") { |f| f.write(ret) }
          html_converter(node).convert(@filename + ".xml")
          doc_converter(node).convert(@filename + ".xml")
        end
        @log.write(@localdir + @filename + ".err") unless @novalid
        @files_to_delete.each { |f| FileUtils.rm f }
        ret
      end

      def makexml1(node)
        result = ["<?xml version='1.0' encoding='UTF-8'?>",
                  "<#{xml_root_tag}>"]
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
        node.attr("doctype")
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

      def term_source_attr(seen_xref)
        { bibitemid: seen_xref.children[0]["target"],
          format: seen_xref.children[0]["format"],
          type: "inline" }
      end

      def add_term_source(xml_t, seen_xref, m)
        if seen_xref.children[0].name == "concept"
          xml_t.origin { |o| o << seen_xref.children[0].to_xml }
        else
          xml_t.origin seen_xref.children[0].content,
            **attr_code(term_source_attr(seen_xref))
        end
        m[:text] && xml_t.modification do |mod|
          mod.p { |p| p << m[:text].sub(/^\s+/, "") }
        end
      end

      TERM_REFERENCE_RE_STR = <<~REGEXP.freeze
        ^(?<xref><(xref|concept)[^>]+>([^<]*</(xref|concept)>)?)
               (,\s(?<text>.*))?
        $
      REGEXP
      TERM_REFERENCE_RE =
        Regexp.new(TERM_REFERENCE_RE_STR.gsub(/\s/, "").gsub(/_/, "\\s"),
                   Regexp::IGNORECASE | Regexp::MULTILINE)

      def extract_termsource_refs(text, node)
        matched = TERM_REFERENCE_RE.match text
        matched.nil? and
          @log.add("Asciidoctor Input", node, "term reference not in expected format: #{text}")
        matched
      end

      def termsource(node)
        matched = extract_termsource_refs(node.content, node) || return
        noko do |xml|
          attrs = { status: matched[:text] ? "modified" : "identical" }
          xml.termsource **attrs do |xml_t|
            seen_xref = Nokogiri::XML.fragment(matched[:xref])
            add_term_source(xml_t, seen_xref, matched)
          end
        end.join("\n")
      end
    end
  end
end
