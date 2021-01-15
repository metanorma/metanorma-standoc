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
          insert and insert.next = b.to_xml or refs.children.first.add_previous_sibling b.to_xml
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
        i = 0
        xmldoc.xpath("//bibliography//references | //clause//references | //annex//references").each do |r|
          r.xpath("./bibitem").each do |b|
            i += 1
            next unless docid = b.at("./docidentifier[@type = 'metanorma']")
            next unless  /^\[\d+\]$/.match(docid.text)
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
        preface = r.xpath("./title/following-sibling::*") & # intersection
          r.xpath("./bibitem[1]/preceding-sibling::*")
        preface.each { |n| n.remove }
      end

      def biblio_cleanup(xmldoc)
        biblio_reorder(xmldoc)
        biblio_nested(xmldoc)
        biblio_renumber(xmldoc)
        biblio_indirect_erefs(xmldoc, %w(express-schema))
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

      def fetch_termbase(termbase, id)
        ""
      end

      def read_local_bibitem(uri)
        return nil if %r{^http[s]?://}.match(uri)
        file = @localdir + uri + ".rxl"
        File.file?(file) or file = @localdir + uri + ".xml"
        File.file?(file) or return nil
        xml = Nokogiri::XML(File.read(file, encoding: "utf-8"))
        ret = xml.at("//*[local-name() = 'bibdata']") or return nil
        ret = Nokogiri::XML(ret.to_xml.sub(%r{(<bibdata[^>]*?) xmlns=("[^"]+"|'[^']+')}, "\\1")).root
        ret.name = "bibitem"
        ins = ret.at("./*[local-name() = 'docidentifier']") or return nil
        ins.previous = %{<uri type="citation">#{uri}</uri>}
        ret&.at("./*[local-name() = 'ext']")&.remove
        ret
      end

      # if citation uri points to local file, get bibitem from it
      def fetch_local_bibitem(xmldoc)
        xmldoc.xpath("//bibitem[formattedref][uri[@type = 'citation']]").each do |b|
          uri = b&.at("./uri[@type = 'citation']")&.text
          bibitem = read_local_bibitem(uri) or next
          bibitem["id"] = b["id"]
          b.replace(bibitem)
        end
      end

      def bibitem_cleanup(xmldoc)
        ref_dl_cleanup(xmldoc)
        fetch_local_bibitem(xmldoc)
      end

      def gather_indirect_erefs(xmldoc, prefix)
        xmldoc.xpath("//eref[@type = '#{prefix}']").each_with_object({}) do |e, m|
          e.delete("type")
          m[e["bibitemid"]] = true
        end.keys
      end

      def insert_indirect_biblio(xmldoc, refs, prefix)
        ins = xmldoc.at("bibliography") or
          xmldoc.root << "<bibliography/>" and ins = xmldoc.at("bibliography")
        ins = ins.add_child("<references hidden='true' normative='false'/>").first
        refs.each do |x|
          ins << <<~END
            <bibitem id="#{x}" type="internal">
            <docidentifier type="repository">#{x.sub(/^#{prefix}_/, "#{prefix}/")}</docidentifier>
            </bibitem>
          END
        end
      end

      def indirect_eref_to_xref(e, id)
        loc = e&.at("./locality[@type = 'anchor']")&.remove&.text
        target = loc ? "#{id}.#{loc}" : id
        e.name = "xref"
        e.delete("bibitemid")
        if e.document.at("//*[@id = '#{target}']")
          e["target"] = target
        else
          e["target"] = id
          e.children = %(** Missing target #{loc})
        end
      end

      def resolve_local_indirect_erefs(xmldoc, refs, prefix)
        refs.each_with_object([]) do |r, m|
          id = r.sub(/^#{prefix}_/, "")
          if xmldoc.at("//*[@id = '#{id}'][@type = '#{prefix}']")
            xmldoc.xpath("//eref[@bibitemid = '#{r}']").each do |e|
              indirect_eref_to_xref(e, id)
            end
          else
            m << r
          end
        end
      end

      def biblio_indirect_erefs(xmldoc, prefixes)
        prefixes.each do |prefix|
          refs = gather_indirect_erefs(xmldoc, prefix)
          refs = resolve_local_indirect_erefs(xmldoc, refs, prefix)
          refs.empty? and return
          insert_indirect_biblio(xmldoc, refs, prefix)
        end
      end
    end
  end
end
