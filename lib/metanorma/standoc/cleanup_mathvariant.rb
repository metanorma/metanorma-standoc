module Metanorma
  module Standoc
    module Cleanup
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
        mathml_italicise(math)
      end
    end
  end
end
