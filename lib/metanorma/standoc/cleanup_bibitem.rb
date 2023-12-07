module Metanorma
  module Standoc
    module Cleanup
      def formattedref_spans(xmldoc)
        xmldoc.xpath("//bibitem[formattedref//span]").each do |b|
          ret = new_bibitem_from_formattedref_spans(b)
          merge_bibitem_from_formattedref_spans(b, ret)
        end
      end

      def new_bibitem_from_formattedref_spans(bib)
        ret = SpansToBibitem.new(bib).convert
        ret.err.each do |e|
          @log.add("Bibliography", bib, e[:msg], severity: e[:fatal] ? 0 : 1)
        end
        ret.out
      end

      def merge_bibitem_from_formattedref_spans(bib, new)
        new["type"] and bib["type"] = new["type"]
        if bib.at("./title") # there already is a fetched record here: merge
          bib.children = MergeBibitems
            .new(bib.to_xml, new.to_xml).merge.to_noko.children
        else bib << new.children.to_xml
        end
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

      def biblio_hidden_inherit(xmldoc)
        xmldoc.xpath("//references[@hidden = 'true']").each do |r|
          r.xpath("./bibitem").each { |b| b["hidden"] = true }
        end
      end

      def biblio_no_ext(xmldoc)
        xmldoc.xpath("//bibitem/ext").each(&:remove)
      end

      def format_ref(ref, type)
        ret = Nokogiri::XML.fragment(ref)
        ret.traverse { |x| x.remove if x.name == "fn" }
        ref = to_xml(ret)
        type != "metanorma" and return @isodoc.docid_prefix(type, ref)
        /^\d+$/.match(ref) && !/^\[.*\]$/.match(ref) and return "[#{ref}]"
        ref
      end

      def reference_names(xmldoc)
        xmldoc.xpath("//bibitem[not(ancestor::bibitem)]").each do |ref|
          @anchors[ref["id"]] =
            if docid = select_docid(ref)
              reference = format_ref(docid.children.to_xml, docid["type"])
              { xref: reference, id: idtype2cit(ref) }
            else { xref: ref["id"], id: { "" => ref["id"] } }
            end
        end
      end

      def idtype2cit(ref)
        ref.xpath("./docidentifier/@type").each_with_object({}) do |t, m|
          m[t.text] and next
          docid = select_docid(ref, t.text) or next
          m[t.text] = format_ref(docid.children.to_xml, docid["type"])
        end
      end

      def select_docid(ref, type = nil)
        type and t = "[@type = '#{type}']"
        ref.at("./docidentifier[@type = 'metanorma']#{t}") ||
          ref.at("./docidentifier[@primary = 'true'][@language = '#{@lang}']#{t}") ||
          ref.at("./docidentifier[@primary = 'true'][not(@language)]#{t}") ||
          ref.at("./docidentifier[@primary = 'true']#{t}") ||
          ref.at("./docidentifier[not(@type = 'DOI')][@language = '#{@lang}']#{t}") ||
          ref.at("./docidentifier[not(@type = 'DOI')][not(@language)]#{t}") ||
          ref.at("./docidentifier[not(@type = 'DOI')]#{t}")
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
        %r{^https?://}.match?(uri) and return nil
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
