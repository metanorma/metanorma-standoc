# frozen_string_literal: true

require "htmlentities"

module Metanorma
  module Standoc
    class Validate
      module Rules
        # Table cell-grid and term-state checks (metanorma-standoc#1381).
        # Both need whole-table or whole-document state, so they are
        # code-backed: no Schematron mapping. Their findings may carry
        # computed values, read by params as +{value: key}+.
        module GridTermChecks
          SECTIONS = %w(* thead tbody tfoot).freeze
          REPORTS = %w(column_overflow row_mismatch).freeze
          COLUMNS = %w(colgroup row_cells).freeze

          module_function

          def install(registry)
            install_cell_grid(registry)
            install_duplicate_designation(registry)
            install_designation_outside_terms(registry)
          end

          # The context node is a table. +report+ column_overflow yields
          # one finding per cell that ends past the column count taken from
          # +columns+ (the colgroup, or the widest direct row); row_mismatch
          # yields one finding on the table when, after rowspan and colspan
          # are applied, its rows (inside +section+) differ in width.
          def install_cell_grid(registry)
            registry.register(
              "cell_grid", required: %w(report), optional: %w(columns section),
                           validate_args: method(:validate_cell_grid),
                           expand: method(:cell_grid_findings)
            )
          end

          def validate_cell_grid(args)
            REPORTS.include?(args["report"]) or
              raise RuleError, "report must be one of #{REPORTS.join(', ')}"
            SECTIONS.include?(args.fetch("section", "*")) or
              raise RuleError, "section must be one of #{SECTIONS.join(', ')}"
            args["report"] == "column_overflow" or return
            COLUMNS.include?(args["columns"]) or
              raise RuleError, "columns must be one of #{COLUMNS.join(', ')}"
          end

          def cell_grid_findings(table, args, _namespaces)
            rows = table.xpath("./#{args.fetch('section', '*')}/tr")
            grid = Grid.new(rows)
            if args["report"] == "row_mismatch"
              grid.ragged? ? [[table, table]] : []
            else
              maxcols = column_count(table, args["columns"])
              maxcols.positive? or return []
              grid.overflowing(maxcols).map do |cell|
                [cell, table, { "columns" => maxcols }]
              end
            end
          end

          def column_count(table, source)
            source == "colgroup" and return table.xpath("./colgroup/col").size
            table.xpath("./tr").map { |tr| tr.xpath("./td | ./th").size }.max || 0
          end

          # Places cells on a grid the way a renderer does: a cell skips
          # slots taken by rowspans from earlier rows.
          class Grid
            def initialize(rows)
              @slots = rows.map { {} }
              @ends = []
              rows.each_with_index do |tr, r|
                curr = 0
                tr.xpath("./td | ./th").each do |cell|
                  curr = place(cell, r, curr)
                end
              end
            end

            def ragged?
              @slots.any? { |row| row.size != @slots.first.size }
            end

            def overflowing(maxcols)
              @ends.select { |_, last| last > maxcols }.map(&:first)
            end

            private

            def place(cell, row, curr)
              rowspan = (cell["rowspan"] || 1).to_i
              colspan = (cell["colspan"] || 1).to_i
              @slots[row] ||= {}
              curr += 1 while @slots[row][curr]
              (row..(row + rowspan - 1)).each do |y|
                @slots[y] ||= {}
                (curr..(curr + colspan - 1)).each { |x| @slots[y][x] = 1 }
              end
              @ends << [cell, curr + colspan - 1]
              curr + colspan
            end
          end

          # The context node is the document root. Terms (selected by
          # +terms+) are grouped by the text of each designation selected by
          # +designation+, prefixed with <domain> text when +prefix+ selects
          # one; text of nested index entries is ignored. Each group of more
          # than one is a finding on its first term.
          def install_duplicate_designation(registry)
            registry.register(
              "duplicate_designation", required: %w(terms designation),
                                       optional: %w(prefix),
                                       validate_args: method(:validate_duplicate),
                                       expand: method(:duplicate_findings)
            )
          end

          def validate_duplicate(args, namespaces = {})
            %w(terms designation prefix).each do |key|
              args[key].nil? && key == "prefix" and next
              Checks.validate_xpath_nodes(args[key], namespaces, key)
            end
          end

          def duplicate_findings(root, args, namespaces)
            groups = duplicate_groups(root, args, namespaces)
            groups.select { |_, terms| terms.size > 1 }.map do |text, terms|
              locations = terms.map { |t| t["anchor"] }.join(", ")
              [terms.first, terms.first,
               { "designation" => text, "locations" => locations }]
            end
          end

          def duplicate_groups(root, args, namespaces)
            root.xpath(args["terms"], namespaces)
              .each_with_object({}) do |term, groups|
              prefix = args["prefix"] && term.at_xpath(args["prefix"], namespaces)&.text
              term.xpath(args["designation"], namespaces).each do |name|
                text = designation_text(name)
                prefix and text = "<#{prefix}> #{text}"
                (groups[text] ||= []) << term
              end
            end
          end

          def designation_text(name)
            name = name.dup
            name.xpath("./index").each(&:remove)
            name.text
          end

          # The context node is the document root. A designation (selected
          # by +designations+) that has no +terms+ ancestor is misplaced.
          # Misplaced designations are grouped by their nearest ancestor
          # among +containers+; each group is a finding on that container,
          # with the designations' hexadecimal-encoded text as its value.
          def install_designation_outside_terms(registry)
            registry.register(
              "designation_outside_terms",
              required: %w(designations containers),
              optional: %w(terms),
              validate_args: method(:validate_outside_terms),
              expand: method(:outside_terms_findings)
            )
          end

          def validate_outside_terms(args, namespaces = {})
            Checks.validate_xpath_nodes(args["designations"], namespaces,
                                        "designations")
            Checks.names_list("containers", args["containers"])
            Checks.names_list("terms", [args.fetch("terms", "terms")])
          end

          def outside_terms_findings(root, args, namespaces)
            terms = args.fetch("terms", "terms")
            coder = HTMLEntities.new
            groups = root.xpath(args["designations"], namespaces)
              .each_with_object({}) do |d, m|
              d.ancestors.detect { |x| x.name == terms } and next
              c = d.ancestors.detect { |x| args["containers"].include?(x.name) }
              c or next
              (m[c] ||= []) << d
            end
            groups.map do |container, desgns|
              text = desgns.map { |x| coder.encode(x.text.strip, :basic, :hexadecimal) }
              [container, container, { "designations" => text.join(", ") }]
            end
          end
        end
      end
    end
  end
end
