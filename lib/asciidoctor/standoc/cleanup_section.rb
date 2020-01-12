require "date"
require "nokogiri"
require "htmlentities"
require "json"
require "pathname"
require "open-uri"

module Asciidoctor
  module Standoc
    module Cleanup
       def make_preface(x, s)
        if x.at("//foreword | //introduction")
          preface = s.add_previous_sibling("<preface/>").first
          foreword = x.at("//foreword")
          preface.add_child foreword.remove if foreword
          introduction = x.at("//introduction")
          preface.add_child introduction.remove if introduction
        end
        make_abstract(x, s)
      end

      def make_abstract(x, s)
        if x.at("//abstract[not(ancestor::bibitem)]")
          preface = s.at("//preface") || s.add_previous_sibling("<preface/>").first
          abstract = x.at("//abstract[not(ancestor::bibitem)]").remove
          preface.prepend_child abstract.remove
          bibabstract = bibabstract_location(x)
          dupabstract = abstract.dup
          dupabstract.traverse { |n| n.remove_attribute("id") }
          dupabstract.remove_attribute("language")
          dupabstract.remove_attribute("script")
          bibabstract.next = dupabstract
        end
      end

      def bibabstract_location(x)
        bibabstract = x.at("//bibdata/script") || x.at("//bibdata/language") ||
          x.at("//bibdata/contributor[not(following-sibling::contributor)]") ||
          x.at("//bibdata/date[not(following-sibling::date)]") ||
          x.at("//docnumber") ||
          x.at("//bibdata/docidentifier[not(following-sibling::docidentifier)]") ||
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

      def sections_order_cleanup(x)
        s = x.at("//sections")
        make_preface(x, s)
        make_bibliography(x, s)
        x.xpath("//sections/annex").reverse_each { |r| s.next = r.remove }
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
      end

      def obligations_cleanup(x)
        obligations_cleanup_info(x)
        obligations_cleanup_norm(x)
        obligations_cleanup_inherit(x)
      end

      def obligations_cleanup_info(x)
        (s = x.at("//foreword")) && s["obligation"] = "informative"
        (s = x.at("//introduction")) && s["obligation"] = "informative"
        x.xpath("//references").each { |r| r["obligation"] = "informative" }
      end

      def obligations_cleanup_norm(x)
        (s = x.at("//clause[title = 'Scope']")) && s["obligation"] = "normative"
        (s = x.at("//clause[title = 'Symbols and Abbreviated Terms']")) &&
          s["obligation"] = "normative"
        x.xpath("//terms").each { |r| r["obligation"] = "normative" }
        x.xpath("//symbols-abbrevs").each { |r| r["obligation"] = "normative" }
      end

      def obligations_cleanup_inherit(x)
        x.xpath("//annex | //clause").each do |r|
          r["obligation"] = "normative" unless r["obligation"]
        end
        x.xpath(Utils::SUBCLAUSE_XPATH).each do |r|
          r["obligation"] = r.at("./ancestor::*/@obligation").text
        end
      end
    end
  end
end
