require "vectory"
require "crass"

module Metanorma
  module Standoc
    module Image
      def svgmap_cleanup(xmldoc)
        svgmap_moveattrs(xmldoc)
        svgmap_populate(xmldoc)
        processed = Vectory::SvgMapping.new(xmldoc, @localdir).call.to_xml

        # vectory 0.13 processes on its own tree and returns the result
        # instead of mutating the caller's document; reparse the processed
        # XML with the caller's own XML library and graft the content back
        # so the cleanup pipeline (which threads xmldoc by reference
        # through every step) keeps working. With vectory 0.12 the document
        # is already mutated and the graft is a no-op.
        new_doc = if defined?(Moxml) && xmldoc.is_a?(Moxml::Node)
                    Moxml.new.parse(processed)
                  elsif defined?(Nokogiri) && xmldoc.is_a?(Nokogiri::XML::Node)
                    Nokogiri::XML(processed)
                  else
                    raise ArgumentError,
                          "unsupported xmldoc type: #{xmldoc.class}"
                  end
        old_root = xmldoc.root
        new_root = new_doc.root
        old_root.children.each(&:remove)
        new_root.children.each { |n| old_root << n }
        xmldoc
      end

      def svgmap_moveattrs(xmldoc)
        xmldoc.xpath("//svgmap").each do |s|
          f = s.at(".//figure") or next
          (t = s.at("./name")) && !f.at("./name") and
            f.add_first_child t.remove
          if s["anchor"] # && Metanorma::Utils::guid_anchor?(f["id"])
            f["anchor"] = s["anchor"]
            s.delete("anchor")
          end
          svgmap_moveattrs1(s, f)
        end
      end

      def svgmap_moveattrs1(svgmap, figure)
        %w(unnumbered number subsequence keep-with-next
           keep-lines-together tag multilingual-rendering).each do |a|
          figure[a] || !svgmap[a] and next
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
            t = li.at(".//eref | .//link | .//xref") or next
            href = t.xpath("./following-sibling::node()")
            href.empty? or
              s << %[<target href="#{svgmap_target(href)}">#{t.to_xml}</target>]
          end
        end
      end

      def svgmap_target(nodeset)
        nodeset.each do |n|
          n.name == "link" or next
          n.children = n["target"]
        end
        nodeset.text.sub(/^[,; ]/, "").strip
      end

      def img_cleanup(xmldoc)
        altmedia_cleanup(xmldoc)
        @datauriimage and datauri_image(xmldoc)
        svg_cleanup(xmldoc)
        xmldoc
      end

      def datauri_image(xmldoc)
        xmldoc.xpath("//image | //altsource").each do |i|
          # do not datauri encode SVG, we need to deduplicate its IDs
          unless read_in_if_svg?(i, @localdir)
            i["src"] &&= Vectory::Utils::datauri(i["src"], @localdir)
          end
        end
      end

      def altmedia_cleanup(xmldoc)
        xmldoc.xpath("//image[@altmedia]").each do |i|
          altmedia_root_cleanup(i)
          d = altmedia_prep(i)
          d or next
          altsource_populate(i, d)
        end
      end

      def altsource_populate(img, dlist)
        dlist.each do |e|
          e[:dd].nil? and next
          img << "<altsource tag='#{e[:dt]}'/>"
          image_attr_copy(e[:dd], img.elements.last)
          altsource_attr_copy(e[:dd], img.elements.last, img)
        end
      end

      def image_attr_copy(src, dest)
        %w(src mimetype filename alt).each do |k|
          src[k] and dest[k] = src[k]
        end
      end

      def altsource_attr_copy(src, dest, img)
        %w(media).each do |k|
          src[k] and dest[k] = src[k]
        end
        %w(height width).each do |k|
          dest[k] = img[k]
          src[k] or next
          src[k] == "auto" and next
          dest[k] = src[k]
        end
      end

      def altmedia_root_cleanup(img)
        %w(altmedia src filename mimetype).each do |k|
          img.delete(k)
        end
      end

      def altmedia_prep(img)
        dl = img.at("./dl") or return
        d = extract_symbols_list(dl.remove).map do |e|
          { dt: e[:dt].text, dd: e[:dd].at(".//image") }
        end
        unless d.detect { |e| e[:dt] == "default" }
          d << d.first.dup
          d[-1][:dt] = "default"
        end
        d
      end

      def svg_cleanup(xmldoc)
        svg_uniqueids(xmldoc)
        svg_classupdate(xmldoc)
      end

      def read_in_if_svg?(img, localdir)
        img["src"] or return false
        path = Vectory::Utils.svgmap_rewrite0_path(img["src"], localdir)
        File.file?(path) or return false
        types = MIME::Types.type_for(path) or return false
        types.first == "image/svg+xml" or return false
        svg = File.read(path, encoding: "utf-8") or return false
        img.add_first_child Nokogiri::XML(svg).root
        true
      end

      def svg_classupdate(xmldoc)
        xmldoc.xpath("//m:svg[m:style]", "m" => SVG_NS)
          .each_with_index do |s, i|
          svg_classupdate1(s, s.at("./m:style", "m" => SVG_NS), i)
        end
      end

      def svg_classupdate1(svg, style, idx)
        tree = Crass.parse(style.text)
        tree.each { |n| svg_suffix_css_style(n, idx) }
        style.children = Crass::Parser.stringify(tree)
        svg.xpath(".//*[@class]").each do |n|
          n["class"] = n["class"].split(/\s+/)
            .map { |x| "#{x}_inject_#{idx}" }.join(" ")
        end
      end

      def svg_suffix_css_style(node, idx)
        (node[:node] == :style_rule && /\./.match?(node[:selector][:value])) or
          return
        v = node[:selector][:value]
          .gsub(/([^.\s]*\.\S+)/, "\\1_inject_#{idx}")
        node[:selector] = Crass.parse("#{v} {}").first[:selector]
      end

      SVG_NS = "http://www.w3.org/2000/svg".freeze

      def svg_uniqueids(xmldoc)
        # only keep non-unique identifiers
        ids = xmldoc.xpath("//m:svg//*/@id | //svg/@id", "m" => SVG_NS)
          .map(&:text).group_by(&:itself).transform_values(&:count)
          .delete_if { |_, v| v < 2 }
        # re-resolve by position each time: replacing an outer SVG detaches
        # the nodes of any SVG nested inside it
        xmldoc.xpath("//m:svg", "m" => SVG_NS).size.times do |i|
          svg = xmldoc.xpath("//m:svg", "m" => SVG_NS)[i]
          ids = svg_uniqueids1(svg, i, ids)
        end
      end

      # Vectory returns a rewritten copy: reparse it with the caller's XML
      # library and swap it into the caller's tree.
      def svg_uniqueids1(svg, idx, ids)
        rewritten = Vectory::SvgIdDisambiguator
          .rewrite(svg.to_xml, "_inject_#{idx}", ids)
          .sub(/\A<\?xml[^>]*\?>\s*/, "")
        new_svg = svg_replace(svg, rewritten)
        new_ids = new_svg.xpath(".//*[@id] | ./@id/..").map { |x| x["id"] }
        ids.merge(new_ids.each.to_h { |value| [value, true] })
      end

      def svg_replace(svg, xml)
        if defined?(Moxml) && svg.is_a?(Moxml::Node)
          Moxml.new(:leptris).parse(xml).root.tap { |n| svg.replace(n) }
        else
          svg.replace(xml).first
        end
      end
    end
  end
end
