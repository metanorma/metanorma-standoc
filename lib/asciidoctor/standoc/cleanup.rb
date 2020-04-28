require "nokogiri"
require "pathname"
require "open-uri"
require "html2doc"
require_relative "./cleanup_block.rb"
require_relative "./cleanup_footnotes.rb"
require_relative "./cleanup_ref.rb"
require_relative "./cleanup_boilerplate.rb"
require_relative "./cleanup_section.rb"
require_relative "./cleanup_inline.rb"
require "relaton_iev"

module Asciidoctor
  module Standoc
    module Cleanup
      def textcleanup(result)
        text = result.flatten.map { |l| l.sub(/\s*$/, "") }  * "\n"
        if !@keepasciimath
          text = text.gsub(%r{<stem type="AsciiMath">(.+?)</stem>}m) do |m|
            "<amathstem>#{HTMLEntities.new.decode($1)}</amathstem>"
          end
          text = Html2Doc.
            asciimath_to_mathml(text, ["<amathstem>", "</amathstem>"])
          x =  Nokogiri::XML(text)
          x.xpath("//*[local-name() = 'math'][not(parent::stem)]").each do |y|
            y.wrap("<stem type='MathML'></stem>")
          end
          text = x.to_xml
        end
        text.gsub(/\s+<fn /, "<fn ")
      end

      def cleanup(xmldoc)
        element_name_cleanup(xmldoc)
        sections_cleanup(xmldoc)
        obligations_cleanup(xmldoc)
        table_cleanup(xmldoc)
        formula_cleanup(xmldoc)
        figure_cleanup(xmldoc)
        ref_cleanup(xmldoc)
        note_cleanup(xmldoc)
        ref_dl_cleanup(xmldoc)
        normref_cleanup(xmldoc)
        biblio_cleanup(xmldoc)
        reference_names(xmldoc)
        symbols_cleanup(xmldoc)
        xref_cleanup(xmldoc)
        concept_cleanup(xmldoc)
        origin_cleanup(xmldoc)
        termdef_cleanup(xmldoc)
        RelatonIev::iev_cleanup(xmldoc, @bibdb)
        element_name_cleanup(xmldoc)
        bpart_cleanup(xmldoc)
        quotesource_cleanup(xmldoc)
        callout_cleanup(xmldoc)
        footnote_cleanup(xmldoc)
        empty_element_cleanup(xmldoc)
        mathml_cleanup(xmldoc)
        script_cleanup(xmldoc)
        docidentifier_cleanup(xmldoc)
        bookmark_cleanup(xmldoc)
        requirement_cleanup(xmldoc)
        bibdata_cleanup(xmldoc)
        boilerplate_cleanup(xmldoc)
        smartquotes_cleanup(xmldoc)
        para_cleanup(xmldoc)
        xmldoc
      end

      def smartquotes_cleanup(xmldoc)
        xmldoc.xpath("//date").each { |d| Utils::endash_date(d) }
        xmldoc.traverse do |n|
          next unless n.text?
          if @smartquotes
            next unless /[-'"(<>]|\.\.|\dx/.match(n)
            next unless n.ancestors("pre, tt, sourcecode, bibdata, on, "\
                                    "stem, figure[@class = 'pseudocode']").empty?
            n.replace(Utils::smartformat(n.text))
          else
            n.replace(n.text.gsub(/(?<=\p{Alnum})\u2019(?=\p{Alpha})/, "'"))
          end
        end
      end

      def docidentifier_cleanup(xmldoc)
      end

      TEXT_ELEMS =
        %w{status language script version author name callout phone email 
           street city state country postcode identifier referenceFrom surname
           referenceTo docidentifier docnumber prefix initial addition forename
           title draft secretariat title-main title-intro title-part}.freeze

      # it seems Nokogiri::XML is treating the content of <script> as cdata,
      # because of its use in HTML. Bad nokogiri. Undoing that, since we use
      # script as a normal tag
      def script_cleanup(xmldoc)
        xmldoc.xpath("//script").each { |x| x.content = x.to_str }
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

      def mathml_cleanup(xmldoc)
        xmldoc.xpath("//stem[@type = 'MathML']").each do |x|
          next if x.children.any? { |y| y.element? }
          math = x.text.gsub(/&lt;/, "<").gsub(/&gt;/, ">").gsub(/&quot;/, '"').
            gsub(/&apos;/, "'").gsub(/&amp;/, "&").
            gsub(/<[^: \r\n\t\/]+:/, "<").gsub(/<\/[^ \r\n\t:]+:/, "</").
            gsub(/ xmlns[^>"']+/, "").
            gsub(/<math /, '<math xmlns="http://www.w3.org/1998/Math/MathML" ').
            gsub(/<math>/, '<math xmlns="http://www.w3.org/1998/Math/MathML">')
          x.children = math
        end
      end

      # allows us to deal with doc relation localities,
      # temporarily stashed to "bpart"
      def bpart_cleanup(xmldoc)
        xmldoc.xpath("//relation/bpart").each do |x|
          extract_localities(x)
          x.replace(x.children)
        end
      end
    end
  end
end
