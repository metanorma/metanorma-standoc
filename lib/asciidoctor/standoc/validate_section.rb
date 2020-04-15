require "nokogiri"

module Asciidoctor
  module Standoc
    module Validate
      def section_validate(doc)
        sourcecode_style(doc.root)
        hanging_para_style(doc.root)
        asset_style(doc.root)
      end

      def sourcecode_style(root)
        root.xpath("//sourcecode").each do |x|
          callouts = x.elements.select { |e| e.name == "callout" }
          annotations = x.elements.select { |e| e.name == "annotation" }
          if callouts.size != annotations.size
            #warn "#{x['id']}: mismatch of callouts and annotations"
        @log.add("Asciidoctor Input", x, "mismatch of callouts and annotations")
          end
        end
      end

      def style_warning(node, msg, text = nil)
        w = msg
        w += ": #{text}" if text
        #warn w
        @log.add("Style Warning", node, w)
      end

      def asset_title_style(root)
        root.xpath("//figure[image][not(name)]").each do |node|
          style_warning(node, "Figure should have title", nil)
        end
        root.xpath("//table[not(name)]").each do |node|
          style_warning(node, "Table should have title", nil)
        end
      end

      def asset_style(root)
        asset_title_style(root)
      end

      def hanging_para_style(root)
        root.xpath("//clause | //annex | //foreword | //introduction | "\
                   "//acknowledgements").each do |c|
          next unless c.at("./clause")
          next if c.elements.select { |n| n.name != "clause" }.empty?
          style_warning(c, "Hanging paragraph in clause")
        end
      end
    end
  end
end
