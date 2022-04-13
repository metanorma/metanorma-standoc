module Metanorma
  module Standoc
    module Cleanup
      def external_terms_boilerplate(sources)
        @i18n.l10n(
          @i18n.external_terms_boilerplate.gsub(/%/, sources || "???"),
          @lang, @script
        )
      end

      def internal_external_terms_boilerplate(sources)
        @i18n.l10n(
          @i18n.internal_external_terms_boilerplate.gsub(/%/, sources || "??"),
          @lang, @script
        )
      end

      def term_defs_boilerplate(div, source, term, _preface, isodoc)
        a = @i18n.term_def_boilerplate and div.next = a
        source.each do |s|
          @anchors[s["bibitemid"]] or
            @log.add("Crossreferences", nil,
                     "term source #{s['bibitemid']} not referenced")
        end
        a = if source.empty? && term.nil?
              @i18n.no_terms_boilerplate
            else
              term_defs_boilerplate_cont(source, term, isodoc)
            end
        a and div.next = a
      end

      def term_defs_boilerplate_cont(src, term, isodoc)
        sources = isodoc.sentence_join(src.map do |s|
          %{<eref bibitemid="#{s['bibitemid']}"/>}
        end)
        if src.empty? then @i18n.internal_terms_boilerplate
        elsif term.nil? then external_terms_boilerplate(sources)
        else
          internal_external_terms_boilerplate(sources)
        end
      end

      def norm_ref_preface(ref)
        if ref.at("./note[@type = 'boilerplate']")
          unwrap_boilerplate_clauses(ref, ".")
        else
          refs = ref.elements.select do |e|
            %w(references bibitem).include? e.name
          end
          pref = refs.empty? ? @i18n.norm_empty_pref : @i18n.norm_with_refs_pref
          ref.at("./title").next = "<p>#{pref}</p>"
        end
      end

      TERM_CLAUSE = "//sections/terms | "\
                    "//sections/clause[descendant::terms]".freeze

      NORM_REF =
        "//bibliography/references[@normative = 'true'][not(@hidden)] | "\
        "//bibliography/clause[.//references[@normative = 'true']]".freeze

      def boilerplate_isodoc(xmldoc)
        x = xmldoc.dup
        x.root.add_namespace(nil, self.class::XML_NAMESPACE)
        xml = Nokogiri::XML(x.to_xml)
        @isodoc ||= isodoc(@lang, @script)
        @isodoc.info(xml, nil)
        @isodoc
      end

      def termdef_boilerplate_cleanup(xmldoc)
        # termdef_remove_initial_paras(xmldoc)
      end

      def termdef_remove_initial_paras(xmldoc)
        xmldoc.xpath("//terms/p | //terms/ul").each(&:remove)
      end

      def unwrap_boilerplate_clauses(xmldoc, xpath)
        xmldoc.xpath(xpath).each do |f|
          f.xpath(".//clause[@type = 'boilerplate'] | "\
                  ".//note[@type = 'boilerplate']").each do |c|
            c&.at("./title")&.remove
            c.replace(c.children)
          end
        end
      end

      def termdef_boilerplate_insert(xmldoc, isodoc, once = false)
        xmldoc.xpath(self.class::TERM_CLAUSE).each do |f|
          next if f.at("./clause[@type = 'boilerplate']")

          term_defs_boilerplate(f.at("./title"),
                                xmldoc.xpath(".//termdocsource"),
                                f.at(".//term"), f.at(".//p"), isodoc)
          break if once
        end
      end

      def boilerplate_cleanup(xmldoc)
        isodoc = boilerplate_isodoc(xmldoc)
        termdef_boilerplate_cleanup(xmldoc)
        termdef_boilerplate_insert(xmldoc, isodoc)
        unwrap_boilerplate_clauses(xmldoc, self.class::TERM_CLAUSE)
        f = xmldoc.at(self.class::NORM_REF) and norm_ref_preface(f)
        initial_boilerplate(xmldoc, isodoc)
      end

      def initial_boilerplate(xml, isodoc)
        return if xml.at("//boilerplate")

        preface = xml.at("//preface") || xml.at("//sections") ||
          xml.at("//annex") || xml.at("//references") or return
        b = boilerplate(xml, isodoc) or return
        preface.previous = b
      end

      def boilerplate_file(_xmldoc)
        File.join(@libdir, "boilerplate.xml")
      end

      def boilerplate(xml, conv)
        file = boilerplate_file(xml)
        if @boilerplateauthority
          file = File.join(@localdir,
                           @boilerplateauthority)
        end
        (!file.nil? and File.exist?(file)) or return
        conv.populate_template(File.read(file, encoding: "UTF-8"), nil)
      end

      def bibdata_cleanup(xmldoc)
        bibdata_anchor_cleanup(xmldoc)
        bibdata_docidentifier_cleanup(xmldoc)
        bibdata_embed_hdr_cleanup(xmldoc)
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
          next if i.zero?

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
        loc = eref&.at("./localityStack[locality[@type = 'anchor']]")
          &.remove&.text ||
          eref&.at("./locality[@type = 'anchor']")&.remove&.text || ident
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
        return if @embed_hdr.nil? || @embed_hdr.empty?

        xmldoc.at("//bibdata") << "<relation type='derivedFrom'>"\
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
    end
  end
end
