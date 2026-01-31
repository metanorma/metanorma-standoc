module Metanorma
  module Standoc
    module Blocks
      def termnote_attrs(node)
        attr_code(id_unnum_attrs(node).merge(keep_attrs(node)
          .merge(
            "keep-separate": node.attr("keep-separate"),
            keepasterm: node.option?("termnote") ? "true" : nil,
            type: node.attr("type")
          )))
      end

      def note_attrs(node)
        attr_code(termnote_attrs(node).merge(admonition_core_attrs(node)
          .merge(type: node.attr("type"))))
      end

      def sidebar(node)
        noko do |xml|
          xml.annotation **sidebar_attrs(node) do |r|
            wrap_in_para(node, r)
          end
        end
      end

      def sidebar_attrs(node)
        date = node.attr("date") || Date.today.iso8601.gsub(/\+.*$/, "")
        date += "T00:00:00Z" unless date.include?("T")
        attr_code(id_attr(node)
          .merge(reviewer: node.attr("reviewer") || node.attr("source") ||
                 "(Unknown)",
                 from: node.attr("from"),
                 to: node.attr("to") || node.attr("from"),
                 type: node.attr("type") || "review",
                 date:))
      end

      def todo_attrs(node)
        sidebar_attrs(node).merge(type: "todo")
      end

      def todo(node)
        noko do |xml|
          xml.annotation **todo_attrs(node) do |r|
            wrap_in_para(node, r)
          end
        end
      end

      # -TO-DO :
      def todo_prefixed_para(node)
        node.lines[0].sub!(/^TODO: /, "")
        todo(node)
      end

      # EDITOR:
      def editor_prefixed_para(node)
        node.lines[0].sub!(/^EDITOR: /, "")
        node.set_attr("type", "editorial")
        node.assign_caption "EDITOR"
        admonition(node)
      end

      def termnote(node)
        noko do |xml|
          xml.termnote **termnote_attrs(node) do |ex|
            wrap_in_para(node, ex)
          end
        end
      end

      def note(node)
        node.option?("termnote") and return termnote(node)
        noko do |xml|
          xml.note **note_attrs(node) do |c|
            wrap_in_para(node, c)
          end
        end
      end

      def boilerplate_note(node)
        node.set_attr("type", "boilerplate")
        note(node)
      end

      def admonition_attrs(node)
        attr_code(keep_attrs(node).merge(id_attr(node)
          .merge(admonition_core_attrs(node)
          .merge(type: admonition_name(node)))))
      end

      def admonition_core_attrs(node)
        { notag: node.attr("notag") == "true" ? "true" : nil,
          coverpage: node.attr("coverpage") == "true" ? "true" : nil,
          beforeclauses: node.attr("beforeclauses") == "true" ? "true" : nil,
          unnumbered: node.attr("unnumbered") ||
            (node.attr("notag") == "true") || nil }
      end

      def admonition_name(node)
        ret = node.attr("type") || node.attr("name") or return
        ret = ret.downcase
        ret == "editor" and ret = "editorial"
        ret
      end

      def admonition(node)
        ret = admonition_alternatives(node) and return ret
        noko do |xml|
          xml.admonition **admonition_attrs(node) do |a|
            block_title(node, a)
            wrap_in_para(node, a)
          end
        end
      end

      def admonition_alternatives(node)
        in_terms? && node.attr("name") == "note" and return termnote(node)
        node.attr("name") == "note" and return note(node)
        node.attr("name") == "todo" and return todo(node)
        nil
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
    end
  end
end
