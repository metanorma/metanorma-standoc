module Asciidoctor
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

      def term_defs_boilerplate(div, source, term, preface, isodoc)
        a = @i18n.term_def_boilerplate and div.next = a
        source.each do |s|
          @anchors[s["bibitemid"]] or
            @log.add("Crossreferences", nil,
                     "term source #{s['bibitemid']} not referenced")
        end
        a = source.empty? && term.nil? ?  @i18n.no_terms_boilerplate :
          term_defs_boilerplate_cont(source, term, isodoc)
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
        refs = ref.elements.select do |e|
          %w(references bibitem).include? e.name
        end
        pref = refs.empty? ? @i18n.norm_empty_pref : @i18n.norm_with_refs_pref
        ref.at("./title").next = "<p>#{pref}</p>"
      end

      TERM_CLAUSE = "//sections/terms | "\
        "//sections/clause[descendant::terms]".freeze

      NORM_REF = "//bibliography/references[@normative = 'true'] | "\
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

      def termdef_unwrap_boilerplate_clauses(xmldoc)
        xmldoc.xpath(self.class::TERM_CLAUSE).each do |f|
          f.xpath(".//clause[@type = 'boilerplate']").each do |c|
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
        termdef_unwrap_boilerplate_clauses(xmldoc)
        f = xmldoc.at(self.class::NORM_REF) and norm_ref_preface(f)
        initial_boilerplate(xmldoc, isodoc)
      end

      def initial_boilerplate(xml, isodoc)
        return if xml.at("//boilerplate")

        preface = xml.at("//preface") || xml.at("//sections") ||
          xml.at("//annex") || xml.at("//references") || return
        b = boilerplate(xml, isodoc) or return
        preface.previous = b
      end

      def boilerplate_file(_xmldoc)
        File.join(@libdir, "boilerplate.xml")
      end

      def boilerplate(xml, conv)
        file = boilerplate_file(xml)
        file = File.join(@localdir, @boilerplateauthority) if @boilerplateauthority
        !file.nil? and File.exists?(file) or return
        conv.populate_template(File.read(file, encoding: "UTF-8"), nil)
      end

      def bibdata_cleanup(xmldoc)
        bibdata_anchor_cleanup(xmldoc)
        bibdata_docidentifier_cleanup(xmldoc)
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
        loc = e&.at("./localityStack[locality[@type = 'anchor']]")&.remove&.text ||
          e&.at("./locality[@type = 'anchor']")&.remove&.text || id
        e.name = "xref"
        e.delete("bibitemid")
        e.delete("citeas")
        e["target"] = loc
        unless e.document.at("//*[@id = '#{loc}']")
          e.children = %(** Missing target #{loc})
          e["target"] = id
        end
      end

      def resolve_local_indirect_erefs(xmldoc, refs, prefix)
        refs.each_with_object([]) do |r, m|
          id = r.sub(/^#{prefix}_/, "")
          if n = xmldoc.at("//*[@id = '#{id}']") and n.at("./ancestor-or-self::*[@type = '#{prefix}']")
            xmldoc.xpath("//eref[@bibitemid = '#{r}']").each do |e|
              indirect_eref_to_xref(e, id)
            end
          else
            m << r
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
    end
  end
end
