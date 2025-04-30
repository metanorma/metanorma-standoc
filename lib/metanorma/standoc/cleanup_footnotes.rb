require "json"

module Metanorma
  module Standoc
    module Cleanup
      def footnote_content(fnote)
        c = if fnote.children.respond_to?(:to_xml)
              fnote.children.to_xml
            else fn.children
            end
        c.gsub(/ id="[^"]+"/, "")
      end

      FIGURE_FN_XPATH =
        "//figure/following-sibling::*[1][self::p and *[1][self::fn]]".freeze

      # include footnotes inside figure if they are the only content
      # of the paras following
      def figure_footnote_cleanup(xmldoc)
        nomatches = false
        until nomatches
          nomatches = true
          xmldoc.xpath(FIGURE_FN_XPATH).each do |s|
            next if s.children.map do |c|
                      c.text? && /[[:alpha:]]/.match(c.text)
                    end.any?

            s.previous_element << s.first_element_child.remove
            s.remove
            nomatches = false
          end
        end
      end

      def duplicate_footnote(fnote, idx, seen)
        content = footnote_content(fnote)
        if seen[content]
          outnum = seen[content]
          fnote.xpath(".//index | .//bookmark").each(&:remove)
        else
          idx += 1
          outnum = idx
          seen[content] = outnum
        end
        [fnote, idx, seen, outnum]
      end

      def table_footnote_renumber1(fnote, idx, seen)
        fnote, idx, seen, outnum = duplicate_footnote(fnote, idx, seen)
        fnote["reference"] = table_footnote_number(outnum)
        fnote["table"] = true
        [idx, seen]
      end

      def table_footnote_number(outnum)
        (outnum - 1 + "a".ord).chr
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

      def other_footnote_renumber1(fnote, idx, seen)
        fnote["table"] and return [idx, seen]
        fnote, idx, seen, outnum = duplicate_footnote(fnote, idx, seen)
        fnote["reference"] = outnum.to_s
        [idx, seen]
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
        ids = xmldoc.xpath("//footnoteblock").each_with_object([]) do |f, m|
          f.name = "fn"
          m << f.text
          if id = xmldoc.at("//*[@id = '#{f.text}']")
            f.children = id.dup.children
          else footnote_block_error(f)
          end
        end
        footnote_block_remove(xmldoc, ids)
      end

      def footnote_block_remove(xmldoc, ids)
        ids.each do |id|
          n = xmldoc.at("//*[@id = '#{id}']") and
            n.remove
        end
      end

      def footnote_block_error(fnote)
        @log.add("Crossreferences", fnote,
                 "Could not resolve footnoteblock:[#{fnote.text}]", severity: 1)
        fnote.children = "[ERROR]"
      end

      def process_hidden_footnotes(xmldoc)
        xmldoc.xpath("//fn").each do |fn|
          first_text = fn.xpath(".//text()")
            .find { |node| !node.text.strip.empty? } or return
          if first_text.text.strip.start_with?("hiddenref%")
            first_text.content = first_text.text.sub(/^hiddenref%/, "")
            fn["hiddenref"] = true
          end
        end
      end

      def footnote_cleanup(xmldoc)
        footnote_block_cleanup(xmldoc)
        title_footnote_move(xmldoc)
        process_hidden_footnotes(xmldoc)
        table_footnote_renumber(xmldoc)
        other_footnote_renumber(xmldoc)
        xmldoc.xpath("//fn").each do |fn|
          fn.delete("table")
        end
      end
    end
  end
end
