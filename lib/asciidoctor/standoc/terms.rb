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

      def symbols_attrs(node, attr)
        case sectiontype1(node)
        when "symbols" then attr.merge(type: "symbols")
        when "abbreviated terms", "abbreviations"
          attr.merge(type: "abbreviated_terms")
        else
          attr
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
        node.role == "nonterm" and
          return nonterm_term_def_subclause_parse(attrs, xml, node)
        node.role == "boilerplate" and
          return terms_boilerplate_parse(attrs, xml, node)
        st = sectiontype(node, false)
        return symbols_parse(attrs, xml, node) if @definitions

        sub = node.find_by(context: :section) { |s| s.level == node.level + 1 }
        sub.empty? || (return term_def_parse(attrs, xml, node, false))
        st == "symbols and abbreviated terms" and
          return symbols_parse(attrs, xml, node)
        st == "terms and definitions" and return clause_parse(attrs, xml, node)
        term_def_subclause_parse1(attrs, xml, node)
      end

      def term_def_subclause_parse1(attrs, xml, node)
        xml.term **attr_code(attrs) do |xml_section|
          term_designation(xml_section, node, "preferred", node.title)
          xml_section << node.content
        end
      end

      def term_def_parse(attrs, xml, node, _toplevel)
        xml.terms **attr_code(attrs) do |section|
          section.title { |t| t << node.title }
          (s = node.attr("source")) && s.split(",").each do |s1|
            section.termdocsource(nil, **attr_code(bibitemid: s1))
          end
          section << node.content
        end
      end

      def term_designation(xml, _node, tag, text)
        xml.send tag do |p|
          p.expression do |e|
            e.name { |name| name << text }
          end
        end
      end

      def term_source_attrs(_node, seen_xref)
        { case: seen_xref.children[0]["case"],
          droploc: seen_xref.children[0]["droploc"],
          bibitemid: seen_xref.children[0]["target"],
          format: seen_xref.children[0]["format"], type: "inline" }
      end

      def add_term_source(node, xml_t, seen_xref, match)
        if seen_xref.children[0].name == "concept"
          xml_t.origin { |o| o << seen_xref.children[0].to_xml }
        else
          attrs = term_source_attrs(node, seen_xref)
          attrs.delete(:text)
          xml_t.origin seen_xref.children[0].content, **attr_code(attrs)
        end
        match[:text] && xml_t.modification do |mod|
          mod.p { |p| p << match[:text].sub(/^\s+/, "") }
        end
      end

      TERM_REFERENCE_RE_STR = <<~REGEXP.freeze
        ^(?<xref><(xref|concept)[^>]+>(.*?</(xref|concept)>)?)
               (,\s(?<text>.*))?
        $
      REGEXP
      TERM_REFERENCE_RE =
        Regexp.new(TERM_REFERENCE_RE_STR.gsub(/\s/, "").gsub(/_/, "\\s"),
                   Regexp::IGNORECASE | Regexp::MULTILINE)

      def extract_termsource_refs(text, node)
        matched = TERM_REFERENCE_RE.match text
        matched.nil? and @log.add("AsciiDoc Input", node,
                                  "term reference not in expected format:"\
                                  "#{text}")
        matched
      end

      def termsource(node)
        matched = extract_termsource_refs(node.content, node) || return
        noko do |xml|
          attrs = { status: matched[:text] ? "modified" : "identical" }
          xml.termsource **attrs do |xml_t|
            seen_xref = Nokogiri::XML.fragment(matched[:xref])
            add_term_source(node, xml_t, seen_xref, matched)
          end
        end.join("\n")
      end

      def termdefinition(node)
        noko do |xml|
          xml.definition do |d|
            d << node.content
          end
        end.join("\n")
      end
    end
  end
end
