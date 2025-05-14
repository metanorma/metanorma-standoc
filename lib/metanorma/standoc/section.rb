require "uri" if /^2\./.match?(RUBY_VERSION)
require_relative "ref_sect"
require_relative "terms"
require_relative "sectiontype"

module Metanorma
  module Standoc
    module Section
      @biblio = false
      @term_def = false
      @norm_ref = false

      def section_attributes(node)
        ret = id_unnum_attrs(node).merge(
          { annex: role_style(node, "appendix") && node.level == 1 ? true : nil,
            colophon: role_style(node, "colophon") ? true : nil,
            preface: role_style(node, "preface") ? true : nil },
        )
        %w(language script branch-number type tag keeptitle
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
          when "metanorma-extension"
            metanorma_extension_parse(a, xml, node)
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
          when "executivesummary"
            executivesummary_parse(a, xml, node)
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
        end
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
        end
      end

      def metanorma_extension_parse(_attrs, xml, node)
        xml.send :"metanorma-extension-clause" do |xml_section|
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

      def clause_attrs_preprocess(attrs, node)
        attrs[:"inline-header"] = node.option? "inline-header"
        attrs[:bibitem] = true if node.option? "bibitem"
        attrs[:level] = node.attr("level")
        set_obligation(attrs, node)
      end

      def clause_parse(attrs, xml, node)
        clause_attrs_preprocess(attrs, node)
        node.option?("appendix") && support_appendix?(node) and
          return appendix_parse(attrs, xml, node)
        xml.send :clause, **attr_code(attrs) do |xml_section|
          xml_section.title { |n| n << node.title } unless node.title.nil?
          xml_section << node.content
        end
      end

      def annex_attrs_preprocess(attrs, node)
        attrs[:"inline-header"] = node.option? "inline-header"
        set_obligation(attrs, node)
      end

      def annex_parse(attrs, xml, node)
        annex_attrs_preprocess(attrs, node)
        xml.annex **attr_code(attrs) do |xml_section|
          xml_section.title { |name| name << node.title }
          xml_section << node.content
        end
      end

      def support_appendix?(_node)
        false
      end

      def appendix_parse(attrs, xml, node)
        attrs[:"inline-header"] = node.option? "inline-header"
        set_obligation(attrs, node)
        xml.appendix **attr_code(attrs) do |xml_section|
          xml_section.title { |name| name << node.title }
          xml_section << node.content
        end
      end

      def introduction_parse(attrs, xml, node)
        xml.introduction **attr_code(attrs) do |xml_section|
          xml_section.title { |t| t << @i18n.introduction }
          xml_section << node.content
        end
      end

      def foreword_parse(attrs, xml, node)
        xml.foreword **attr_code(attrs) do |xml_section|
          xml_section.title { |t| t << node.title }
          xml_section << node.content
        end
      end

      def acknowledgements_parse(attrs, xml, node)
        xml.acknowledgements **attr_code(attrs) do |xml_section|
          xml_section.title { |t| (t << node.title) || @i18n.acknowledgements }
          xml_section << node.content
        end
      end

      def executivesummary_parse(attrs, xml, node)
        xml.executivesummary **attr_code(attrs) do |xml_section|
          xml_section.title { |t| (t << node.title) || @i18n.executivesummary }
          xml_section << node.content
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
        end
      end
    end
  end
end
