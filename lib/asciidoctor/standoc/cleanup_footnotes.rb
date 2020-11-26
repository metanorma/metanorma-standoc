require "date"
require "htmlentities"
require "json"
require "open-uri"

module Asciidoctor
  module Standoc
    module Cleanup
      def footnote_content(fn)
        c = fn.children.respond_to?(:to_xml) ? fn.children.to_xml : fn.children
        c.gsub(/ id="[^"]+"/, "")
      end

      # include footnotes inside figure if they are the only content 
      # of the paras following
      def figure_footnote_cleanup(xmldoc)
        nomatches = false
        until nomatches
          q = "//figure/following-sibling::*[1][self::p and *[1][self::fn]]"
          nomatches = true
          xmldoc.xpath(q).each do |s|
            next if s.children.map { |c| c.text? && /[[:alpha:]]/.match(c.text) }.any?
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
          t.xpath(".//fn[not(ancestor::name)]").each do |fn|
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

      def title_footnote_move(xmldoc)
        ins = xmldoc.at("//bibdata/language")
        xmldoc.xpath("//bibdata/title//fn").each do |f|
          f.name = "note"
          f["type"] = "title-footnote"
          f.delete("reference")
          ins.previous = f.remove
        end
      end

      def footnote_block_cleanup(xmldoc)
        xmldoc.xpath("//footnoteblock").each do |f|
          f.name = 'fn'
          if id = xmldoc.at("//*[@id = '#{f.text}']")
            f.children = id.remove.children
          else
            @log.add("Crossreferences", f,
                     "Could not resolve footnoteblock:[#{f.text}]")
            f.children = "[ERROR]"
          end
        end
      end

      def footnote_cleanup(xmldoc)
        footnote_block_cleanup(xmldoc)
        title_footnote_move(xmldoc)
        table_footnote_renumber(xmldoc)
        other_footnote_renumber(xmldoc)
        xmldoc.xpath("//fn").each do |fn|
          fn.delete("table")
        end
      end
    end
  end
end
