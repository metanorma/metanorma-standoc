module Metanorma
  module Standoc
    module Base
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
        @doctype = doctype(node)
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
        @blockunnumbered = (node.attr("block-unnumbered") || "").split(",")
          .map(&:strip)
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
        @localdir = Metanorma::Utils::localdir(node)
        @output_dir = outputdir node
      end

      def init_i18n(node)
        @lang = node.attr("language") || "en"
        @script = node.attr("script") ||
          Metanorma::Utils.default_script(node.attr("language"))
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
    end
  end
end
