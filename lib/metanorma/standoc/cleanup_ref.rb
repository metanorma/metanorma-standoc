require "relaton_bib"
require_relative "merge_bibitems"
require_relative "spans_to_bibitem"
require_relative "cleanup_bibitem"

module Metanorma
  module Standoc
    module Cleanup
      def biblio_reorder(xmldoc)
        xmldoc.xpath("//references[@normative = 'false']").each do |r|
          biblio_reorder1(r)
        end
      end

      def biblio_reorder1(refs)
        fold_notes_into_biblio(refs)
        bib = refs.xpath("./bibitem")
        @sort_biblio and bib = sort_biblio(bib)
        insert_sorted_bibitems(refs, bib)
        extract_notes_from_biblio(refs)
        refs.xpath("./references").each { |r| biblio_reorder1(r) }
      end

      def insert_sorted_bibitems(refs, bib)
        insert = refs.at("./bibitem")&.previous_element
        refs.xpath("./bibitem").each(&:remove)
        bib.reverse_each do |b|
          (insert and insert.next = b.to_xml) or
            refs.children.first.add_previous_sibling b.to_xml
        end
      end

      def sort_biblio(bib)
        bib
      end

      # default presuppose that all citations in biblio numbered
      # consecutively, but that standards codes are preserved as is:
      # only numeric references are renumbered
      def biblio_renumber(xmldoc)
        i = 0
        xmldoc.xpath("//references[not(@normative = 'true')]" \
                     "[not(@hidden = 'true')]").each do |r|
          r.xpath("./bibitem[not(@hidden = 'true')]").each do |b|
            i += 1
            docid = b.at("./docidentifier[@type = 'metanorma']") or next
            /^\[\d+\]$/.match?(docid.text) or next
            docid.children = "[#{i}]"
          end
        end
      end

      # move ref before p
      def ref_cleanup(xmldoc)
        xmldoc.xpath("//p/ref").each do |r|
          parent = r.parent
          parent.previous = r.remove
        end
      end

      def normref_cleanup(xmldoc)
        r = xmldoc.at(self.class::NORM_REF) || return
        preface = ((r.xpath("./title/following-sibling::*") & # intersection
                    r.xpath("./bibitem[1]/preceding-sibling::*")) -
        r.xpath("./note[@type = 'boilerplate']/descendant-or-self::*"))
        preface.each(&:remove)
      end

      def biblio_cleanup(xmldoc)
        biblio_reorder(xmldoc)
        biblio_annex(xmldoc)
        biblio_nested(xmldoc)
        biblio_renumber(xmldoc)
        biblio_linkonly(xmldoc)
        biblio_hidden_inherit(xmldoc)
        biblio_no_ext(xmldoc)
      end

      def biblio_linkonly(xmldoc)
        xmldoc.at("//xref[@hidden]") or return
        ins = xmldoc.at("//bibliography")
          .add_child("<references hidden='true' normative='true'/>").first
        refs = xmldoc.xpath("//xref[@hidden]").each_with_object([]) do |x, m|
          @refids << x["target"]
          m << { id: x["target"], ref: x["hidden"] }
          x.delete("hidden")
        end
        ins << insert_hidden_bibitems(refs)
      end

      def insert_hidden_bibitems(bib)
        refs = bib.each_with_object([]) do |b, m|
          m << reference1code(%(<ref id="#{b[:id]}">[#{b[:ref]}]</ref>), nil)
        end
        reference_populate(refs)
      end

      def biblio_annex(xmldoc)
        xmldoc.xpath("//annex[references/references]").each do |t|
          t.xpath("./clause | ./references | ./terms").size == 1 or next
          r = t.at("./references")
          r.xpath("./references").each { |b| b["normative"] = r["normative"] }
          r.replace(r.elements)
        end
      end

      def biblio_nested(xmldoc)
        biblio_nested_initial_items(xmldoc)
        biblio_nested_sections(xmldoc)
      end

      def biblio_nested_initial_items(xmldoc)
        xmldoc.xpath("//references[references][bibitem]").each do |t|
          r = t.at("./references")
          ref = t.at("./bibitem")
            .before("<references unnumbered='true'></references>").previous
          (ref.xpath("./following-sibling::*") &
           r.xpath("./preceding-sibling::*")).each do |x|
            ref << x
          end
        end
      end

      def biblio_nested_sections(xmldoc)
        xmldoc.xpath("//references[references]").each do |t|
          t.name = "clause"
          t.xpath("./references").each { |r| r["normative"] = t["normative"] }
          t.delete("normative")
        end
      end
    end
  end
end
