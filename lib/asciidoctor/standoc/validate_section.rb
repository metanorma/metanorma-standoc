require "nokogiri"

module Asciidoctor
  module Standoc
    module Validate
      def section_validate(doc)
        sourcecode_style(doc.root)
        asset_style(doc.root)
      end

      def sourcecode_style(root)
        root.xpath("//sourcecode").each do |x|
          callouts = x.elements.select { |e| e.name == "callout" }
          annotations = x.elements.select { |e| e.name == "annotation" }
          if callouts.size != annotations.size
            warn "#{x['id']}: mismatch of callouts and annotations"
          end
        end
      end

      def style_warning(node, msg, text)
        return if @novalid
        w = "ISO style: WARNING (#{Utils::current_location(node)}): #{msg}"
        w += ": #{text}" if text
        warn w
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
    end
  end
end
