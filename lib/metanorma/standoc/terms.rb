module Metanorma
  module Standoc
    module Section
      def in_terms?
        @term_def
      end

      def nonterm_symbols_parse(attrs, xml, node)
        stash_symbols
        clause_parse(attrs, xml, node)
        pop_symbols
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
          section_title(xml_section, node.title)
          stash_symbols
          @definitions = true
          stash_term_def
          xml_section << node.content
          pop_symbols
          pop_term_def
        end
      end

      def nonterm_term_def_subclause_parse(attrs, xml, node)
        stash_term_def
        clause_parse(attrs, xml, node)
        pop_term_def
      end

      def terms_boilerplate_parse(attrs, xml, node)
        stash_term_def
        clause_parse(attrs.merge(type: "boilerplate"), xml, node)
        pop_term_def
      end

      def stash_term_def
        @stashed_term_def ||= []
        @stashed_term_def.push(@term_def)
        @term_def = false
      end

      def pop_term_def
        @term_def = @stashed_term_def.pop
      end

      def stash_symbols
        @stashed_definitions ||= []
        @stashed_definitions.push(@definitions)
        @definitions = false
      end

      def pop_symbols
        @definitions = @stashed_definitions.pop
      end

      # subclause contains subclauses
      def term_def_subclause_parse(attrs, xml, node)
        node.role == "nonterm" and
          return nonterm_term_def_subclause_parse(attrs, xml, node)
        node.role == "boilerplate" and
          return terms_boilerplate_parse(attrs, xml, node)
        @definitions and return symbols_parse(attrs, xml, node)
        term_contains_subclauses(node) and
          return term_def_parse(attrs, xml, node, false)
        case sectiontype(node, false)
        when "symbols and abbreviated terms"
          return symbols_parse(attrs, xml, node)
        when "terms and definitions"
          return clause_parse(attrs, xml, node)
        end
        term_def_subclause_parse1(attrs, xml, node)
      end

      def term_contains_subclauses(node)
        sub = node.find_by(context: :section) { |s| s.level == node.level + 1 }
        !sub.empty?
      end

      def term_def_subclause_parse1(attrs, xml, node)
        xml.term **attr_code(attrs) do |xml_section|
          term_designation(xml_section, node, "preferred", node.title)
          xml_section << node.content
        end
      end

      def term_def_parse(attrs, xml, node, _toplevel)
        xml.terms **attr_code(attrs) do |section|
          section_title(section, node.title)
          (s = node.attr("source")) && s.split(",").each do |s1|
            section.termdocsource(nil, **attr_code(bibitemid: s1))
          end
          section << node.content
        end
      end

      def term_designation(xml, _node, tag, text)
        xml.send tag do |p|
          p.expression do |e|
            add_noko_elem(e, "name", text)
            # e.name { |name| name << text }
          end
        end
      end

      def termsource_origin_attrs(_node, seen_xref)
        { case: seen_xref.children[0]["case"],
          droploc: seen_xref.children[0]["droploc"],
          bibitemid: seen_xref.children[0]["target"],
          format: seen_xref.children[0]["format"], type: "inline" }
      end

      def add_term_source(node, xml_t, seen_xref, match)
        attrs = {}
        body = seen_xref.children[0]
        unless body.name == "concept"
          attrs = termsource_origin_attrs(node, seen_xref)
          body = body.children
        end
        xml_t.origin **attr_code(attrs) do |o|
          o << body.to_xml
        end
        add_term_source_mod(xml_t, match)
      end

      def add_term_source_mod(xml_t, match)
        match[:text] && xml_t.modification do |mod|
          mod.p { |p| p << match[:text].sub(/^\s+/, "") }
        end
      end

      def extract_termsource_refs(text, node)
        matched = TERM_REFERENCE_RE.match text
        matched.nil? and @log.add("STANDOC_13", node, params: [text])
        matched
      end

      def termsource_attrs(node, matched)
        status = node.attr("status")&.downcase ||
          (matched[:text] ? "modified" : "identical")
        { status: status, type: node.attr("type")&.downcase || "authoritative" }
      end

      def termsource(node)
        matched = extract_termsource_refs(node.content, node) or return
        noko do |xml|
          xml.source **termsource_attrs(node, matched) do |xml_t|
            seen_xref = Nokogiri::XML.fragment(matched[:xref])
            add_term_source(node, xml_t, seen_xref, matched)
          end
        end
      end

      def termdefinition(node)
        noko do |xml|
          xml.definition **attr_code(id_attr(nil)
            .merge(type: node.attr("type"))) do |d|
            d << node.content
          end
        end
      end

      include ::Metanorma::Standoc::Regex
    end
  end
end
