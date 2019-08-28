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
        source.each { |s| @anchors[s["bibitemid"]] or
                      warn "term source #{s['bibitemid']} not referenced" }
        if source.empty? && term.nil?
          div.next = @no_terms_boilerplate
        else
          div.next = term_defs_boilerplate_cont(source, term, isodoc)
        end
        div.next = @term_def_boilerplate
      end

      def term_defs_boilerplate_cont(src, term, isodoc)
        sources = isodoc.sentence_join(src.map do |s|
          %{<eref bibitem="#{s['bibitemid']}"/>}
        end)
        if src.empty? then @internal_terms_boilerplate
        elsif term.nil? then external_terms_boilerplate(sources)
        else
          internal_external_terms_boilerplate(sources)
        end
      end

      TERM_CLAUSE = "//sections/terms | "\
        "//sections/clause[descendant::terms]".freeze

      def boilerplate_cleanup(xmldoc)
        isodoc = IsoDoc::Convert.new({})
        @lang = xmldoc&.at("//bibdata/language")&.text
        @script = xmldoc&.at("//bibdata/script")&.text
        isodoc.i18n_init(@lang, @script)
        f = xmldoc.at(TERM_CLAUSE) and
          term_defs_boilerplate(f.at("./title"),
                                xmldoc.xpath(".//termdocsource"),
                                f.at(".//term"), f.at(".//p"), isodoc)

      end
    end
  end
end
