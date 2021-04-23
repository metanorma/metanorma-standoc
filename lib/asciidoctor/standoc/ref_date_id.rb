module Asciidoctor
  module Standoc
    module Refs
      def set_date_range(date, text)
        matched = /^(?<from>[0-9]+)(-+(?<to>[0-9]+))?$/.match text
        return unless matched[:from]

        if matched[:to]
          date.from matched[:from]
          date.to matched[:to]
        else
          date.on matched[:from]
        end
      end

      def id_and_year(id, year)
        year ? "#{id}:#{year}" : id
      end

      def norm_year(year)
        /^&\#821[12];$/.match(year) and return "--"
        /^\d\d\d\d-\d\d\d\d$/.match(year) and return year
        year&.sub(/(?<=[0-9])-.*$/, "")
      end

      def conditional_date(bib, match, noyr)
        if m.names.include?("year") && !match[:year].nil?
          bib.date(**{ type: "published" }) do |d|
            noyr and d.on "--" or set_date_range(d, norm_year(match[:year]))
          end
        end
      end

      def use_my_anchor(ref, id)
        ref.parent.elements.last["id"] = id
        ref
      end

      def docid(bib, code)
        type, code1 = if /^\[\d+\]$|^\([^)]+\).*$/.match?(code)
                        ["metanorma", mn_code(code)]
                      else
                        @bibdb&.docid_type(code) || [nil, code]
                      end
        code1.sub!(/^nofetch\((.+)\)$/, "\\1")
        bib.docidentifier **attr_code(type: type) do |d|
          d << code1
        end
      end

      def docnumber(bib, code)
        bib.docnumber do |d|
          d << HTMLEntities.new.decode(code).sub(/^[^\d]*/, "")
        end
      end

      def mn_code(code)
        code.sub(/^\(/, "[").sub(/\).*$/, "]").sub(/^nofetch\((.+)\)$/, "\\1")
      end
    end
  end
end
