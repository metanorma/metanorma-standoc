module Metanorma
  module Standoc
    module Cleanup
      def external_terms_boilerplate(sources)
        e = @i18n.external_terms_boilerplate
        @i18n.l10n(e.gsub(/%(?=\p{P}|\p{Z}|$)/, sources || "???"),
                   @lang, @script, @locale)
      end

      def internal_external_terms_boilerplate(sources)
        e = @i18n.internal_external_terms_boilerplate
        @i18n.l10n(e.gsub(/%(?=\p{P}|\p{Z}|$)/, sources || "??"),
                   @lang, @script)
      end

      def term_defs_boilerplate(div, source, term, _preface, isodoc)
        a = @i18n.term_def_boilerplate and div.next = a
        source.each do |s|
          @anchors[s["bibitemid"]] or
            @log.add("Crossreferences", nil,
                     "term source #{s['bibitemid']} not referenced", severity: 1)
        end
        a = if source.empty? && term.nil? then @i18n.no_terms_boilerplate
            else term_defs_boilerplate_cont(source, term, isodoc)
            end and div.next = a
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
        ins = norm_ref_boilerplate_insert_location(ref)
        ins2 = norm_ref_process_boilerplate_note(ref)
        ins2 == :populated and return
        ins2 == :missing or ins = ins2
        refs = ref.elements.select do |e|
          %w(references bibitem).include? e.name
        end
        pref = refs.empty? ? @i18n.norm_empty_pref : @i18n.norm_with_refs_pref
        ins.next = "<p>#{pref}</p>"
      end

      def norm_ref_process_boilerplate_note(ref)
        ins2 = ref.at("./note[@type = 'boilerplate']") or return :missing
        if ins2 && ins2.text.strip.downcase == "(default)"
          ins2.children = " "
          ins2.children.first
        else :populated
        end
      end

      def norm_ref_boilerplate_insert_location(ref)
        while (n = ref.parent) && %w(clause references).include?(n&.name)
          n.elements.detect do |e|
            !%(title references).include?(e.name) &&
              !e.at("./self::clause[@type = 'boilerplate']") &&
              !e.at("./self::clause[.//references][not(.//clause[not(.//bibitem)])]")
          end and break
          ref = n
        end
        ref.at("./title")
      end

      TERM_CLAUSE =
        "//sections//terms[not(.//ancestor::clause[@type = 'terms'])] | " \
        "//sections/clause[descendant::terms][@type = 'terms'] | " \
        "//sections/clause[not(@type = 'terms')]//terms".freeze

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
        term_defs_boilerplate(ins, xmldoc.xpath(".//termdocsource"),
                              sect.at(".//term"), sect.at(".//p"), isodoc)
      end

      def boilerplate_cleanup(xmldoc)
        isodoc = boilerplate_isodoc(xmldoc)
        termdef_boilerplate_cleanup(xmldoc)
        termdef_boilerplate_insert(xmldoc, isodoc)
        unwrap_boilerplate_clauses(xmldoc, self.class::TERM_CLAUSE)
        if f = xmldoc.at(self.class::NORM_REF)
          norm_ref_preface(f)
          unwrap_boilerplate_clauses(f, ".")
        end
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
        @boilerplateauthority and
          file2 = File.join(@localdir, @boilerplateauthority)
        resolve_boilerplate_files(process_boilerplate_file(file, conv),
                                  process_boilerplate_file(file2, conv))
      end

      def process_boilerplate_file(filename, conv)
        (!filename.nil? and File.exist?(filename)) or return
        b = conv.populate_template(boilerplate_read(filename), nil)
        boilerplate_file_convert(b)
      end

      def resolve_boilerplate_files(built_in, user_add)
        built_in || user_add or return
        built_in && user_add or return to_xml(built_in || user_add)
        merge_boilerplate_files(built_in, user_add)
      end

      def merge_boilerplate_files(built_in, user_add)
        %w(copyright license legal feedback).each do |w|
          resolve_boilerplate_statement(built_in, user_add, w)
        end
        to_xml(built_in)
      end

      def resolve_boilerplate_statement(built_in, user_add, statement)
        b = user_add.at("./#{statement}-statement") or return
        if a = built_in.at("./#{statement}-statement")
          b.text.strip.empty? and a.remove or a.replace(b)
        else
          built_in << b
        end
      end

      def boilerplate_read(file)
        ret = File.read(file, encoding: "UTF-8")
        /\.adoc$/.match?(file) and
          ret.gsub!(/(?<!\{)(\{\{[^{}]+\}\})(?!\})/, "pass:[\\1]")
        ret
      end

      # If Asciidoctor, convert top clauses to tags and wrap in <boilerplate>
      def boilerplate_file_convert(file)
        ret = Nokogiri::XML(file).root and return ret
        boilerplate_file_restructure(file)
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
