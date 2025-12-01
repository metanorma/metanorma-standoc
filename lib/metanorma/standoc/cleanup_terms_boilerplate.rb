module Metanorma
  module Standoc
    module Cleanup
      def external_terms_boilerplate(sources)
        e = @i18n.external_terms_boilerplate
        e.gsub(/%(?=\p{P}|\p{Z}|$)/, sources || "???")
      end

      def internal_external_terms_boilerplate(sources)
        e = @i18n.internal_external_terms_boilerplate
        e.gsub(/%(?=\p{P}|\p{Z}|$)/, sources || "??")
      end

      def boilerplate_snippet_convert(adoc, isodoc)
        b = isodoc.populate_template(adoc, nil)
        ret = boilerplate_xml_cleanup(adoc2xml(b, backend.to_sym))
        @i18n.l10n(ret.children.to_xml, @lang, @script)
      end

      def term_defs_boilerplate(div, source, term, _preface, isodoc)
        verify_term_defs_source(source)
        a = @i18n.term_def_boilerplate and
          div.next = boilerplate_snippet_convert(a, isodoc)
        a = if source.empty? && term.nil? then @i18n.no_terms_boilerplate
            else term_defs_boilerplate_cont(source, term, isodoc)
            end
        a and div.next = boilerplate_snippet_convert(a, isodoc)
      end

      def verify_term_defs_source(source)
        source.each do |s|
          @anchors[s["bibitemid"]] or
            @log.add("STANDOC_28", nil, params: [s["bibitemid"]])
        end
      end

      def term_defs_boilerplate_cont(src, term, isodoc)
        sources = isodoc.sentence_join(src.map do |s|
          %{&lt;&lt;#{s['bibitemid']}&gt;&gt;}
        end).gsub("&lt;", "<").gsub("&gt;", ">")
        if src.empty? then @i18n.internal_terms_boilerplate
        elsif term.nil? then external_terms_boilerplate(sources)
        else
          internal_external_terms_boilerplate(sources)
        end
      end

      TERM_CLAUSE =
        "//sections//terms[not(.//ancestor::clause[@type = 'terms'])] | " \
        "//sections/clause[descendant::terms][@type = 'terms'] | " \
        "//sections/clause[not(@type = 'terms')]//terms".freeze

      def termdef_boilerplate_cleanup(xmldoc)
        # termdef_remove_initial_paras(xmldoc)
      end

      def termdef_remove_initial_paras(xmldoc)
        xmldoc.xpath("//terms/p | //terms/ul").each(&:remove)
      end

      def termdef_boilerplate_insert(xmldoc, isodoc, once = false)
        if once
          f = termdef_boilerplate_insert_location(xmldoc) and
            termdef_boilerplate_insert1(f, xmldoc, isodoc)
        else
          xmldoc.xpath(self.class::TERM_CLAUSE).each do |f|
            termdef_boilerplate_insert1(f, xmldoc, isodoc)
          end
        end
      end

      def termdef_boilerplate_insert_location(xmldoc)
        f = xmldoc.at(self.class::TERM_CLAUSE)
        root = xmldoc.at("//sections/terms | //sections/clause[@type = 'terms']")
        if f && root && f["id"] != root["id"]
          f = termdef_boilerplate_climb_up(f, root)
        elsif !f && root then f = root
        end
        f
      end

      def termdef_boilerplate_climb_up(clause, container)
        container.at(".//*[@id = '#{clause['id']}']") or return clause
        while (n = clause.parent)
          n.at(".//definitions") and break
          clause = n
          n["id"] == container["id"] and break
        end
        clause
      end

      def termdef_boilerplate_insert1(sect, xmldoc, isodoc)
        ins = sect.at("./title")
        if (ins2 = sect.at("./clause[@type = 'boilerplate'] | " \
                "./note[@type = 'boilerplate']"))
          ins2.text.strip.downcase == "(default)" or return
          ins2.children = " "
          ins = ins2.children.first
        end
        require "debug"; binding.b
        term_defs_boilerplate(ins, xmldoc.xpath(".//termdocsource"),
                              sect.at(".//term"), sect.at(".//p"), isodoc)
      end
    end
  end
end
