require "metanorma/standoc/utils"

module Metanorma
  module Standoc
    module Cleanup
      # Indices sort after letter but before any following
      # letter (x, x_m, x_1, xa); we use colon to force that sort order.
      # Numbers sort *after* letters; we use thorn to force that sort order.
      # Capitals sort before their corresponding lowercase.
      def symbol_key(sym)
        @c.decode(asciimath_key(sym).text)
          .gsub(/[\[\]{}<>()]/, "").gsub(/\s/m, "")
          .gsub(/[[:punct:]]|[_^]/, ":\\0").gsub("`", "")
          .gsub(/[0-9]+/, "þ\\0")
          .tr("AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz",
              "ABCFEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
      end

      def extract_symbols_list(dlist)
        dl_out = []
        dlist.xpath("./dt | ./dd").each do |dtd|
          if dtd.name == "dt"
            dl_out << { dt: dtd.remove, key: symbol_key(dtd) }
          else
            dl_out.last[:dd] = dtd.remove
          end
        end
        dl_out
      end

      def symbols_cleanup(docxml)
        docxml.xpath("//definitions/dl").each do |dl|
          dl_out = extract_symbols_list(dl)
          dl_out.sort! { |a, b| a[:key] <=> b[:key] || a[:dt] <=> b[:dt] }
          dl.children = dl_out.map { |d| d[:dt].to_s + d[:dd].to_s }.join("\n")
        end
        docxml
      end
    end
  end
end
