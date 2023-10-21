module Metanorma
  module Standoc
    module Cleanup
      def external_terms_boilerplate(sources)
        @i18n.l10n(
          @i18n.external_terms_boilerplate.gsub("%", sources || "???"),
          @lang, @script, @locale
        )
      end

      def internal_external_terms_boilerplate(sources)
        @i18n.l10n(
          @i18n.internal_external_terms_boilerplate.gsub("%", sources || "??"),
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
        if once
          f = termdef_boilerplate_insert_location(xmldoc)
          termdef_boilerplate_insert1(f, xmldoc, isodoc)
        else
          xmldoc.xpath(self.class::TERM_CLAUSE).each do |f|
            termdef_boilerplate_insert1(f, xmldoc, isodoc)
          end
        end
      end

      def termdef_boilerplate_insert_location(xmldoc)
        f = xmldoc.at(self.class::TERM_CLAUSE)
        root = xmldoc.at("//sections/terms | //sections/clause[.//terms]")
        f.at("./following::terms") and return root
        f.at("./preceding-sibling::clause") and return root
        f
      end

      def termdef_boilerplate_insert1(sect, xmldoc, isodoc)
        sect.at("./clause[@type = 'boilerplate'] | " \
                "./note[@type = 'boilerplate']") and return
        term_defs_boilerplate(sect.at("./title"),
                              xmldoc.xpath(".//termdocsource"),
                              sect.at(".//term"), sect.at(".//p"), isodoc)
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
        preface = xml.at("//preface | //sections | //annex | //references") or
          return
        b = boilerplate(xml, isodoc) or return
        preface.previous = b
      end

      def boilerplate_file(_xmldoc)
        File.join(@libdir, "boilerplate.xml")
      end

      def boilerplate(xml, conv)
        # prevent infinite recursion of asciidoc boilerplate processing
        xml.at("//metanorma-extension/semantic-metadata/" \
               "headless[text() = 'true']") and return nil
        file = boilerplate_file(xml)
        @boilerplateauthority and file = File.join(@localdir,
                                                   @boilerplateauthority)
        (!file.nil? and File.exist?(file)) or return
        b = conv.populate_template(boilerplate_read(file), nil)
        boilerplate_file_convert(b)
      end

      def boilerplate_read(file)
        ret = File.read(file, encoding: "UTF-8")
        /\.adoc$/.match?(file) and
          ret.gsub!(/(?<!\{)(\{\{[^{}]+\}\})(?!\})/, "pass:[\\1]")
        ret
      end

      # If Asciidoctor, convert top clauses to tags and wrap in <boilerplate>
      def boilerplate_file_convert(file)
        Nokogiri::XML(file).root and return file
        to_xml(boilerplate_file_restructure(file))
      end

      # If Asciidoctor, convert top clauses to tags and wrap in <boilerplate>
      def boilerplate_file_restructure(file)
        ret = adoc2xml(file, backend.to_sym)
        boilerplate_xml_cleanup(ret)
        ret.name = "boilerplate"
        boilerplate_top_elements(ret)
        ret
      end

      # remove Metanorma namespace, so generated doc containing boilerplate
      # can be queried consistently
      # _\d+ anchor is assigned to titleless clauses, will clash with main doc
      # instances of same
      def boilerplate_xml_cleanup(xml)
        ns = xml.namespace.href
        xml.traverse do |n|
          n.element? or next
          n.namespace.href == ns and n.namespace = nil
          /^_\d+$/.match?(n["id"]) and
            n["id"] = "_#{UUIDTools::UUID.random_create}"
        end
      end

      def boilerplate_top_elements(xml)
        xml.elements.each do |e|
          (t = e.at("./title") and /-statement$/.match?(t.text)) or next
          e.name = t.remove.text
          e.keys.each { |a| e.delete(a) } # rubocop:disable Style/HashEachMethods
        end
      end
    end
  end
end
