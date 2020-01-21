module Asciidoctor
  module Standoc
    module Cleanup
      def external_terms_boilerplate(sources)
        IsoDoc::Function::I18n::l10n(
          @external_terms_boilerplate.gsub(/%/, sources || "???"),
          @lang, @script)
      end

      def internal_external_terms_boilerplate(sources)
        IsoDoc::Function::I18n::l10n(
          @internal_external_terms_boilerplate.gsub(/%/, sources || "??"),
          @lang, @script)
      end

      def term_defs_boilerplate(div, source, term, preface, isodoc)
        div.next = @term_def_boilerplate
        source.each { |s| @anchors[s["bibitemid"]] or
                      warn "term source #{s['bibitemid']} not referenced" }
        if source.empty? && term.nil?
          div.next = @no_terms_boilerplate
        else
          div.next = term_defs_boilerplate_cont(source, term, isodoc)
        end
      end

      def term_defs_boilerplate_cont(src, term, isodoc)
        sources = isodoc.sentence_join(src.map do |s|
          %{<eref bibitemid="#{s['bibitemid']}"/>}
        end)
        if src.empty? then @internal_terms_boilerplate
        elsif term.nil? then external_terms_boilerplate(sources)
        else
          internal_external_terms_boilerplate(sources)
        end
      end

      def norm_ref_preface(f)
      refs = f.elements.select do |e|
        ["reference", "bibitem"].include? e.name
      end
      f.at("./title").next =
        "<p>#{(refs.empty? ? @norm_empty_pref : @norm_with_refs_pref)}</p>"
    end

      TERM_CLAUSE = "//sections/terms | "\
        "//sections/clause[descendant::terms]".freeze

      NORM_REF = "//bibliography/references[title = 'Normative References' or "\
        "title = 'Normative references']".freeze

      def boilerplate_isodoc(xmldoc)
        isodoc = IsoDoc::Convert.new({})
        @lang = xmldoc&.at("//bibdata/language")&.text
        @script = xmldoc&.at("//bibdata/script")&.text
        isodoc.i18n_init(@lang, @script)
        isodoc
      end

      def boilerplate_cleanup(xmldoc)
        isodoc = boilerplate_isodoc(xmldoc)
        f = xmldoc.at(self.class::TERM_CLAUSE) and
          term_defs_boilerplate(f.at("./title"),
                                xmldoc.xpath(".//termdocsource"),
                                f.at(".//term"), f.at(".//p"), isodoc)
        f = xmldoc.at(self.class::NORM_REF) and
          norm_ref_preface(f)
        initial_boilerplate(xmldoc)
      end

      def initial_boilerplate(x)
        return if x.at("//boilerplate")
        preface = x.at("//preface") || x.at("//sections") || x.at("//annex") ||
          x.at("//references") || return
        b = boilerplate(x) or return
        preface.previous = b
      end

      class EmptyAttr
        def attr(_x)
          nil
        end
      end

      def boilerplate(x_orig)
        file = @boilerplateauthority ? "#{@localdir}/#{@boilerplateauthority}" :
          File.join(@libdir, "boilerplate.xml")
        File.exists?(file) or return
        x = x_orig.dup
        # TODO variable
        x.root.add_namespace(nil, "http://riboseinc.com/isoxml")
        x = Nokogiri::XML(x.to_xml)
        conv = html_converter(EmptyAttr.new)
        conv.metadata_init("en", "Latn", {})
        conv.info(x, nil)
          conv.populate_template((File.read(file, encoding: "UTF-8")), nil)
      end

      def bibdata_cleanup(xmldoc)
        xmldoc.xpath("//bibdata//bibitem | //bibdata//note").each do |b|
          b.delete("id")
        end
      end
    end
  end
end
