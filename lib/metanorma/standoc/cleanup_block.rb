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
      end

      def inject_id(xmldoc, path)
        xmldoc.xpath(path).each do |x|
          x["id"] ||= Metanorma::Utils::anchor_or_uuid
        end
      end

      # include where definition list inside stem block
      def formula_cleanup(formula)
        formula_cleanup_where1(formula)
        formula_cleanup_where2(formula)
      end

      def formula_cleanup_where1(formula)
        q = "//formula/following-sibling::*[1][self::dl]"
        formula.xpath(q).each do |s|
          s["key"] == "true" and s.previous_element << s.remove
        end
      end

      def formula_cleanup_where2(formula)
        q = "//formula/following-sibling::*[1][self::p]"
        formula.xpath(q).each do |s|
          if s.text =~ /^\s*where[^a-z]*$/i && s&.next_element&.name == "dl"
            s.next_element["key"] = "true"
            s.previous_element << s.next_element.remove
            s.remove
          end
        end
      end

      def figure_dl_cleanup1(xmldoc)
        q = "//figure/following-sibling::*[self::dl]"
        q1 = "//figure/figure/following-sibling::*[self::dl]"
        (xmldoc.xpath(q) - xmldoc.xpath(q1)).each do |s|
          s["key"] == "true" and s.previous_element << s.remove
        end
      end

      # include key definition list inside figure
      def figure_dl_cleanup2(xmldoc)
        q = "//figure/following-sibling::*[self::p]"
        xmldoc.xpath(q).each do |s|
          if s.text =~ /^\s*key[^a-z]*$/i && s&.next_element&.name == "dl"
            s.next_element["key"] = "true"
            s.previous_element << s.next_element.remove
            s.remove
          end
        end
      end

      # examples containing only figures become subfigures of figures
      def subfigure_cleanup(xmldoc)
        xmldoc.xpath("//example[figure]").each do |e|
          next unless e.elements.reject do |m|
            %w(name figure index note).include?(m.name) ||
              (m.name == "dl" && m["key"] == "true")
          end.empty?

          e.name = "figure"
        end
      end

      def single_subfigure_cleanup(xmldoc)
        xmldoc.xpath("//figure[figure]").each do |e|
          s = e.xpath("./figure")
          return unless s.size == 1

          s[0].replace(s[0].children)
        end
      end

      def figure_cleanup(xmldoc)
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
          next if n["keep-separate"] == "true" || !n.ancestors("table").empty?

          prev = n.previous_element || next
          n.parent = prev if ELEMS_ALLOW_NOTES.include? prev.name
        end
        xmldoc.xpath("//note[@keep-separate] | " \
                     "//termnote[@keep-separate]").each do |n|
          n.delete("keep-separate")
        end
      end

      def link_callouts_to_annotations(callouts, annotations)
        callouts.each_with_index do |c, i|
          c["target"] = "_#{UUIDTools::UUID.random_create}"
          annotations[i]["id"] = c["target"]
        end
      end

      def align_callouts_to_annotations(xmldoc)
        xmldoc.xpath("//sourcecode").each do |x|
          callouts = x.elements.select { |e| e.name == "callout" }
          annotations = x.elements.select { |e| e.name == "annotation" }
          callouts.size == annotations.size and
            link_callouts_to_annotations(callouts, annotations)
        end
      end

      def merge_annotations_into_sourcecode(xmldoc)
        xmldoc.xpath("//sourcecode").each do |x|
          while x&.next_element&.name == "annotation"
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
            next unless n.text?
            next unless /#{Regexp.escape(@sourcecode_markup_start)}/
              .match?(n.text)

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
        node.text.split(/(#{Regexp.escape(@sourcecode_markup_start)}|
                          #{Regexp.escape(@sourcecode_markup_end)})/x)
          .each_slice(4).map.with_object([]) do |a, acc|
          acc << safe_noko(a[0], node.document)
          next unless a.size == 4

          acc << Asciidoctor.convert(
            a[2], doctype: :inline, backend: (self&.backend&.to_sym || :standoc)
          )
        end.join
      end

      def form_cleanup(xmldoc)
        xmldoc.xpath("//select").each do |s|
          while s&.next_element&.name == "option"
            s << s.next_element
          end
        end
      end

      def block_index_cleanup(xmldoc)
        xmldoc.xpath("//quote | //td | //th | //formula | //li | //dt | " \
                     "//dd | //example | //note | //figure | //sourcecode | " \
                     "//admonition | //termnote | //termexample | //form  | " \
                     "//requirement | //recommendation | //permission | " \
                     "//imagemap | //svgmap").each do |b|
          b.xpath("./p[indexterm]").each do |p|
            indexterm_para?(p) or next
            p.replace(p.children)
          end
        end
      end

      def indexterm_para?(para)
        p = para.dup
        p.xpath("./index").each(&:remove)
        p.text.strip.empty?
      end

      def include_indexterm?(elem)
        return false if elem.nil?

        !%w(image literal sourcecode).include?(elem.name)
      end

      def para_index_cleanup(xmldoc)
        xmldoc.xpath("//p[index]").select { |p| indexterm_para?(p) }
          .each do |p|
            para_index_cleanup1(p, p.previous_element, p.next_element)
          end
      end

      def para_index_cleanup1(para, prev, foll)
        if include_indexterm?(prev)
          prev << para.remove.children
        elsif include_indexterm?(foll) && !foll.children.empty?
          foll.children.first.previous = para.remove.children
        end
      end
    end
  end
end
