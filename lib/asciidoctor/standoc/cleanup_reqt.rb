module Asciidoctor
  module Standoc
    module Cleanup
      def requirement_cleanup(xmldoc)
        requirement_metadata(xmldoc)
        requirement_descriptions(xmldoc)
        requirement_inherit(xmldoc)
      end

      REQRECPER = "//requirement | //recommendation | //permission".freeze

      def requirement_inherit(xmldoc)
        xmldoc.xpath(REQRECPER).each do |r|
          ins = r.at("./classification") ||
            r.at("./description | ./measurementtarget | ./specification | "\
                 "./verification | ./import | ./description | ./requirement | "\
                 "./recommendation | ./permission | ./component")
          r.xpath("./*//inherit").each { |i| ins.previous = i }
        end
      end

      def requirement_descriptions(xmldoc)
        xmldoc.xpath(REQRECPER).each do |r|
          r.children.each do |e|
            unless e.element? && (reqt_subpart(e.name) ||
                %w(requirement recommendation permission).include?(e.name))
              next if e.text.strip.empty?

              t = Nokogiri::XML::Element.new("description", r)
              e.before(t)
              t.children = e.remove
            end
          end
          requirement_description_cleanup1(r)
        end
      end

      def requirement_description_cleanup1(reqt)
        while d = reqt.at("./description[following-sibling::*[1]"\
                          "[self::description]]")
          n = d.next.remove
          d << n.children
        end
        reqt.xpath("./description[normalize-space(.)='']").each do |r|
          r.replace("\n")
        end
      end

      def requirement_metadata(xmldoc)
        xmldoc.xpath(REQRECPER).each do |r|
          dl = r&.at("./dl[@metadata = 'true']")&.remove or next
          requirement_metadata1(r, dl)
        end
      end

      def requirement_metadata1_tags
        %w(label subject inherit)
      end

      def requirement_metadata1(reqt, dlist)
        unless ins = reqt.at("./title")
          reqt.children.first.previous = " "
          ins = reqt.children.first
        end
        %w(obligation model type).each do |a|
          reqt_dl_to_attrs(reqt, dlist, a)
        end
        requirement_metadata1_tags.each do |a|
          ins = reqt_dl_to_elems(ins, reqt, dlist, a)
        end
        reqt_dl_to_classif(ins, reqt, dlist)
      end

      def reqt_dl_to_attrs(reqt, dlist, name)
        e = dlist.at("./dt[text()='#{name}']") or return
        val = e.at("./following::dd/p") || e.at("./following::dd") or return
        reqt[name] = val.text
      end

      def reqt_dl_to_elems(ins, reqt, dlist, name)
        if a = reqt.at("./#{name}[last()]")
          ins = a
        end
        dlist.xpath("./dt[text()='#{name}']").each do |e|
          val = e.at("./following::dd/p") || e.at("./following::dd")
          val.name = name
          ins.next = val
          ins = ins.next
        end
        ins
      end

      def reqt_dl_to_classif(ins, reqt, dlist)
        if a = reqt.at("./classification[last()]")
          ins = a
        end
        dlist.xpath("./dt[text()='classification']").each do |e|
          val = e.at("./following::dd/p") || e.at("./following::dd")
          req_classif_parse(val.text).each do |r|
            ins.next = "<classification><tag>#{r[0]}</tag>"\
                       "<value>#{r[1]}</value></classification>"
          end
        end
      end
    end
  end
end
