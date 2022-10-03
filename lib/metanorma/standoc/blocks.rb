require "htmlentities"
require "uri" if /^2\./.match?(RUBY_VERSION)
require_relative "./blocks_notes"

module Metanorma
  module Standoc
    module Blocks
      def id_attr(node = nil)
        { id: Metanorma::Utils::anchor_or_uuid(node),
          tag: node&.attr("tag"),
          "multilingual-rendering": node&.attr("multilingual-rendering") }
      end

      def id_unnum_attrs(node)
        attr_code(id_attr(node).merge(
                    unnumbered: node.option?("unnumbered") ? "true" : nil,
                    number: node.attr("number"),
                    subsequence: node.attr("subsequence"),
                  ))
      end

      def formula_attrs(node)
        attr_code(id_unnum_attrs(node)
          .merge(keep_attrs(node).merge(
                   inequality: node.option?("inequality") ? "true" : nil,
                 )))
      end

      def keep_attrs(node)
        { "keep-with-next": node.attr("keep-with-next"),
          "keep-lines-together": node.attr("keep-lines-together") }
      end

      # We append each contained block to its parent
      def open(node)
        role = node.role || node.attr("style")
        reqt_subpart?(role) and return requirement_subpart(node)
        role == "form" and return form(node)
        role == "definition" and return termdefinition(node)
        result = []
        node.blocks.each { |b| result << send(b.context, b) }
        result
      end

      def form(node)
        noko do |xml|
          xml.form **attr_code(id_attr(node)
            .merge(class: node.attr("class"),
                   name: node.attr("name"), action: node.attr("action"))) do |f|
            f << node.content
          end
        end
      end

      def literal_attrs(node)
        attr_code(id_attr(node).merge(keep_attrs(node)))
      end

      def literal(node)
        noko do |xml|
          xml.figure **literal_attrs(node) do |f|
            figure_title(node, f)
            f.pre node.lines.join("\n"),
                  **attr_code(id: Metanorma::Utils::anchor_or_uuid,
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
          xml.termexample **attr_code(id_attr(node)
            .merge(
              keepasterm: node.option?("termexample") || nil,
            )) do |ex|
            wrap_in_para(node, ex)
          end
        end.join("\n")
      end

      def example(node)
        (in_terms? || node.option?("termexample")) and return term_example(node)
        role = node.role || node.attr("style")
        ret = example_to_requirement(node, role) ||
          example_by_role(node, role) and return ret
        reqt_subpart?(role) and return requirement_subpart(node)
        example_proper(node)
      end

      def example_by_role(node, role)
        case role
        when "pseudocode" then pseudocode_example(node)
        when "svgmap" then svgmap_example(node)
        when "form" then form(node)
        when "definition" then termdefinition(node)
        when "figure" then figure_example(node)
        end
      end

      def example_to_requirement(node, role)
        return unless @reqt_models.requirement_roles.key?(role&.to_sym)

        # need to call here for proper recursion ordering
        select_requirement_model(node)
        requirement(node,
                    @reqt_models.requirement_roles[role.to_sym], role)
      end

      def svgmap_attrs(node)
        attr_code(id_attr(node)
          .merge(id: node.id, number: node.attr("number"),
                 unnumbered: node.option?("unnumbered") ? "true" : nil,
                 subsequence: node.attr("subsequence"))
        .merge(keep_attrs(node)))
      end

      def svgmap_example(node)
        noko do |xml|
          xml.svgmap **attr_code(svgmap_attrs(node).merge(
                                   src: node.attr("src"), alt: node.attr("alt"),
                                 )) do |ex|
            figure_title(node, ex)
            ex << node.content
          end
        end.join("\n")
      end

      # prevent A's and other subs inappropriate for pseudocode
      def pseudocode_example(node)
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

      def figure_example(node)
        noko do |xml|
          xml.figure **figure_attrs(node) do |ex|
            node.title.nil? or ex.name { |name| name << node.title }
            wrap_in_para(node, ex)
          end
        end.join("\n")
      end

      def figure_title(node, out)
        return if node.title.nil?

        out.name { |name| name << node.title }
      end

      def figure_attrs(node)
        attr_code(id_unnum_attrs(node).merge(keep_attrs(node))
          .merge(class: node.attr("class")))
      end

      def image(node)
        noko do |xml|
          xml.figure **figure_attrs(node) do |f|
            figure_title(node, f)
            f.image **image_attributes(node)
          end
        end
      end

      def para_attrs(node)
        attr_code(id_attr(node).merge(keep_attrs(node)
          .merge(align: node.attr("align"),
                 variant_title: node.role == "variant-title" ? true : nil,
                 type: node.attr("type"))))
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
        attr_code(id_attr(node).merge(keep_attrs(node))
          .merge(align: node.attr("align")))
      end

      def quote_attribution(node, out)
        if node.attr("citetitle")
          m = /^(?<cite>[^,]+)(?:,(?<text>.*$))?$/m.match node.attr("citetitle")
          out.source **attr_code(target: m[:cite], type: "inline") do |s|
            s <<  m[:text]
          end
        end
        node.attr("attribution") and
          out.author { |a| a << node.attr("attribution") }
      end

      def quote(node)
        noko do |xml|
          xml.quote **quote_attrs(node) do |q|
            quote_attribution(node, q)
            wrap_in_para(node, q)
          end
        end.join("\n")
      end

      def listing_attrs(node)
        attr_code(id_attr(node).merge(keep_attrs(node)
                  .merge(lang: node.attr("language"),
                         unnumbered: node.option?("unnumbered") ? "true" : nil,
                         number: node.attr("number"),
                         filename: node.attr("filename"))))
      end

      def listing(node)
        fragment = ::Nokogiri::XML::Builder.new do |xml|
          xml.sourcecode **listing_attrs(node) do |s|
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
            p << @c.encode(@c.decode(node.content), :basic, :hexadecimal)
          end
        end
      end
    end
  end
end
