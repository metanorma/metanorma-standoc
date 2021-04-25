require "date"
require "htmlentities"
require "open-uri"

module Asciidoctor
  module Standoc
    module Cleanup
      def para_cleanup(xmldoc)
        ["//p[not(ancestor::bibdata)]", "//ol[not(ancestor::bibdata)]",
         "//ul[not(ancestor::bibdata)]", "//quote[not(ancestor::bibdata)]",
         "//note[not(ancestor::bibitem or ancestor::table or ancestor::bibdata)]"
        ].each { |w| inject_id(xmldoc, w) }
      end

      def inject_id(xmldoc, path)
        xmldoc.xpath(path).each do |x|
          x["id"] ||= Metanorma::Utils::anchor_or_uuid
        end
      end

      def dl1_table_cleanup(xmldoc)
        q = "//table/following-sibling::*[1][self::dl]"
        xmldoc.xpath(q).each do |s|
          s["key"] == "true" and s.previous_element << s.remove
        end
      end

      # move Key dl after table footer
      def dl2_table_cleanup(xmldoc)
        q = "//table/following-sibling::*[1][self::p]"
        xmldoc.xpath(q).each do |s|
          if s.text =~ /^\s*key[^a-z]*$/i && s&.next_element&.name == "dl"
            s.next_element["key"] = "true"
            s.previous_element << s.next_element.remove
            s.remove
          end
        end
      end

      def insert_thead(s)
        thead = s.at("./thead")
        return thead unless thead.nil?

        if tname = s.at("./name")
          thead = tname.add_next_sibling("<thead/>").first
          return thead
        end
        s.children.first.add_previous_sibling("<thead/>").first
      end

      def header_rows_cleanup(xmldoc)
        xmldoc.xpath("//table[@headerrows]").each do |s|
          thead = insert_thead(s)
          (thead.xpath("./tr").size...s["headerrows"].to_i).each do
            row = s.at("./tbody/tr")
            row.parent = thead
          end
          thead.xpath(".//td").each { |n| n.name = "th" }
          s.delete("headerrows")
        end
      end

      def table_cleanup(xmldoc)
        dl1_table_cleanup(xmldoc)
        dl2_table_cleanup(xmldoc)
        notes_table_cleanup(xmldoc)
        header_rows_cleanup(xmldoc)
      end

      # move notes into table
      def notes_table_cleanup(xmldoc)
        nomatches = false
        until nomatches
          q = "//table/following-sibling::*[1][self::note]"
          nomatches = true
          xmldoc.xpath(q).each do |n|
            n.previous_element << n.remove
            nomatches = false
          end
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
        xmldoc.xpath(q).each do |s|
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
          next unless e.elements.map(&:name).reject do |m|
            %w(name figure).include? m
          end.empty?

          e.name = "figure"
        end
      end

      def figure_cleanup(xmldoc)
        figure_footnote_cleanup(xmldoc)
        figure_dl_cleanup1(xmldoc)
        figure_dl_cleanup2(xmldoc)
        subfigure_cleanup(xmldoc)
      end

      ELEMS_ALLOW_NOTES = %w[p formula ul ol dl figure].freeze

      # if a note is at the end of a section, it is left alone
      # if a note is followed by a non-note block, 
      # it is moved inside its preceding block if it is not delimited
      # (so there was no way of making that block include the note)
      def note_cleanup(xmldoc)
        q = "//note[following-sibling::*[not(local-name() = 'note')]]"
        xmldoc.xpath(q).each do |n|
          next if n["keep-separate"] == "true"
          next unless n.ancestors("table").empty?

          prev = n.previous_element || next
          n.parent = prev if ELEMS_ALLOW_NOTES.include? prev.name
        end
        xmldoc.xpath("//note[@keep-separate] | "\
                     "//termnote[@keep-separate]").each do |n|
          n.delete("keep-separate")
        end
      end

      def link_callouts_to_annotations(callouts, annotations)
        callouts.each_with_index do |c, i|
          c["target"] = "_" + UUIDTools::UUID.random_create
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
            next unless /#{Regexp.escape(@sourcecode_markup_start)}/.match?(n.text)

            n.replace(sourcecode_markup(n))
          end
        end
      end

      def sourcecode_markup(n)
        acc = []
        n.text.split(/(#{Regexp.escape(@sourcecode_markup_start)}|#{Regexp.escape(@sourcecode_markup_end)})/)
          .each_slice(4).map do |a|
          acc << Nokogiri::XML::Text.new(a[0], n.document)
            .to_xml(encoding: "US-ASCII", save_with: Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
          next unless a.size == 4

          acc << Asciidoctor.convert(a[2], backend: (self&.backend&.to_sym || :standoc), doctype: :inline)
        end
        acc.join
      end
    end
  end
end
