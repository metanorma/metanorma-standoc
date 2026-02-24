require "nokogiri"
require "pathname"
require "html2doc"
require "relaton_iev"
require "forwardable"
require_relative "attachment"
require_relative "block"
require_relative "table"
require_relative "footnotes"
require_relative "ref"
require_relative "asciibib"
require_relative "boilerplate"
require_relative "bibdata"
require_relative "bibitem"
require_relative "section"
require_relative "section_names"
require_relative "index"
require_relative "terms"
require_relative "symbols"
require_relative "xref"
require_relative "inline"
require_relative "amend"
require_relative "maths"
require_relative "image"
require_relative "reqt"
require_relative "text"
require_relative "toc"
require_relative "review"
require_relative "dochistory"
require_relative "terms_designations"
require_relative "merge_bibitems"
require_relative "spans_to_bibitem"
require_relative "spans_to_bibitem_preprocessing"

module Metanorma
  module Standoc
    class Cleanup
      extend Forwardable

      attr_reader :log

      # Delegate method calls to converter
      def_delegators :@converter,
                     :isodoc, :to_xml, :csv_split, :isolated_asciidoctor_convert,
                     :xml_namespace, :backend, :reference1code, :reference_populate

      def initialize(converter)
        @converter = converter
        @anchor_alias = {}
        @internal_eref_namespaces = []
        # Shadow instance variables from converter (attributes/accessors)
        @log = converter.log
        @bibdb = converter.bibdb
        @lang = converter.lang
        @script = converter.script
        @libdir = converter.libdir
        @locale = converter.locale
        @novalid = converter.novalid
        @output_dir = converter.output_dir
        @filename = converter.filename
        @files_to_delete = converter.files_to_delete
        @datauriattachment = converter.instance_variable_get(:@datauriattachment)
        # Use instance_variable_get for variables that conflict with methods
        # or don't have clean accessors
        @local_log = converter.instance_variable_get(:@local_log)
        @isodoc = converter.instance_variable_get(:@isodoc)
        @anchors = converter.instance_variable_get(:@anchors)
        @localdir = converter.instance_variable_get(:@localdir)
        @c = converter.instance_variable_get(:@c)
        @refids = converter.instance_variable_get(:@refids)
        @sourcecode_markup_start =
          converter.instance_variable_get(:@sourcecode_markup_start)
        @sourcecode_markup_end =
          converter.instance_variable_get(:@sourcecode_markup_end)
        @smartquotes = converter.instance_variable_get(:@smartquotes)
        @i18n = @isodoc&.i18n
        @toclevels = converter.instance_variable_get(:@toclevels)
        @htmltoclevels = converter.instance_variable_get(:@htmltoclevels)
        @doctoclevels = converter.instance_variable_get(:@doctoclevels)
        @pdftoclevels = converter.instance_variable_get(:@pdftoclevels)
        @stage_published = converter.instance_variable_get(:@stage_published)
        @numberfmt_default = converter.instance_variable_get(:@numberfmt_default)
        # Reuse converter's relaton_log instead of creating a new one
        @relaton_log = converter.relaton_log
      end

      # Include all cleanup modules
      include Attachment
      include Block
      include Table
      include Footnotes
      include Ref
      include Asciibib
      include Boilerplate
      include Bibdata
      include Bibitem
      include Section
      include SectionNames
      include Index
      include Terms
      include Symbols
      include Xref
      include Inline
      include Amend
      include Maths
      include Image
      include Reqt
      include Text
      include Toc
      include Review
      include Dochistory
      include TermsDesignations

      def cleanup(xmldoc)
        @doctype = xmldoc.at("//bibdata/ext/doctype")&.text
        element_name_cleanup(xmldoc)
        source_include_cleanup(xmldoc) # feeds: misccontainer_cleanup
        passthrough_cleanup(xmldoc) # feeds: smartquotes_cleanup
        annotation_cleanup(xmldoc)
        unnumbered_blocks_cleanup(xmldoc)
        termdocsource_cleanup(xmldoc) # feeds: metadata_cleanup
        metadata_cleanup(xmldoc) # feeds: boilerplate_cleanup, bibdata_cleanup,
        # docidentifier_cleanup (in generic: template)
        misccontainer_cleanup(xmldoc)
        sections_cleanup(xmldoc) # feeds: obligations_cleanup, toc_cleanup,
        # floatingtitle_cleanup
        obligations_cleanup(xmldoc)
        para_index_cleanup(xmldoc)
        block_index_cleanup(xmldoc)
        key_cleanup(xmldoc) # feeds: table_cleanup, figure_cleanup,
        # formula_cleanup
        table_cleanup(xmldoc) # feeds: blocksource_cleanup
        formula_cleanup(xmldoc)
        form_cleanup(xmldoc)
        sourcecode_cleanup(xmldoc) # feeds: callout_cleanup
        figure_cleanup(xmldoc)
        blocksource_cleanup(xmldoc)
        requirement_cleanup(xmldoc) # feeds: xref_cleanup
        element_name_cleanup(xmldoc)
        ref_cleanup(xmldoc) # feeds: bibitem_cleanup
        note_cleanup(xmldoc)
        clausebefore_cleanup(xmldoc) # feeeds: floatingtitle_cleanup
        floatingtitle_cleanup(xmldoc)
        bibitem_cleanup(xmldoc) # feeds: normref_cleanup, biblio_cleanup,
        # reference_names, bpart_cleanup, attachment_cleanup
        normref_cleanup(xmldoc)
        biblio_cleanup(xmldoc)
        reference_names(xmldoc)
        terms_terms_cleanup(xmldoc) # feeds: boilerplate_cleanup
        asciimath_cleanup(xmldoc) # feeds: mathml_cleanup, termdef_cleanup,
        # symbols_cleanup
        symbols_cleanup(xmldoc) # feeds: termdef_cleanup
        xref_cleanup(xmldoc) # feeds: concept_cleanup, origin_cleanup
        concept_cleanup(xmldoc) # feeds: related_cleanup, termdef_cleanup
        related_cleanup(xmldoc) # feeds: termdef_cleanup
        origin_cleanup(xmldoc) # feeds: termdef_cleanup
        bookmark_cleanup(xmldoc)
        termdef_cleanup(xmldoc) # feeds: relaton_iev_cleanup, term_index_cleanup
        relaton_iev_cleanup(xmldoc)
        relaton_log_cleanup(xmldoc)
        element_name_cleanup(xmldoc)
        term_index_cleanup(xmldoc)
        bpart_cleanup(xmldoc)
        quotesource_cleanup(xmldoc)
        callout_cleanup(xmldoc)
        footnote_cleanup(xmldoc)
        ol_cleanup(xmldoc)
        mathml_cleanup(xmldoc)
        script_cleanup(xmldoc)
        docidentifier_cleanup(xmldoc) # feeds: bibdata_cleanup
        ext_contributor_cleanup(xmldoc) # feeds: bibdata_cleanup
        ext_dochistory_cleanup(xmldoc) # feeds: bibdata_cleanup
        bibdata_cleanup(xmldoc) # feeds: boilerplate_cleanup
        boilerplate_cleanup(xmldoc) # feeds: xref_cleanup for new <<>>
        # introduced, pres_metadata_cleanup
        pres_metadata_cleanup(xmldoc)
        xref_cleanup(xmldoc)
        svgmap_cleanup(xmldoc) # feeds: img_cleanup
        review_cleanup(xmldoc)
        toc_cleanup(xmldoc)
        smartquotes_cleanup(xmldoc)
        linebreak_cleanup(xmldoc)
        variant_cleanup(xmldoc)
        para_cleanup(xmldoc)
        source_id_cleanup(xmldoc)
        empty_element_cleanup(xmldoc)
        img_cleanup(xmldoc)
        anchor_cleanup(xmldoc)
        link_cleanup(xmldoc)
        passthrough_metanorma_cleanup(xmldoc)
        metadata_cleanup_final(xmldoc)
        xmldoc
      end

      def relaton_iev_cleanup(xmldoc)
        _, err = RelatonIev::iev_cleanup(xmldoc, @bibdb)
        err.each do |e|
          @log.add("RELATON_5", nil, params: e)
        end
      end

      RELATON_SEVERITIES =
        { "INFO": "RELATON_4", "WARN":  "RELATON_3", "ERROR":  "RELATON_2",
          "FATAL": "RELATON_1", "UNKNOWN":  "RELATON_4" }.freeze

      def relaton_log_cleanup(_xmldoc)
        @relaton_log or return
        @relaton_log.rewind
        @relaton_log.string.split(/(?<=})\n(?={)/).each do |l|
          e = JSON.parse(l)
          relaton_log_add?(e) and
            @log.add(RELATON_SEVERITIES[e["severity"].to_sym], e["key"],
                     params: [e["message"]])
        end
      end

      def relaton_log_add?(entry)
        entry["message"].include?("Fetching from") and return false
        entry["message"].include?("Downloaded index from") and return false
        entry["message"].start_with?("Found:") or return true
        id = /^Found: `(.+)`$/.match(entry["message"]) or return true
        !relaton_key_eqv?(entry["key"], id[1])
      end

      def relaton_key_eqv?(sought, found)
        sought = sought.sub(" (all parts)", "").sub(/:(19|20)\d\d$/, "")
        found = found.sub(" (all parts)", "").sub(/:(19|20)\d\d$/, "")
        sought.end_with?(found)
      end

      def docidentifier_cleanup(xmldoc); end

      TEXT_ELEMS =
        %w{status language script version author name callout phone email
           street city state country postcode identifier referenceFrom surname
           referenceTo docidentifier docnumber prefix initial addition forename
           title draft secretariat title-main title-intro title-part
           verbal-definition non-verbal-representation}.freeze

      # it seems Nokogiri::XML is treating the content of <script> as cdata,
      # because of its use in HTML. Bad Nokogiri. Undoing that, since we use
      # script as a normal tag
      def script_cleanup(xmldoc)
        xmldoc.xpath("//script").each { |x| x.content = x.to_str }
      end

      def empty_element_cleanup(xmldoc)
        xmldoc.xpath("//#{TEXT_ELEMS.join(' | //')}").each do |x|
          x.name == "name" && x.parent.name == "expression" and next
          x.children.empty? and x.remove
        end
      end

      def element_name_cleanup(xmldoc)
        xmldoc.traverse { |n| n.name = n.name.tr("_", "-") }
      end

      def metadata_cleanup(xmldoc)
        bibdata_published(xmldoc) # feeds: bibdata_cleanup,
        # docidentifier_cleanup (in generic: template)
        metadata_attrs = @converter.instance_variable_get(:@metadata_attrs)
        (metadata_attrs.nil? || metadata_attrs.empty?) and return
        ins = add_misc_container(xmldoc)
        ins << metadata_attrs
      end

      def pres_metadata_cleanup(xmldoc)
        unless @isodoc
          @isodoc = isodoc(@lang, @script, @locale)
          @converter.instance_variable_set(:@isodoc, @isodoc)
        end
        isodoc_bibdata_parse(xmldoc)
        xmldoc.xpath("//presentation-metadata/* | //semantic-metadata/*")
          .each do |x|
            /\{\{|\{%/.match?(x) or next
            x.children = @isodoc.populate_template(
              to_xml(x.children), nil
            )
        end
      end

      def metadata_cleanup_final(xmldoc)
        root = nil
        %w(semantic presentation).each do |k|
          xmldoc.xpath("//#{k}-metadata").each_with_index do |x, i|
            if i.zero? then root = x
            else
              root << x.remove.elements
            end
          end
        end
      end

      def annotation_cleanup(xmldoc)
        ret = xmldoc.xpath("//annotation[@type = 'ignore-log']")
          .each_with_object([]) do |ann, m|
            error_ids = Array(csv_split(ann.text || "", ","))
            m << { from: ann["from"], to: ann["to"], error_ids: error_ids }
            ann
        end
        config = @log.suppress_log
        config[:locations] += ret
        @log.suppress_log = config
      end
    end
  end
end
