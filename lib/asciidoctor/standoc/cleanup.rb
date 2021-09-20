require "nokogiri"
require "pathname"
require "html2doc"
require_relative "./cleanup_block"
require_relative "./cleanup_table"
require_relative "./cleanup_footnotes"
require_relative "./cleanup_ref"
require_relative "./cleanup_ref_dl"
require_relative "./cleanup_boilerplate"
require_relative "./cleanup_section"
require_relative "./cleanup_terms"
require_relative "./cleanup_xref"
require_relative "./cleanup_inline"
require_relative "./cleanup_amend"
require_relative "./cleanup_maths"
require_relative "./cleanup_image"
require_relative "./cleanup_reqt"
require_relative "./cleanup_text"
require "relaton_iev"

module Asciidoctor
  module Standoc
    module Cleanup
      def cleanup(xmldoc)
        element_name_cleanup(xmldoc)
        sections_cleanup(xmldoc)
        obligations_cleanup(xmldoc)
        table_cleanup(xmldoc)
        formula_cleanup(xmldoc)
        form_cleanup(xmldoc)
        sourcecode_cleanup(xmldoc)
        figure_cleanup(xmldoc)
        element_name_cleanup(xmldoc)
        ref_cleanup(xmldoc)
        note_cleanup(xmldoc)
        clausebefore_cleanup(xmldoc)
        bibitem_cleanup(xmldoc)
        normref_cleanup(xmldoc)
        biblio_cleanup(xmldoc)
        reference_names(xmldoc)
        symbols_cleanup(xmldoc)
        xref_cleanup(xmldoc)
        concept_cleanup(xmldoc)
        origin_cleanup(xmldoc)
        bookmark_cleanup(xmldoc)
        termdef_cleanup(xmldoc)
        RelatonIev::iev_cleanup(xmldoc, @bibdb)
        element_name_cleanup(xmldoc)
        bpart_cleanup(xmldoc)
        quotesource_cleanup(xmldoc)
        callout_cleanup(xmldoc)
        footnote_cleanup(xmldoc)
        mathml_cleanup(xmldoc)
        script_cleanup(xmldoc)
        docidentifier_cleanup(xmldoc)
        requirement_cleanup(xmldoc)
        bibdata_cleanup(xmldoc)
        svgmap_cleanup(xmldoc)
        boilerplate_cleanup(xmldoc)
        toc_cleanup(xmldoc)
        smartquotes_cleanup(xmldoc)
        variant_cleanup(xmldoc)
        para_cleanup(xmldoc)
        empty_element_cleanup(xmldoc)
        img_cleanup(xmldoc)
        anchor_cleanup(xmldoc)
        xmldoc
      end

      def docidentifier_cleanup(xmldoc); end

      TEXT_ELEMS =
        %w{status language script version author name callout phone email
           street city state country postcode identifier referenceFrom surname
           referenceTo docidentifier docnumber prefix initial addition forename
           title draft secretariat title-main title-intro title-part}.freeze

      # it seems Nokogiri::XML is treating the content of <script> as cdata,
      # because of its use in HTML. Bad nokogiri. Undoing that, since we use
      # script as a normal tag
      def script_cleanup(xmldoc)
        xmldoc.xpath("//script").each { |x| x.content = x.to_str }
      end

      def empty_element_cleanup(xmldoc)
        xmldoc.xpath("//" + TEXT_ELEMS.join(" | //")).each do |x|
          x.remove if x.children.empty?
        end
      end

      def element_name_cleanup(xmldoc)
        xmldoc.traverse { |n| n.name = n.name.gsub(/_/, "-") }
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

          c.xpath("./variant").each do |n|
            if n.at_xpath("preceding-sibling::node()"\
                          "[not(self::text()[not(normalize-space())])][1]"\
                          "[self::variantwrap]")
              n.previous_element << n
            else
              n.replace("<variantwrap/>").first << n
            end
          end
        end
        xmldoc.xpath("//variantwrap").each { |n| n.name = "variant" }
      end

      def variant_space_cleanup(xmldoc)
        xmldoc.xpath("//*[variant]").each do |c|
          if c&.next&.text? && c&.next&.next&.name == "variant"
            c.next.text.gsub(/\s/, "").empty? and
              c.next.remove
          end
        end
      end

      def toc_cleanup(xmldoc)
        toc_cleanup_para(xmldoc)
        xmldoc.xpath("//toc").each { |t| toc_cleanup1(t, xmldoc) }
        toc_cleanup_clause(xmldoc)
      end

      def toc_cleanup_para(xmldoc)
        xmldoc.xpath("//p[toc]").each do |x|
          x.xpath("./toc").reverse.each do |t|
            x.next = t
          end
          x.remove if x.text.strip.empty?
        end
      end

      def toc_index(toc, xmldoc)
        depths = toc_index_depths(toc)
        depths.keys.each_with_object([]) do |key, arr|
          xmldoc.xpath(key).each do |x|
            t = x.at("./following-sibling::variant-title[@type = 'toc']") and
              x = t
            arr << { text: x.children.to_xml, depth: depths[key].to_i,
                     target: x.xpath("(./ancestor-or-self::*/@id)[last()]")[0].text,
                     line: x.line }
          end
        end.sort_by { |a| a[:line] }
      end

      def toc_index_depths(toc)
        toc.xpath("./toc-xpath").each_with_object({}) do |x, m|
          m[x.text] = x["depth"]
        end
      end

      def toc_cleanup1(toc, xmldoc)
        depth = 1
        ret = ""
        toc_index(toc, xmldoc).each do |x|
          if depth > x[:depth] then ret += "</ul></li>" * (depth - x[:depth])
          elsif depth < x[:depth] then ret += "<li><ul>" * (x[:depth] - depth)
          end
          ret += "<li><xref target='#{x[:target]}'>#{x[:text]}</xref></li>"
          depth = x[:depth]
        end
        toc.children = "<ul>#{ret}</ul>"
      end

      def toc_cleanup_clause(xmldoc)
        xmldoc
          .xpath("//clause[@type = 'toc'] | //annex[@type = 'toc']").each do |c|
          c.xpath(".//ul[not(ancestor::ul)]").each do |ul|
            toc_cleanup_clause_entry(xmldoc, ul)
            ul.replace("<toc>#{ul.to_xml}</toc>")
          end
        end
      end

      def toc_cleanup_clause_entry(xmldoc, list)
        list.xpath(".//xref[not(text())]").each do |x|
          c1 = xmldoc.at("//*[@id = '#{x['target']}']")
          t = c1.at("./variant-title[@type = 'toc']") || c1.at("./title")
          x << t.dup.children
        end
      end
    end
  end
end
