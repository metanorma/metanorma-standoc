require "date"
require "nokogiri"
require "pathname"
require "open-uri"
require "html2doc"
require "pp"
require_relative "./cleanup_block.rb"
require_relative "./cleanup_footnotes.rb"
require_relative "./cleanup_ref.rb"

module Asciidoctor
  module Standoc
    module Cleanup
      def textcleanup(result)
        text = result.flatten.map { |l| l.sub(/\n$/, "") }  * "\n"
        if !@keepasciimath
          text = text.gsub(%r{<stem type="AsciiMath">(.+?)</stem>},
                           '<amathstem>\1</amathstem>')
          text = Html2Doc.
            asciimath_to_mathml(text, ['<amathstem>', "</amathstem>"]).
            gsub(%r{<math xmlns='http://www.w3.org/1998/Math/MathML'>},
                 "<stem type='MathML'>"\
                 "<math xmlns='http://www.w3.org/1998/Math/MathML'>").
                 gsub(%r{</math>}, %{</math></stem>})
        end
        text.gsub(/\s+<fn /, "<fn ")
      end

      def cleanup(xmldoc)
        termdef_cleanup(xmldoc)
        sections_cleanup(xmldoc)
        obligations_cleanup(xmldoc)
        table_cleanup(xmldoc)
        formula_cleanup(xmldoc)
        figure_cleanup(xmldoc)
        ref_cleanup(xmldoc)
        note_cleanup(xmldoc)
        normref_cleanup(xmldoc)
        biblio_cleanup(xmldoc)
        reference_names(xmldoc)
        xref_cleanup(xmldoc)
        origin_cleanup(xmldoc)
        iev_cleanup(xmldoc)
        bpart_cleanup(xmldoc)
        quotesource_cleanup(xmldoc)
        para_cleanup(xmldoc)
        callout_cleanup(xmldoc)
        element_name_cleanup(xmldoc)
        footnote_cleanup(xmldoc)
        empty_element_cleanup(xmldoc)
        mathml_cleanup(xmldoc)
        script_cleanup(xmldoc)
        docidentifier_cleanup(xmldoc)
        bookmark_cleanup(xmldoc)
        smartquotes_cleanup(xmldoc)
        requirement_cleanup(xmldoc)
        xmldoc
      end

      def smartquotes_cleanup(xmldoc)
        return unless @smartquotes
        xmldoc.traverse do |n|
          next unless n.text?
          next unless n.ancestors("pre, tt, sourcecode, bibdata, on").empty?
          n.replace(Utils::smartformat(n.text))
        end
        xmldoc
      end

      def docidentifier_cleanup(xmldoc)
      end

      TEXT_ELEMS =
        %w{status language script version author name callout phone email 
           street city state country postcode identifier referenceFrom
           referenceTo docidentifier docnumber prefix initial addition surname
           forename
           title draft secretariat title-main title-intro title-part}.freeze

      # it seems Nokogiri::XML is treating the content of <script> as cdata,
      # because of its use in HTML. Bad nokogiri. Undoing that, since we use
      # script as a normal tag
      def script_cleanup(xmldoc)
        xmldoc.xpath("//script").each do |x|
          x.content = x.to_str
        end
      end

      def empty_element_cleanup(xmldoc)
        xmldoc.xpath("//" + TEXT_ELEMS.join(" | //")).each do |x|
          x.remove if x.children.empty?
        end
      end

      def element_name_cleanup(xmldoc)
        xmldoc.traverse { |n| n.name = n.name.gsub(/_/, "-") }
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
          if callouts.size == annotations.size
            link_callouts_to_annotations(callouts, annotations)
          end
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

      def termdef_stem_cleanup(xmldoc)
        xmldoc.xpath("//term/p/stem").each do |a|
          if a.parent.elements.size == 1
            # para containing just a stem expression
            t = Nokogiri::XML::Element.new("admitted", xmldoc)
            parent = a.parent
            t.children = a.remove
            parent.replace(t)
          end
        end
      end

      def termdomain_cleanup(xmldoc)
        xmldoc.xpath("//p/domain").each do |a|
          prev = a.parent.previous
          prev.next = a.remove
        end
      end

      def termdefinition_cleanup(xmldoc)
        xmldoc.xpath("//term").each do |d|
          first_child = d.at("./p | ./figure | ./formula") || return
          t = Nokogiri::XML::Element.new("definition", xmldoc)
          first_child.replace(t)
          t << first_child.remove
          d.xpath("./p | ./figure | ./formula").each { |n| t << n.remove }
        end
      end

      def termdef_unnest_cleanup(xmldoc)
        # release termdef tags from surrounding paras
        nodes = xmldoc.xpath("//p/admitted | //p/deprecates")
        while !nodes.empty?
          nodes[0].parent.replace(nodes[0].parent.children)
          nodes = xmldoc.xpath("//p/admitted | //p/deprecates")
        end
      end

      def termdef_boilerplate_cleanup(xmldoc)
        xmldoc.xpath("//terms/p | //terms/ul").each(&:remove)
      end

      def termdef_subclause_cleanup(xmldoc)
        xmldoc.xpath("//terms[terms]").each do |t|
          t.name = "clause"
        end
      end

      def termdocsource_cleanup(xmldoc)
        f = xmldoc.at("//preface | //sections")
        xmldoc.xpath("//terms/termdocsource | "\
                     "//clause/termdocsource").each do |s|
          f.previous = s.remove
        end
      end

      def term_children_cleanup(xmldoc)
        xmldoc.xpath("//term").each do |t|
          ex = t.xpath("./termexample")
          t.xpath("./termnote").each { |n| t << n.remove }
          t.xpath("./termexample").each { |n| t << n.remove }
          t.xpath("./termsource").each { |n| t << n.remove }
        end
      end

      def termdef_cleanup(xmldoc)
        termdef_unnest_cleanup(xmldoc)
        termdef_stem_cleanup(xmldoc)
        termdomain_cleanup(xmldoc)
        termdefinition_cleanup(xmldoc)
        termdef_boilerplate_cleanup(xmldoc)
        termdef_subclause_cleanup(xmldoc)
        term_children_cleanup(xmldoc)
        termdocsource_cleanup(xmldoc)
      end

      def biblio_cleanup(xmldoc)
        xmldoc.xpath("//references[references]").each do |t|
          t.name = "clause"
        end
      end

      def empty_text_before_first_element(x)
        x.children.each do |c|
          if c.text?
            return false if /\S/.match(c.text)
          end
          return true if c.element?
        end
        true
      end

      def strip_initial_space(x)
        if x.children[0].text?
          if !/\S/.match(x.children[0].text)
            x.children[0].remove
          else
            x.children[0].content = x.children[0].text.gsub(/^ /, "")
          end
        end
      end

      def bookmark_cleanup(xmldoc)
        xmldoc.xpath("//li[descendant::bookmark]").each do |x|
          if x&.elements&.first&.name == "p" &&
              x&.elements&.first&.elements&.first&.name == "bookmark"
            if empty_text_before_first_element(x.elements[0])
              x["id"] = x.elements[0].elements[0].remove["id"]
              strip_initial_space(x.elements[0])
            end
          end
        end
      end

      def mathml_cleanup(xmldoc)
        xmldoc.xpath("//stem[@type = 'MathML']").each do |x|
          next if x.children.any? { |y| y.element? }
          math = x.text.gsub(/&lt;/, "<").gsub(/&gt;/, ">").gsub(/&quot;/, '"').
            gsub(/&amp;/, "&").gsub(/<[^:\/]+:/, "<").gsub(/<\/[^:]+:/, "</").
            gsub(/ xmlns[^>]+/, "").
            gsub(/<math>/, '<math xmlns="http://www.w3.org/1998/Math/MathML">')
          x.children = math
        end
      end
    end
  end
end
