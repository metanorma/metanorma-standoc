module Metanorma
  module Standoc
    module Table
      def table_attrs(node)
        keep_attrs(node)
          .merge(id_unnum_attrs(node))
          .merge(headerrows: node.attr("headerrows"),
                 alt: node.attr("alt"),
                 summary: node.attr("summary"),
                 width: node.attr("width"))
      end

      def table(node)
        @table_fn_number = "a"
        noko do |xml|
          xml.table **attr_code(table_attrs(node)) do |xml_table|
            colgroup(node, xml_table)
            table_name(node, xml_table)
            %i(head body foot).reject { |tblsec| node.rows[tblsec].empty? }
            table_head_body_and_foot node, xml_table
          end
        end
      end

      private

      def colgroup(node, xml_table)
        node.option? "autowidth" and return
        cols = node.attr("cols")&.split(",") or return
        (cols.size > 1) && cols.all? { |c| /\d/.match(c) } or return
        xml_table.colgroup do |cg|
          node.columns.each do |col|
            cg.col width: "#{col.attr 'colpcwidth'}%"
          end
        end
      end

      def table_name(node, xml_table)
        if node.title?
          xml_table.name do |n|
            n << node.title
          end
        end
      end

      def table_cell1(cell)
        if cell.style == :asciidoc
          cell.content
        else
          cell.text
        end
      end

      def table_cell(node, xml_tr, tblsec)
        cell_attributes = id_attr(node).merge(
          { colspan: node.colspan, valign: node.attr("valign"),
            rowspan: node.rowspan, align: node.attr("halign") },
        )
        cell_tag = "td"
        cell_tag = "th" if tblsec == :head || node.style == :header
        xml_tr.send cell_tag, **attr_code(cell_attributes) do |thd|
          thd << table_cell1(node)
        end
      end

      def table_head_body_and_foot(node, xml)
        %i(head body foot).reject { |s| node.rows[s].empty? }.each do |s|
          xml.send "t#{s}" do |xml_tblsec|
            node.rows[s].each do |row|
              xml_tblsec.tr **attr_code(id_attr(nil)) do |xml_tr|
                row.each { |cell| table_cell(cell, xml_tr, s) }
              end
            end
          end
        end
      end
    end
  end
end
