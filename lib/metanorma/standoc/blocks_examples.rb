module Metanorma
  module Standoc
    module Blocks
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
