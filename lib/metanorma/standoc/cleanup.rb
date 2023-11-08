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
require "relaton_iev"

module Metanorma
  module Standoc
    module Cleanup
      def cleanup(xmldoc)
        @doctype = xmldoc.at("//bibdata/ext/doctype")&.text
        element_name_cleanup(xmldoc)
        passthrough_cleanup(xmldoc)
        unnumbered_blocks_cleanup(xmldoc)
        metadata_cleanup(xmldoc) # feeds: boilerplate_cleanup
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
        asciimath_cleanup(xmldoc) # feeds: mathml_cleanup, termdef_cleanup, symbols_cleanup
        symbols_cleanup(xmldoc) # feeds: termdef_cleanup
        xref_cleanup(xmldoc) # feeds: concept_cleanup, origin_cleanup
        concept_cleanup(xmldoc) # feeds: related_cleanup, termdef_cleanup
        related_cleanup(xmldoc) # feeds: termdef_cleanup
        origin_cleanup(xmldoc) # feeds: termdef_cleanup
        bookmark_cleanup(xmldoc)
        termdef_cleanup(xmldoc) # feeds: iev_cleanup, term_index_cleanup
        RelatonIev::iev_cleanup(xmldoc, @bibdb)
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
        bibdata_cleanup(xmldoc)
        svgmap_cleanup(xmldoc) # feeds: img_cleanup
        boilerplate_cleanup(xmldoc)
        toc_cleanup(xmldoc)
        smartquotes_cleanup(xmldoc)
        variant_cleanup(xmldoc)
        para_cleanup(xmldoc)
        empty_element_cleanup(xmldoc)
        img_cleanup(xmldoc)
        anchor_cleanup(xmldoc)
        link_cleanup(xmldoc)
        xmldoc
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
        xmldoc.traverse { |n| n.name = n.name.gsub("_", "-") }
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
        xmldoc.xpath("//*[variant]").each do |c|
          next unless c.children.any? do |n|
            n.name != "variant" && (!n.text? || !n.text.gsub(/\s/, "").empty?)
          end

          variant_cleanup1(c)
        end
        xmldoc.xpath("//variantwrap").each { |n| n.name = "variant" }
      end

      def variant_cleanup1(elem)
        elem.xpath("./variant").each do |n|
          if n.at_xpath("preceding-sibling::node()" \
                        "[not(self::text()[not(normalize-space())])][1]" \
                        "[self::variantwrap]")
            n.previous_element << n
          else
            n.replace("<variantwrap/>").first << n
          end
        end
      end

      def variant_space_cleanup(xmldoc)
        xmldoc.xpath("//*[variant]").each do |c|
          next if c.next.nil? || c.next.next.nil?

          if c.next.text? && c.next.next.name == "variant"
            c.next.text.gsub(/\s/, "").empty? and
              c.next.remove
          end
        end
      end

      def metadata_cleanup(xmldoc)
        (@metadata_attrs.nil? || @metadata_attrs.empty?) and return
        ins = add_misc_container(xmldoc)
        ins << @metadata_attrs
      end
    end
  end
end
