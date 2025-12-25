require "nokogiri"
require "pathname"
require "html2doc"
require_relative "cleanup_block"
require_relative "cleanup_table"
require_relative "cleanup_footnotes"
require_relative "cleanup_ref"
require_relative "cleanup_asciibib"
require_relative "cleanup_boilerplate"
require_relative "cleanup_bibdata"
require_relative "cleanup_section"
require_relative "cleanup_index"
require_relative "cleanup_terms"
require_relative "cleanup_symbols"
require_relative "cleanup_xref"
require_relative "cleanup_inline"
require_relative "cleanup_amend"
require_relative "cleanup_maths"
require_relative "cleanup_image"
require_relative "cleanup_reqt"
require_relative "cleanup_text"
require_relative "cleanup_toc"
require_relative "cleanup_review"
require_relative "cleanup_dochistory"
require "relaton_iev"

module Metanorma
  module Standoc
    module Cleanup
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
        # reference_names, bpart_cleanup
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
        entry["key"].end_with?(id[1]) and return false
        true
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
        (@metadata_attrs.nil? || @metadata_attrs.empty?) and return
        ins = add_misc_container(xmldoc)
        ins << @metadata_attrs
      end

      def pres_metadata_cleanup(xmldoc)
        @isodoc ||= isodoc(@lang, @script, @locale)
        isodoc_bibdata_parse(xmldoc)
        xmldoc.xpath("//presentation-metadata/* | //semantic-metadata/*")
          .each do |x|
          /\{\{|\{%/.match?(x) or next
          x.children = @isodoc.populate_template(to_xml(x.children), nil)
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
