module Asciidoctor
  module Standoc
    module Cleanup
      def requirement_cleanup(reqt)
        requirement_descriptions(reqt)
        requirement_inherit(reqt)
      end

      def requirement_inherit(reqt)
        reqt.xpath("//requirement | //recommendation | //permission")
          .each do |r|
          ins = r.at("./classification") ||
            r.at("./description | ./measurementtarget | ./specification | "\
                 "./verification | ./import | ./description | ./requirement | "\
                 "./recommendation | ./permission")
          r.xpath("./*//inherit").each { |i| ins.previous = i }
        end
      end

      def requirement_descriptions(reqt)
        reqt.xpath("//requirement | //recommendation | //permission")
          .each do |r|
          r.children.each do |e|
            unless e.element? && (reqt_subpart(e.name) ||
                %w(requirement recommendation permission).include?(e.name))
              t = Nokogiri::XML::Element.new("description", reqt)
              e.before(t)
              t.children = e.remove
            end
          end
          requirement_cleanup1(r)
        end
      end

      def requirement_cleanup1(reqt)
        while d = reqt.at("./description[following-sibling::*[1]"\
            "[self::description]]")
          n = d.next.remove
          d << n.children
        end
        reqt.xpath("./description[normalize-space(.)='']").each do |r|
          r.replace("\n")
        end
      end
    end
  end
end
