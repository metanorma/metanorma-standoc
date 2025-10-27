require_relative "cleanup_attachment"

module Metanorma
  module Standoc
    module Cleanup
      def formattedref_spans(xmldoc)
        xmldoc.xpath("//bibitem[formattedref//span]").each do |b|
          ret = new_bibitem_from_formattedref_spans(b)
          merge_bibitem_from_formattedref_spans(b, ret)
        end
        xmldoc.xpath("//bibitem[@amend]").each do |b|
          b.delete("amend")
        end
      end

      def new_bibitem_from_formattedref_spans(bib)
        ret = SpansToBibitem.new(bib).convert
        ret.err.each do |e|
          @log.add(e[:fatal] ? "STANDOC_52" : "STANDOC_53",
                   bib, params: [e[:msg]])
        end
        ret.out
      end

      def merge_bibitem_from_formattedref_spans(bib, new)
        merge_bibitem_from_formattedref_span_attrs(bib, new)
        if bib.at("./title") && bib["amend"]
          # there already is a fetched record here: merge
          bib.children = MergeBibitems
            .new(bib.to_xml, new.to_xml).merge.to_noko.children
        elsif bib.at("./title") # replace record
          bib.children = new.children.to_xml
        else bib << new.children.to_xml
        end
      end

      def merge_bibitem_from_formattedref_span_attrs(bib, new)
        %w(type language script locale).each do |k|
          new[k] and bib[k] = new[k]
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
          r.xpath("./note[@appended]").reverse_each do |n|
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
          @anchors[ref["anchor"]] =
            if docid = select_docid(ref)
              reference = format_ref(docid.children.to_xml, docid["type"])
              { xref: reference, id: idtype2cit(ref) }
            else { xref: ref["anchor"], id: { "" => ref["anchor"] } }
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
          bibitem["anchor"] = b["anchor"]
          b.replace(bibitem)
        end
      end

      def bibitem_nested_id(xmldoc)
        xmldoc.xpath("//bibitem//bibitem").each do |b|
          b.delete("id")
          b.delete("anchor")
        end
        xmldoc.xpath("//bibdata//bibitem").each do |b|
          b.delete("id")
          b.delete("anchor")
        end
      end

      # remove dupes if both same ID and same docid, in case dupes introduced
      # through termbases
      def remove_dup_bibtem_id(xmldoc)
        bibitem_id_docid_hash(xmldoc).each_value do |v|
          v.each_value do |v1|
            v1[1..].each(&:remove)
          end
        end
      end

      def bibitem_id_docid_hash(xmldoc)
        xmldoc.xpath("//bibitem[@anchor]").each_with_object({}) do |b, m|
          m[b["anchor"]] ||= {}
          docid = b.at("./docidentifier")&.text || "NO ID"
          m[b["anchor"]][docid] ||= []
          m[b["anchor"]][docid] << b
        end
      end

      def remove_empty_docid(xmldoc)
        xmldoc.xpath("//bibitem/docidentifier[normalize-space(.)='']")
          .each(&:remove)
      end

      def empty_docid_to_title(xmldoc)
        xmldoc.xpath("//references/bibitem").each do |b|
          b.at("./docidentifier[not(@type = 'metanorma' or @type = 'DOI' or " \
           "@type = 'metanorma-ordinal')]") and next
          empty_docid_to_title?(b) or next
          ins = b.at("./title[last()]") || b.at("./formattedref")
          id = bibitem_title_to_id(b) or return
          ins.next = <<~XML
            <docidentifier type='title' primary='true'>#{id}</docidentifier>
          XML
        end
      end

      def bibitem_title_to_id(bibitem)
        t = bibitem.at("./title") || bibitem.at("./formattedref") or return
        t.text
      end

      # normative references only, biblio uses ordinal code instead
      def empty_docid_to_title?(bibitem)
        bibitem.parent["normative"] == "true"
      end

      def bibitem_cleanup(xmldoc)
        bibitem_nested_id(xmldoc) # feeds remove_dup_bibtem_id
        ref_dl_cleanup(xmldoc)
        formattedref_spans(xmldoc)
        fetch_local_bibitem(xmldoc)
        remove_empty_docid(xmldoc)
        empty_docid_to_title(xmldoc)
        remove_dup_bibtem_id(xmldoc)
        attachment_cleanup(xmldoc)
      end
    end
  end
end
