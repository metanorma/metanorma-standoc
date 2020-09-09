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
        a&.elements[-1]&.name = "quote" and a.elements[-1].name = "replacement"
        d = a.add_child("<description/>").first
        a.elements.each { |e| e.parent = d unless e.name == "description" }
        e = d.at("./replacement") and d.next = e
        d.xpath("./autonumber").each { |e| d.previous = e }
        move_attrs_to_amend(c, a)
        a
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
