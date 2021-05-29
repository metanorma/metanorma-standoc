module Asciidoctor
  module Standoc
    module Cleanup
      def get_or_make_title(node)
        unless node.at("./title")
          if node.children.empty?
            node << "<title/>"
          else
            node.children.first.previous = "<title/>"
          end
        end
        node.at("./title")
      end

      def replace_title(doc, xpath, text, first = false)
        return unless text

        doc.xpath(xpath).each_with_index do |node, i|
          next if first && !i.zero?

          title = get_or_make_title(node)
          fn = title.xpath("./fn")
          fn.each(&:remove)
          title.content = text
          fn.each { |n| title << n }
        end
      end

      def sections_names_cleanup(xml)
        replace_title(xml, "//clause[@type = 'scope']", @i18n&.scope)
        replace_title(xml, "//preface//abstract", @i18n&.abstract)
        replace_title(xml, "//foreword", @i18n&.foreword)
        replace_title(xml, "//introduction", @i18n&.introduction)
        replace_title(xml, "//acknowledgements", @i18n&.acknowledgements)
        section_names_refs_cleanup(xml)
        section_names_terms_cleanup(xml)
      end

      def section_names_refs_cleanup(xml)
        replace_title(xml, "//references[@normative = 'true']",
                      @i18n&.normref, true)
        replace_title(xml, "//references[@normative = 'false']",
                      @i18n&.bibliography, true)
      end

      NO_SYMABBR = "[.//definitions[not(@type)]]".freeze
      SYMABBR = "[.//definitions[@type = 'symbols']]"\
        "[.//definitions[@type = 'abbreviated_terms']]".freeze
      SYMnoABBR = "[.//definitions[@type = 'symbols']]"\
        "[not(.//definitions[@type = 'abbreviated_terms'])]".freeze
      ABBRnoSYM = "[.//definitions[@type = 'abbreviated_terms']]"\
        "[not(.//definitions[@type = 'symbols'])]".freeze

      def section_names_terms_cleanup(x)
        replace_title(x, "//definitions[@type = 'symbols']", @i18n&.symbols)
        replace_title(x, "//definitions[@type = 'abbreviated_terms']",
                      @i18n&.abbrev)
        replace_title(x, "//definitions[not(@type)]", @i18n&.symbolsabbrev)
        replace_title(x, "//terms#{SYMnoABBR} | //clause[.//terms]#{SYMnoABBR}",
                      @i18n&.termsdefsymbols, true)
        replace_title(x, "//terms#{ABBRnoSYM} | //clause[.//terms]#{ABBRnoSYM}",
                      @i18n&.termsdefabbrev, true)
        replace_title(x, "//terms#{SYMABBR} | //clause[.//terms]#{SYMABBR}",
                      @i18n&.termsdefsymbolsabbrev, true)
        replace_title(x, "//terms#{NO_SYMABBR} | //clause[.//terms]#{NO_SYMABBR}",
                      @i18n&.termsdefsymbolsabbrev, true)
        replace_title(
          x,
          "//terms[not(.//definitions)] | //clause[.//terms][not(.//definitions)]",
          @i18n&.termsdef, true
        )
      end
    end
  end
end
