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
          @log.add("Bibliography", bib, e[:msg], severity: e[:fatal] ? 0 : 1)
        end
        ret.out
      end

      def merge_bibitem_from_formattedref_spans(bib, new)
        new["type"] and bib["type"] = new["type"]
        if bib.at("./title") && bib["amend"]
          # there already is a fetched record here: merge
          bib.children = MergeBibitems
            .new(bib.to_xml, new.to_xml).merge.to_noko.children
        elsif bib.at("./title") # replace record
          bib.children = new.children.to_xml
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

      def attachment_cleanup(xmldoc)
        xmldoc.xpath("//bibitem[uri/@type = 'attachment']").each do |b|
          b["hidden"] = "true"
          u = b.at("./uri[@type = 'attachment']")
          c = b.at("./uri[@type = 'citation']") ||
            u.after("<uri type='citation'/>")
          uri = attachment_uri(u.text, b)
          u.children = uri
          c.children = uri
        end
      end

      def attachment_uri(path, bib)
        init_attachments
        path = File.join(@localdir, path)
        valid_attachment?(path, bib) or return ""
        @datauriattachment or return attachment_location(path)
        save_attachment(path, bib)
      end

      def save_attachment(path, bib)
        init_attachments
        f = File.basename(path)
        File.exist?(File.join(@attachmentsdir, f)) and
          f += "_#{UUIDTools::UUID.random_create}"
        out_fld = File.join(@attachmentsdir, f)
        FileUtils.cp(path, out_fld)
        datauri_attachment(out_fld, bib.document)
      end

      def attachment_location(path)
        f = path
        @datauriattachment and
          f = File.join(@attachmentsdir, File.basename(path))
        Pathname.new(File.expand_path(f))
          .relative_path_from(Pathname.new(File.expand_path(@output_dir))).to_s
      end

      def datauri_attachment(path, doc)
        @datauriattachment or return
        m = add_misc_container(doc)
        f = attachment_location(path)
        e = (m << "<attachment name='#{f}'/>").last_element_child
        Vectory::Utils::datauri(path, @output_dir).scan(/.{1,60}/)
          .each { |dd| e << "#{dd}\n" }
        f
      end

      def valid_attachment?(path, bib)
        File.exist?(path) and return true
        p = Pathname.new(path).cleanpath
        @log.add("Bibliography", bib, "Attachment #{p} does not exist",
                 severity: 0)
        false
      end

      def init_attachments
        @datauriattachment or return
        @attachmentsdir and return
        @attachmentsfld = "_#{@filename}_attachments"
        @attachmentsdir = File.join(@output_dir, @attachmentsfld)
        FileUtils.rm_rf(@attachmentsdir)
        FileUtils.mkdir_p(@attachmentsdir)
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

      def empty_identifiers(xmldoc)
        xmldoc.xpath("//bibitem[not(@suppress_identifier)]").each do |b|
          b.xpath("./docidentifier").each do |d|
            d.text.strip.empty? and d.remove
          end
          b.at("./docidentifier") and next
          b["suppress_identifier"] = true
        end
      end

      def bibitem_cleanup(xmldoc)
        bibitem_nested_id(xmldoc) # feeds remove_dup_bibtem_id
        remove_dup_bibtem_id(xmldoc)
        ref_dl_cleanup(xmldoc)
        formattedref_spans(xmldoc)
        fetch_local_bibitem(xmldoc)
        attachment_cleanup(xmldoc)
        empty_identifiers(xmldoc)
      end
    end
  end
end
