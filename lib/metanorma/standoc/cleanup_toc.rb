module Metanorma
  module Standoc
    module Cleanup
      def toc_cleanup(xmldoc)
        toc_cleanup_para(xmldoc)
        xmldoc.xpath("//toc").each { |t| toc_cleanup1(t, xmldoc) }
        toc_cleanup_clause(xmldoc)
        toc_metadata(xmldoc)
      end

      def toc_cleanup_para(xmldoc)
        xmldoc.xpath("//p[toc]").each do |x|
          x.xpath("./toc").reverse.each do |t|
            x.next = t
          end
          x.remove if x.text.strip.empty?
        end
      end

      def toc_index(toc, xmldoc)
        depths = toc_index_depths(toc)
        depths.keys.each_with_object([]) do |key, arr|
          xmldoc.xpath(key).each do |x|
            arr << toc_index1(key, x, depths)
          end
        end.sort_by { |a| a[:line] }
      end

      def toc_index1(key, entry, depths)
        t = entry.at("./following-sibling::variant-title[@type = 'toc']") and
          entry = t
        { text: entry.children.to_xml, depth: depths[key].to_i,
          target: entry.xpath("(./ancestor-or-self::*/@id)[last()]")[0].text,
          line: entry.line }
      end

      def toc_index_depths(toc)
        toc.xpath("./toc-xpath").each_with_object({}) do |x, m|
          m[x.text] = x["depth"]
        end
      end

      def toc_cleanup1(toc, xmldoc)
        depth = 1
        ret = ""
        toc_index(toc, xmldoc).each do |x|
          ret = toc_cleanup1_entry(x, depth, ret)
          depth = x[:depth]
        end
        toc.children = "<ul>#{ret}</ul>"
      end

      def toc_cleanup1_entry(entry, depth, ret)
        if depth > entry[:depth]
          ret += "</ul></li>" * (depth - entry[:depth])
        elsif depth < entry[:depth]
          ret += "<li><ul>" * (entry[:depth] - depth)
        end
        ret + "<li><xref target='#{entry[:target]}'>#{entry[:text]}</xref></li>"
      end

      def toc_cleanup_clause(xmldoc)
        xmldoc
          .xpath("//clause[@type = 'toc'] | //annex[@type = 'toc']").each do |c|
          c.xpath(".//ul[not(ancestor::ul)]").each do |ul|
            toc_cleanup_clause_entry(xmldoc, ul)
            ul.replace("<toc>#{ul.to_xml}</toc>")
          end
        end
      end

      def toc_cleanup_clause_entry(xmldoc, list)
        list.xpath(".//xref[not(text())]").each do |x|
          c1 = xmldoc.at("//*[@id = '#{x['target']}']")
          t = c1.at("./variant-title[@type = 'toc']") || c1.at("./title")
          x << t.dup.children
        end
      end

      def toc_metadata(xmldoc)
        @htmltoclevels || @doctoclevels || @toclevels or return
        ins = add_misc_container(xmldoc)
        toc_metadata1(ins)
      end

      def toc_metadata1(ins)
        [[@toclevels, "TOC Heading Levels"],
         [@htmltoclevels, "HTML TOC Heading Levels"],
         [@doctoclevels, "DOC TOC Heading Levels"]].each do |n|
          n[0] and ins << "<presentation-metadata><name>#{n[1]}</name>" \
                          "<value>#{n[0]}</value></presentation-metadata>"
        end
      end
    end
  end
end
