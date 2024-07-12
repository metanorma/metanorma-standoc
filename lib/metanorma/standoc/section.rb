require "uri" if /^2\./.match?(RUBY_VERSION)
require_relative "ref_sect"
require_relative "terms"

module Metanorma
  module Standoc
    module Section
      @biblio = false
      @term_def = false
      @norm_ref = false

      def sectiontype1(node)
        node.attr("style") == "abstract" and return "abstract"
        node.attr("heading")&.downcase ||
          node.title
            .gsub(%r{<index>.*?</index>}m, "")
            .gsub(%r{<fn[^>]*>.*?</fn>}m, "")
            .gsub(/<[^>]+>/, "")
            .strip.downcase.sub(/\.$/, "")
      end

      def sectiontype(node, level = true)
        ret = sectiontype1(node)
        ret1 = preface_main_filter(sectiontype_streamline(ret), node)
        ret1 == "symbols and abbreviated terms" and return ret1
        !level || node.level == 1 || node.attr("heading") or return nil
        @seen_headers.include? ret and return nil
        @seen_headers << ret unless ret1.nil?
        @seen_headers_canonical << ret1 unless ret1.nil?
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
        when "acknowledgements", "acknowledgments"
          "acknowledgements"
        else
          ret
        end
      end

      PREFACE_CLAUSE_NAMES =
        %w(abstract foreword introduction metanorma-extension termdocsource
           misc-container acknowledgements).freeze

      MAIN_CLAUSE_NAMES =
        ["normative references", "terms and definitions", "scope",
         "symbols and abbreviated terms", "clause", "bibliography"].freeze

      def role_style(node, value)
        node.role == value || node.attr("style") == value
      end

      def start_main_section(ret, node)
        role_style(node, "preface") and return
        @preface = false if self.class::MAIN_CLAUSE_NAMES.include?(ret)
        @preface = false if self.class::PREFACE_CLAUSE_NAMES
          .intersection(@seen_headers_canonical + [ret]).empty?
      end

      def preface_main_filter(ret, node)
        start_main_section(ret, node)
        if @preface
          self.class::MAIN_CLAUSE_NAMES.include?(ret) and return nil
        else
          self.class::PREFACE_CLAUSE_NAMES.include?(ret) and return nil
        end

        ret
      end

      def section_attributes(node)
        ret =
          { id: Metanorma::Utils::anchor_or_uuid(node),
            unnumbered: node.option?("unnumbered") ? "true" : nil,
            annex: role_style(node, "appendix") && node.level == 1 ? true : nil,
            colophon: role_style(node, "colophon") ? true : nil,
            preface: role_style(node, "preface") ? true : nil }
        %w(language script number branch-number type tag keeptitle
           multilingual-rendering).each do |k|
          a = node.attr(k) and ret[k.to_sym] = a
        end
        section_attributes_change(node, ret).compact
      end

      def section_attributes_change(node, ret)
        node.attributes["change"] or return ret
        ret.merge(change: node.attributes["change"],
                  path: node.attributes["path"],
                  path_end: node.attributes["path_end"],
                  title: node.attributes["title"])
      end

      def section(node)
        a = section_attributes(node)
        noko do |xml|
          case sectiontype(node)
          when "misc-container", "metanorma-extension"
            misccontainer_parse(a, xml, node)
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
            elsif @norm_ref ||
                (node.attr("style") == "bibliography" &&
                 sectiontype(node, false) == "normative references")
              norm_ref_parse(a, xml, node)
            elsif @biblio || node.attr("style") == "bibliography"
              bibliography_parse(a, xml, node)
            elsif node.attr("style") == "abstract"
              abstract_parse(a, xml, node)
            elsif node.attr("style") == "index"
              indexsect_parse(a, xml, node)
            elsif node.attr("style") == "appendix" && node.level == 1
              annex_parse(a, xml, node)
            else
              clause_parse(a, xml, node)
            end
          end
        end.join("\n")
      end

      def set_obligation(attrs, node)
        attrs[:obligation] =
          if node.attributes.has_key?("obligation")
            node.attr("obligation")
          elsif node.parent.attributes.has_key?("obligation")
            node.parent.attr("obligation")
          else "normative"
          end
      end

      def preamble(node)
        noko do |xml|
          xml.foreword **attr_code(section_attributes(node)) do |xml_abstract|
            xml_abstract.title do |t|
              t << (node.blocks[0].title || @i18n.foreword)
            end
            xml_abstract << node.content
          end
        end.join("\n")
      end

      def misccontainer_parse(_attrs, xml, node)
        xml.send :"misc-container-clause" do |xml_section|
          xml_section << node.content
        end
      end

      def indexsect_parse(attrs, xml, node)
        xml.indexsect **attr_code(attrs) do |xml_section|
          xml_section.title { |name| name << node.title }
          xml_section << node.content
        end
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
        attrs[:"inline-header"] = node.option? "inline-header"
        attrs[:bibitem] = true if node.option? "bibitem"
        attrs[:level] = node.attr("level")
        set_obligation(attrs, node)
        xml.send :clause, **attr_code(attrs) do |xml_section|
          xml_section.title { |n| n << node.title } unless node.title.nil?
          xml_section << node.content
        end
      end

      def annex_parse(attrs, xml, node)
        attrs[:"inline-header"] = node.option? "inline-header"
        set_obligation(attrs, node)
        xml.annex **attr_code(attrs) do |xml_section|
          xml_section.title { |name| name << node.title }
          xml_section << node.content
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
          xml_section.title { |t| (t << node.title) || @i18n.acknowledgements }
          content = node.content
          xml_section << content
        end
      end

      def floating_title_attrs(node)
        attr_code(id_attr(node)
          .merge(align: node.attr("align"), depth: node.level,
                 type: "floating-title"))
      end

      def floating_title(node)
        noko do |xml|
          xml.floating_title **floating_title_attrs(node) do |xml_t|
            xml_t << node.title
          end
        end.join("\n")
      end
    end
  end
end
