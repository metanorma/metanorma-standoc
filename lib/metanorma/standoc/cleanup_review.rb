module Metanorma
  module Standoc
    module Cleanup
      def review_cleanup(xmldoc)
        reviews = xmldoc.xpath("//review")
        reviews.empty? and return
        ctr = xmldoc.root.add_child("<review-container/>").first
        reviews.each do |r|
          review_set_location(r)
          ctr << r
        end
      end

      def review_insert_bookmark(review, id)
        parent = review.parent
        children = parent.children
        index = children.index(review)
        x = previous_review_siblings(children, index) ||
          following_review_siblings(children, index)
        ins = if x then x.at(".//text()")
              else review.before("<p> </p>").previous.at(".//text()")
              end
        ins.previous = "<bookmark id='#{id}'/>"
      end

      def previous_review_siblings(children, index)
        x = nil
        (index - 1).downto(0) do |i|
          node = children[i]
          if node.element? && node.name != "review" && node.text.strip != ""
            x = node
            break
          end
        end
        x
      end

      def following_review_siblings(children, index)
        x = nil
        (index + 1).upto(children.size - 1) do |i|
          node = children[i]
          if node.element? && node.name != "review" && node.text.strip != ""
            x = node
            break
          end
        end
        x
      end

      def review_set_location(review)
        unless review["from"]
          id = "_#{UUIDTools::UUID.random_create}"
          review_insert_bookmark(review, id)
          review["from"] = id
        end
        review["to"] ||= review["from"]
      end
    end
  end
end
