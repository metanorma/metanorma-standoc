module Metanorma
  module Standoc
    module Cleanup
      def get_or_make_title(node)
        node.at("./title") or node.add_first_child "<title/>"
        ret = node.at("./title")
        add_id(ret)
        ret
      end

      def replace_title(doc, xpath, text, first = false)
        text or return
        doc.xpath(xpath).each_with_index do |node, i|
          first && !i.zero? and next
          node["keeptitle"] == "true" and next
          title = get_or_make_title(node)
          set_title_with_footnotes(title, text)
        end
      end

      def set_title_with_footnotes(title, text)
        fn = title.xpath("./fn | ./bookmark | ./index")
        fn.each(&:remove)
        title.children = text
        fn.each { |n| title << n }
      end

      def sections_names_cleanup(xml)
        replace_title(xml, "//clause[@type = 'scope']", @i18n&.scope)
        sections_names_pref_cleanup(xml)
        section_names_refs_cleanup(xml)
        section_names_terms_cleanup(xml)
        xml.xpath("//*[@keeptitle]").each { |s| s.delete("keeptitle") }
      end

      def sections_names_pref_cleanup(xml)
        replace_title(xml, "//preface//abstract", @i18n&.abstract)
        replace_title(xml, "//foreword", @i18n&.foreword)
        replace_title(xml, "//introduction", @i18n&.introduction)
        replace_title(xml, "//acknowledgements", @i18n&.acknowledgements)
        replace_title(xml, "//executivesummary", @i18n&.executivesummary)
      end

      def section_names_refs_cleanup(xml)
        replace_title(xml, "//bibliography/references[@normative = 'true']",
                      @i18n&.normref, true)
        replace_title(xml, "//bibliography/references[@normative = 'false']",
                      @i18n&.bibliography, true)
      end

      NO_SYMABBR = "[.//definitions[not(@type)]]".freeze
      SYMABBR = "[.//definitions[@type = 'symbols']]" \
                "[.//definitions[@type = 'abbreviated_terms']]".freeze
      SYM_NO_ABBR = "[.//definitions[@type = 'symbols']]" \
                  "[not(.//definitions[@type = 'abbreviated_terms'])]".freeze
      ABBR_NO_SYM = "[.//definitions[@type = 'abbreviated_terms']]" \
                  "[not(.//definitions[@type = 'symbols'])]".freeze

      def section_names_terms_cleanup(xml)
        section_names_definitions(xml)
        section_names_terms1_cleanup(xml)
      end

      def section_names_definitions(xml)
        auto_name_definitions(xml) or return
        replace_title(xml, "//definitions[@type = 'symbols']",
                      @i18n&.symbols)
        replace_title(xml, "//definitions[@type = 'abbreviated_terms']",
                      @i18n&.abbrev)
        replace_title(xml, "//definitions[not(@type)]",
                      @i18n&.symbolsabbrev)
      end

      def auto_name_definitions(xml)
        xml.xpath("//definitions[@type = 'symbols']").size > 1 and return false
        xml.xpath("//definitions[@type = 'abbreviated_terms']").size > 1 and
          return false
        xml.xpath("//definitions[not(@type)]").size > 1 and return false
        true
      end

      def section_names_terms1_cleanup(xml)
        auto_name_terms(xml) or return
        replace_title(xml, "//terms#{SYM_NO_ABBR} | //clause[@type = 'terms']#{SYM_NO_ABBR}",
                      @i18n&.termsdefsymbols, true)
        replace_title(xml, "//terms#{ABBR_NO_SYM} | //clause[@type = 'terms']#{ABBR_NO_SYM}",
                      @i18n&.termsdefabbrev, true)
        replace_title(xml, "//terms#{SYMABBR} | //clause[@type = 'terms']#{SYMABBR}",
                      @i18n&.termsdefsymbolsabbrev, true)
        replace_title(xml, "//terms#{NO_SYMABBR} | //clause[@type = 'terms']#{NO_SYMABBR}",
                      @i18n&.termsdefsymbolsabbrev, true)
        replace_title(xml, "//terms[not(.//definitions)] | //clause[@type = 'terms'][not(.//definitions)]",
                      @i18n&.termsdef, true)
      end

      # do not auto-name terms sections if there are terms subclauses
      # not covered by the auto titles,
      # or if more than one title is covered by an auto title
      def auto_name_terms(xml)
        n = xml.at("//terms | //clause[.//terms]")
        out = terms_subclauses(n)
          .each_with_object({ term: 0, sna: 0, ans: 0, sa: 0, nsa: 0,
                              tsna: 0, tans: 0, tsa: 0, tnsa: 0,
                              termdef: 0, other: 0 }) do |x, m|
          terms_subclause_type_tally(x, m, n)
        end
        out.delete(:parent)
        !out.values.detect { |x| x > 1 } && out[:other].zero?
      end

      def terms_subclauses(node)
        legal = %w(terms definitions clause)
        [node, node&.elements].compact.flatten
          .select do |x|
            legal.include?(x.name) &&
              !(x.name == "clause" && x["type"] == "boilerplate")
          end
      end

      def terms_subclause_type_tally(node, acc, parent)
        hasterm = node.at(".//term")
        sym = if (hasterm && !node.at(".//definitions")) ||
            (node.name == "terms" && !hasterm)
                unless acc[:parent] == :term # don't count Term > Term twice
                  :term
                end
              elsif hasterm && node.at("./self::*#{SYM_NO_ABBR}") then :tsna
              elsif hasterm && node.at("./self::*#{ABBR_NO_SYM}") then :tans
              elsif hasterm && node.at("./self::*#{SYMABBR}") then :tsa
              elsif hasterm && node.at("./self::*#{NO_SYMABBR}") then :tnsa
              elsif node.at("./self::*#{SYM_NO_ABBR}") then :sna
              elsif node.at("./self::*#{ABBR_NO_SYM}") then :ans
              elsif node.at("./self::*#{SYMABBR}") then :sa
              elsif node.at("./self::*#{NO_SYMABBR}") then :nsa
              elsif node.name == "definitions" # ignore
              elsif node == parent && hasterm && node.at(".//definitions")
                :termdef
              else :other
              end
        node == parent and acc[:parent] = sym
        sym and acc[sym] += 1
      end

      def sections_variant_title_cleanup(xml)
        path = section_containers.map { |x| "./ancestor::#{x}" }.join(" | ")
        xml.xpath("//p[@variant_title]").each do |p|
          p.name = "variant-title"
          p.delete("variant_title")
          p.xpath("(#{path})[last()]").each do |sect|
            (ins = sect.at("./title") and ins.next = p) or
              sect.add_first_child(p)
          end
        end
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
        t.next_element or s.add_first_child(t.remove)
      end
    end
  end
end
