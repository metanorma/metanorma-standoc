module Metanorma
  module Standoc
    module Validate
      def table_validate(doc)
        empty_table_validate(doc)
        doc.xpath("//table[colgroup]").each do |t|
          maxrowcols_validate(t, t.xpath("./colgroup/col").size)
        end
        doc.xpath("//table[.//*[@colspan] | .//*[@rowspan]]").each do |t|
          maxrowcols_validate(t, max_td_count(t), mode: "row_cols")
        end
        doc.xpath("//table[.//*[@rowspan]]").each do |t|
          maxrowcols_validate(t, max_td_count(t), mode: "thead_row")
        end
      end

      def empty_table_validate(doc)
        doc.xpath("//table[not(.//tr)]").reject(&reject_metanorma_extension)
          .each do |t|
          @log.add("STANDOC_2", t)
        end
      end

      def max_td_count(table)
        max = 0
        table.xpath("./tr").each do |tr|
          n = tr.xpath("./td | ./th").size
          max < n and max = n
        end
        max
      end

      def maxrowcols_validate(table, maxcols, mode: "row_cols")
        reject_metanorma_extension.call(table) and return
        case mode
        when "row_cols"
          maxrowcols_validate0(table, maxcols, "*", mode)
        when "thead_row"
          %w{thead tbody tfoot}.each do |w|
            maxrowcols_validate0(table, maxcols, w, mode)
          end
        end
      end

      def maxrowcols_validate0(table, maxcols, tablechild, mode)
        cells2d = table.xpath("./#{tablechild}/tr")
          .each_with_object([]) { |_r, m| m << {} }
        table.xpath("./#{tablechild}/tr").each_with_index do |tr, r|
          curr = 0
          tr.xpath("./td | ./th").each do |td|
            curr = maxcols_validate1(td, r, curr, cells2d, maxcols, mode)
          end
        end
        maxrows_validate(table, cells2d, tablechild, mode)
      end

      # code doesn't actually do anything, since Asciidoctor refuses to generate
      # table with inconsistent column count
      def maxcols_validate1(tcell, row, curr, cells2d, maxcols, mode)
        rs = tcell&.attr("rowspan")&.to_i || 1
        cs = tcell&.attr("colspan")&.to_i || 1
        curr = table_tracker_update(cells2d, row, curr, rs, cs)
        maxcols_check(curr + cs - 1, maxcols, tcell) if mode == "row_cols"
        curr + cs
      end

      def table_tracker_update(cells2d, row, curr, rowspan, colspan)
        cells2d[row] ||= {}
        while cells2d[row][curr]
          curr += 1
        end
        (row..(row + rowspan - 1)).each do |y2|
          cells2d[y2] ||= {}
          (curr..(curr + colspan - 1)).each { |x2| cells2d[y2][x2] = 1 }
        end
        curr
      end

      def maxrows_validate(table, cells2d, tablechild, mode)
        err = "are inconsistent"
        mode == "thead_row" and err = "cannot go outside #{tablechild}"
        if cells2d.any? { |x| x.size != cells2d.first.size }
          @log.add("STANDOC_4", table, params: [err])
        end
      end

      # if maxcols or maxrows negative, do not check them
      def maxcols_check(col, maxcols, tcell)
        if maxcols.positive? && col > maxcols
          @log.add("STANDOC_5", tcell, params: [maxcols])
        end
      end
    end
  end
end
