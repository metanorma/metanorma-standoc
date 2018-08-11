require "date"
require "nokogiri"
require "htmlentities"
require "json"
require "pathname"
require "open-uri"
require "pp"

module Asciidoctor
  module Standoc
    module Cleanup
      # include footnotes inside figure
      def figure_footnote_cleanup(xmldoc)
        nomatches = false
        until nomatches
          q = "//figure/following-sibling::*[1][self::p and *[1][self::fn]]"
          nomatches = true
          xmldoc.xpath(q).each do |s|
            s.previous_element << s.first_element_child.remove
            s.remove
            nomatches = false
          end
        end
      end

      def table_footnote_renumber1(fn, i, seen)
        if seen[fn.text] then outnum = seen[fn.text]
        else
          i += 1
          outnum = i
          seen[fn.text] = outnum
        end
        fn["reference"] = (outnum - 1 + "a".ord).chr
        fn["table"] = true
        [i, seen]
      end

      def table_footnote_renumber(xmldoc)
        xmldoc.xpath("//table | //figure").each do |t|
          seen = {}
          i = 0
          t.xpath(".//fn").each do |fn|
            i, seen = table_footnote_renumber1(fn, i, seen)
          end
        end
      end

      def footnote_renumber(xmldoc)
        table_footnote_renumber(xmldoc)
        xmldoc.xpath("//fn").each do |fn|
          fn.delete("table")
        end
      end
    end
  end
end
