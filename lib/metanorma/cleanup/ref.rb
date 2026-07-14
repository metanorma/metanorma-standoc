require "relaton/bib"
require_relative "merge_bibitems"
require_relative "spans_to_bibitem"
require_relative "bibitem"

module Metanorma
  module Standoc
    module Ref
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

      BIBLIO_PUBLISHER_ORG =
        "./contributor[role/@type = 'publisher']/organization".freeze

      # Configurable publisher sort ranking, shared by every flavour's
      # bibliography sort. `table` is the flavour's default ordering, an array
      # of { abbrev:, name:, rank: }. A per-document / metanorma-taste override
      # (:sort-biblio-<abbrev>: <rank>: <name> attributes, captured into
      # @publisher_sort_config) REPLACES the flavour default when present.
      #
      # A matched publisher gets its configured rank; an unmatched standards
      # reference sorts immediately after the ranked publishers, and a
      # non-standard reference last. With no override and the flavour's own
      # default table, this reproduces the flavour's historical hardcoded ranks.
      def publisher_sort_rank(bib, table)
        table = publisher_sort_table(table)
        if (entry = publisher_sort_match(bib, table))
          return entry[:rank]
        end

        maxrank = table.map { |e| e[:rank] }.max || 0
        biblio_standards_ref?(bib) ? maxrank + 1 : maxrank + 2
      end

      # Secondary sort token: the co-publisher(s) other than the matched
      # primary. Deterministic when several co-publishers exist (returns the
      # smallest token), which reproduces e.g. JIS's "JIS+IEC before
      # JIS+ISO, JIS+IEC+ISO alongside JIS+IEC" ordering.
      def publisher_sort_second(bib, table)
        entry = publisher_sort_match(bib, publisher_sort_table(table))
        entry or return ""
        bib.xpath(BIBLIO_PUBLISHER_ORG)
          .reject { |o| publisher_org_match?(o, entry) }
          .map { |o| (o.at("./abbreviation") || o.at("./name"))&.text&.strip }
          .compact.reject(&:empty?).min || ""
      end

      def publisher_sort_table(default_table)
        cfg = @publisher_sort_config
        cfg && !cfg.empty? ? cfg : default_table
      end

      # lowest-ranked table entry whose publisher appears on the bibitem
      def publisher_sort_match(bib, table)
        orgs = bib.xpath(BIBLIO_PUBLISHER_ORG)
        table.sort_by { |e| e[:rank] }.find do |e|
          orgs.any? { |o| publisher_org_match?(o, e) }
        end
      end

      # A table entry matches a publisher organization on its abbreviation
      # (case-insensitive, since AsciiDoc lowercases attribute-derived abbrevs)
      # or on any of its names (`name` may be a single string or an array; the
      # latter lets a flavour list, e.g., a Japanese and an English publisher
      # name for the same rank).
      def publisher_org_match?(org, entry)
        abbr = org.at("./abbreviation")&.text&.strip
        name = org.at("./name")&.text&.strip
        names = Array(entry[:name]).map { |n| n.to_s.strip }.reject(&:empty?)
        (!entry[:abbrev].to_s.empty? && abbr&.casecmp?(entry[:abbrev])) ||
          (!name.to_s.empty? && names.include?(name))
      end

      # Whether a bibitem is a standards reference (sorts after the ranked
      # publishers, before non-standard references). Base definition: it has a
      # typed, non-DOI/ISSN/ISBN docidentifier. Flavours may widen this (ISO
      # also treats an untyped docidentifier as a standards reference).
      def biblio_standards_ref?(bib)
        !!bib.at("./docidentifier[@type][not(#{@conv.skip_docid} or " \
                 "@type = 'metanorma')]")
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
          m << @conv
            .reference1code(%(<ref id="#{b[:id]}">[#{b[:ref]}]</ref>), nil)
        end
        @conv.reference_populate(refs)
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
