module Asciidoctor
  module Standoc
    module Cleanup
      def termdef_stem_cleanup(xmldoc)
        xmldoc.xpath("//term/p/stem").each do |a|
          if a.parent.elements.size == 1 # para contains just a stem expression
            parent = a.parent
            parent.replace("<admitted>#{term_expr(a.to_xml)}</admitted>")
          end
        end
        xmldoc.xpath("//term//expression/name[stem]").each do |n|
          n.parent.name = "letter-symbol"
        end
      end

      # release termdef tags from surrounding paras
      def termdef_unnest_cleanup(xmldoc)
        desgn = "//p/admitted | //p/deprecates | //p/preferred | //p//related"
        nodes = xmldoc.xpath(desgn)
        while !nodes.empty?
          nodes[0].parent.replace(nodes[0].parent.children)
          nodes = xmldoc.xpath(desgn)
        end
      end

      def term_dl_to_metadata(xmldoc)
        xmldoc.xpath("//term[dl[@metadata = 'true']]").each do |t|
          t.xpath("./dl[@metadata = 'true']").each do |dl|
            prev = dl_to_designation(dl) or next
            term_dl_to_designation_metadata(prev, dl)
            term_dl_to_term_metadata(prev, dl)
            term_dl_to_expression_metadata(prev, dl)
            dl.remove
          end
        end
      end

      def term_dl_to_term_metadata(prev, dlist)
        return unless prev.name == "preferred" &&
          prev.at("./preceding-sibling::preferred").nil?

        ins = term_element_insert_point(prev)
        %w(domain subject usageinfo).each do |a|
          ins = dl_to_elems(ins, prev.parent, dlist, a)
        end
      end

      def term_dl_to_designation_metadata(prev, dlist)
        %w(absent geographicArea).each { |a| dl_to_attrs(related2pref(prev), dlist, a) }
      end

      def term_element_insert_point(prev)
        ins = prev
        while %w(preferred admitted deprecates related domain dl)
            .include? ins&.next_element&.name
          ins = ins.next_element
        end
        ins
      end

      def term_dl_to_expression_metadata(prev, dlist)
        %w(language script type isInternational).each do |a|
          dl_to_attrs(prev, dlist, a)
        end
        %w(abbreviationType pronunciation).reverse.each do |a|
          dl_to_elems(prev.at("./expression/name"), prev, dlist, a)
        end
        g = dlist.at("./dt[text()='grammar']/following::dd//dl") and
          term_dl_to_expression_grammar(prev, g)
        term_to_letter_symbol(prev, dlist)
      end

      def term_dl_to_expression_grammar(prev, dlist)
        prev.at(".//expression") or return
        prev.at(".//expression") << "<grammar><sentinel/></grammar>"
        %w(gender isPreposition isParticiple isAdjective isAdverb isNoun
           grammarValue).reverse.each do |a|
          dl_to_elems(prev.at(".//expression/grammar/*"), prev.elements.last,
                      dlist, a)
        end
        term_dl_to_designation_gender(prev)
      end

      def term_dl_to_designation_gender(prev)
        gender = prev.at(".//expression/grammar/gender")
        /,/.match?(gender&.text) and
          gender.replace(gender.text.split(/,\s*/)
            .map { |x| "<gender>#{x}</gender>" }.join)
        prev.at(".//expression/grammar/sentinel").remove
      end

      def term_to_letter_symbol(prev, dlist)
        ls = dlist.at("./dt[text()='letter-symbol']/following::dd/p")
        return unless ls&.text == "true"

        prev.at(".//expression").name = "letter-symbol"
      end

      def dl_to_designation(dlist)
        prev = dlist.previous_element
        unless %w(preferred admitted deprecates related).include? prev&.name
          @log.add("AsciiDoc Input", dlist, "Metadata definition list does "\
                                            "not follow a term designation")
          return nil
        end
        prev
      end

      def term_nonverbal_designations(xmldoc)
        xmldoc.xpath("//term/preferred | //term/admitted | //term/deprecates")
          .each do |d|
          d.text.strip.empty? or next
          n = d.next_element
          if %w(formula figure).include?(n&.name)
            term_nonverbal_designations1(d, n)
          else d.at("./expression/name") or
            d.children = term_expr("")
          end
        end
      end

      def term_nonverbal_designations1(desgn, elem)
        desgn = related2pref(desgn)
        if elem.name == "figure"
          elem.at("./name").remove
          desgn.children =
            "<graphical-symbol>#{elem.remove.to_xml}</graphical-symbol>"
        else
          desgn.children = term_expr(elem.at("./stem").to_xml)
          elem.remove
        end
      end

      def term_termsource_to_designation(xmldoc)
        xmldoc.xpath("//term/termsource").each do |t|
          p = t.previous_element
          while %w(domain subject usageinfo).include? p&.name
            p = p.previous_element
          end
          %w(preferred admitted deprecates related).include?(p&.name) or
            next
          related2pref(p) << t.remove
        end
      end

      def term_designation_reorder(xmldoc)
        xmldoc.xpath("//term").each do |t|
          %w(preferred admitted deprecates related)
            .each_with_object([]) do |tag, m|
            t.xpath("./#{tag}").each { |x| m << x.remove }
          end.reverse.each do |x|
            t.children.first.previous = x
          end
        end
      end

      def related2pref(elem)
        elem.name == "related" ? elem = elem.at("./preferred") : elem
      end
    end
  end
end
