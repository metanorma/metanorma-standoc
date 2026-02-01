require "date"
require "htmlentities"

module Metanorma
  module Standoc
    module Cleanup
      def para_cleanup(xmldoc)
        ["//p[not(ancestor::bibdata)]", "//ol[not(ancestor::bibdata)]",
         "//ul[not(ancestor::bibdata)]", "//quote[not(ancestor::bibdata)]",
         "//dl[not(ancestor::bibdata)]",
         "//note[not(ancestor::bibitem or " \
         "ancestor::table or ancestor::bibdata)]"].each do |w|
          inject_id(xmldoc, w)
        end
        xmldoc.xpath("//p[not(text()) and not(node())]").each(&:remove)
      end

      def inject_id(xmldoc, path)
        xmldoc.xpath(path).each do |x|
          x["id"] or add_id(x)
        end
      end

      def key_cleanup(xmldoc)
        xmldoc.xpath("//*[@key = 'true']").each do |x|
          x.delete("key")
          x.replace("<key>#{to_xml(x)}</key>")
        end
        key_concatenate(xmldoc)
        xmldoc.xpath("//key//key").each { |x| x.replace(x.children) }
      end

      def key_concatenate(xmldoc)
        xmldoc.xpath("//key").each do |x|
          while x.next_element&.name == "key"
            x << x.next_element.remove.children
          end
        end
      end

      # include where definition list inside stem block
      def formula_cleanup(formula)
        formula_cleanup_where1(formula)
        formula_cleanup_where2(formula)
      end

      def formula_cleanup_where1(formula)
        q = "//formula/following-sibling::*[1][self::key]"
        formula.xpath(q).each do |s|
          s.previous_element << s.remove
        end
      end

      def formula_cleanup_where2(formula)
        text_key_extract(formula, "formula", "where")
      end

      def text_key_extract(elem, tag, keywd)
        q = "//#{tag}/following-sibling::*[1][self::p]"
        elem.xpath(q).each do |s|
          if s.text =~ /^\s*#{keywd}[^a-z]*$/i && s&.next_element&.name == "dl"
            s.previous_element << "<key>#{to_xml(s.next_element.remove)}</key>"
            s.remove
          end
        end
      end

      def figure_dl_cleanup1(xmldoc)
        q = "//figure/following-sibling::*[self::key]"
        q1 = "//figure/figure/following-sibling::*[self::key]"
        (xmldoc.xpath(q) - xmldoc.xpath(q1)).each do |s|
          s.previous_element << s.remove
        end
      end

      # include key definition list inside figure
      def figure_dl_cleanup2(xmldoc)
        text_key_extract(xmldoc, "figure", "key")
      end

      # examples containing only figures become subfigures of figures
      def subfigure_cleanup(xmldoc)
        xmldoc.xpath("//example[figure]").each do |e|
          e.elements.reject do |m|
            %w(name figure index note key).include?(m.name)
          end.empty? or next
          e.name = "figure"
        end
      end

      def single_subfigure_cleanup(xmldoc)
        xmldoc.xpath("//figure[figure]").each do |e|
          s = e.xpath("./figure")
          s.size == 1 or next
          s[0].replace(s[0].children)
        end
      end

      def figure_table_cleanup(xmldoc)
        xmldoc.xpath("//figure").each do |f|
          t = f.at("./table") or next
          t["plain"] = true
          t.xpath(".//td | .//th").each do |d|
            d["align"] = "center"
            d["valign"] = "bottom"
          end
          t.xpath("./note | ./footnote | ./dl | ./source")
            .each { |n| f << n }
        end
      end

      def figure_cleanup(xmldoc)
        figure_table_cleanup(xmldoc)
        figure_footnote_cleanup(xmldoc)
        subfigure_cleanup(xmldoc)
        figure_dl_cleanup1(xmldoc)
        figure_dl_cleanup2(xmldoc)
        single_subfigure_cleanup(xmldoc)
      end

      ELEMS_ALLOW_NOTES = %w[p formula ul ol dl figure].freeze

      # if a note is at the end of a section, it is left alone
      # if a note is followed by a non-note block,
      # it is moved inside its preceding block if it is not delimited
      # (so there was no way of making that block include the note)
      def note_cleanup(xmldoc)
        xmldoc.xpath("//note").each do |n|
          n["keep-separate"] == "true" || !n.ancestors("table").empty? and next
          prev = n.previous_element or next
          n.parent = prev if ELEMS_ALLOW_NOTES.include? prev.name
        end
        xmldoc.xpath("//note[@keep-separate] | " \
                     "//termnote[@keep-separate]").each do |n|
          n.delete("keep-separate")
        end
      end

      def link_callouts_to_annotations(callouts, annotations)
        callouts.each_with_index do |c, i|
          add_id(annotations[i])
          annotations[i]["anchor"] = annotations[i]["id"]
          c["target"] = annotations[i]["id"]
        end
      end

      def align_callouts_to_annotations(xmldoc)
        xmldoc.xpath("//sourcecode").each do |x|
          callouts = x.xpath("./body/callout")
          annotations = x.xpath("./callout-annotation")
          callouts.size == annotations.size and
            link_callouts_to_annotations(callouts, annotations)
        end
      end

      def merge_annotations_into_sourcecode(xmldoc)
        xmldoc.xpath("//sourcecode").each do |x|
          while x.next_element&.name == "callout-annotation"
            x.next_element.parent = x
          end
        end
      end

      def callout_cleanup(xmldoc)
        merge_annotations_into_sourcecode(xmldoc)
        align_callouts_to_annotations(xmldoc)
      end

      def sourcecode_cleanup(xmldoc)
        xmldoc.xpath("//sourcecode").each do |x|
          x.traverse do |n|
            n.text? or next
            /#{Regexp.escape(@sourcecode_markup_start)}/.match?(n.text) or next
            n.replace(sourcecode_markup(n))
          end
        end
      end

      def safe_noko(text, doc)
        Nokogiri::XML::Text.new(text, doc).to_xml(
          encoding: "US-ASCII",
          save_with: Nokogiri::XML::Node::SaveOptions::NO_DECLARATION,
        )
      end

      def sourcecode_markup(node)
        source_markup_prep(node).each_slice(4).map.with_object([]) do |a, acc|
          acc << safe_noko(a[0], node.document)
          a.size == 4 or next
          acc << isolated_asciidoctor_convert(
            "{blank} #{a[2]}", doctype: :inline,
                               backend: backend&.to_sym || :standoc
          ).strip
        end.join
      end

      def source_markup_prep(node)
        ret = node.text.split(/(#{Regexp.escape(@sourcecode_markup_start)}|
                          #{Regexp.escape(@sourcecode_markup_end)})/x)
        source_markup_validate(node, ret)
        ret
      end

      def source_markup_validate(node, ret)
        ret.each_slice(4) do |a|
          a.size == 4 or next
          a[1] == @sourcecode_markup_start && a[3] == @sourcecode_markup_end or
            @log.add("STANDOC_61", node, params: [a.join])
        end
      end

      def form_cleanup(xmldoc)
        xmldoc.xpath("//select").each do |s|
          while s.next_element&.name == "option"
            s << s.next_element
          end
        end
      end

      def ol_cleanup(doc)
        doc.xpath("//ol[@explicit-type]").each do |x|
          x.delete("explicit-type")
          @log.add("STANDOC_14", x, display: false)
        end
      end

      def blocksource_cleanup(xmldoc)
        xmldoc.xpath("//figure//source | //table//source").each do |s|
          s.delete("type")
        end
      end

      def unnumbered_blocks_cleanup(xmldoc)
        @blockunnumbered&.each do |b|
          xmldoc.xpath("//#{b}").each do |e|
            /^[^_]/.match?(e["anchor"]) and e["unnumbered"] = "false"
            e["unnumbered"] ||= "true"
          end
        end
      end
    end
  end
end
