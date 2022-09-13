module Metanorma
  module Standoc
    module Cleanup
      def svgmap_cleanup(xmldoc)
        svg_uniqueids(xmldoc)
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
        if @datauriimage
          xmldoc.xpath("//image").each do |i|
            # do not datauri encode SVG, we need to deduplicate its IDs
            unless read_in_if_svg(i, @localdir)
              warn "i[src]"
warn i["src"]
local_path = i["src"]
        relative_path = File.join(@localdir, i["src"])

        # Check whether just the local path or the other specified relative path
        # works.
        path = [local_path, relative_path].detect do |p|
          File.exist?(p) ? p : nil
        end
              warn "path"
        warn path
              warn "Marcel"
        warn Marcel::MimeType.for(Pathname.new(path))
              warn "binread"
              warn File.binread(path).size
        bin = File.binread(path)
              warn "data"
        data = Base64.strict_encode64(bin)
        warn data
        warn "end"

              i["src"] = Metanorma::Utils::datauri(i["src"], @localdir)
            end
          end
        end
        svg_uniqueids(xmldoc)
        xmldoc
      end

      def read_in_if_svg(img, localdir)
        return false unless img["src"]

        path = Metanorma::Utils::svgmap_rewrite0_path(img["src"], localdir)
        File.file?(path) or return false
        types = MIME::Types.type_for(path) or return false
        types.first == "image/svg+xml" or return false
        svg = File.read(path, encoding: "utf-8") or return false
        img.replace(Nokogiri::XML(svg).root.to_xml)
        true
      end

      IRI_TAG_PROPERTIES_MAP = {
        clipPath: ["clip-path"],
        "color-profile": nil,
        cursor: nil,
        filter: nil,
        linearGradient: ["fill", "stroke"],
        marker: ["marker", "marker-end", "marker-mid", "marker-start"],
        mask: nil,
        pattern: ["fill", "stroke"],
        radialGradient: ["fill", "stroke"],
      }.freeze

      SVG_NS = "http://www.w3.org/2000/svg".freeze

      def svg_uniqueids(xmldoc)
        # only keep non-unique identifiers
        ids = xmldoc.xpath("//m:svg//*/@id | //svg/@id", "m" => SVG_NS)
          .map(&:text).group_by(&:itself).transform_values(&:count)
          .delete_if { |_, v| v < 2 }
        xmldoc.xpath("//m:svg", "m" => SVG_NS).each_with_index do |s, i|
          ids = svg_uniqueids1(s, i, ids)
        end
      end

      def svg_iri_properties(id_elems)
        iri_tag_names = id_elems.each_with_object([]) do |e, m|
          IRI_TAG_PROPERTIES_MAP.key?(e.name.to_sym) and m = m << e.name
        end.uniq
        iri_properties = iri_tag_names.each_with_object([]) do |t, m|
          (IRI_TAG_PROPERTIES_MAP[t.to_sym] || [t]).each { |t1| m = m << t1 }
        end.uniq
        return [] if iri_properties.empty?

        iri_properties << "style"
      end

      def svg_uniqueids1(svg, idx, ids)
        id_elems = svg.xpath(".//*[@id] | ./@id/..")
        iri_properties = svg_iri_properties(id_elems)
        svg_uniqueids2(svg, iri_properties, idx, ids)
        new_ids = id_elems.map { |x| x["id"] }
          .map { |x| x + (ids[x] ? "_inject_#{idx}" : "") }
        ids.merge(new_ids.each.map { |value| [value, true] }.to_h)
      end

      def svg_uniqueids2(svg, iri_properties, idx, ids)
        svg.traverse do |e|
          next unless e.element?

          if e.name == "style"
            svg_styleupdate(e, idx, ids)
          elsif !e.attributes.empty?
            svg_attrupdate(e, iri_properties, idx, ids)
          end
          svg_linkupdate(e, idx, ids)
          svg_idupdate(e, idx, ids)
        end
      end

      def svg_update_url(text, idx, ids)
        text.gsub(/url\("?#([a-zA-Z][\w:.-]*)"?\)/) do |x|
          if ids[$1] then "url(##{$1}_inject_#{idx})"
          else x
          end
        end
      end

      def svg_styleupdate(elem, idx, ids)
        elem.children = svg_update_url(elem.text, idx, ids)
      end

      def svg_attrupdate(elem, iri_properties, idx, ids)
        iri_properties.each do |p|
          next unless elem[p]

          elem[p] = svg_update_url(elem[p], idx, ids)
        end
      end

      def svg_linkupdate(elem, idx, ids)
        %w(xlink:href href).each do |ref|
          iri = elem[ref]&.strip
          next unless /^#/.match?(iri)
          next unless ids[iri.sub(/^#/, "")]

          elem[ref] += "_inject_#{idx}"
        end
      end

      def svg_idupdate(elem, idx, ids)
        return unless elem["id"]
        return unless ids[elem["id"]]

        elem["id"] += "_inject_#{idx}"
      end
    end
  end
end
