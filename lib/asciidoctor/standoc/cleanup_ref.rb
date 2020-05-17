require "set"
require "relaton_bib"

module Asciidoctor
  module Standoc
    module Cleanup
      def biblio_reorder(xmldoc)
        xmldoc.xpath("//references[@normative = 'false']").each do |r|
          biblio_reorder1(r)
        end
      end

      def biblio_reorder1(refs)
        fold_notes_into_biblio(refs)
        bib = sort_biblio(refs.xpath("./bibitem"))
        insert = refs&.at("./bibitem")&.previous_element
        refs.xpath("./bibitem").each { |b| b.remove }
        bib.reverse.each do |b|
          insert and insert.next = b.to_xml or
            refs.children.first.add_previous_sibling b.to_xml
        end
        extract_notes_from_biblio(refs)
        refs.xpath("./references").each { |r| biblio_reorder1(r) }
      end

      def fold_notes_into_biblio(refs)
        refs.xpath("./bibitem").each do |r|
          while r&.next_element&.name == "note" do
            r.next_element["appended"] = true
            r << r.next_element.remove
          end
        end
      end

      def extract_notes_from_biblio(refs)
        refs.xpath("./bibitem").each do |r|
          r.xpath("./note[@appended]").reverse.each do |n|
            n.delete("appended")
            r.next = n
          end
        end
      end

      def sort_biblio(bib)
        bib
      end

      # default presuppose that all citations in biblio numbered
      # consecutively, but that standards codes are preserved as is:
      # only numeric references are renumbered
      def biblio_renumber(xmldoc)
        r = xmldoc.at("//references[@normative = 'false'] | "\
                      "//clause[.//references[@normative = 'false']]") or return
        r.xpath(".//bibitem[not(ancestor::bibitem)]").each_with_index do |b, i|
          next unless docid = b.at("./docidentifier[@type = 'metanorma']")
          next unless  /^\[\d+\]$/.match(docid.text)
          docid.children = "[#{i + 1}]"
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
        preface = r.xpath("./title/following-sibling::*") & # intersection
          r.xpath("./bibitem[1]/preceding-sibling::*")
        preface.each { |n| n.remove }
      end

      def biblio_cleanup(xmldoc)
        biblio_reorder(xmldoc)
        biblio_nested(xmldoc)
        biblio_renumber(xmldoc)
      end

      def biblio_nested(xmldoc)
        xmldoc.xpath("//references[references]").each do |t|
          t.name = "clause"
          t.xpath("./references").each { |r| r["normative"] = t["normative"] }
          t.delete("normative")
        end
      end

      def docid_prefix(prefix, docid)
        docid = "#{prefix} #{docid}" unless omit_docid_prefix(prefix)
        docid
      end

      def omit_docid_prefix(prefix)
        return true if prefix.nil? || prefix.empty?
        %(ISO IEC IEV ITU metanorma).include? prefix
      end

      def format_ref(ref, type, isopub)
        return docid_prefix(type, ref) if isopub
        return "[#{ref}]" if /^\d+$/.match(ref) && !/^\[.*\]$/.match(ref)
        ref
      end

      ISO_PUBLISHER_XPATH =
        "./contributor[role/@type = 'publisher']/"\
        "organization[abbreviation = 'ISO' or abbreviation = 'IEC' or "\
        "name = 'International Organization for Standardization' or "\
        "name = 'International Electrotechnical Commission']".freeze

      def reference_names(xmldoc)
        xmldoc.xpath("//bibitem[not(ancestor::bibitem)]").each do |ref|
          isopub = ref.at(ISO_PUBLISHER_XPATH)
          docid = ref.at("./docidentifier[@type = 'metanorma']") ||
            ref.at("./docidentifier[not(@type = 'DOI')]") or next
          reference = format_ref(docid.text, docid["type"], isopub)
          @anchors[ref["id"]] = { xref: reference }
        end
      end

      def ref_dl_cleanup(xmldoc)
        xmldoc.xpath("//clause[@bibitem = 'true']").each do |c|
          bib = dl_bib_extract(c) or next
          bibitemxml = RelatonBib::BibliographicItem.new(
            RelatonBib::HashConverter::hash_to_bib(bib)).to_xml or next
          bibitem = Nokogiri::XML(bibitemxml)
          bibitem["id"] = c["id"] if c["id"]
          c.replace(bibitem.root)
        end
      end

      def extract_from_p(tag, bib, key)
        return unless bib[tag]
        "<#{key}>#{bib[tag].at('p').children}</#{key}>"
      end

      # if the content is a single paragraph, replace it with its children
      # single links replaced with uri
      def p_unwrap(p)
        elems = p.elements
        if elems.size == 1 && elems[0].name == "p"
          link_unwrap(elems[0]).children.to_xml.strip
        else
          p.to_xml.strip
        end
      end

      def link_unwrap(p)
        elems = p.elements
        if elems.size == 1 && elems[0].name == "link"
          p.at("./link").replace(elems[0]["target"].strip)
        end
        p
      end

      def dd_bib_extract(dtd)
        return nil if dtd.children.empty?
        dtd.at("./dl") and return dl_bib_extract(dtd)
        elems = dtd.remove.elements
        return p_unwrap(dtd) unless elems.size == 1 &&
          %w(ol ul).include?(elems[0].name)
        ret = []
        elems[0].xpath("./li").each do |li|
          ret << p_unwrap(li)
        end
        ret
      end

      def add_to_hash(bib, key, val)
        Utils::set_nested_value(bib, key.split(/\./), val)
      end

      # definition list, with at most one level of unordered lists
      def dl_bib_extract(c, nested = false)
        dl = c.at("./dl") or return
        bib = {}
        key = ""
        dl.xpath("./dt | ./dd").each do |dtd|
          dtd.name == "dt" and key = dtd.text.sub(/:+$/, "") or
            add_to_hash(bib, key, dd_bib_extract(dtd))
        end
        c.xpath("./clause").each do |c1|
          key = c1&.at("./title")&.text&.downcase&.strip
          next unless %w(contributor relation series).include? key
          add_to_hash(bib, key, dl_bib_extract(c1, true))
        end
        if !nested and c.at("./title")
          title = c.at("./title").remove.children.to_xml
          bib["title"] = bib["title"] ? Array(bib["title"]) : []
          bib["title"] << title if !title.empty?
        end
        bib
      end

      def fetch_termbase(termbase, id)
        ""
      end
    end
  end
end
