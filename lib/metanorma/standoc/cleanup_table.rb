module Metanorma
  module Standoc
    module Cleanup
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
          if s.text =~ /^\s*key[^a-z]*$/i && s&.next_element&.name == "dl"
            s.next_element["key"] = "true"
            s.previous_element << s.next_element.remove
            s.remove
          end
        end
      end

      def insert_thead(table)
        thead = table.at("./thead")
        thead.nil? or return thead
        if tname = table.at("./name")
          thead = tname.add_next_sibling("<thead/>").first
          return thead
        end
        table.children.first.add_previous_sibling("<thead/>").first
      end

      def header_rows_cleanup(xmldoc)
        xmldoc.xpath("//table[@headerrows]").each do |s|
          thead = insert_thead(s)
          (thead.xpath("./tr").size...s["headerrows"].to_i).each do
            s.at("./tbody/tr").parent = thead
          end
          thead.xpath(".//td").each { |n| n.name = "th" }
          s.delete("headerrows")
        end
      end

      def table_cleanup(xmldoc)
        dl1_table_cleanup(xmldoc)
        dl2_table_cleanup(xmldoc)
        sources_table_cleanup(xmldoc)
        notes_table_cleanup(xmldoc)
        header_rows_cleanup(xmldoc)
        tr_style_cleanup(xmldoc)
        td_style_cleanup(xmldoc)
      end

      def sources_table_cleanup(xmldoc)
        nomatches = false
        until nomatches
          nomatches = true
          xmldoc.xpath("//table/following-sibling::*[1]" \
                       "[self::source]").each do |n|
            n.previous_element << n.remove
            nomatches = false
          end
        end
      end

      # move notes into table
      def notes_table_cleanup(xmldoc)
        nomatches = false
        until nomatches
          nomatches = true
          xmldoc.xpath("//table/following-sibling::*[1]" \
                       "[self::note[not(@keep-separate = 'true')]]").each do |n|
            n.delete("keep-separate")
            n.previous_element << n.remove
            nomatches = false
          end
        end
      end

      def tr_style_cleanup(xmldoc)
        xmldoc.xpath("//tr[.//tr-style]").each do |tr|
          ret = tr.xpath(".//tr-style").each_with_object([]) do |s, m|
            m << s.text
          end
          tr["style"] = ret.join(";")
        end
        xmldoc.xpath(".//tr-style").each(&:remove)
      end

      def td_style_cleanup(xmldoc)
        xmldoc.xpath("//td[.//td-style] | //th[.//td-style]").each do |tr|
          ret = tr.xpath(".//td-style").each_with_object([]) do |s, m|
            m << s.text
          end
          tr["style"] = ret.join(";")
        end
        xmldoc.xpath(".//td-style").each(&:remove)
      end
    end
  end
end
