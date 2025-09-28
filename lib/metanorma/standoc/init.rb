require_relative "utils"
require_relative "regex"

module Metanorma
  module Standoc
    module Base
      def init(node)
        init_vars
        init_misc(node)
        init_processing(node) # feeds init_i18n
        init_log(node)
        init_image(node)
        init_reqt(node)
        init_toc(node)
        init_output(node) # feeds init_biblio
        init_i18n(node)
        init_biblio(node)
        init_math(node)
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
        @doctype = doctype(node)
        @draft = node.attributes.has_key?("draft")
        @index_terms = node.attr("index-terms")
        @boilerplateauthority = node.attr("boilerplate-authority")
        @embed_hdr = node.attr("embed_hdr")
        @embed_id = node.attr("embed_id")
        @document_scheme = document_scheme(node)
        @source_linenums = node.attr("source-linenums-option") == "true"
        @semantic_headless = node.attr("semantic-metadata-headless") == "true"
        @default_doctype = "standard"
      end

      def init_processing(node)
        @localdir = Metanorma::Utils::localdir(node)
        @xrefstyle = node.attr("xrefstyle")
        @novalid = node.attr("novalid")
        @isolated_conversion_stack = []
        @smartquotes = node.attr("smartquotes") != "false"
        @sourcecode_markup_start = node.attr("sourcecode-markup-start") || "{{{"
        @sourcecode_markup_end = node.attr("sourcecode-markup-end") || "}}}"
        @blockunnumbered = (node.attr("block-unnumbered") || "").split(",")
          .map(&:strip)
      end

      def init_log(node)
        @log or return
        severity = node.attr("log-filter-severity")&.to_i || 4
        category = node.attr("log-filter-category") || ""
        category = category.split(",").map(&:strip)
        @log.suppress_log = { severity:, category: }
      end

      def init_image(node)
        @datauriimage = node.attr("data-uri-image") != "false"
        @datauriattachment = node.attr("data-uri-attachment") != "false"
        @dataurimaxsize = node.attr("data-uri-maxsize")&.to_i || 13981013
      end

      def init_reqt(node)
        @default_requirement_model = node.attr("requirements-model") ||
          default_requirement_model
        @reqt_models = requirements_processor
          .new({ default: @default_requirement_model })
      end

      def init_toc(node)
        @htmltoclevels = node.attr("toclevels-html") ||
          node.attr("htmltoclevels") ||
          node.attr("toclevels") || toc_default[:html_levels]
        @doctoclevels = node.attr("toclevels-doc") ||
          node.attr("doctoclevels") || node.attr("toclevels") ||
          toc_default[:word_levels]
        @pdftoclevels = node.attr("toclevels-pdf") ||
          node.attr("toclevels") || toc_default[:pdf_levels]
        @toclevels = node.attr("toclevels") || toc_default[:html_levels]
        @tocfigures = node.attr("toc-figures")
        @toctables = node.attr("toc-tables")
        @tocrecommendations = node.attr("toc-recommendations")
      end

      def toc_default
        { word_levels: 2, html_levels: 2, pdf_levels: 2 }
      end

      def init_output(node)
        @fontheader = default_fonts(node)
        @files_to_delete = []
        @filename = if node.attr("docfile")
                      File.basename(node.attr("docfile"))&.gsub(/\.adoc$/, "")
                    else ""
                    end
        @output_dir = outputdir node
      end

      def i18nyaml_path(node)
        if i18nyaml = node.attr("i18nyaml")
          (Pathname.new i18nyaml).absolute? or
            i18nyaml = File.join(@localdir, i18nyaml)
        end
        i18nyaml
      end

      def init_i18n(node)
        @lang = node.attr("language") || "en"
        @script = node.attr("script") ||
          Metanorma::Utils.default_script(node.attr("language"))
        @locale = node.attr("locale")
        @isodoc = isodoc(@lang, @script, @locale, i18nyaml_path(node))
        @i18n = @isodoc.i18n
      end

      def init_biblio(node)
        @no_isobib_cache = node.attr("no-isobib-cache")
        @no_isobib = node.attr("no-isobib")
        @flush_caches = node.attr("flush-caches")
        init_bib_log
        @bibdb = nil
        init_bib_caches(node)
        init_iev_caches(node)
        @local_bibdb =
          ::Metanorma::Standoc::LocalBiblio.new(node, @localdir, self)
      end

      def init_bib_log
        @relaton_log = StringIO.new
        relaton_logger = Relaton::Logger::Log
          .new(@relaton_log, levels: %i(info warn error fatal unknown),
                             formatter: Relaton::Logger::FormatterJSON)
        Relaton.logger_pool[:my_logger] = relaton_logger
      end

      def init_math(node)
        @keepasciimath = node.attr("mn-keep-asciimath") &&
          node.attr("mn-keep-asciimath") != "false"
        @numberfmt_default =
          kv_parse(@c.decode(node.attr("number-presentation")))
        numberfmt_formula(node)
        @numberfmt_prof = node.attributes.each_with_object({}) do |(k, v), m|
          p = /^number-presentation-profile-(.*)$/.match(k) or next
          m[p[1]] = kv_parse(@c.decode(v))
        end
      end

      def numberfmt_formula(node)
        @numberfmt_formula = node.attr("number-presentation-formula")
        @numberfmt_formula.nil? ||
          @numberfmt_formula == "number-presentation" and
          @numberfmt_formula = @c.decode(node.attr("number-presentation"))
        @numberfmt_formula == "nil" and @numberfmt_formula = nil
        @numberfmt_formula == "default" and
          @numberfmt_formula = "notation='basic'"
        @numberfmt_formula = @c.decode(@numberfmt_formula)
      end

      def requirements_processor
        Metanorma::Requirements
      end
    end
  end
end
