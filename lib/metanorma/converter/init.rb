require_relative "utils"
require_relative "regex"
require "json"

module Metanorma
  module Standoc
    module Base
      def init(node)
        init_vars
        init_misc(node)
        init_processing(node) # feeds init_i18n
        init_log(node)
        init_suppression(node)
        init_image(node)
        init_reqt(node)
        init_toc(node)
        init_output(node) # feeds init_biblio
        init_i18n(node)
        init_biblio(node)
        init_math(node)
        init_xref(node)
        init_metadata(node)
      end

      def init_metadata(node)
        @doctype = doctype(node)
        @draft = node.attributes.has_key?("draft")
        @document_scheme = document_scheme(node)
        @default_doctype = "standard"
        @stage_published = node.attr("docstage-published")
        @docstage_valid = node.attr("docstage-valid")&.split(/,\s*/)
        @metadata_attrs = metadata_attrs(node)
      end

      def init_vars
        @files_to_delete ||= [] # early init failures must not mask in clean_exit
        @fn_number ||= 0
        @refids = Set.new
        @anchors = {}
        @seen_headers = []
        @seen_headers_canonical = []
        @embed_hdr = []
        @reqt_model = nil
        @preface = true
      end

      def init_misc(node)
        @index_terms = node.attr("index-terms")
        @boilerplateauthority = node.attr("boilerplate-authority")
        @embed_hdr = node.attr("embed_hdr")
        @embed_id = node.attr("embed_id")
        @source_linenums = node.attr("source-linenums-option") == "true" # feeds log
        @semantic_headless = node.attr("semantic-metadata-headless") == "true"
      end

      def init_xref(node)
        @xrefstyle = node.attr("xrefstyle")
        @erefstyle = node.attr("erefstyle")
        @originstyle = node.attr("originstyle")
      end

      def init_processing(node)
        @localdir = Metanorma::Utils::localdir(node)
        @novalid = node.attr("novalid")
        @nocleanup = node.attr("nocleanup")
        @isolated_conversion_stack = []
        @smartquotes = node.attr("smartquotes") != "false"
        @sourcecode_markup_start = node.attr("sourcecode-markup-start") || "{{{"
        @sourcecode_markup_end = node.attr("sourcecode-markup-end") || "}}}"
        @blockunnumbered = csv_split(node.attr("block-unnumbered"), ",")
      end

      def init_log(node)
        @log or return
        @semantic_headless and return
        severity = node.attr("log-filter-severity")&.to_i || 4
        category = csv_split(node.attr("log-filter-category"), ",")
        error_ids = csv_split(node.attr("log-filter-error-ids"), ",")
        error_regexes = extract_log_filter_error_regex(node)
        locations = cleanup_log_filter_error_log(
          extract_log_filter_error_loc(node),
        )
        @log.suppress_log = { severity:, category:, error_ids:,
                              error_regexes:, locations: }
      end

      # `log-filter-error-regex`: comma-separated regexes matched against the
      # interpolated message text, suppressing matching entries without
      # suppressing the other messages sharing the code (utils Log).
      def extract_log_filter_error_regex(node)
        csv_split(node.attr("log-filter-error-regex"), ",")
          &.map { |r| Regexp.new(r) } || []
      end

      def extract_log_filter_error_loc(node)
        locations = JSON.parse(node.attr("log-filter-error-loc") || "[]")
        locations = [locations] unless locations.is_a?(Array)
        locations.map { |loc| loc.transform_keys(&:to_sym) }
      end

      def cleanup_log_filter_error_log(locations)
        locations.each do |loc|
          loc[:to] ||= loc[:from]
          loc[:error_ids] ||= []
          loc[:error_ids] &&= Array(loc[:error_ids])
        end
      end

      # Declarative validation suppression (metanorma-standoc#1369).
      # Resolution chain: flavor config < taste config < document config.
      # Absent layers are skipped silently; a malformed layer raises
      # naming the layer. The resolved config is injected into the log
      # (utils Log suppression hook), and one Suppression entry
      # (STANDOC_68) summarizes the effective configuration.
      def init_suppression(node)
        @log or return
        flavor_cfg, flavor_src = gem_suppression_config(
          "metanorma-#{validation_flavor_name}", validation_flavor_name,
          "flavor",
        )
        taste_cfg, taste_src = taste_suppression_config(node)
        doc_cfg, doc_src = document_suppression_config(node)

        layers = [flavor_cfg, taste_cfg, doc_cfg].compact
        return if layers.empty?

        config = layers.reduce { |base, higher| base.merge(higher) }
        return if config.empty?

        @log.suppression = config
        log_suppression_dump([flavor_src, taste_src, doc_src].compact,
                             config)
      end

      # The flavor identity, derived from the most-derived Validate
      # subclass declaring validation_flavor (metanorma-iso declares
      # "iso", metanorma-bsi "bsi", standoc "standoc").
      def validation_flavor_name
        m = validate_class.instance_method(:validation_flavor)
        m.owner.name.sub(/\AMetanorma::/, "").sub(/::Validate\z/, "")
          .downcase
      rescue NameError
        "standoc"
      end

      def taste_suppression_config(node)
        taste = node.attr("taste") || ENV["METANORMA_TASTE"] or return
        gem_suppression_config("metanorma-taste-#{taste}", taste, "taste")
      end

      # A gem layer: +gem_name+ ships
      # lib/metanorma/<dir>/validation_policy/metanorma.yml. Absent gem
      # (Gem::LoadError) or absent file: layer skipped silently; a
      # malformed file raises naming the layer.
      def gem_suppression_config(gem_name, dir, layer)
        spec = Gem::Specification.find_by_name(gem_name)
        path = File.join(spec.gem_dir, "lib", "metanorma", dir,
                         "validation_policy", "metanorma.yml")
        return unless File.exist?(path)

        [load_suppression_config(path, layer), path]
      rescue Gem::LoadError
        nil
      end

      def load_suppression_config(path, layer)
        Validate::Suppression::Config.from_yaml(path)
      rescue StandardError => e
        raise ArgumentError,
              "invalid validation suppression config " \
              "(#{layer} layer): #{e.message}"
      end

      def validation_config_path(node)
        if (ret = node.attr("validation-config"))
          (Pathname.new ret).absolute? or
            ret = File.join(@localdir, ret)
        end
        ret
      end

      # Document layer: :validation-config: file, then the
      # :validation-off: / :validation-warning: sugars, then the
      # log-filter-* aliases (same layer: later parts override earlier
      # parts per code).
      def document_suppression_config(node)
        parts = []
        if (path = validation_config_path(node))
          parts << [load_suppression_config(path, "document"), path]
        end
        sugar = suppression_sugar_config(node)
        unless sugar.empty?
          parts << [sugar, ":validation-off:/:validation-warning:"]
        end
        legacy = legacy_suppression_config(node)
        unless legacy.empty?
          parts << [legacy, "log-filter-* (legacy aliases)"]
        end
        return [nil, nil] if parts.empty?

        config = parts.map(&:first)
          .reduce { |base, higher| base.merge(higher) }
        [config, parts.map(&:last).join(", ")]
      end

      # `:validation-off:` codes drop; `:validation-warning:` codes
      # reclassify to warning.
      def suppression_sugar_config(node)
        cfg = Validate::Suppression::Config.new
        cfg.rules =
          Array(csv_split(node.attr("validation-off"), ",")).map do |code|
            Validate::Suppression::RuleEntry.new(code: code.strip,
                                                 severity: "off")
          end +
          Array(csv_split(node.attr("validation-warning"), ",")).map do |code|
            Validate::Suppression::RuleEntry.new(code: code.strip,
                                                 severity: "warning")
          end
        cfg
      end

      # Alias migration (behavior-preserving): the legacy
      # log-filter-error-ids and log-filter-category attributes translate
      # 1:1 onto Config rules. Their enforcement remains with the
      # untouched suppress_log path, which drops those entries before the
      # suppression hook is consulted, so existing behavior is
      # bit-identical; the translation surfaces them in the
      # effective-config dump and prepares the deprecation-notice
      # release. log-filter-severity, log-filter-error-regex and
      # log-filter-error-loc have no v1 Config equivalent and stay
      # suppress_log-only.
      def legacy_suppression_config(node)
        cfg = Validate::Suppression::Config.new
        ids = Array(csv_split(node.attr("log-filter-error-ids"), ","))
        cats = Array(csv_split(node.attr("log-filter-category"), ","))
        cfg.rules = ids.map do |c|
          Validate::Suppression::RuleEntry.new(code: c.strip,
                                               severity: "off")
        end
        unless cats.empty?
          cfg.category_rules = { "category" => cats.each_with_object({}) do |c, m|
            m[c.strip] = { "severity" => "off" }
          end }
        end
        cfg
      end

      # One Suppression entry (STANDOC_68, info severity, display off)
      # summarizing the effective configuration.
      def log_suppression_dump(sources, config)
        counts = config.rules_count
        parts = ["sources: #{sources.join(', ')}",
                 "code rules: #{counts[:total]} " \
                 "(off: #{counts[:off]}, " \
                 "reclassified: #{counts[:reclassified]})"]
        parts << "allow patterns: #{counts[:allow]}" if counts[:allow].positive?
        parts << "exclude patterns: #{counts[:exclude]}" if counts[:exclude].positive?
        parts << "family rules: #{counts[:family]}" if counts[:family].positive?
        @log.add("STANDOC_68", nil, display: false, params: [parts.join("; ")])
      end

      def init_image(node)
        @datauriimage = node.attr("data-uri-image") != "false"
        @datauriattachment = node.attr("data-uri-attachment") != "false"
        @dataurimaxsize = node.attr("data-uri-maxsize")&.to_i || 13981013
        @svg_conform_profile = node.attr("svg-conform-profile")
        @png_conform_profile = node.attr("png-conform-profile")
      end

      def init_reqt(node)
        @default_requirement_model = node.attr("requirements-model") ||
          default_requirement_model
        @default_requirement_render = node.attr("requirements-render")
        conv = presentation_xml_converter(EmptyAttr.new)
        @reqt_models = requirements_processor
          .new({ default: @default_requirement_model, conv: conv })
      end

      def init_toc(node)
        init_toc_levels(node)
        init_toc_types(node)
      end

      def init_toc_levels(node)
        @htmltoclevels = node.attr("toclevels-html") ||
          node.attr("htmltoclevels") ||
          node.attr("toclevels") || toc_default[:html_levels]
        @doctoclevels = node.attr("toclevels-doc") ||
          node.attr("doctoclevels") || node.attr("toclevels") ||
          toc_default[:word_levels]
        @pdftoclevels = node.attr("toclevels-pdf") ||
          node.attr("toclevels") || toc_default[:pdf_levels]
        @toclevels = node.attr("toclevels") || toc_default[:html_levels]
      end

      def init_toc_types(node)
        @tocfigures = node.attr("toc-figures") != "false"
        @toctables = node.attr("toc-tables") != "false"
        @tocrecommendations = node.attr("toc-recommendations") != "false"
        @tocexamples = node.attr("toc-examples") != "false"
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
        if ret = node.attr("i18nyaml")
          (Pathname.new ret).absolute? or
            ret = File.join(@localdir, ret)
        end
        ret
      end

      def relaton_render_path(node)
        if ret = node.attr("relaton-render-config")
          (Pathname.new ret).absolute? or
            ret = File.join(@localdir, ret)
        end
        ret
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
        @sort_biblio = node.attr("sort-biblio") != "false"
        @publisher_sort_config = init_publisher_sort_config(node)
        init_bib_db(node)
        init_bib_caches(node)
        init_iev_caches(node)
        init_bib_log
        @biblio_cutoff = biblio_cutoff(node)
      end

      # Per-publisher bibliography sort ranks, from
      # :sort-biblio-<abbrev>: <rank>: <name> document attributes (set directly
      # in a document or injected by a metanorma-taste config). AsciiDoc
      # lowercases attribute names, so <abbrev> is matched case-insensitively
      # downstream. Returns [] when none are set (flavours keep their default
      # publisher ordering).
      def init_publisher_sort_config(node)
        node.attributes.each_with_object([]) do |(k, v), acc|
          m = /\Asort-biblio-(?<abbrev>.+)\z/.match(k.to_s) or next
          rank_s, name = v.to_s.split(":", 2)
          rank = Integer(rank_s.to_s.strip, exception: false) or next
          acc << { abbrev: m[:abbrev].strip, name: name&.strip, rank: rank }
        end
      end

      def init_bib_db(node)
        @bibdb = nil
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

      def biblio_cutoff(node)
        # An explicit :bibliography-cutoff-date: overrides the date derived from
        # the document's own dates, and a sentinel (none/false/no/off) disables
        # the cutoff entirely. metanorma/metanorma-standoc#941.
        if (override = node.attr("bibliography-cutoff-date"))
          override = override.strip
          return nil if %w(none false no off).include?(override.downcase)

          return complete_and_compare_dates([override])
        end
        dates = %w(revdate published-date accessed-date created-date
                   implemented-date confirmed-date updated-date issued-date
                   circulated-date unchanged-date copyright-year)
          .each_with_object([]) do |k, m|
          date = node.attr(k) or next
          m << date
        end
        dates.empty? and return nil
        complete_and_compare_dates(dates)
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
