module Metanorma
  module Standoc
    module Blocks
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

      def figure_example(node)
        noko do |xml|
          xml.figure **figure_attrs(node) do |ex|
            node.title.nil? or ex.name { |name| name << node.title }
            wrap_in_para(node, ex)
          end
        end.join("")
      end

      def figure_title(node, out)
        node.title.nil? and return
        out.name { |name| name << node.title }
      end

      def figure_attrs(node)
        attr_code(id_unnum_attrs(node).merge(keep_attrs(node))
          .merge(class: node.attr("class"),
                 width: node.attr("width")))
      end

      def image(node)
        noko do |xml|
          xml.figure **figure_attrs(node) do |f|
            figure_title(node, f)
            f.image **image_attributes(node)
          end
        end
      end
    end
  end
end
