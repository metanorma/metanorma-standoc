require "htmlentities"
require "uri"

module Asciidoctor
  module Standoc
    module Blocks
      def id_attr(node = nil)
        { id: Utils::anchor_or_uuid(node) }
      end

      def id_unnum_attr(node)
        attr_code( id: Utils::anchor_or_uuid(node),
                  unnumbered: node.option?("unnumbered") ? "true" : nil,
                  subsequence: node.attr("subsequence") )
      end

      def formula_attr(node)
        attr_code( id: Utils::anchor_or_uuid(node),
                  inequality: node.option?("inequality") ? "true" : nil,
                  unnumbered: node.option?("unnumbered") ? "true" : nil,
                  subsequence: node.attr("subsequence") )
      end

      # We append each contained block to its parent
      def open(node)
        role = node.role || node.attr("style")
        Utils::reqt_subpart(role) and
          return requirement_subpart(node)
        result = []
        node.blocks.each do |b|
          result << send(b.context, b)
        end
        result
      end

      def literal_attrs(node)
        attr_code(id_attr(node))
      end

      def literal(node)
        noko do |xml|
          xml.figure **literal_attrs(node) do |f|
            figure_title(node, f)
            f.pre node.lines.join("\n"), **attr_code(id: Utils::anchor_or_uuid,
                                                     alt: node.attr("alt"))
          end
        end
      end

      # NOTE: html escaping is performed by Nokogiri
      def stem(node)
        stem_content = node.lines.join("\n")
        noko do |xml|
          xml.formula **formula_attr(node) do |s|
            stem_parse(stem_content, s, node.style.to_sym)
          end
        end
      end

      def sidebar_attrs(node)
        todo_attrs(node).merge(attr_code(
          from: node.attr("from"),
          to: node.attr("to") || node.attr("from") ))
      end

      def sidebar(node)
        return unless draft?
        noko do |xml|
          xml.review **(sidebar_attrs(node)) do |r|
            wrap_in_para(node, r)
          end
        end
      end

      def todo_attrs(node)
        date = node.attr("date") || Date.today.iso8601.gsub(/\+.*$/, "")
        date += "T00:00:00Z" unless /T/.match date
        attr_code(
          id: Utils::anchor_or_uuid(node),
          reviewer: node.attr("reviewer") || node.attr("source") || "(Unknown)",
          date: date )
      end

      def todo(node)
        noko do |xml|
          xml.review **(todo_attrs(node)) do |r|
            wrap_in_para(node, r)
          end
        end
      end

      def termnote(n)
        noko do |xml|
          xml.termnote **id_attr(n) do |ex|
            wrap_in_para(n, ex)
          end
        end.join
      end

      def note(n)
        noko do |xml|
          xml.note **id_attr(n) do |c|
            wrap_in_para(n, c)
          end
        end.join
      end

      def admonition_attrs(node)
        name = node.attr("name")
        if type = node.attr("type")
          ["danger", "safety precautions"].each do |t|
            name = t if type.casecmp(t).zero?
          end
        end
        attr_code(id: Utils::anchor_or_uuid(node), type: name)
      end

      def admonition(node)
        return termnote(node) if in_terms?
        return note(node) if node.attr("name") == "note"
        return todo(node) if node.attr("name") == "todo"
        noko do |xml|
          xml.admonition **admonition_attrs(node) do |a|
            node.title.nil? or a.name { |name| name << node.title }
            wrap_in_para(node, a)
          end
        end.join
      end

      def term_example(node)
        noko do |xml|
          xml.termexample **id_attr(node) do |ex|
            wrap_in_para(node, ex)
          end
        end.join
      end

      def example(node)
        return term_example(node) if in_terms?
        role = node.role || node.attr("style")
        %w(recommendation requirement permission).include?(role) and
          return requirement(node, role)
        return pseudocode_example(node) if role == "pseudocode"
        example_proper(node)
      end

      def pseudocode_example(node)
        noko do |xml|
          xml.figure **{id: Asciidoctor::Standoc::Utils::anchor_or_uuid(node),
                        class: "pseudocode"} do |ex|
            figure_title(node, ex)
            wrap_in_para(node, ex)
          end
        end.join
      end

      def example_attrs(node)
        attr_code(id_unnum_attr(node))
      end

      def example_proper(node)
        noko do |xml|
          xml.example **example_attrs(node) do |ex|
            node.title.nil? or ex.name { |name| name << node.title }
            wrap_in_para(node, ex)
          end
        end.join
      end

      def figure_title(node, f)
        return if node.title.nil?
        f.name { |name| name << node.title }
      end

      def figure_attrs(node)
        attr_code(id_unnum_attr(node))
      end

      def image(node)
        noko do |xml|
          xml.figure **figure_attrs(node) do |f|
            figure_title(node, f)
            f.image **(image_attributes(node))
          end
        end
      end

      def para_attrs(node)
        attr_code(align: node.attr("align"),
                  id: Utils::anchor_or_uuid(node))
      end

      def paragraph(node)
        return termsource(node) if node.role == "source"
        noko do |xml|
          xml.p **para_attrs(node) do |xml_t|
            xml_t << node.content
          end
        end.join
      end

      def quote_attrs(node)
        attr_code(id: Utils::anchor_or_uuid(node), align: node.attr("align"))
      end

      def quote_attribution(node, out)
        if node.attr("citetitle")
          m = /^(?<cite>[^,]+)(,(?<text>.*$))?$/m.match node.attr("citetitle")
          out.source m[:text],
            **attr_code(target: m[:cite], type: "inline")
        end
        if node.attr("attribution")
          out.author { |a| a << node.attr("attribution") }
        end
      end

      def quote(node)
        noko do |xml|
          xml.quote **(quote_attrs(node)) do |q|
            quote_attribution(node, q)
            wrap_in_para(node, q)
          end
        end.join
      end

      def listing_attrs(node)
        attr_code(lang: node.attr("language"),
                  id: Utils::anchor_or_uuid(node),
                  filename: node.attr("filename"))
      end

      # NOTE: html escaping is performed by Nokogiri
      def listing(node)
        fragment = ::Nokogiri::XML::Builder.new do |xml|
          xml.sourcecode **(listing_attrs(node)) do |s|
            figure_title(node, s)
            s << node.content
          end
        end
        fragment.to_xml(encoding: "US-ASCII", save_with:
                        Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
      end

      def pass(node)
        node.content
      end
    end
  end
end
