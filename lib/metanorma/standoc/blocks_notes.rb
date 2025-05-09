module Metanorma
  module Standoc
    module Blocks
      def termnote_attrs(node)
        attr_code(id_unnum_attrs(node).merge(keep_attrs(node)
          .merge(
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
            type: node.attr("type") || nil,
          ),
        )
      end

      def sidebar(node)
        noko do |xml|
          xml.review **sidebar_attrs(node) do |r|
            wrap_in_para(node, r)
          end
        end
      end

      def todo_attrs(node)
        date = node.attr("date") || Date.today.iso8601.gsub(/\+.*$/, "")
        date += "T00:00:00Z" unless date.include?("T")
        attr_code(id_attr(node)
          .merge(reviewer: node.attr("reviewer") || node.attr("source") ||
                 "(Unknown)",
                 date:, type: "todo"))
      end

      def todo(node)
        noko do |xml|
          xml.review **todo_attrs(node) do |r|
            wrap_in_para(node, r)
          end
        end
      end

      def termnote(node)
        noko do |xml|
          xml.termnote **termnote_attrs(node) do |ex|
            wrap_in_para(node, ex)
          end
        end
      end

      def note(node)
        node.option?("termnote") and return termnote(node)
        noko do |xml|
          xml.note **note_attrs(node) do |c|
            wrap_in_para(node, c)
          end
        end
      end

      def boilerplate_note(node)
        node.set_attr("type", "boilerplate")
        note(node)
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
        ret = node.attr("type") || node.attr("name") or return
        ret = ret.downcase
        ret == "editor" and ret = "editorial"
        ret
      end

      def admonition(node)
        ret = admonition_alternatives(node) and return ret
        noko do |xml|
          xml.admonition **admonition_attrs(node) do |a|
            node.title.nil? or a.name { |name| name << node.title }
            wrap_in_para(node, a)
          end
        end
      end

      def admonition_alternatives(node)
        in_terms? && node.attr("name") == "note" and return termnote(node)
        node.attr("name") == "note" and return note(node)
        node.attr("name") == "todo" and return todo(node)
        nil
      end
    end
  end
end
