module Metanorma
  module Standoc
    module Blocks
      def svgmap_attrs(node)
        attr_code(id_unnum_attrs(node).merge(keep_attrs(node)))
      end

      def svgmap_example(node)
        noko do |xml|
          xml.svgmap **attr_code(svgmap_attrs(node).merge(
                                   src: node.attr("src"), alt: node.attr("alt"),
                                 )) do |ex|
            block_title(node, ex)
            ex << node.content
          end
        end
      end

      def figure_example(node)
        noko do |xml|
          xml.figure **figure_attrs(node) do |ex|
            block_title(node, ex)
            wrap_in_para(node, ex)
          end
        end
      end

      def figure_attrs(node)
        attr_code(id_unnum_attrs(node).merge(keep_attrs(node))
          .merge(class: node.attr("class"),
                 width: node.attr("width")))
      end

      def image(node)
        noko do |xml|
          xml.figure **figure_attrs(node) do |f|
            block_title(node, f)
            f.image **image_attributes(node).tap { |h| h.delete(:anchor) }
          end
        end
      end
    end
  end
end
