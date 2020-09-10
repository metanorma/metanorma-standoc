module Asciidoctor
  module Standoc
    module Cleanup
      def change_clauses(x)
        x.xpath("//clause[@change]").each do |c|
          a = create_amend(c)
        end
      end

      def create_amend(c)
        a = c.add_child("<amend id='_#{UUIDTools::UUID.random_create}'/>").first
        c.elements.each do |e|
          e.parent = a unless %w(amend title).include? e.name
        end
        create_amend1(c, a)
      end

      def create_amend1(c, a)
        create_amend2(c, a)
        d = a.at("./description")
        d.xpath(".//autonumber").each { |e| d.previous = e }
        d.xpath(".//p[normalize-space(.)='']").each { |e| e.remove }
        move_attrs_to_amend(c, a)
        a
      end

      def create_amend2(c, a)
        q = a.at("./quote") and q.name = "replacement"
        if q.nil?
          a.children = "<description>#{a.children.to_xml}</description>"
        else
          pre = q&.xpath("./preceding-sibling::*")&.remove
          post = q&.xpath("./following-sibling::*")&.remove
          pre.empty? or a << "<description>#{pre.to_xml}</description>"
          a << q.remove
          post.empty? or a << "<description>#{post.to_xml}</description>"
        end
      end

      def move_attrs_to_amend(c, a)
        %w(change path path_end title).each do |e|
          next unless c[e]
          a[e] = c[e]
          c.delete(e)
        end
        return unless a["locality"]
        loc = a.children.add_previous_sibling("<location/>")
        extract_localities1(loc, a["locality"])
        loc1 = loc.at("./localityStack") and loc.replace(loc1.elements)
        a.delete("locality")
      end
    end
  end
end
