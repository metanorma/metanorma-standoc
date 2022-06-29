module Metanorma
  module Standoc
    module Blocks
      def termnote_attrs(node)
        attr_code(id_attr(node).merge(keep_attrs(node)
          .merge(
            unnumbered: node.attr("unnumbered"),
            number: node.attr("number"),
            subsequence: node.attr("subsequence"),
            "keep-separate": node.attr("keep-separate"),
            keepasterm: node.option?("termnote") ? "true" : nil,
          )))
      end

      def note_attrs(node)
        attr_code(termnote_attrs(node).merge(admonition_core_attrs(node)
          .merge(type: node.attr("type"))))
      end

      def sidebar_attrs(node)
        todo_attrs(node).merge(
          attr_code(
            from: node.attr("from"),
            to: node.attr("to") || node.attr("from"),
          ),
        )
      end

      def sidebar(node)
        return unless draft?

        noko do |xml|
          xml.review **sidebar_attrs(node) do |r|
            wrap_in_para(node, r)
          end
        end.join("\n")
      end

      def todo_attrs(node)
        date = node.attr("date") || Date.today.iso8601.gsub(/\+.*$/, "")
        date += "T00:00:00Z" unless /T/.match? date
        attr_code(id_attr(node)
          .merge(reviewer: node.attr("reviewer") || node.attr("source") ||
                 "(Unknown)",
                 date: date))
      end

      def todo(node)
        noko do |xml|
          xml.review **todo_attrs(node) do |r|
            wrap_in_para(node, r)
          end
        end.join("\n")
      end

      def termnote(node)
        noko do |xml|
          xml.termnote **termnote_attrs(node) do |ex|
            wrap_in_para(node, ex)
          end
        end.join("\n")
      end

      def note(node)
        return termnote(node) if node.option?("termnote")

        noko do |xml|
          xml.note **note_attrs(node) do |c|
            wrap_in_para(node, c)
          end
        end.join("\n")
      end

      def admonition_attrs(node)
        attr_code(keep_attrs(node).merge(id_attr(node)
          .merge(admonition_core_attrs(node)
          .merge(type: admonition_name(node)))))
      end

      def admonition_core_attrs(node)
        { notag: node.attr("notag") == "true" ? "true" : nil,
          coverpage: node.attr("coverpage") == "true" ? "true" : nil,
          beforeclauses: node.attr("beforeclauses") == "true" ? "true" : nil,
          unnumbered: node.attr("unnumbered") ||
            (node.attr("notag") == "true") || nil }
      end

      def admonition_name(node)
        name = node.attr("name")
        a = node.attr("type") and ["danger", "safety precautions"].each do |t|
          name = t if a.casecmp(t).zero?
        end
        name
      end

      def admonition(node)
        return termnote(node) if in_terms? && node.attr("name") == "note"
        return note(node) if node.attr("name") == "note"
        return todo(node) if node.attr("name") == "todo"

        noko do |xml|
          xml.admonition **admonition_attrs(node) do |a|
            node.title.nil? or a.name { |name| name << node.title }
            wrap_in_para(node, a)
          end
        end.join("\n")
      end
    end
  end
end
