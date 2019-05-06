require "htmlentities"
require "uri"

module Asciidoctor
  module Standoc
    module Section
      @biblio = false
      @term_def = false
      @norm_ref = false

      def in_biblio?
        @biblio
      end

      def in_terms?
        @term_def
      end

      def in_norm_ref?
        @norm_ref
      end

      def sectiontype(node)
        ret = node&.attr("heading")&.downcase ||
          node.title.gsub(/<[^>]+>/, "").downcase
        return ret if ["symbols and abbreviated terms", "abbreviations",
                       "abbreviated terms", "symbols"].include? ret
        return nil unless node.level == 1
        return nil if @seen_headers.include? ret
        @seen_headers << ret
        ret
      end

      def section(node)
        a = { id: Utils::anchor_or_uuid(node) }
        noko do |xml|
          case sectiontype(node)
          when "introduction" then introduction_parse(a, xml, node)
          when "normative references" then norm_ref_parse(a, xml, node)
          when "terms and definitions",
            "terms, definitions, symbols and abbreviated terms",
            "terms, definitions, symbols and abbreviations",
            "terms, definitions and symbols",
            "terms, definitions and abbreviations",
            "terms, definitions and abbreviated terms"
            @term_def = true
            term_def_parse(a, xml, node, true)
            @term_def = false
          when "symbols and abbreviated terms",
            "symbols",
            "abbreviated terms",
            "abbreviations"
            symbols_parse(a, xml, node)
          when "bibliography" then bibliography_parse(a, xml, node)
          else
            if @term_def then term_def_subclause_parse(a, xml, node)
            elsif @definitions then symbols_parse(a, xml, node)
            elsif @biblio then bibliography_parse(a, xml, node)
            elsif node.attr("style") == "bibliography"
              bibliography_parse(a, xml, node)
            elsif node.attr("style") == "abstract" 
              abstract_parse(a, xml, node)
            elsif node.attr("style") == "appendix" && node.level == 1
              annex_parse(a, xml, node)
            else
              clause_parse(a, xml, node)
            end
          end
        end.join("\n")
      end

      def set_obligation(attrs, node)
        attrs[:obligation] = if node.attributes.has_key?("obligation")
                               node.attr("obligation")
                             elsif node.parent.attributes.has_key?("obligation")
                               node.parent.attr("obligation")
                             else
                               "normative"
                             end
      end

      def abstract_parse(attrs, xml, node)
        xml.abstract **attr_code(attrs) do |xml_section|
          xml_section << node.content
        end
      end

      def clause_parse(attrs, xml, node)
        attrs["inline-header".to_sym] = node.option? "inline-header"
        attrs[:bibitem] = true if node.option? "bibitem"
        attrs[:level] = node.attr("level")
        set_obligation(attrs, node)
        xml.send "clause", **attr_code(attrs) do |xml_section|
          xml_section.title { |n| n << node.title } unless node.title.nil?
          xml_section << node.content
        end
      end

      def annex_parse(attrs, xml, node)
        attrs["inline-header".to_sym] = node.option? "inline-header"
        set_obligation(attrs, node)
        xml.annex **attr_code(attrs) do |xml_section|
          xml_section.title { |name| name << node.title }
          xml_section << node.content
        end
      end

      def bibliography_parse(attrs, xml, node)
        node.attr("style") == "bibliography" or
          warn "Section not marked up as [bibliography]!"
        @biblio = true
        xml.references **attr_code(attrs) do |xml_section|
          title = node.level == 1 ? "Bibliography" : node.title
          xml_section.title { |t| t << title }
          xml_section << node.content
        end
        @biblio = false
      end

      def nonterm_symbols_parse(attrs, xml, node)
        @definitions = false
        clause_parse(attrs, xml, node)
        @definitions = true
      end

      def symbols_parse(attrs, xml, node)
        node.role == "nonterm" and return nonterm_symbols_parse(attrs, xml, node)
        xml.definitions **attr_code(attrs) do |xml_section|
          xml_section.title { |t| t << node.title }
          defs = @definitions
          termdefs = @term_def
          @definitions = true
          @term_def = false
          xml_section << node.content
          @definitions = defs
          @term_def = termdefs
        end
      end

      SYMBOLS_TITLES = ["symbols and abbreviated terms", "symbols",
                        "abbreviated terms"].freeze

      def nonterm_term_def_subclause_parse(attrs, xml, node)
        @term_def = false
        clause_parse(attrs, xml, node)
        @term_def = true
      end

      # subclause contains subclauses
      def term_def_subclause_parse(attrs, xml, node)
        node.role == "nonterm" and
          return nonterm_term_def_subclause_parse(attrs, xml, node)
        return symbols_parse(attrs, xml, node) if @definitions
        sub = node.find_by(context: :section) { |s| s.level == node.level + 1 }
        sub.empty? || (return term_def_parse(attrs, xml, node, false))
        SYMBOLS_TITLES.include?(node.title.downcase) and
          (return symbols_parse(attrs, xml, node))
        xml.term **attr_code(attrs) do |xml_section|
          xml_section.preferred { |name| name << node.title }
          xml_section << node.content
        end
      end

      def term_def_title(toplevel, node)
        return node.title unless toplevel
        sub = node.find_by(context: :section) do |s|
          SYMBOLS_TITLES.include? s.title.downcase
        end
        return "Terms and definitions" if sub.empty?
        "Terms, definitions, symbols and abbreviated terms"
      end

      def term_def_parse(attrs, xml, node, toplevel)
        xml.terms **attr_code(attrs) do |section|
          section.title { |t| t << term_def_title(toplevel, node) }
          (s = node.attr("source")) && s.split(/,/).each do |s1|
            section.termdocsource(nil, **attr_code(bibitemid: s1))
          end
          section << node.content
        end
      end

      def norm_ref_parse(attrs, xml, node)
        @norm_ref = true
        xml.references **attr_code(attrs) do |xml_section|
          xml_section.title { |t| t << "Normative References" }
          xml_section << node.content
        end
        @norm_ref = false
      end

      def introduction_parse(attrs, xml, node)
        xml.introduction **attr_code(attrs) do |xml_section|
          xml_section.title = "Introduction"
          content = node.content
          xml_section << content
        end
      end
    end
  end
end
