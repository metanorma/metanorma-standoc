require "nokogiri"
require "pathname"
require "html2doc"
require "asciimath2unitsml"
require_relative "./cleanup_block"
require_relative "./cleanup_footnotes"
require_relative "./cleanup_ref"
require_relative "./cleanup_ref_dl"
require_relative "./cleanup_boilerplate"
require_relative "./cleanup_section"
require_relative "./cleanup_terms"
require_relative "./cleanup_inline"
require_relative "./cleanup_amend"
require "relaton_iev"

module Asciidoctor
  module Standoc
    module Cleanup
      def asciimath2mathml(text)
        text = text.gsub(%r{<stem type="AsciiMath">(.+?)</stem>}m) do
          "<amathstem>#{HTMLEntities.new.decode($1)}</amathstem>"
        end
        text = Html2Doc.asciimath_to_mathml(text,
                                            ["<amathstem>", "</amathstem>"])
        x =  Nokogiri::XML(text)
        x.xpath("//*[local-name() = 'math'][not(parent::stem)]").each do |y|
          y.wrap("<stem type='MathML'></stem>")
        end
        x.to_xml
      end

      def xml_unescape_mathml(x)
        return if x.children.any? { |y| y.element? }

        math = x.text.gsub(/&lt;/, "<").gsub(/&gt;/, ">")
          .gsub(/&quot;/, '"').gsub(/&apos;/, "'").gsub(/&amp;/, "&")
          .gsub(/<[^: \r\n\t\/]+:/, "<").gsub(/<\/[^ \r\n\t:]+:/, "</")
        x.children = math
      end

      MATHML_NS = "http://www.w3.org/1998/Math/MathML".freeze

      def mathml_preserve_space(m)
        m.xpath(".//m:mtext", "m" => MATHML_NS).each do |x|
          x.children = x.children.to_xml
            .gsub(/^\s/, "&#xA0;").gsub(/\s$/, "&#xA0;")
        end
      end

      def mathml_namespace(stem)
        stem.xpath("./math").each { |x| x.default_namespace = MATHML_NS }
      end

      def mathml_mi_italics
        { uppergreek: true, upperroman: true,
          lowergreek: true, lowerroman: true }
      end

      # presuppose multichar mi upright, singlechar mi MathML default italic
      def mathml_italicise(x)
        x.xpath(".//m:mi[not(ancestor::*[@mathvariant])]",
                "m" => MATHML_NS).each do |i|
          char = HTMLEntities.new.decode(i.text)
          i["mathvariant"] = "normal" if mi_italicise?(char)
        end
      end

      def mi_italicise?(c)
        return false if c.length > 1

        if /\p{Greek}/.match?(c)
          /\p{Lower}/.match(c) && !mathml_mi_italics[:lowergreek] ||
            /\p{Upper}/.match(c) && !mathml_mi_italics[:uppergreek]
        elsif /\p{Latin}/.match?(c)
          /\p{Lower}/.match(c) && !mathml_mi_italics[:lowerroman] ||
            /\p{Upper}/.match(c) && !mathml_mi_italics[:upperroman]
        else
          false
        end
      end

      UNITSML_NS = "https://schema.unitsml.org/unitsml/1.0".freeze

      def add_misc_container(xmldoc)
        unless ins = xmldoc.at("//misc-container")
          a = xmldoc.at("//termdocsource") || xmldoc.at("//bibdata")
          a.next = "<misc-container/>"
          ins = xmldoc.at("//misc-container")
        end
        ins
      end

      def mathml_unitsML(xmldoc)
        return unless xmldoc.at(".//m:*", "m" => UNITSML_NS)

        misc = add_misc_container(xmldoc)
        unitsml = misc.add_child("<UnitsML xmlns='#{UNITSML_NS}'/>").first
        %w(Unit CountedItem Quantity Dimension Prefix).each do |t|
          gather_unitsml(unitsml, xmldoc, t)
        end
      end

      def gather_unitsml(unitsml, xmldoc, t)
        tags = xmldoc.xpath(".//m:#{t}", "m" => UNITSML_NS)
          .each_with_object({}) do |x, m|
          m[x["id"]] = x.remove
        end
        return if tags.empty?

        set = unitsml.add_child("<#{t}Set/>").first
        tags.each_value { |v| set << v }
      end

      def asciimath2unitsml_options
        { multiplier: :space }
      end

      def mathml_cleanup(xmldoc)
        unitsml = Asciimath2UnitsML::Conv.new(asciimath2unitsml_options)
        xmldoc.xpath("//stem[@type = 'MathML']").each do |x|
          xml_unescape_mathml(x)
          mathml_namespace(x)
          mathml_preserve_space(x)
          mathml_italicise(x)
          unitsml.MathML2UnitsML(x)
        end
        mathml_unitsML(xmldoc)
      end
    end
  end
end
