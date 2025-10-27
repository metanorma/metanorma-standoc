require "uri" if /^2\./.match?(RUBY_VERSION)
require_relative "./blocks_notes"
require_relative "./blocks_image"

module Metanorma
  module Standoc
    module Blocks
      def id_attr(node = nil)
        anchor = node&.id
        { id: "_#{UUIDTools::UUID.random_create}",
          anchor: anchor && !anchor.empty? ? anchor : nil,
          tag: node&.attr("tag"), columns: node&.attr("columns"),
          "multilingual-rendering": node&.attr("multilingual-rendering") }
          .compact
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
        role == "boilerplate" and return boilerplate_note(node)
        result = []
        node.blocks.each { |b| result << send(b.context, b) }
        result
      end

      def block_title(node, out)
        node.title.nil? and return
        out.name **attr_code(id_attr(nil)) do |name|
          name << node.title
        end
      end

      def form_attrs(node)
        attr_code(id_attr(node)
          .merge(class: node.attr("class"),
                 name: node.attr("name"), action: node.attr("action")))
      end

      def form(node)
        noko do |xml|
          xml.form **form_attrs(node) do |f|
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
            block_title(node, f)
            pre_attrs = id_attr(node).tap { |h| h.delete(:anchor) }
              .merge(alt: node.attr("alt"))
            f.pre node.lines.join("\n"), **attr_code(pre_attrs)
          end
        end
      end

      # NOTE: html escaping is performed by Nokogiri
      def stem(node)
        noko do |xml|
          xml.formula **formula_attrs(node) do |s|
            stem_parse(node.lines.join("\n"), s, node.style.to_sym, node)
          end
        end
      end

      def term_example(node)
        noko do |xml|
          xml.termexample **attr_code(id_attr(node)
            .merge(keepasterm: node.option?("termexample") || nil)) do |ex|
            wrap_in_para(node, ex)
          end
        end
      end

      def example(node)
        role = node.role || node.attr("style")
        ret = example_to_requirement(node, role) ||
          example_by_role(node, role) and return ret
        (in_terms? || node.option?("termexample")) and return term_example(node)
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
        @reqt_models.requirement_roles.key?(role&.to_sym) or return
        # need to call here for proper recursion ordering
        select_requirement_model(node)
        requirement(node,
                    @reqt_models.requirement_roles[role.to_sym], role)
      end

      # prevent A's and other subs inappropriate for pseudocode
      def pseudocode_example(node)
        node.blocks.each { |b| b.remove_sub(:replacements) }
        noko do |xml|
          xml.figure **example_attrs(node).merge(class: "pseudocode") do |ex|
            block_title(node, ex)
            wrap_in_para(node, ex)
          end
        end
      end

      def example_attrs(node)
        attr_code(id_unnum_attrs(node).merge(keep_attrs(node)))
      end

      def example_proper(node)
        noko do |xml|
          xml.example **example_attrs(node) do |ex|
            block_title(node, xml)
            wrap_in_para(node, ex)
          end
        end
      end

      def para_attrs(node)
        attr_code(id_attr(node).merge(keep_attrs(node)
          .merge(align: node.attr("align"),
                 variant_title: node.role == "variant-title" ? true : nil,
                 type: node.attr("type"))))
      end

      # TODO: term sources occasionally turning up as "source source"?
      def paragraph(node)
        node.role&.sub(/ .*$/, "") == "source" and return termsource(node)
        content = node.content
        content.start_with?("TODO: ") and return todo_prefixed_para(node)
        content.start_with?("EDITOR: ") and return editor_prefixed_para(node)
        noko do |xml|
          xml.p **para_attrs(node) do |xml_t|
            xml_t << content
          end
        end
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
        end
      end

      def listing_attrs(node)
        linenums = node.option?("linenums") || node.attributes[3] ||
          @source_linenums
        attr_code(id_attr(node).merge(keep_attrs(node)
                  .merge(lang: node.attr("language"),
                         linenums: linenums ? "true" : nil,
                         unnumbered: node.option?("unnumbered") ? "true" : nil,
                         number: node.attr("number"),
                         filename: node.attr("filename"))))
      end

      def listing(node)
        fragment = ::Nokogiri::XML::Builder.new do |xml|
          xml.sourcecode **listing_attrs(node) do |s|
            block_title(node, s)
            s.body do |b|
              b << node.content
            end
          end
        end
        fragment.to_xml(encoding: "US-ASCII", save_with:
                        Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
      end

      def pass(node)
        format = node.attr("format") || "metanorma"
        noko do |xml|
          xml.passthrough **attr_code(formats: format) do |p|
            content = @c.encode(node.content, :basic, :hexadecimal)
            p << content
            format == "metanorma" and
              passthrough_validate(node, node.content, content)
          end
        end
      end

      PASSTHRU_ERR = <<~ERRMSG.freeze
        This is not valid Metanorma XML. If you intended a different format, such as HTML, you need to specify `format=` on the pass markup;
        refer to https://www.metanorma.org/author/topics/blocks/passthroughs/
      ERRMSG

      # need to validate Metanorma XML before it passes to textcleanup,
      # where passthrough wrapper and escaped tags are removed:
      # <passthrough formats="metanorma>&lt;tag&gt</passthrough> => <tag>
      # Do not treat not well-formed XML as invalid,
      # as it may be fragment, e.g. unterminated start of element markup
      def passthrough_validate(node, content, encoded_content)
        valid, = validate_document_fragment(content.dup)
        !valid and
          @log.add("STANDOC_42", node, params: [encoded_content])
      end
    end
  end
end
