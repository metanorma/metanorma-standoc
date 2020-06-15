module Asciidoctor
  module Standoc
    module Blocks
      def termnote_attr(node)
        attr_code(id_attr(node).merge(
          "keep-separate": node.attr("keep-separate")))
      end

      def note_attr(node)
        attr_code(id_attr(node).merge(
          "keep-separate": node.attr("keep-separate"),
          beforeclauses: node.attr("beforeclauses") == "true" ? "true" : nil))
      end

      def sidebar_attrs(node)
        todo_attrs(node).merge(attr_code(
          from: node.attr("from"), to: node.attr("to") || node.attr("from") ))
      end

      def sidebar(node)
        return unless draft?
        noko do |xml|
          xml.review **(sidebar_attrs(node)) do |r|
            wrap_in_para(node, r)
          end
        end
      end

      def todo_attrs(node)
        date = node.attr("date") || Date.today.iso8601.gsub(/\+.*$/, "")
        date += "T00:00:00Z" unless /T/.match date
        attr_code(
          id: Utils::anchor_or_uuid(node),
          reviewer: node.attr("reviewer") || node.attr("source") || "(Unknown)",
          date: date )
      end

      def todo(node)
        noko do |xml|
          xml.review **(todo_attrs(node)) do |r|
            wrap_in_para(node, r)
          end
        end
      end

      def termnote(n)
        noko do |xml|
          xml.termnote **termnote_attr(n) do |ex|
            wrap_in_para(n, ex)
          end
        end.join("\n")
      end

      def note(n)
        noko do |xml|
          xml.note **note_attr(n) do |c|
            wrap_in_para(n, c)
          end
        end.join("\n")
      end

      def admonition_attrs(node)
        name = node.attr("name")
        a = node.attr("type") and ["danger", "safety precautions"].each do |t|
          name = t if a.casecmp(t).zero?
        end
        attr_code(id: Utils::anchor_or_uuid(node), type: name,
                  beforeclauses: node.attr("beforeclauses") == "true" ? "true" : nil)
      end

      def admonition(node)
        return termnote(node) if in_terms?
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
