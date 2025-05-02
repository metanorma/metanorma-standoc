module Metanorma
  module Standoc
    module Cleanup
      def change_clauses(docxml)
        docxml.xpath("//clause[@change]").each do |c|
          create_amend(c)
        end
      end

      def create_amend(clause)
        a = clause.add_child("<amend/>").first
        add_id(a)
        clause.elements.each do |e|
          e.parent = a unless %w(amend title).include? e.name
        end
        create_amend1(clause, a)
      end

      def create_amend1(clause, amend)
        create_amend2(clause, amend)
        d = amend.at("./description")
        autonum = d.xpath(".//autonumber").map(&:remove)
        d.xpath(".//p[normalize-space(.)='']").each(&:remove)
        move_attrs_to_amend(clause, amend)
        autonum.each { |a| amend << a }
        amend
      end

      def create_amend2(_clause, amend)
        q = amend.at("./quote") and q.name = "newcontent"
        if q.nil?
          amend.children = "<description>#{amend.children.to_xml}</description>"
          return
        end
        pre = q.xpath("./preceding-sibling::*").each(&:remove)
        post = q.xpath("./following-sibling::*").each(&:remove)
        pre.empty? or amend << "<description>#{pre.to_xml}</description>"
        amend << q.remove
        post.empty? or amend << "<description>#{post.to_xml}</description>"
      end

      def move_attrs_to_amend(clause, amend)
        %w(change path path_end title).each do |e|
          clause[e] or next
          amend[e] = clause[e]
          clause.delete(e)
        end
        amend["locality"] or return
        loc = amend.children.add_previous_sibling("<location/>")
        extract_localities1(loc, amend["locality"])
        loc1 = loc.at("./localityStack") and loc.replace(loc1.elements)
        amend.delete("locality")
      end
    end
  end
end
