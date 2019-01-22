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
      def footnote_content(fn)
        c = fn.children.respond_to?(:to_xml) ? fn.children.to_xml : fn.children
        c.gsub(/ id="[^"]+"/, "")
      end

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
        content = footnote_content(fn)
        if seen[content] then outnum = seen[content]
        else
          i += 1
          outnum = i
          seen[content] = outnum
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

      def other_footnote_renumber1(fn, i, seen)
        unless fn["table"]
          content = footnote_content(fn)
          if seen[content] then outnum = seen[content]
          else
            i += 1
            outnum = i
            seen[content] = outnum
          end
          fn["reference"] = outnum.to_s
        end
        [i, seen]
      end

      def other_footnote_renumber(xmldoc)
        seen = {}
        i = 0
        xmldoc.xpath("//fn").each do |fn|
          i, seen = other_footnote_renumber1(fn, i, seen)
        end
      end

      def footnote_cleanup(xmldoc)
        table_footnote_renumber(xmldoc)
        other_footnote_renumber(xmldoc)
        xmldoc.xpath("//fn").each do |fn|
          fn.delete("table")
        end
      end
    end
  end
end
