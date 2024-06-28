require "asciimath2unitsml"

module Metanorma
  module Standoc
    module Cleanup
      def asciimath_cleanup(xml)
        !@keepasciimath and asciimath2mathml(xml)
      end

      def asciimath2mathml(xml)
        xpath = xml.xpath("//stem[@type = 'AsciiMath']")
        xpath.each_with_index do |x, i|
          progress_conv(i, 500, xpath.size, 1000, "AsciiMath")
          asciimath2mathml_indiv(x)
        end
        asciimath2mathml_wrap(xml)
      end

      def asciimath2mathml_indiv(elem)
        elem["type"] = "MathML"
        expr = @c.decode(elem.text)
        ret = asciimath_parse(expr, elem)
        ret += "<asciimath>#{@c.encode(expr, :basic)}</asciimath>"
        elem.children = ret
      rescue StandardError => e
        asciimath2mathml_err(elem.to_xml, e)
      end

      # https://medium.com/@rickwang_wxc/in-ruby-given-a-string-detect-if-it-is-valid-numeric-c58275eace60
      NUMERIC_REGEX = %r{^((\+|-)?\d*\.?\d+)([eE](\+|-){1}\d+)?$}

      MATHML_NS = "http://www.w3.org/1998/Math/MathML".freeze

      def asciimath_parse(expr, elem)
        if NUMERIC_REGEX.match?(expr)
          @novalid or elem["validate"] = "false"
          <<~MATH
            <math xmlns='#{MATHML_NS}'><mstyle displaystyle='false'><mn>#{expr}</mn></mstyle></math>
          MATH
        else
          Plurimath::Math.parse(expr, "asciimath")
            .to_mathml(display_style: elem["block"])
        end
      end

      def asciimath2mathml_err(text, expr)
        err = "Malformed MathML: #{expr}\n#{text}"
        @log.add("Maths", nil, err, severity: 0)
      end

      def asciimath2mathml_wrap(xml)
        xml.xpath("//*[local-name() = 'math'][@display]").each do |y|
          y.delete("display")
        end
        # x.xpath("//stem").each do |y|
        # y.next_element&.name == "asciimath" and y << y.next_element
        # end
        xml
      end

      def progress_conv(idx, step, total, threshold, msg)
        return unless (idx % step).zero? && total > threshold && idx.positive?

        warn "#{msg} #{idx} of #{total}"
      end

      def xml_unescape_mathml(xml)
        return if xml.children.any?(&:element?)

        math = xml.text.gsub("&lt;", "<").gsub("&gt;", ">")
          .gsub("&quot;", '"').gsub("&apos;", "'").gsub("&amp;", "&")
          .gsub(/<[^: \r\n\t\/]+:/, "<").gsub(/<\/[^ \r\n\t:]+:/, "</")
        xml.children = math
      end

      def mathml_preserve_space(math)
        math.xpath(".//m:mtext", "m" => MATHML_NS).each do |x|
          x.children = x.children.to_xml
            .gsub(/^\s/, "&#xA0;").gsub(/\s$/, "&#xA0;")
        end
      end

      def mathml_namespace(stem)
        stem.xpath("./*[local-name() = 'math']").each do |x|
          x.default_namespace = MATHML_NS
        end
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
        char.length > 1 and return false
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
        unless ins = xmldoc.at("//metanorma-extension")
          a = xmldoc.xpath("//termdocsource")&.last || xmldoc.at("//bibdata")
          a.next = "<metanorma-extension/>"
          ins = xmldoc.at("//metanorma-extension")
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
          m[x["xml:id"]] = x.remove
        end
        return if tags.empty?

        set = unitsml.add_child("<#{tag}Set/>").first
        tags.each_value { |v| set << v }
      end

      def asciimath2unitsml_options
        { multiplier: :space }
      end

      MATHVARIANT_OVERRIDE = {
        bold: { normal: "bold", italic: "bold-italic", fraktur: "bold-fraktur",
                script: "bold-script", "sans-serif": "bold-sans-serif",
                "sans-serif-italic": "sans-serif-bold-italic" },
        italic: { normal: "italic", bod: "bold-italic",
                  "sans-serif": "sans-serif-italic",
                  "bold-sans-serif": "sans-serif-bold-italic" },
        "bold-italic": { normal: "bold-italic", bold: "bold-italic",
                         italic: "bold-italic",
                         "sans-serif": "sans-serif-bold-italic",
                         "bold-sans-serif": "sans-serif-bold-italic",
                         "sans-serif-italic": "sans-serif-bold-italic" },
        fraktur: { normal: "fraktur", bold: "bold-fraktur" },
        "bold-fraktur": { normal: "bold-fraktur", fraktur: "bold-fraktur" },
        script: { normal: "script", bold: "bold-script" },
        "bold-script": { normal: "script", script: "bold-script" },
        "sans-serif": { normal: "sans-serif", bold: "bold-sans-serif",
                        italic: "sans-serif-italic",
                        "bold-italic": "sans-serif-bold-italic" },
        "bold-sans-serif": { normal: "bold-sans-serif", bold: "bold-sans-serif",
                             "sans-serif": "bold-sans-serif",
                             italic: "sans-serif-bold-italic",
                             "bold-italic": "sans-serif-bold-italic",
                             "sans-serif-italic": "sans-serif-bold-italic" },
        "sans-serif-italic": { normal: "sans-serif-italic",
                               italic: "sans-serif-italic",
                               "sans-serif": "sans-serif-italic",
                               bold: "sans-serif-bold-italic",
                               "bold-italic": "sans-serif-bold-italic",
                               "sans-serif-bold": "sans-serif-bold-italic" },
        "sans-serif-bold-italic": { normal: "sans-serif-bold-italic",
                                    italic: "sans-serif-bold-italic",
                                    "sans-serif": "sans-serif-bold-italic",
                                    "sans-serif-italic": "sans-serif-bold-italic",
                                    bold: "sans-serif-bold-italic",
                                    "bold-italic": "sans-serif-bold-italic",
                                    "sans-serif-bold": "sans-serif-bold-italic" },
      }.freeze

      def mathvariant_override(inner, outer)
        o = outer.to_sym
        i = inner.to_sym
        MATHVARIANT_OVERRIDE[o] or return inner
        MATHVARIANT_OVERRIDE[o][i] || inner
      end

      def mathml_mathvariant(math)
        math.xpath(".//*[@mathvariant]").each do |outer|
          outer.xpath(".//*[@mathvariant]").each do |inner|
            inner["mathvariant"] =
              mathvariant_override(inner["mathvariant"], outer["mathvariant"])
          end
        end
      end

      def mathml_mn_format(math)
        math.xpath(".//m:mn", "m" => MATHML_NS).each do |m|
          profile = mathml_mn_profile(m)
          attr = profile.each_with_object([]) do |(k, v), acc|
            v == "nil" and next
            acc << "#{k}='#{v}'"
          end.join(",")
          attr.empty? or m["data-metanorma-numberformat"] = attr
        end
      end

      def mathml_mn_profile(mnum)
        fmt = @numberfmt_default&.dup || {}
        fmt1 = {}
        fmt2 = kv_parse(mnum["data-metanorma-numberformat"] || "")
        if fmt2["profile"]
          fmt1 = @numberfmt_prof[fmt2["profile"]] || {}
          fmt2.delete("profile")
        end
        fmt.merge(fmt1).merge(fmt2)
      end

      def mathml_cleanup(xmldoc)
        unitsml = Asciimath2UnitsML::Conv.new(asciimath2unitsml_options)
        xmldoc.xpath("//stem[@type = 'MathML'][not(@validate = 'false')]")
          .each do |x|
          xml_unescape_mathml(x)
          mathml_namespace(x)
          mathml_preserve_space(x)
          unitsml.MathML2UnitsML(x)
          mathml_mathvariant(x)
          mathml_italicise(x)
          mathml_mn_format(x)
        end
        mathml_unitsML(xmldoc)
      end
    end
  end
end
