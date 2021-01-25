require "htmlentities"
require "uri"
require_relative "./blocks_notes"

module Asciidoctor
  module Standoc
    module Blocks
      def id_attr(node = nil)
        { id: Metanorma::Utils::anchor_or_uuid(node) }
      end

      def id_unnum_attrs(node)
        attr_code( id: Metanorma::Utils::anchor_or_uuid(node),
                  unnumbered: node.option?("unnumbered") ? "true" : nil,
                  number: node.attr("number"),
                  subsequence: node.attr("subsequence") )
      end

      def formula_attrs(node)
        attr_code(id_unnum_attrs(node).merge(keep_attrs(node).merge(
          inequality: node.option?("inequality") ? "true" : nil)))
      end

      def keep_attrs(node)
        { "keep-with-next": node.attr("keep-with-next"),
          "keep-lines-together": node.attr("keep-lines-together") }
      end

      # We append each contained block to its parent
      def open(node)
        role = node.role || node.attr("style")
        Metanorma::Utils::reqt_subpart(role) and return requirement_subpart(node)
        result = []
        node.blocks.each do |b|
          result << send(b.context, b)
        end
        result
      end

      def literal_attrs(node)
        attr_code(id_attr(node).merge(keep_attrs(node)))
      end

      def literal(node)
        noko do |xml|
          xml.figure **literal_attrs(node) do |f|
            figure_title(node, f)
            f.pre node.lines.join("\n"), **attr_code(id: Metanorma::Utils::anchor_or_uuid,
                                                     alt: node.attr("alt"))
          end
        end
      end

      # NOTE: html escaping is performed by Nokogiri
      def stem(node)
        noko do |xml|
          xml.formula **formula_attrs(node) do |s|
            stem_parse(node.lines.join("\n"), s, node.style.to_sym)
          end
        end
      end

      def term_example(node)
        noko do |xml|
          xml.termexample **id_attr(node) do |ex|
            wrap_in_para(node, ex)
          end
        end.join("\n")
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
        # prevent A's and other subs inappropriate for pseudocode
        node.blocks.each { |b| b.remove_sub(:replacements) }
        noko do |xml|
          xml.figure **example_attrs(node).merge(class: "pseudocode") do |ex|
            figure_title(node, ex)
            wrap_in_para(node, ex)
          end
        end.join("\n")
      end

      def example_attrs(node)
        attr_code(id_unnum_attrs(node).merge(keep_attrs(node)))
      end

      def example_proper(node)
        noko do |xml|
          xml.example **example_attrs(node) do |ex|
            node.title.nil? or ex.name { |name| name << node.title }
            wrap_in_para(node, ex)
          end
        end.join("\n")
      end

      def figure_title(node, f)
        return if node.title.nil?
        f.name { |name| name << node.title }
      end

      def figure_attrs(node)
        attr_code(id_unnum_attrs(node).merge(keep_attrs(node)))
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
        attr_code(keep_attrs(node).merge(align: node.attr("align"), 
                                        id: Metanorma::Utils::anchor_or_uuid(node)))
      end

      def paragraph(node)
        return termsource(node) if node.role == "source"
        noko do |xml|
          xml.p **para_attrs(node) do |xml_t|
            xml_t << node.content
          end
        end.join("\n")
      end

      def quote_attrs(node)
        attr_code(keep_attrs(node).merge(align: node.attr("align"), 
                                        id: Metanorma::Utils::anchor_or_uuid(node)))
      end

      def quote_attribution(node, out)
        if node.attr("citetitle")
          m = /^(?<cite>[^,]+)(,(?<text>.*$))?$/m.match node.attr("citetitle")
          out.source **attr_code(target: m[:cite], type: "inline") do |s|
            s <<  m[:text]
          end
        end
        node.attr("attribution") and
          out.author { |a| a << node.attr("attribution") }
      end

      def quote(node)
        noko do |xml|
          xml.quote **(quote_attrs(node)) do |q|
            quote_attribution(node, q)
            wrap_in_para(node, q)
          end
        end.join("\n")
      end

      def listing_attrs(node)
        attr_code(keep_attrs(node).merge(lang: node.attr("language"),
                                        id: Metanorma::Utils::anchor_or_uuid(node),
                                        unnumbered: node.option?("unnumbered") ? "true" : nil,
                                        number: node.attr("number"),
                                        filename: node.attr("filename")))
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
        noko do |xml|
          xml.passthrough **attr_code(formats: 
                                      node.attr("format") || "metanorma") do |p|
            p << HTMLEntities.new.encode(node.content, :basic, :hexadecimal)
          end
        end
      end
    end
  end
end
