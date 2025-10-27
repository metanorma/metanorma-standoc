require "nokogiri"

module Metanorma
  module Standoc
    module Validate
      def section_validate(doc)
        sourcecode_style(doc.root)
        hanging_para_style(doc.root)
        asset_style(doc.root)
      end

      def sourcecode_style(root)
        root.xpath("//sourcecode").each do |x|
          callouts = x.xpath("./body/callout")
          annotations = x.xpath("./callout-annotation")
          callouts_error(x, callouts, annotations)
        end
      end

      def callouts_error(elem, callouts, annotations)
        if callouts.size != annotations.size && !annotations.empty?
          @log.add("STANDOC_47", elem, params: [callouts.size, annotations.size])
        end
      end

      def style_warning(node, msg, text = nil)
        w = msg
        w += ": #{text}" if text
        @log.add("STANDOC_48", node, params: [w])
      end

      def reject_metanorma_extension
        ->(node) {
          node.ancestors.detect do |x|
            x.name == "metanorma-extension"
          end
        }
      end

      def asset_title_style(root)
        root.xpath("//figure[image][not(name)]")
          .reject(&reject_metanorma_extension).each do |node|
          style_warning(node, "Figure should have title", nil)
        end
        root.xpath("//table[not(name)]")
          .reject(&reject_metanorma_extension).each do |node|
          style_warning(node, "Table should have title", nil)
        end
      end

      def asset_style(root)
        asset_title_style(root)
      end

      def hanging_para_style(root)
        root.xpath("//clause | //annex | //foreword | //introduction | " \
                   "//acknowledgements | //executivesummary").each do |c|
          c.at("./clause") or next
          c.elements.reject do |n|
            %w(clause title).include? n.name
          end.empty? and next
          style_warning(c, "Hanging paragraph in clause")
        end
      end

      def norm_ref_validate(doc)
        doc.xpath("//references[@normative = 'true']/bibitem").each do |b|
          docid = b.at("./docidentifier[@type = 'metanorma']") or next
          /^\[\d+\]$/.match?(docid.text) or next
          @log.add("STANDOC_49", b)
        end
      end
    end
  end
end
