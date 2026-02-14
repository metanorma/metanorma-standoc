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
        move_attrs_to_amend(clause, amend)
        create_amend_autonum(amend)
        amend
      end

      def create_amend_autonum(amend)
        autonum = (amend.xpath(".//autonumber") -
                   amend.xpath(".//clause//autonumber")).map(&:remove)
        amend.xpath(".//p[normalize-space(.)='']").each(&:remove)
        ins = amend.children.first
        autonum.each { |a| ins.previous = a }
        (amend.xpath(".//clause") - amend.xpath(".//clause/clause")).each do |c|
          create_amend_autonum(c)
        end
      end

      # possible formats: DESC? BLOCKQUOTE DESC?; DESC? BLOCKQUOTE? SUBCLAUSES+
      def create_amend2(clause, amend)
        q, pre, post = create_amend2_prep(clause, amend)
        if q.empty?
          amend.children = "<description>#{amend.children.to_xml}</description>"
          return
        end
        ins = amend.add_child("<newcontent/>").first
        q.each { |n| ins << n.remove }
        pre.empty? or ins.previous = "<description>#{pre.to_xml}</description>"
        post.empty? or ins.next = "<description>#{post.to_xml}</description>"
      end

      def create_amend2_prep(_clause, amend)
        ret = amend.xpath("./quote[1]")
        ret += amend.xpath("./clause")
        ret.empty? and return [[], nil, nil]
        pre = ret[0].xpath("./preceding-sibling::*").each(&:remove)
        post = ret[-1].xpath("./following-sibling::*").each(&:remove)
        ret[0].name == "quote" and ret = ret[0].remove.children + ret[1..]
        [ret, pre, post]
      end

      def move_attrs_to_amend(clause, amend)
        %w(change path path_end title).each do |e|
          clause[e] or next
          amend[e] = clause[e]
          clause.delete(e)
        end
        move_attrs_to_amend_locality(clause, amend)
      end

      def move_attrs_to_amend_locality(_clause, amend)
        amend["locality"] or return
        loc = amend.children.add_previous_sibling("<location/>")
        extract_localities1(loc, amend["locality"])
        loc1 = loc.at("./localityStack") and loc.replace(loc1.elements)
        amend.delete("locality")
      end
    end
  end
end
