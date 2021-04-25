require "date"
require "htmlentities"
require "json"
require "open-uri"
require "mathml2asciimath"

module Asciidoctor
  module Standoc
    module Cleanup
      def make_preface(x, s)
        if x.at("//foreword | //introduction | //acknowledgements | "\
            "//*[@preface]")
          preface = s.add_previous_sibling("<preface/>").first
          f = x.at("//foreword") and preface.add_child f.remove
          f = x.at("//introduction") and preface.add_child f.remove
          move_clauses_into_preface(x, preface)
          f = x.at("//acknowledgements") and preface.add_child f.remove
        end
        make_abstract(x, s)
      end

      def move_clauses_into_preface(x, preface)
        x.xpath("//*[@preface]").each do |c|
          c.delete("preface")
          preface.add_child c.remove
        end
      end

      def make_abstract(x, s)
        if x.at("//abstract[not(ancestor::bibitem)]")
          preface = s.at("//preface") ||
            s.add_previous_sibling("<preface/>").first
          abstract = x.at("//abstract[not(ancestor::bibitem)]").remove
          preface.prepend_child abstract.remove
          bibabstract = bibabstract_location(x)
          dupabstract = abstract.dup
          dupabstract.traverse { |n| n.remove_attribute("id") }
          dupabstract.remove_attribute("language")
          dupabstract.remove_attribute("script")
          dupabstract&.at("./title")&.remove
          bibabstract.next = dupabstract
        end
      end

      def bibabstract_location(x)
        x.at("//bibdata/script") || x.at("//bibdata/language") ||
          x.at("//bibdata/contributor[not(following-sibling::contributor)]") ||
          x.at("//bibdata/date[not(following-sibling::date)]") ||
          x.at("//docnumber") ||
          x.at("//bibdata/docidentifier"\
               "[not(following-sibling::docidentifier)]") ||
        x.at("//bibdata/uri[not(following-sibling::uri)]") ||
        x.at("//bibdata/title[not(following-sibling::title)]")
      end

      def make_bibliography(x, s)
        if x.at("//sections/references")
          biblio = s.add_next_sibling("<bibliography/>").first
          x.xpath("//sections/references").each do |r|
            biblio.add_child r.remove
          end
        end
      end

      def make_indexsect(x, s)
        x.xpath("//sections/indexsect").reverse_each { |r| s.next = r.remove }
      end

      def sections_order_cleanup(x)
        s = x.at("//sections")
        make_preface(x, s)
        make_annexes(x)
        make_indexsect(x, s)
        make_bibliography(x, s)
        x.xpath("//sections/annex").reverse_each { |r| s.next = r.remove }
      end
      def make_annexes(x)
        x.xpath("//*[@annex]").each do |y|
          y.delete("annex")
          next if y.name == "annex" || !y.ancestors("annex").empty?

          y.wrap("<annex/>")
          y.parent["id"] = "_#{UUIDTools::UUID.random_create}"
          y.parent["obligation"] = y["obligation"]
          y.parent["language"] = y["language"]
          y.parent["script"] = y["script"]
        end
      end

      def maxlevel(x)
        max = 5
        x.xpath("//clause[@level]").each do |c|
          max = c["level"].to_i if max < c["level"].to_i
        end
        max
      end

      def sections_level_cleanup(x)
        m = maxlevel(x)
        return if m < 6

        m.downto(6).each do |l|
          x.xpath("//clause[@level = '#{l}']").each do |c|
            c.delete("level")
            c.previous_element << c.remove
          end
        end
      end

      def sections_cleanup(x)
        sections_order_cleanup(x)
        sections_level_cleanup(x)
        sections_names_cleanup(x)
        change_clauses(x)
      end

      def obligations_cleanup(x)
        obligations_cleanup_info(x)
        obligations_cleanup_norm(x)
        obligations_cleanup_inherit(x)
      end

      def obligations_cleanup_info(x)
        (s = x.at("//foreword")) && s["obligation"] = "informative"
        (s = x.at("//introduction")) && s["obligation"] = "informative"
        (s = x.at("//acknowledgements")) && s["obligation"] = "informative"
        x.xpath("//references").each { |r| r["obligation"] = "informative" }
        x.xpath("//preface//clause").each do |r|
          r["obligation"] = "informative"
        end
      end

      def obligations_cleanup_norm(x)
        (s = x.at("//clause[@type = 'scope']")) && s["obligation"] = "normative"
        x.xpath("//terms").each { |r| r["obligation"] = "normative" }
        x.xpath("//definitions").each { |r| r["obligation"] = "normative" }
      end

      def obligations_cleanup_inherit(x)
        x.xpath("//annex | //clause[not(ancestor::boilerplate)]").each do |r|
          r["obligation"] = "normative" unless r["obligation"]
        end
        x.xpath(Utils::SUBCLAUSE_XPATH).each do |r|
          o = r&.at("./ancestor::*/@obligation")&.text and r["obligation"] = o
        end
      end

      def clausebefore_cleanup(xmldoc)
        preface_clausebefore_cleanup(xmldoc)
        sections_clausebefore_cleanup(xmldoc)
      end

       def preface_clausebefore_cleanup(xmldoc)
        return unless xmldoc.at("//preface")

        unless ins = xmldoc.at("//preface").children.first
          xmldoc.at("//preface") << " "
          ins = xmldoc.at("//preface").children.first
        end
        xmldoc.xpath("//preface//*[@beforeclauses = 'true']").each do |x|
          x.delete("beforeclauses")
          ins.previous = x.remove
        end
      end

      def sections_clausebefore_cleanup(xmldoc)
        return unless xmldoc.at("//sections")

        unless ins = xmldoc.at("//sections").children.first
          xmldoc.at("//sections") << " "
          ins = xmldoc.at("//sections").children.first
        end
        xmldoc.xpath("//sections//*[@beforeclauses = 'true']").each do |x|
          x.delete("beforeclauses")
          ins.previous = x.remove
        end
      end

      def get_or_make_title(node)
          unless node.at("./title")
            if node.children.empty?
              node << "<title/>"
            else
              node.children.first.previous = "<title/>"
            end
          end
          node.at("./title")
      end

      def replace_title(doc, xpath, text, first = false)
        return unless text

        doc.xpath(xpath).each_with_index do |node, i|
          next if first && !i.zero?

          title = get_or_make_title(node)
          fn = title.xpath("./fn")
          fn.each { |n| n.remove }
          title.content = text
          fn.each { |n| title << n }
        end
      end

      def sections_names_cleanup(xml)
        replace_title(xml, "//clause[@type = 'scope']", @i18n&.scope)
        replace_title(xml, "//preface//abstract", @i18n&.abstract)
        replace_title(xml, "//foreword", @i18n&.foreword)
        replace_title(xml, "//introduction", @i18n&.introduction)
        replace_title(xml, "//acknowledgements", @i18n&.acknowledgements)
        section_names_refs_cleanup(xml)
        section_names_terms_cleanup(xml)
      end

      def section_names_refs_cleanup(xml)
        replace_title(xml, "//references[@normative = 'true']",
                      @i18n&.normref, true)
        replace_title(xml, "//references[@normative = 'false']",
                      @i18n&.bibliography, true)
      end

      NO_SYMABBR = "[.//definitions[not(@type)]]".freeze
      SYMABBR = "[.//definitions[@type = 'symbols']"\
        "[@type = 'abbreviated_terms']]".freeze
      SYMnoABBR = "[.//definitions[@type = 'symbols']"\
        "[not(@type = 'abbreviated_terms')]]".freeze
      ABBRnoSYM = "[.//definitions[not(@type = 'symbols')]"\
        "[@type = 'abbreviated_terms']]".freeze

      def section_names_terms_cleanup(x)
        replace_title(x, "//definitions[@type = 'symbols']", @i18n&.symbols)
        replace_title(x, "//definitions[@type = 'abbreviated_terms']",
                      @i18n&.abbrev)
        replace_title(x, "//definitions[not(@type)]", @i18n&.symbolsabbrev)
        replace_title(x, "//terms#{SYMnoABBR} | //clause[.//terms]#{SYMnoABBR}",
                      @i18n&.termsdefsymbols, true)
        replace_title(x, "//terms#{ABBRnoSYM} | //clause[.//terms]#{ABBRnoSYM}",
                      @i18n&.termsdefabbrev, true)
        replace_title(x, "//terms#{SYMABBR} | //clause[.//terms]#{SYMABBR}",
                      @i18n&.termsdefsymbolsabbrev, true)
        replace_title(x, "//terms#{NO_SYMABBR} | //clause[.//terms]#{NO_SYMABBR}",
                      @i18n&.termsdefsymbolsabbrev, true)
        replace_title(
          x, "//terms[not(.//definitions)] | //clause[.//terms][not(.//definitions)]",
          @i18n&.termsdef, true)
      end
    end
  end
end
