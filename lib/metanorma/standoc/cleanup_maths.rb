require "asciimath2unitsml"

module Metanorma
  module Standoc
    module Cleanup
      def asciimath2mathml(text)
        text = text.gsub(%r{<stem type="AsciiMath">(.+?)</stem>}m) do
          "<amathstem>#{@c.decode($1)}</amathstem>"
        end
        text = Html2Doc.new({})
          .asciimath_to_mathml(text, ["<amathstem>", "</amathstem>"])
        x =  Nokogiri::XML(text)
        x.xpath("//*[local-name() = 'math'][not(parent::stem)]").each do |y|
          y.wrap("<stem type='MathML'></stem>")
        end
        x.to_xml
      end

      def xml_unescape_mathml(xml)
        return if xml.children.any? { |y| y.element? }

        math = xml.text.gsub(/&lt;/, "<").gsub(/&gt;/, ">")
          .gsub(/&quot;/, '"').gsub(/&apos;/, "'").gsub(/&amp;/, "&")
          .gsub(/<[^: \r\n\t\/]+:/, "<").gsub(/<\/[^ \r\n\t:]+:/, "</")
        xml.children = math
      end

      MATHML_NS = "http://www.w3.org/1998/Math/MathML".freeze

      def mathml_preserve_space(math)
        math.xpath(".//m:mtext", "m" => MATHML_NS).each do |x|
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
      def mathml_italicise(xml)
        xml.xpath(".//m:mi[not(ancestor::*[@mathvariant])]",
                  "m" => MATHML_NS).each do |i|
          char = @c.decode(i.text)
          i["mathvariant"] = "normal" if mi_italicise?(char)
        end
      end

      def mi_italicise?(char)
        return false if char.length > 1

        case char
        when /\p{Greek}/
          (/\p{Lower}/.match(char) && !mathml_mi_italics[:lowergreek]) ||
            (/\p{Upper}/.match(char) && !mathml_mi_italics[:uppergreek])
        when /\p{Latin}/
          (/\p{Lower}/.match(char) && !mathml_mi_italics[:lowerroman]) ||
            (/\p{Upper}/.match(char) && !mathml_mi_italics[:upperroman])
        else false
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

      def gather_unitsml(unitsml, xmldoc, tag)
        tags = xmldoc.xpath(".//m:#{tag}", "m" => UNITSML_NS)
          .each_with_object({}) do |x, m|
          m[x["id"]] = x.remove
        end
        return if tags.empty?

        set = unitsml.add_child("<#{tag}Set/>").first
        tags.each_value { |v| set << v }
      end

      def asciimath2unitsml_options
        { multiplier: :space }
      end

      def mathvariant_override(inner, outer)
        case outer
        when "bold"
          case inner
          when "normal" then "bold"
          when "italic" then "bold-italic"
          when "fraktur" then "bold-fraktur"
          when "script" then "bold-script"
          when "sans-serif" then "bold-sans-serif"
          when "sans-serif-italic" then "sans-serif-bold-italic"
          else inner
          end
        when "italic"
          case inner
          when "normal" then "italic"
          when "bold" then "bold-italic"
          when "sans-serif" then "sans-serif-italic"
          when "bold-sans-serif" then "sans-serif-bold-italic"
          else inner
          end
        when "bold-italic"
          case inner
          when "normal", "bold", "italic" then "bold-italic"
          when "sans-serif", "bold-sans-serif", "sans-serif-italic"
            "sans-serif-bold-italic"
          else inner
          end
        when "fraktur"
          case inner
          when "normal" then "fraktur"
          when "bold" then "bold-fraktur"
          else inner
          end
        when "bold-fraktur"
          case inner
          when "normal", "fraktur" then "bold-fraktur"
          else inner
          end
        when "script"
          case inner
          when "normal" then "script"
          when "bold" then "bold-script"
          else inner
          end
        when "bold-script"
          case inner
          when "normal", "script" then "bold-script"
          else inner
          end
        when "sans-serif"
          case inner
          when "normal" then "sans-serif"
          when "bold" then "bold-sans-serif"
          when "italic" then "sans-serif-italic"
          when "bold-italic" then "sans-serif-bold-italic"
          else inner
          end
        when "bold-sans-serif"
          case inner
          when "normal", "bold", "sans-serif" then "bold-sans-serif"
          when "italic", "bold-italic", "sans-serif-italic"
            "sans-serif-bold-italic"
          else inner
          end
        when "sans-serif-italic"
          case inner
          when "normal", "italic", "sans-serif" then "sans-serif-italic"
          when "bold", "bold-italic", "sans-serif-bold"
            "sans-serif-bold-italic"
          else inner
          end
        when "sans-serif-bold-italic"
          case inner
          when "normal", "italic", "sans-serif", "sans-serif-italic",
          "bold", "bold-italic", "sans-serif-bold"
            "sans-serif-bold-italic"
          else inner
          end
        else inner
        end
      end

      def mathml_mathvariant(math)
        math.xpath(".//*[@mathvariant]").each do |outer|
          outer.xpath(".//*[@mathvariant]").each do |inner|
            inner["mathvariant"] =
              mathvariant_override(outer["mathvariant"], inner["mathvariant"])
          end
        end
      end

      def mathml_cleanup(xmldoc)
        unitsml = Asciimath2UnitsML::Conv.new(asciimath2unitsml_options)
        xmldoc.xpath("//stem[@type = 'MathML']").each do |x|
          xml_unescape_mathml(x)
          mathml_namespace(x)
          mathml_preserve_space(x)
          unitsml.MathML2UnitsML(x)
          mathml_mathvariant(x)
          mathml_italicise(x)
        end
        mathml_unitsML(xmldoc)
      end
    end
  end
end
