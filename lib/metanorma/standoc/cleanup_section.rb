require_relative "cleanup_section_names"

module Metanorma
  module Standoc
    module Cleanup
      def make_preface(xml, sect)
        if xml.at("//foreword | //introduction | //acknowledgements | " \
                  "//*[@preface]")
          preface = sect.add_previous_sibling("<preface/>").first
          f = xml.at("//foreword") and to_preface(preface, f)
          f = xml.at("//introduction") and to_preface(preface, f)
          move_clauses_into_preface(xml, preface)
          f = xml.at("//acknowledgements") and to_preface(preface, f)
        end
        make_abstract(xml, sect)
      end

      def move_clauses_into_preface(xml, preface)
        xml.xpath("//*[@preface]").each do |c|
          to_preface(preface, c)
        end
      end

      def to_preface(preface, clause)
        clause.delete("preface")
        preface.add_child clause.remove
      end

      def make_colophon(xml)
        xml.at("//clause[@colophon]") or return
        colophon = xml.root.add_child("<colophon/>").first
        xml.xpath("//*[@colophon]").each do |c|
          c.delete("colophon")
          colophon.add_child c.remove
        end
      end

      def make_abstract(xml, sect)
        if xml.at("//abstract[not(ancestor::bibitem)]")
          preface = sect.at("//preface") ||
            sect.add_previous_sibling("<preface/>").first
          abstract = xml.at("//abstract[not(ancestor::bibitem)]").remove
          preface.prepend_child abstract.remove
          bibabstract = bibabstract_location(xml)
          bibabstract.next = clean_abstract(abstract.dup)
        end
      end

      def clean_abstract(dupabstract)
        dupabstract.traverse { |n| n.remove_attribute("id") }
        %w(language script unnumbered).each do |w|
          dupabstract.remove_attribute(w)
        end
        dupabstract.at("./title")&.remove
        dupabstract
      end

      def bibabstract_location(xml)
        xml.at("//bibdata/script") || xml.at("//bibdata/language") ||
          xml.at("//bibdata/contributor[not(following-sibling::contributor)]") ||
          xml.at("//bibdata/date[not(following-sibling::date)]") ||
          xml.at("//docnumber") ||
          xml.at("//bibdata/docidentifier" \
                 "[not(following-sibling::docidentifier)]") ||
          xml.at("//bibdata/uri[not(following-sibling::uri)]") ||
          xml.at("//bibdata/title[not(following-sibling::title)]")
      end

      def make_bibliography(xml, sect)
        if xml.at("//sections/references | //xref[@hidden]")
          biblio = sect.add_next_sibling("<bibliography/>").first
          xml.xpath("//sections/references").each do |r|
            biblio.add_child r.remove
          end
        end
      end

      def make_indexsect(xml, sect)
        xml.xpath("//sections/indexsect").reverse_each do |r|
          sect.next = r.remove
        end
      end

      def sections_order_cleanup(xml)
        s = xml.at("//sections")
        pop_floating_title(xml)
        make_preface(xml, s)
        make_annexes(xml)
        make_indexsect(xml, s)
        make_bibliography(xml, s)
        make_colophon(xml)
        xml.xpath("//sections/annex").reverse_each { |r| s.next = r.remove }
      end

      def make_annexes(xml)
        xml.xpath("//*[@annex]").each do |y|
          y.delete("annex")
          y.name == "annex" || !y.ancestors("annex").empty? and next
          y.wrap("<annex/>")
          y.parent["id"] = "_#{UUIDTools::UUID.random_create}"
          %w(obligation language script).each do |w|
            y.parent[w] = y[w]
          end
        end
      end

      def maxlevel(xml)
        max = 5
        xml.xpath("//clause[@level]").each do |c|
          max = c["level"].to_i if max < c["level"].to_i
        end
        max
      end

      def sections_level_cleanup(xml)
        m = maxlevel(xml)
        m < 6 and return
        m.downto(6).each do |l|
          xml.xpath("//clause[@level = '#{l}']").each do |c|
            c.delete("level")
            c.previous_element << c.remove
          end
        end
      end

      def sections_cleanup(xml)
        misccontainer_cleanup(xml)
        sections_order_cleanup(xml)
        sections_level_cleanup(xml)
        sections_names_cleanup(xml)
        sections_variant_title_cleanup(xml)
        change_clauses(xml)
      end

      def misccontainer_cleanup(xml)
        m = xml.at("//misc-container-clause") or return
        ins = add_misc_container(xml)
        ins << m.remove.children
      end

      def single_clause_annex(xml)
        xml.xpath("//annex").each do |a|
          single_clause_annex1(a)
        end
      end

      def obligations_cleanup(xml)
        obligations_cleanup_info(xml)
        obligations_cleanup_norm(xml)
        obligations_cleanup_inherit(xml)
      end

      def obligations_cleanup_info(xml)
        xml.xpath("//foreword | //introduction | //acknowledgements | " \
                  "//references | //preface//clause").each do |r|
          r["obligation"] = "informative"
        end
      end

      def obligations_cleanup_norm(xml)
        s = xml.at("//clause[@type = 'scope']") and
          s["obligation"] = "normative"
        xml.xpath("//terms").each { |r| r["obligation"] = "normative" }
        xml.xpath("//definitions").each { |r| r["obligation"] = "normative" }
      end

      def obligations_cleanup_inherit(xml)
        xml.xpath("//annex | //clause[not(ancestor::boilerplate)]").each do |r|
          r["obligation"] = "normative" unless r["obligation"]
        end
        xml.xpath(Utils::SUBCLAUSE_XPATH).each do |r|
          o = r.at("./ancestor::*/@obligation")&.text and r["obligation"] = o
        end
      end

      def clausebefore_cleanup(xmldoc)
        sections_clausebefore_cleanup(xmldoc)
        preface_clausebefore_cleanup(xmldoc)
      end

      def preface_clausebefore_cleanup(xmldoc)
        xmldoc.at("//preface") or return
        ins = insert_before(xmldoc, "//preface")
        xmldoc.xpath("//preface//*[@beforeclauses = 'true']").each do |x|
          x.delete("beforeclauses")
          ins.previous = x.remove
        end
        xmldoc.xpath("//*[@coverpage = 'true']").each do |x|
          ins.previous = x.remove
        end
      end

      def sections_clausebefore_cleanup(xmldoc)
        xmldoc.at("//sections") or return
        ins = insert_before(xmldoc, "//sections")
        xmldoc.xpath("//sections//*[@beforeclauses = 'true']")
          .reverse.each do |x|
          x.delete("beforeclauses")
          ins.previous = x.remove
        end
        endofpreface_clausebefore(xmldoc, ins)
      end

      # only move clausebefore notes at the very end of preface
      def endofpreface_clausebefore(xmldoc, ins)
        xmldoc.xpath("//preface//*[@beforeclauses = 'true']").reverse
          .each do |x|
          textafter = xmldoc.xpath("//preface//*") & x.xpath("./following::*")
          textafter.text.strip.empty? or break
          x.delete("beforeclauses")
          ins.previous = x.remove
        end
      end

      def insert_before(xmldoc, xpath)
        unless ins = xmldoc.at(xpath).children.first
          xmldoc.at(xpath) << " "
          ins = xmldoc.at(xpath).children.first
        end
        ins
      end

      def floatingtitle_cleanup(xmldoc)
        pop_floating_title(xmldoc) # done again, after endofpreface_clausebefore
        floating_title_preface2sections(xmldoc)
      end

      def pop_floating_title(xmldoc)
        loop do
          found = false
          xmldoc.xpath("//floating-title").each do |t|
            t.next_element.nil? or next
            %w(sections annex preface).include? t.parent.name and next
            t.parent.next = t
            found = true
          end
          break unless found
        end
      end

      def floating_title_preface2sections(xmldoc)
        t = xmldoc.at("//preface/floating-title") or return
        s = xmldoc.at("//sections")
        unless t.next_element
          s.children.first.previous = t.remove
        end
      end
    end
  end
end
