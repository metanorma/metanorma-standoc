module Asciidoctor
  module Standoc
    module Section
      def in_terms?
        @term_def
      end

      def nonterm_symbols_parse(attrs, xml, node)
        defs = @definitions
        @definitions = false
        clause_parse(attrs, xml, node)
        @definitions = defs
      end

      def symbols_attrs(node, a)
        case sectiontype1(node)
        when "symbols" then a.merge(type: "symbols")
        when "abbreviated terms", "abbreviations" then a.merge(type: "abbreviated_terms")
        else
          a
        end
      end

      def symbols_parse(attr, xml, node)
        node.role == "nonterm" and return nonterm_symbols_parse(attr, xml, node)
        xml.definitions **attr_code(attr) do |xml_section|
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

      def nonterm_term_def_subclause_parse(attrs, xml, node)
        defs = @term_def
        @term_def = false
        clause_parse(attrs, xml, node)
        @term_def = defs
      end

      def terms_boilerplate_parse(attrs, xml, node)
        defs = @term_def
        @term_def = false
        clause_parse(attrs.merge(type: "boilerplate"), xml, node)
        @term_def = defs
      end

      # subclause contains subclauses
      def term_def_subclause_parse(attrs, xml, node)
        node.role == "nonterm"  and return nonterm_term_def_subclause_parse(attrs, xml, node)
        node.role == "boilerplate"  and return terms_boilerplate_parse(attrs, xml, node)
        st = sectiontype(node, false)
        return symbols_parse(attrs, xml, node) if @definitions
        sub = node.find_by(context: :section) { |s| s.level == node.level + 1 }
        sub.empty? || (return term_def_parse(attrs, xml, node, false))
        st == "symbols and abbreviated terms" and (return symbols_parse(attrs, xml, node))
        st == "terms and definitions" and return clause_parse(attrs, xml, node)
        term_def_subclause_parse1(attrs, xml, node)
      end

      def term_def_subclause_parse1(attrs, xml, node)
        xml.term **attr_code(attrs) do |xml_section|
          xml_section.preferred { |name| name << node.title }
          xml_section << node.content
        end
      end

      def term_def_parse(attrs, xml, node, toplevel)
        xml.terms **attr_code(attrs) do |section|
          section.title { |t| t << node.title }
          (s = node.attr("source")) && s.split(/,/).each do |s1|
            section.termdocsource(nil, **attr_code(bibitemid: s1))
          end
          section << node.content
        end
      end
    end
  end
end
