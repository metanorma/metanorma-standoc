module Metanorma
  module Standoc
    module Cleanup
      def review_cleanup(xmldoc)
        reviews = xmldoc.xpath("//annotation")
        reviews.empty? and return
        ctr = xmldoc.root.add_child("<annotation-container/>").first
        reviews.each do |r|
          review_set_location(r)
          ctr << r
        end
      end

      def review_insert_bookmark(review)
        parent = review.parent
        children = parent.children
        index = children.index(review)
        x = find_review_sibling(children, index, :previous) ||
          find_review_sibling(children, index, :following)
        ins = x || review.before("<p> </p>").previous.at(".//text()")
        ins.previous = "<bookmark/>"
        ins.previous
      end

      # we know node is a block: dig for a place bookmark can go
      def available_bookmark_destination(node)
        ret = case node.name
              when "title", "name", "p" then node
              when "sourcecode" then node.at(".//name")
              when "admonition", "note", "example", "li", "quote", "dt", "dd",
                "permission", "requirement", "recommendation"
                node.at(".//p | .//name") || node
              when "formula"
                node.at(".//p | .//name | .//dt")
              when "ol", "ul" then node.at(".//p | .//name") || node.at("./li")
              when "dl" then node.at(".//p | .//name") || node.at("./dt | ./dd")
              when "table" then node.at(".//td[text()] | .//th[text()]")
              end or return nil
        first_non_stem_text(ret)
      end

      def first_non_stem_text(ret)
        first_non_stem_text = nil
        ret.traverse do |n|
          if n.text? && n.ancestors("stem").empty? && !n.text.strip.empty?
            first_non_stem_text = n
            break
          end
        end
        first_non_stem_text
      end

      def find_review_sibling(children, index, direction = :previous)
        range = if direction == :previous then (index - 1).downto(0)
                else (index + 1).upto(children.size - 1)
                end
        range.each do |i|
          node = children[i]
          if node.element? && !node.text.empty? && node.text.strip != "" &&
              ret = available_bookmark_destination(node)
            return ret
          end
        end
        nil
      end

      def review_set_location(review)
        unless review["from"]
          bookmark = review_insert_bookmark(review)
          add_id(bookmark)
          bookmark["anchor"] = bookmark["id"]
          review["from"] = bookmark["id"]
        end
        review["to"] ||= review["from"]
      end
    end
  end
end
