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
require_relative "localbib"
require "mn-requirements"

module Metanorma
  module Standoc
    module Base
      XML_ROOT_TAG = "standard-document".freeze
      XML_NAMESPACE = "https://www.metanorma.org/ns/standoc".freeze
      FONTS_MANIFEST = "fonts-manifest".freeze

      attr_accessor :log, :fatalerror

      def xml_root_tag
        self.class::XML_ROOT_TAG
      end

      def xml_namespace
        self.class::XML_NAMESPACE
      end

      def init(node)
        init_vars
        init_misc(node)
        init_processing(node)
        init_reqt(node)
        init_toc(node)
        init_output(node) # feeds init_biblio
        init_i18n(node)
        init_biblio(node)
        @metadata_attrs = metadata_attrs(node)
      end

      def init_vars
        @fn_number ||= 0
        @refids = Set.new
        @anchor_alias = {}
        @anchors = {}
        @internal_eref_namespaces = []
        @seen_headers = []
        @seen_headers_canonical = []
        @embed_hdr = []
        @reqt_model = nil
        @preface = true
      end

      def init_misc(node)
        @draft = node.attributes.has_key?("draft")
        @index_terms = node.attr("index-terms")
        @boilerplateauthority = node.attr("boilerplate-authority")
        @embed_hdr = node.attr("embed_hdr")
        @embed_id = node.attr("embed_id")
        @document_scheme = node.attr("document-scheme")
        @xrefstyle = node.attr("xrefstyle")
        @source_linenums = node.attr("source-linenums-option") == "true"
      end

      def init_processing(node)
        @novalid = node.attr("novalid")
        @smartquotes = node.attr("smartquotes") != "false"
        @keepasciimath = node.attr("mn-keep-asciimath") &&
          node.attr("mn-keep-asciimath") != "false"
        @sourcecode_markup_start = node.attr("sourcecode-markup-start") || "{{{"
        @sourcecode_markup_end = node.attr("sourcecode-markup-end") || "}}}"
        @datauriimage = node.attr("data-uri-image") != "false"
      end

      def init_reqt(node)
        @default_requirement_model = (node.attr("requirements-model") ||
                                        default_requirement_model)
        @reqt_models = requirements_processor
          .new({ default: @default_requirement_model })
      end

      def init_toc(node)
        @htmltoclevels = node.attr("htmltoclevels") ||
          node.attr("toclevels") || toc_default[:html_levels]
        @doctoclevels = node.attr("doctoclevels") ||
          node.attr("toclevels") || toc_default[:word_levels]
        @toclevels = node.attr("toclevels") || toc_default[:word_levels]
        @tocfigures = node.attr("toc-figures")
        @toctables = node.attr("toc-tables")
        @tocrecommendations = node.attr("toc-recommendations")
      end

      def toc_default
        { word_levels: 2, html_levels: 2 }
      end

      def init_output(node)
        @fontheader = default_fonts(node)
        @log = Metanorma::Utils::Log.new
        @files_to_delete = []
        @filename = if node.attr("docfile")
                      File.basename(node.attr("docfile"))&.gsub(/\.adoc$/, "")
                    else ""
                    end
        @localdir = Metanorma::Utils::localdir(node)
        @output_dir = outputdir node
        @fatalerror = []
      end

      def init_i18n(node)
        @lang = (node.attr("language") || "en")
        @script = (node.attr("script") ||
                   Metanorma::Utils.default_script(node.attr("language")))
        @locale = node.attr("locale")
        @isodoc = isodoc(@lang, @script, @locale, node.attr("i18nyaml"))
        @i18n = @isodoc.i18n
      end

      def init_biblio(node)
        @no_isobib_cache = node.attr("no-isobib-cache")
        @no_isobib = node.attr("no-isobib")
        @bibdb = nil
        init_bib_caches(node)
        init_iev_caches(node)
        @local_bibdb =
          ::Metanorma::Standoc::LocalBiblio.new(node, @localdir, self)
      end

      def requirements_processor
        Metanorma::Requirements
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
        ret = to_xml(makexml(node))
        outputs(node, ret) unless node.attr("nodoc") || !node.attr("docfile")
        ret
      end

      def insert_xml_cr(doc)
        doc.gsub(%r{(</(clause|table|figure|p|bibitem|ul|ol|dl|dt|dd|li|example|
                       sourcecode|formula|quote|references|annex|appendix|title|
                       name|note|thead|tbody|tfoot|th|td|form|requirement|
                       recommendation|permission|imagemap|svgmap|preferred|
                       admitted|related|deprecates|letter-symbol|domain|
                       graphical-symbol|expression|abbreviation-type|subject|
                       pronunciation|grammar|term|terms|termnote|termexample|
                       termsource|origin|termref|modification)>)}x, "\\1\n")
          .gsub(%r{(<(title|name))}, "\n\\1")
          .gsub(%r{(<sourcecode[^>]*>)\s+(<name[^>]*>[^<]+</name>)\s+}, "\\1\\2")
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
        @novalid or @log.write("#{@output_dir}#{@filename}.err")
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
        ret = node.attr("doctype")&.gsub(/\s+/, "-")&.downcase || "standard"
        ret = "standard" if ret == "article"
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
        node.attributes.each_with_object([]) do |(k, v), ret|
          %w(presentation semantic).each do |t|
            /^#{t}-metadata-/.match?(k) or next
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
        else File.join(node.attr("output_dir"), "")
        end
      end
    end
  end
end
