require "htmlentities"
require "uri"
require_relative "ref_sect"

module Asciidoctor
  module Standoc
    module Section
      @biblio = false
      @term_def = false
      @norm_ref = false

      def in_terms?
        @term_def
      end

      def sectiontype1(node)
        node&.attr("heading")&.downcase ||
          node.title.gsub(/<[^>]+>/, "").downcase
      end

      def sectiontype(node, level = true)
        ret = sectiontype1(node)
        ret1 = sectiontype_streamline(ret)
        return ret1 if "symbols and abbreviated terms" == ret1
        return nil unless !level || node.level == 1
        return nil if @seen_headers.include? ret
        @seen_headers << ret
        ret1
      end

      def sectiontype_streamline(ret)
        case ret
        when "terms and definitions",
          "terms, definitions, symbols and abbreviated terms",
          "terms, definitions, symbols and abbreviations",
          "terms, definitions and symbols",
          "terms, definitions and abbreviations",
          "terms, definitions and abbreviated terms"
          "terms and definitions"
        when "symbols and abbreviated terms",
          "symbols", "abbreviated terms", "abbreviations"
          "symbols and abbreviated terms"
        else
          ret
        end
      end

      def section_attributes(node)
        { id: Utils::anchor_or_uuid(node),
          language: node.attributes["language"],
          script: node.attributes["script"],
          annex: (
            ((node.attr("style") == "appendix" || node.role == "appendix") && 
             node.level == 1) ? true : nil
          ),
          preface: (
            (node.role == "preface" || node.attr("style") == "preface") ?
            true : nil),
        }
      end

      def section(node)
        a = section_attributes(node)
        noko do |xml|
          case sectiontype(node)
          when "introduction" then introduction_parse(a, xml, node)
          when "foreword" then foreword_parse(a, xml, node)
          when "scope" then scope_parse(a, xml, node)
          when "normative references" then norm_ref_parse(a, xml, node)
          when "terms and definitions"
            @term_def = true
            term_def_parse(a, xml, node, true)
            @term_def = false
          when "symbols and abbreviated terms"
            symbols_parse(symbols_attrs(node, a), xml, node)
          when "acknowledgements"
            acknowledgements_parse(a, xml, node)
          when "bibliography" 
            bibliography_parse(a, xml, node)
          else
            if @term_def then term_def_subclause_parse(a, xml, node)
            elsif @definitions then symbols_parse(a, xml, node)
            elsif @norm_ref then norm_ref_parse(a, xml, node)
            elsif @biblio then bibliography_parse(a, xml, node)
            elsif node.attr("style") == "bibliography" && sectiontype(node, false) == "normative references"
              norm_ref_parse(a, xml, node)
            elsif node.attr("style") == "bibliography" && sectiontype(node, false) == "bibliography"
              bibliography_parse(a, xml, node)
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

      def preamble(node)
        noko do |xml|
          xml.foreword **attr_code(section_attributes(node)) do |xml_abstract|
            xml_abstract.title { |t| t << (node.blocks[0].title || @i18n.foreword) }
            content = node.content
            xml_abstract << content
          end
        end.join("\n")
      end

      def abstract_parse(attrs, xml, node)
        xml.abstract **attr_code(attrs) do |xml_section|
          xml_section << node.content
        end
      end

      def scope_parse(attrs, xml, node)
        clause_parse(attrs.merge(type: "scope"), xml, node)
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

      def nonterm_symbols_parse(attrs, xml, node)
        @definitions = false
        clause_parse(attrs, xml, node)
        @definitions = true
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
        @term_def = false
        clause_parse(attrs, xml, node)
        @term_def = true
      end

      # subclause contains subclauses
      def term_def_subclause_parse(attrs, xml, node)
        node.role == "nonterm"  and
          return nonterm_term_def_subclause_parse(attrs, xml, node)
        st = sectiontype(node, false)
        return symbols_parse(attrs, xml, node) if @definitions
        sub = node.find_by(context: :section) { |s| s.level == node.level + 1 }
        sub.empty? || (return term_def_parse(attrs, xml, node, false))
        st == "symbols and abbreviated terms" and
          (return symbols_parse(attrs, xml, node))
        st == "terms and definitions" and
          return clause_parse(attrs, xml, node)
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

      def introduction_parse(attrs, xml, node)
        xml.introduction **attr_code(attrs) do |xml_section|
          xml_section.title { |t| t << @i18n.introduction }
          content = node.content
          xml_section << content
        end
      end

      def foreword_parse(attrs, xml, node)
        xml.foreword **attr_code(attrs) do |xml_section|
          xml_section.title { |t| t << node.title }
          content = node.content
          xml_section << content
        end
      end

      def acknowledgements_parse(attrs, xml, node)
        xml.acknowledgements **attr_code(attrs) do |xml_section|
          xml_section.title { |t| t << node.title || @i18n.acknowledgements }
          content = node.content
          xml_section << content
        end
      end
    end
  end
end
