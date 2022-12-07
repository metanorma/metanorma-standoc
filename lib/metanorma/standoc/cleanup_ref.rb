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
          (insert and insert.next = b.to_xml) or
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
        xmldoc.xpath("//references[not(@normative = 'true')]" \
                     "[not(@hidden = 'true')]").each do |r|
          r.xpath("./bibitem[not(@hidden = 'true')]").each do |b|
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
        biblio_annex(xmldoc)
        biblio_nested(xmldoc)
        biblio_renumber(xmldoc)
        biblio_linkonly(xmldoc)
        biblio_hidden_inherit(xmldoc)
        biblio_no_ext(xmldoc)
      end

      def biblio_hidden_inherit(xmldoc)
        xmldoc.xpath("//references[@hidden = 'true']").each do |r|
          r.xpath("./bibitem").each do |b|
            b["hidden"] = true
          end
        end
      end

      def biblio_linkonly(xmldoc)
        return unless xmldoc.at("//xref[@hidden]")

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

      def biblio_no_ext(xmldoc)
        xmldoc.xpath("//bibitem/ext").each(&:remove)
      end

      def biblio_annex(xmldoc)
        xmldoc.xpath("//annex[references/references]").each do |t|
          next unless t.xpath("./clause | ./references | ./terms").size == 1

          r = t.at("./references")
          r.xpath("./references").each { |b| b["normative"] = r["normative"] }
          r.replace(r.elements)
        end
      end

      def biblio_nested(xmldoc)
        xmldoc.xpath("//references[references]").each do |t|
          t.name = "clause"
          t.xpath("./references").each { |r| r["normative"] = t["normative"] }
          t.delete("normative")
        end
      end

      def format_ref(ref, type)
        ret = Nokogiri::XML.fragment(ref)
        ret.traverse do |x|
          x.remove if x.name == "fn"
        end
        ref = to_xml(ret)
        return @isodoc.docid_prefix(type, ref) if type != "metanorma"
        return "[#{ref}]" if /^\d+$/.match(ref) && !/^\[.*\]$/.match(ref)

        ref
      end

      ISO_PUBLISHER_XPATH =
        "./contributor[role/@type = 'publisher']/" \
        "organization[abbreviation = 'ISO' or abbreviation = 'IEC' or " \
        "name = 'International Organization for Standardization' or " \
        "name = 'International Electrotechnical Commission']".freeze

      def reference_names(xmldoc)
        xmldoc.xpath("//bibitem[not(ancestor::bibitem)]").each do |ref|
          docid = select_docid(ref) or next
          reference = format_ref(docid.children.to_xml, docid["type"])
          @anchors[ref["id"]] = { xref: reference }
        end
      end

      def select_docid(ref)
        ref.at("./docidentifier[@type = 'metanorma']") ||
          ref.at("./docidentifier[@primary = 'true'][@language = '#{@lang}']") ||
          ref.at("./docidentifier[@primary = 'true'][not(@language)]") ||
          ref.at("./docidentifier[@primary = 'true']") ||
          ref.at("./docidentifier[not(@type = 'DOI')][@language = '#{@lang}']") ||
          ref.at("./docidentifier[not(@type = 'DOI')][not(@language)]") ||
          ref.at("./docidentifier[not(@type = 'DOI')]")
      end

      def fetch_termbase(_termbase, _id)
        ""
      end

      def read_local_bibitem(uri)
        xml = read_local_bibitem_file(uri) or return nil
        ret = xml.at("//*[local-name() = 'bibdata']") or return nil
        ret = Nokogiri::XML(ret.to_xml
          .sub(%r{(<bibdata[^>]*?) xmlns=("[^"]+"|'[^']+')}, "\\1")).root
        ret.name = "bibitem"
        ins = ret.at("./*[local-name() = 'docidentifier']") or return nil
        ins.previous = %{<uri type="citation">#{uri}</uri>}
        ret&.at("./*[local-name() = 'ext']")&.remove
        ret
      end

      def read_local_bibitem_file(uri)
        return nil if %r{^https?://}.match?(uri)

        file = "#{@localdir}#{uri}.rxl"
        File.file?(file) or file = "#{@localdir}#{uri}.xml"
        File.file?(file) or return nil
        Nokogiri::XML(File.read(file, encoding: "utf-8"))
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
        formattedref_spans(xmldoc)
        fetch_local_bibitem(xmldoc)
      end
    end
  end
end
