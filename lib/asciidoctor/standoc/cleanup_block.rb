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
      def para_cleanup(xmldoc)
        inject_id(xmldoc, "//p | //ol | //ul")
        inject_id(xmldoc, "//note[not(ancestor::bibitem)][not(ancestor::table)]")
      end

      def inject_id(xmldoc, path)
        xmldoc.xpath(path).each do |x|
          x["id"] ||= Utils::anchor_or_uuid
        end
      end

      # move Key dl after table footer
      def dl_table_cleanup(xmldoc)
        q = "//table/following-sibling::*[1][self::p]"
        xmldoc.xpath(q).each do |s|
          if s.text =~ /^\s*key[^a-z]*$/i && !s.next_element.nil? &&
              s.next_element.name == "dl"
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
          s.delete("headerrows")
        end
      end

      def table_cleanup(xmldoc)
        dl_table_cleanup(xmldoc)
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
      def formula_cleanup(x)
        q = "//formula/following-sibling::*[1][self::p]"
        x.xpath(q).each do |s|
          if s.text =~ /^\s*where[^a-z]*$/i && !s.next_element.nil? &&
              s.next_element.name == "dl"
            s.previous_element << s.next_element.remove
            s.remove
          end
        end
      end

      # include key definition list inside figure
      def figure_dl_cleanup(xmldoc)
        q = "//figure/following-sibling::*[self::p]"
        xmldoc.xpath(q).each do |s|
          if s.text =~ /^\s*key[^a-z]*$/i && !s.next_element.nil? &&
              s.next_element.name == "dl"
            s.previous_element << s.next_element.remove
            s.remove
          end
        end
      end

      # examples containing only figures become subfigures of figures
      def subfigure_cleanup(xmldoc)
        nodes = xmldoc.xpath("//example/figure")
        while !nodes.empty?
          nodes[0].parent.name = "figure"
          nodes = xmldoc.xpath("//example/figure")
        end
      end

      def figure_cleanup(xmldoc)
        figure_footnote_cleanup(xmldoc)
        figure_dl_cleanup(xmldoc)
        subfigure_cleanup(xmldoc)
      end

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

      ELEMS_ALLOW_NOTES =
        %w[p formula ul ol dl figure].freeze

      # if a note is at the end of a section, it is left alone
      # if a note is followed by a non-note block,
      # it is moved inside its preceding block if it is not delimited
      # (so there was no way of making that block include the note)
      def note_cleanup(xmldoc)
        q = "//note[following-sibling::*[not(local-name() = 'note')]]"
        xmldoc.xpath(q).each do |n|
          next unless n.ancestors("table").empty?
          prev = n.previous_element || next
          n.parent = prev if ELEMS_ALLOW_NOTES.include? prev.name
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

      def requirement_cleanup(x)
        x.xpath("//requirement | //recommendation | //permission").each do |r|
          r.children.each do |e|
            unless e.element? && (Utils::reqt_subpart(e.name) || 
                %w(requirement recommendation permission).include?(e.name))
              t = Nokogiri::XML::Element.new("description", x)
              e.before(t)
              t.children = e.remove
            end
          end
          requirement_cleanup1(r)
        end
      end

      def requirement_cleanup1(r)
        while d = r.at("./description[following-sibling::*[1][self::description]]")
          n = d.next.remove
          d << n.children
        end
        r.xpath("./description[not(./*) and normalize-space(.)='']").each do |d|
          d.replace("\n")
        end
      end
    end
  end
end
