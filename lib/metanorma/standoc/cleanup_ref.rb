require "set"
require "relaton_bib"

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
        bib = sort_biblio(refs.xpath("./bibitem"))
        insert = refs&.at("./bibitem")&.previous_element
        refs.xpath("./bibitem").each(&:remove)
        bib.reverse.each do |b|
          insert and insert.next = b.to_xml or
            refs.children.first.add_previous_sibling b.to_xml
        end
        extract_notes_from_biblio(refs)
        refs.xpath("./references").each { |r| biblio_reorder1(r) }
      end

      def fold_notes_into_biblio(refs)
        refs.xpath("./bibitem").each do |r|
          while r&.next_element&.name == "note"
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
        i = 0
        xmldoc.xpath("//bibliography//references | //clause//references | "\
                     "//annex//references").each do |r|
          next if r["normative"] == "true"

          r.xpath("./bibitem").each do |b|
            i += 1
            next unless docid = b.at("./docidentifier[@type = 'metanorma']")
            next unless /^\[\d+\]$/.match?(docid.text)

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
        biblio_nested(xmldoc)
        biblio_renumber(xmldoc)
        biblio_no_ext(xmldoc)
      end

      def biblio_no_ext(xmldoc)
        xmldoc.xpath("//bibitem/ext").each(&:remove)
      end

      def biblio_nested(xmldoc)
        xmldoc.xpath("//references[references]").each do |t|
          t.name = "clause"
          t.xpath("./references").each { |r| r["normative"] = t["normative"] }
          t.delete("normative")
        end
      end

      def format_ref(ref, type)
        return @isodoc.docid_prefix(type, ref) if type != "metanorma"
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
          # isopub = ref.at(ISO_PUBLISHER_XPATH)
          docid = ref.at("./docidentifier[@type = 'metanorma']") ||
            ref.at("./docidentifier[not(@type = 'DOI')]") or next
          reference = format_ref(docid.text, docid["type"])
          @anchors[ref["id"]] = { xref: reference }
        end
      end

      def fetch_termbase(_termbase, _id)
        ""
      end

      def read_local_bibitem(uri)
        return nil if %r{^https?://}.match?(uri)

        file = "#{@localdir}#{uri}.rxl"
        File.file?(file) or file = "#{@localdir}#{uri}.xml"
        File.file?(file) or return nil
        xml = Nokogiri::XML(File.read(file, encoding: "utf-8"))
        ret = xml.at("//*[local-name() = 'bibdata']") or return nil
        ret = Nokogiri::XML(ret.to_xml
          .sub(%r{(<bibdata[^>]*?) xmlns=("[^"]+"|'[^']+')}, "\\1")).root
        ret.name = "bibitem"
        ins = ret.at("./*[local-name() = 'docidentifier']") or return nil
        ins.previous = %{<uri type="citation">#{uri}</uri>}
        ret&.at("./*[local-name() = 'ext']")&.remove
        ret
      end

      # if citation uri points to local file, get bibitem from it
      def fetch_local_bibitem(xmldoc)
        xmldoc.xpath("//bibitem[formattedref][uri[@type = 'citation']]")
          .each do |b|
          uri = b&.at("./uri[@type = 'citation']")&.text
          bibitem = read_local_bibitem(uri) or next
          bibitem["id"] = b["id"]
          b.replace(bibitem)
        end
      end

      def bibitem_nested_id(xmldoc)
        xmldoc.xpath("//bibitem//bibitem").each do |b|
          b.delete("id")
        end
      end

      def bibitem_cleanup(xmldoc)
        bibitem_nested_id(xmldoc)
        ref_dl_cleanup(xmldoc)
        fetch_local_bibitem(xmldoc)
      end
    end
  end
end
