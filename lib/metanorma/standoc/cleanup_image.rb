module Metanorma
  module Standoc
    module Cleanup
      def svgmap_cleanup(xmldoc)
        svgmap_moveattrs(xmldoc)
        svgmap_populate(xmldoc)
        Metanorma::Utils::svgmap_rewrite(xmldoc, @localdir)
      end

      def guid?(str)
        /^_[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/i
          .match(str)
      end

      def svgmap_moveattrs(xmldoc)
        xmldoc.xpath("//svgmap").each do |s|
          f = s.at(".//figure") or next
          (t = s.at("./name")) && !f.at("./name") and
            f.children.first.previous = t.remove
          if s["id"] && guid?(f["id"])
            f["id"] = s["id"]
            s.delete("id")
          end
          svgmap_moveattrs1(s, f)
        end
      end

      def svgmap_moveattrs1(svgmap, figure)
        %w(unnumbered number subsequence keep-with-next
           keep-lines-together tag multilingual-rendering).each do |a|
          next if figure[a] || !svgmap[a]

          figure[a] = svgmap[a]
          svgmap.delete(a)
        end
      end

      def svgmap_populate(xmldoc)
        xmldoc.xpath("//svgmap").each do |s|
          s1 = s.dup
          s.children.remove
          f = s1.at(".//figure") and s << f
          s1.xpath(".//li").each do |li|
            t = li&.at(".//eref | .//link | .//xref") or next
            href = t.xpath("./following-sibling::node()")
            href.empty? or
              s << %[<target href="#{svgmap_target(href)}">#{t.to_xml}</target>]
          end
        end
      end

      def svgmap_target(nodeset)
        nodeset.each do |n|
          next unless n.name == "link"

          n.children = n["target"]
        end
        nodeset.text.sub(/^[,; ]/, "").strip
      end

      def img_cleanup(xmldoc)
        return xmldoc unless @datauriimage

        xmldoc.xpath("//image").each do |i|
          i["src"] = Metanorma::Utils::datauri(i["src"], @localdir)
        end
      end
    end
  end
end
