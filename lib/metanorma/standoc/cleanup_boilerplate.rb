module Metanorma
  module Standoc
    module Cleanup
      def external_terms_boilerplate(sources)
        @i18n.l10n(
          @i18n.external_terms_boilerplate.gsub(/%/, sources || "???"),
          @lang, @script, @locale
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
        a = if source.empty? && term.nil? then @i18n.no_terms_boilerplate
            else term_defs_boilerplate_cont(source, term, isodoc)
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

      TERM_CLAUSE = "//sections/terms | " \
                    "//sections/clause[descendant::terms]".freeze

      NORM_REF =
        "//bibliography/references[@normative = 'true'][not(@hidden)] | " \
        "//bibliography/clause[.//references[@normative = 'true']]".freeze

      def boilerplate_isodoc(xmldoc)
        x = xmldoc.dup
        x.root.add_namespace(nil, self.class::XML_NAMESPACE)
        xml = Nokogiri::XML(x.to_xml)
        @isodoc ||= isodoc(@lang, @script, @locale)
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
          f.xpath(".//clause[@type = 'boilerplate'] | " \
                  ".//note[@type = 'boilerplate']").each do |c|
            c.at("./title")&.remove
            c.replace(c.children)
          end
        end
      end

      def termdef_boilerplate_insert(xmldoc, isodoc, once = false)
        xmldoc.xpath(self.class::TERM_CLAUSE).each do |f|
          f.at("./clause[@type = 'boilerplate'] | " \
               "./note[@type = 'boilerplate']") and next
          term_defs_boilerplate(f.at("./title"),
                                xmldoc.xpath(".//termdocsource"),
                                f.at(".//term"), f.at(".//p"), isodoc)
          once and break
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
        xml.at("//boilerplate") and return
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
        @boilerplateauthority and
          file = File.join(@localdir, @boilerplateauthority)
        (!file.nil? and File.exist?(file)) or return
        b = conv.populate_template(File.read(file, encoding: "UTF-8"), nil)
        boilerplate_file_convert(b)
      end

      # If Asciidoctor, convert top clauses to tags and wrap in <boilerplate>
      def boilerplate_file_convert(file)
        Nokogiri::XML(file).root and return file
        ret = adoc2xml(file, self.backend.to_sym)
        to_xml(boilerplate_file_restructure(ret))
      end

      # If Asciidoctor, convert top clauses to tags and wrap in <boilerplate>
      def boilerplate_file_restructure(ret)
        ret.name = "boilerplate"
        ret.elements.each do |e|
          t = e.at("./xmlns:title")
          e.name = t&.remove&.text
          e.keys.each { |a| e.delete(a) } # rubocop:disable Style/HashEachMethods
        end
        ret
      end
    end
  end
end
