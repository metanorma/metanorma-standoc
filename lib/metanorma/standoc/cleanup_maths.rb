require_relative "cleanup_mathvariant"

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
        ret = asciimath_parse(expr, elem)&.strip
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
          unitsml = if expr.include?("unitsml")
                      { unitsml: { xml: true,
                                   multiplier: :space } }
                    else {} end
          Plurimath::Math.parse(expr, "asciimath")
            .to_mathml(**{ display_style: elem["block"] }.merge(unitsml))
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

      def mathml_xml_cleanup(stem)
        xml_unescape_mathml(stem)
        mathml_namespace(stem)
        mathml_preserve_space(stem)
      end

      def progress_conv(idx, step, total, threshold, msg)
        (idx % step).zero? && total > threshold && idx.positive? or return
        warn "#{msg} #{idx} of #{total}"
      end

      def xml_unescape_mathml(xml)
        xml.children.any?(&:element?) and return
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

      UNITSML_NS = "https://schema.unitsml.org/unitsml/1.0".freeze

      def add_misc_container(xmldoc)
        unless ins = xmldoc.at("//metanorma-extension")
          a = xmldoc.xpath("//termdocsource")&.last || xmldoc.at("//bibdata")
          a.next = "<metanorma-extension/>"
          ins = xmldoc.at("//metanorma-extension")
        end
        ins
      end

      def mathml_unitsml(xmldoc)
        xmldoc.at(".//m:*", "m" => UNITSML_NS) or return
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
        tags.empty? and return
        set = unitsml.add_child("<#{tag}Set/>").first
        tags.each_value { |v| set << v }
      end

      def asciimath2unitsml_options
        { multiplier: :space }
      end

      def mathml_mn_format(math)
        math["number-format"] or return
        math.xpath(".//m:mn", "m" => MATHML_NS).each do |m|
          profile = mathml_mn_profile(m)
          attr = profile.each_with_object([]) do |(k, v), acc|
            v == "nil" and next
            acc << "#{k}='#{@c.decode v}'"
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

      def mathml_stem_format(stem)
        f = mathml_stem_format_attr(stem) or return
        attr = quoted_csv_split(f, ",").map do |x|
          m = /^(.+?)=(.+)?$/.match(x) or next
          "#{m[1]}='#{@c.decode m[2]}'"
        end.join(",")
        stem.xpath(".//m:mn", "m" => MATHML_NS).each do |m|
          attr.empty? or m["data-metanorma-numberformat"] = attr
        end
      end

      def mathml_stem_format_attr(stem)
        f = stem["number-format"] || @numberfmt_formula or return
        if f == "nil"
          stem.delete("number-format")
          return
        end
        f == "default" or return f
        if @numberfmt_default.empty?
          "notation='basic'"
        else @numberfmt_default&.map { |k, v| "#{k}='#{v}'" }&.join(",")
        end
      end

      def mathml_number_format(stem)
        mathml_stem_format(stem)
        mathml_mn_format(stem)
        stem.delete("number-format")
      end

      def mathml_cleanup(xmldoc)
        xmldoc.xpath("//stem[@type = 'MathML'][not(@validate = 'false')]")
          .each do |x|
          mathml_xml_cleanup(x)
          mathml_mathvariant(x)
        end
        xmldoc.xpath("//stem[@type = 'MathML']")
          .each { |x| mathml_number_format(x) }
        mathml_unitsml(xmldoc)
      end
    end
  end
end
