require "date"
require "htmlentities"
require "open-uri"

module Asciidoctor
  module Standoc
    module Cleanup
      def para_cleanup(xmldoc)
        ["//p[not(ancestor::bibdata)]", "//ol[not(ancestor::bibdata)]",
         "//ul[not(ancestor::bibdata)]", "//quote[not(ancestor::bibdata)]",
         "//note[not(ancestor::bibitem or ancestor::table or ancestor::bibdata)]"
        ].each { |w| inject_id(xmldoc, w) }
      end

      def inject_id(xmldoc, path)
        xmldoc.xpath(path).each do |x|
          x["id"] ||= Metanorma::Utils::anchor_or_uuid
        end
      end

      def dl1_table_cleanup(xmldoc)
        q = "//table/following-sibling::*[1][self::dl]"
        xmldoc.xpath(q).each do |s|
          s["key"] == "true" and s.previous_element << s.remove
        end
      end

      # move Key dl after table footer
      def dl2_table_cleanup(xmldoc)
        q = "//table/following-sibling::*[1][self::p]"
        xmldoc.xpath(q).each do |s|
          if s.text =~ /^\s*key[^a-z]*$/i && !s.next_element.nil? && s.next_element.name == "dl"
            s.next_element["key"] = "true"
            s.previous_element << s.next_element.remove
            s.remove
          end
        end
      end

      def insert_thead(s)
        thead = s.at("./thead")
        return thead unless thead.nil?
        if tname = s.at("./name")
          thead = tname.add_next_sibling("<thead/>").first
          return thead
        end
        s.children.first.add_previous_sibling("<thead/>").first
      end

      def header_rows_cleanup(xmldoc)
        xmldoc.xpath("//table[@headerrows]").each do |s|
          thead = insert_thead(s)
          (thead.xpath("./tr").size...s["headerrows"].to_i).each do
            row = s.at("./tbody/tr")
            row.parent = thead
          end
          thead.xpath(".//td").each { |n| n.name = "th" }
          s.delete("headerrows")
        end
      end

      def table_cleanup(xmldoc)
        dl1_table_cleanup(xmldoc)
        dl2_table_cleanup(xmldoc)
        notes_table_cleanup(xmldoc)
        header_rows_cleanup(xmldoc)
      end

      # move notes into table
      def notes_table_cleanup(xmldoc)
        nomatches = false
        until nomatches
          q = "//table/following-sibling::*[1][self::note]"
          nomatches = true
          xmldoc.xpath(q).each do |n|
            n.previous_element << n.remove
            nomatches = false
          end
        end
      end

      # include where definition list inside stem block
      def formula_cleanup(x)
        formula_cleanup_where1(x)
        formula_cleanup_where2(x)
      end

      def formula_cleanup_where1(x)
        q = "//formula/following-sibling::*[1][self::dl]"
        x.xpath(q).each do |s|
          s["key"] == "true" and s.previous_element << s.remove
        end
      end

      def formula_cleanup_where2(x)
        q = "//formula/following-sibling::*[1][self::p]"
        x.xpath(q).each do |s|
          if s.text =~ /^\s*where[^a-z]*$/i && !s.next_element.nil? && s.next_element.name == "dl"
            s.next_element["key"] = "true"
            s.previous_element << s.next_element.remove
            s.remove
          end
        end
      end

      def figure_dl_cleanup1(xmldoc)
        q = "//figure/following-sibling::*[self::dl]"
        xmldoc.xpath(q).each do |s|
          s["key"] == "true" and s.previous_element << s.remove
        end
      end

      # include key definition list inside figure
      def figure_dl_cleanup2(xmldoc)
        q = "//figure/following-sibling::*[self::p]"
        xmldoc.xpath(q).each do |s|
          if s.text =~ /^\s*key[^a-z]*$/i && !s.next_element.nil? && s.next_element.name == "dl"
            s.next_element["key"] = "true"
            s.previous_element << s.next_element.remove
            s.remove
          end
        end
      end

      # examples containing only figures become subfigures of figures
      def subfigure_cleanup(xmldoc)
        xmldoc.xpath("//example[figure]").each do |e|
          next unless e.elements.map { |m| m.name }.reject { |m| %w(name figure).include? m }.empty?
          e.name = "figure"
        end
      end

      def figure_cleanup(xmldoc)
        figure_footnote_cleanup(xmldoc)
        figure_dl_cleanup1(xmldoc)
        figure_dl_cleanup2(xmldoc)
        subfigure_cleanup(xmldoc)
      end

      ELEMS_ALLOW_NOTES = %w[p formula ul ol dl figure].freeze

      # if a note is at the end of a section, it is left alone
      # if a note is followed by a non-note block, it is moved inside its preceding block if it is not delimited
      # (so there was no way of making that block include the note)
      def note_cleanup(xmldoc)
        q = "//note[following-sibling::*[not(local-name() = 'note')]]"
        xmldoc.xpath(q).each do |n|
          next if n["keep-separate"] == "true"
          next unless n.ancestors("table").empty?
          prev = n.previous_element || next
          n.parent = prev if ELEMS_ALLOW_NOTES.include? prev.name
        end
        xmldoc.xpath("//note[@keep-separate]").each { |n| n.delete("keep-separate") }
        xmldoc.xpath("//termnote[@keep-separate]").each { |n| n.delete("keep-separate") }
      end

      def requirement_cleanup(x)
        requirement_descriptions(x)
        requirement_inherit(x)
      end

      def requirement_inherit(x)
        x.xpath("//requirement | //recommendation | //permission").each do |r|
          ins = r.at("./classification") ||
            r.at("./description | ./measurementtarget | ./specification | "\
                 "./verification | ./import | ./description | ./requirement | "\
                 "./recommendation | ./permission")
          r.xpath("./*//inherit").each { |i| ins.previous = i }
        end
      end

      def requirement_descriptions(x)
        x.xpath("//requirement | //recommendation | //permission").each do |r|
          r.children.each do |e|
            unless e.element? && (reqt_subpart(e.name) ||
                %w(requirement recommendation permission).include?(e.name))
              t = Nokogiri::XML::Element.new("description", x)
              e.before(t)
              t.children = e.remove
            end
          end
          requirement_cleanup1(r)
        end
      end

      def requirement_cleanup1(r)
        while d = r.at("./description[following-sibling::*[1][self::description]]")
          n = d.next.remove
          d << n.children
        end
        r.xpath("./description[normalize-space(.)='']").each { |d| d.replace("\n") }
      end

      def svgmap_cleanup(xmldoc)
        svgmap_populate(xmldoc)
        Metanorma::Utils::svgmap_rewrite(xmldoc, @localdir)
      end

      def svgmap_populate(xmldoc)
        xmldoc.xpath("//svgmap").each do |s|
          s1 = s.dup
          s.children.remove
          f = s1.at(".//figure") and s << f
          s1.xpath(".//li").each do |li|
            t = li&.at(".//eref | .//link | .//xref") or next
            href = t.xpath("./following-sibling::node()")
            next if href.empty?
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
    end
  end
end
