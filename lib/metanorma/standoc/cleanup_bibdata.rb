module Metanorma
  module Standoc
    module Cleanup
      def bibdata_cleanup(xmldoc)
        bibdata_anchor_cleanup(xmldoc)
        bibdata_docidentifier_cleanup(xmldoc)
        bibdata_embed_hdr_cleanup(xmldoc) # feeds bibdata_embed_id_cleanup
        bibdata_embed_id_cleanup(xmldoc)
        biblio_indirect_erefs(xmldoc, @internal_eref_namespaces&.uniq)
      end

      def bibdata_anchor_cleanup(xmldoc)
        xmldoc.xpath("//bibdata//bibitem | //bibdata//note").each do |b|
          b.delete("id")
        end
      end

      def bibdata_docidentifier_cleanup(xmldoc)
        ins = xmldoc.at("//bibdata/docidentifier")
        xmldoc.xpath("//bibdata/docidentifier").each_with_index do |b, i|
          i.zero? and next
          ins.next = b.remove
          ins = ins.next
        end
      end

      def gather_indirect_erefs(xmldoc, prefix)
        xmldoc.xpath("//eref[@type = '#{prefix}']")
          .each_with_object({}) do |e, m|
          e.delete("type")
          m[e["bibitemid"]] = true
        end.keys
      end

      def insert_indirect_biblio(xmldoc, refs, prefix)
        i = xmldoc.at("bibliography") or
          xmldoc.root << "<bibliography/>" and i = xmldoc.at("bibliography")
        i = i.add_child("<references hidden='true' normative='false'/>").first
        refs.each do |x|
          i << <<~BIB
            <bibitem id="#{x}" type="internal">
            <docidentifier type="repository">#{x.sub(/^#{prefix}_/, "#{prefix}/")}</docidentifier>
            </bibitem>
          BIB
        end
      end

      def indirect_eref_to_xref(eref, ident)
        loc = eref.at("./localityStack[locality[@type = 'anchor']]")
          &.remove&.text ||
          eref.at("./locality[@type = 'anchor']")&.remove&.text || ident
        eref.name = "xref"
        eref.delete("bibitemid")
        eref.delete("citeas")
        eref["target"] = loc
        unless eref.document.at("//*[@id = '#{loc}']")
          eref.children = %(** Missing target #{loc})
          eref["target"] = ident
        end
      end

      def resolve_local_indirect_erefs(xmldoc, refs, prefix)
        refs.each_with_object([]) do |r, m|
          id = r.sub(/^#{prefix}_/, "")
          n = xmldoc.at("//*[@id = '#{id}']")
          if n&.at("./ancestor-or-self::*[@type = '#{prefix}']")
            xmldoc.xpath("//eref[@bibitemid = '#{r}']").each do |e|
              indirect_eref_to_xref(e, id)
            end
          else m << r
          end
        end
      end

      def biblio_indirect_erefs(xmldoc, prefixes)
        prefixes&.each do |prefix|
          refs = gather_indirect_erefs(xmldoc, prefix)
          refs = resolve_local_indirect_erefs(xmldoc, refs, prefix)
          refs.empty? and next
          insert_indirect_biblio(xmldoc, refs, prefix)
        end
      end

      def bibdata_embed_hdr_cleanup(xmldoc)
        (@embed_hdr.nil? || @embed_hdr.empty?) and return
        xmldoc.at("//bibdata") << "<relation type='derivedFrom'>" \
                                  "#{hdr2bibitem(@embed_hdr.first)}</relation>"
      end

      def hdr2bibitem(hdr)
        xml = Asciidoctor
          .convert(hdr[:text], backend: hdr2bibitem_type(hdr),
                               header_footer: true)
        b = Nokogiri::XML(xml).at("//xmlns:bibdata")
        b.name = "bibitem"
        b.delete("type")
        embed_recurse(b, hdr)
        b.to_xml
      end

      def hdr2bibitem_type(hdr)
        m = /:mn-document-class: (\S+)/.match(hdr[:text])
        if m then m[1].to_sym
        else Processor.new.asciidoctor_backend
        end
      end

      def embed_recurse(bibitem, node)
        node[:child].map { |x| hdr2bibitem(x) }.each do |x|
          bibitem << "<relation type='derivedFrom'>#{x}</relation>"
        end
      end

      def bibdata_embed_id_cleanup(xmldoc)
        @embed_id.nil? and return
        bibdata = xmldoc.at("//bibdata")
        @embed_id.each do |d|
          bibdata = bibdata.at("./relation[@type = 'derivedFrom']/bibitem")
          ident = bibdata.at("./docidentifier[@primary = 'true']") ||
            bibdata.at("./docidentifier")
          xmldoc.xpath("//xref[@target = '#{d}'][normalize-space(text()) = '']")
            .each { |x| x << ident.text }
        end
      end

      def ext_contributor_cleanup(xmldoc)
        t = xmldoc.xpath("//metanorma-extension/clause/title").detect do |x|
          x.text.strip.casecmp("contributor metadata").zero?
        end or return
        a = t.at("../sourcecode") or return
        ins = xmldoc.at("//bibdata/contributor[last()]")
        yaml = YAML.safe_load(a.text, permitted_classes: [Date])
        ext_contributors_process(yaml, ins)
      end

      def yaml2relaton(yaml, amend = nil)
        r = RelatonBib.parse_yaml(yaml.to_yaml, [Date], symbolize_names: true)
        h = RelatonBib::HashConverter.hash_to_bib(r)
        b = RelatonBib::BibliographicItem.new(**h).to_xml
        amend and b.sub!("</bibitem>", "#{amend}</bibitem>")
        b
      end

      def ext_contributors_process(yaml, ins)
        yaml.is_a?(Hash) && !yaml["contributor"] and yaml = [yaml]
        yaml.is_a?(Array) and yaml = { "contributor" => yaml }
        r = yaml2relaton(yaml)
        Nokogiri::XML(r).xpath("//contributor").reverse
          .each do |c|
          ins.next = c
        end
      end

      def bib_relation_insert_pt(xmldoc)
        ins = nil
        %w(relation copyright status abstract script language note version
           edition contributor).each do |x|
          ins = xmldoc.at("//bibdata/#{x}[last()]") and break
        end
        ins
      end

      def ext_dochistory_cleanup(xmldoc)
        t = xmldoc.xpath("//metanorma-extension/clause/title").detect do |x|
          x.text.strip.casecmp("document history").zero?
        end or return
        a = t.at("../sourcecode") or return
        ins = bib_relation_insert_pt(xmldoc) or return
        docid = xmldoc.at("//bibdata/docidentifier")
        yaml = YAML.safe_load(a.text, permitted_classes: [Date])
        ext_dochistory_process(yaml, ins, docid)
      end

      def ext_dochistory_process(yaml, ins, docid)
        yaml.is_a?(Hash) and yaml = [yaml]
        yaml.reverse.each do |y|
          type = y["relation.type"] || "updatedBy"
          docid and
            y["docid"] ||= [{ "type" => docid["type"], "id" => docid.text }]
          r = yaml2relaton(y, amend_hash2mn(y["amend"]))
          ins.next = "<relation type='#{type}'>#{r}</relation>"
        end
      end

      def amend_hash2mn(yaml)
        yaml.nil? and return ""
        yaml.is_a?(Hash) and yaml = [yaml]
        yaml.map { |x| amend_hash2mn1(x) }.join("\n")
      end

      def amend_attrs(yaml)
        ret = ""
        %w(change path path_end title).each do |x|
          a = yaml[x] and ret += " x='#{a}'"
        end
        ret = "<amend#{ret}>"
      end

      def amend_hash2mn1(yaml)
        ret = amend_attrs(yaml)
        ret += amend_description(yaml)
        ret += amend_location(yaml)
        ret += amend_classification(yaml)
        "#{ret}</amend>"
      end

      def amend_location(yaml)
        a = yaml["location"] or return ""
        a.is_a?(Array) or a = [a]
        ret = a.map do |x|
          elem = Nokogiri::XML("<location>#{x}</location>").root
          extract_localities(elem)
          elem.children.to_xml
        end.join("\n")
        "<location>#{ret}</location>"
      end

      def amend_description(yaml)
        a = yaml["description"] or return ""
        out = adoc2xml(a, backend.to_sym)
        "<description>#{out.children.to_xml}</description>"
      end

      def amend_classification(yaml)
        a = yaml["classification"] or return ""
        a.is_a?(Array) or a = [a]
        a.map { |x| amend_classification1(x) }.join("\n")
      end

      def amend_classification1(yaml)
        yaml.is_a?(Hash) or yaml = { "tag" => "default", "value" => yaml }
        <<~OUT
          <classification><tag>#{yaml['tag']}</tag><value>#{yaml['value']}</value></classification>
        OUT
      end
    end
  end
end
