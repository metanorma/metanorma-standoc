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
          @log.add("Bibliography", nil, e, severity: 0)
        end
      end

      RELATON_SEVERITIES =
        { "INFO": 3, "WARN": 2, "ERROR": 1, "FATAL": 0,
          "UNKNOWN": 3 }.freeze

      def relaton_log_cleanup(_xmldoc)
        @relaton_log or return
        @relaton_log.rewind
        @relaton_log.string.split(/(?<=})\n(?={)/).each do |l|
          e = JSON.parse(l)
          @log.add("Relaton", e["key"], e["message"],
                   severity: RELATON_SEVERITIES[e["severity"].to_sym])
        end
      end

      def docidentifier_cleanup(xmldoc); end

      TEXT_ELEMS =
        %w{status language script version author name callout phone email
           street city state country postcode identifier referenceFrom surname
           referenceTo docidentifier docnumber prefix initial addition forename
           title draft secretariat title-main title-intro title-part
           verbal-definition non-verbal-representation}.freeze

      # it seems Nokogiri::XML is treating the content of <script> as cdata,
      # because of its use in HTML. Bad nokogiri. Undoing that, since we use
      # script as a normal tag
      def script_cleanup(xmldoc)
        xmldoc.xpath("//script").each { |x| x.content = x.to_str }
      end

      def empty_element_cleanup(xmldoc)
        xmldoc.xpath("//#{TEXT_ELEMS.join(' | //')}").each do |x|
          next if x.name == "name" && x.parent.name == "expression"

          x.remove if x.children.empty?
        end
      end

      def element_name_cleanup(xmldoc)
        xmldoc.traverse { |n| n.name = n.name.tr("_", "-") }
      end

      # allows us to deal with doc relation localities,
      # temporarily stashed to "bpart"
      def bpart_cleanup(xmldoc)
        xmldoc.xpath("//relation/bpart").each do |x|
          extract_localities(x)
          x.replace(x.children)
        end
      end

      def variant_cleanup(xmldoc)
        variant_space_cleanup(xmldoc)
        xmldoc.xpath("//*[lang-variant]").each do |c|
          if only_langvariant_children?(c)
            duplicate_langvariants(c, c.xpath("./lang-variant"))
          else
            c.xpath(".//lang-variant").each { |x| x.name = "span" }
          end
        end
      end

      def only_langvariant_children?(node)
        node.children.none? do |n|
          n.name != "lang-variant" && (!n.text? || !n.text.strip.empty?)
        end
      end

      def duplicate_langvariants(container, variants)
        lang_variant_to_node(variants.first, container)
        variants[1..].reverse.each do |node|
          new = container.dup
          lang_variant_to_node(node, new)
          container.next = new
        end
      end

      def lang_variant_to_node(variant, node)
        node.children = variant.children
        node["lang"] = variant["lang"]
        node.delete("script")
        variant["script"] and node["script"] = variant["script"]
      end

      def variant_space_cleanup(xmldoc)
        xmldoc.xpath("//*[lang-variant]").each do |c|
          c.next.nil? || c.next.next.nil? and next
          if c.next.text? && c.next.next.name == "lang-variant"
            c.next.text.gsub(/\s/, "").empty? and
              c.next.remove
          end
        end
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
    end
  end
end
