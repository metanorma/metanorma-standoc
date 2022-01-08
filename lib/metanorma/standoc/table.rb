module Asciidoctor
  module Standoc
    module Table
      def table_attrs(node)
        keep_attrs(node)
          .merge(id: Metanorma::Utils::anchor_or_uuid(node),
                 headerrows: node.attr("headerrows"),
                 unnumbered: node.option?("unnumbered") ? "true" : nil,
                 number: node.attr("number"),
                 subsequence: node.attr("subsequence"),
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
            %i(head body foot).reject do |tblsec|
              node.rows[tblsec].empty?
            end
            table_head_body_and_foot node, xml_table
          end
        end
      end

      private

      def colgroup(node, xml_table)
        return if node.option? "autowidth"

        cols = node&.attr("cols")&.split(/,/) or return
        return unless (cols.size > 1) && cols.all? { |c| /\d/.match(c) }

        xml_table.colgroup do |cg|
          node.columns.each do |col|
            cg.col **{ width: "#{col.attr 'colpcwidth'}%" }
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

      def table_cell1(cell, thd)
        thd << if cell.style == :asciidoc
                 cell.content
               else
                 cell.text
               end
      end

      def table_cell(node, xml_tr, tblsec)
        cell_attributes =
          { id: node.id, colspan: node.colspan, valign: node.attr("valign"),
            rowspan: node.rowspan, align: node.attr("halign") }
        cell_tag = "td"
        cell_tag = "th" if tblsec == :head || node.style == :header
        xml_tr.send cell_tag, **attr_code(cell_attributes) do |thd|
          table_cell1(node, thd)
        end
      end

      def table_head_body_and_foot(node, xml)
        %i(head body foot).reject { |s| node.rows[s].empty? }.each do |s|
          xml.send "t#{s}" do |xml_tblsec|
            node.rows[s].each do |row|
              xml_tblsec.tr do |xml_tr|
                row.each { |cell| table_cell(cell, xml_tr, s) }
              end
            end
          end
        end
      end
    end
  end
end
