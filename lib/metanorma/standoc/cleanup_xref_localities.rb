module Metanorma
  module Standoc
    module Cleanup
      def tq(text)
        text.sub(/^"/, "").sub(/"$/, "")
      end

      def extract_localities(elem)
        elem.children.empty? and return
        f = elem.children.first
        f.text? or return xref_display_text(elem, elem.children.remove)
        head = f.remove.text
        tail = elem.children.remove
        d = extract_localities1(elem, head)
        tail and d << tail
        d.children.empty? and d.remove
      end

      # treat n-n-n locality as "n-n-n", do not parse as a range
      def locality_normalise(text)
        re = to_regex(LOCALITY_REGEX_STR_TRIPLEDASH)
        m = re.match(text) and
          text = %(#{m[:locality]}"#{m[:ref]}"#{m[:text]})
        text
      end

      def extract_localities1(elem, text)
        re = to_regex(LOCALITY_REGEX_STR)
        b = elem.add_child("<localityStack/>").first if re.match text
        while (m = re.match locality_normalise(text))
          add_locality(b, m)
          text = extract_localities_update_text(m)
          b = elem.add_child("<localityStack/>").first if m[:punct] == ";"
        end
        fill_in_eref_connectives(elem)
        xref_display_text(elem, text)
      end

      def xref_display_text(elem, text)
        d = elem.add_child("<display-text></display-text>").first
        d.add_child(text) if text
        d
      end

      # clause=3;and!5 => clause=3;and!clause=5
      def extract_localities_update_text(match)
        ret = match[:text]
        re = to_regex(LOCALITY_REGEX_VALUE_ONLY_STR)
        re.match?(ret) && match[:punct] == ";" and
          ret.sub!(%r{^(#{CONN_REGEX_STR})}o, "\\1#{match[:locality]}=")
        ret
      end

      def add_locality(stack, match)
        stack.children.empty? && match[:conn] and
          stack["connective"] = match[:conn]
        ref =
          match[:ref] ? "<referenceFrom>#{tq match[:ref]}</referenceFrom>" : ""
        refto = match[:to] ? "<referenceTo>#{tq match[:to]}</referenceTo>" : ""
        stack.add_child("<locality type='#{locality_label(match)}'>#{ref}" \
                        "#{refto}</locality>")
      end

      def fill_in_eref_connectives(elem)
        elem.xpath("./localityStack").size < 2 and return
        elem.xpath("./localityStack[not(@connective)]").each do |l|
          n = l.next_element
          l["connective"] = "and"
          n && n.name == "localityStack" && n["connective"] == "to" and
            l["connective"] = "from"
        end
      end

      def locality_label(match)
        loc = match[:locality] || match[:locality2]
        /^locality:/.match?(loc) ? loc : loc&.downcase
      end

      def xref_parse_compound_locations(locations, xref)
        l = locations.map { |y| y.split("!", 2) }
        l.map.with_index do |y, i|
          y.size == 1 and
            y.unshift(l.dig(i + 1, 0) == "to" ? "from" : "and")
          %w(and from to or).include?(y[0]) or
            @log.add("STANDOC_31", xref, params: [y[0]])
          y
        end
      end

      def xref_compound_wrapup(xmldoc)
        xmldoc.xpath("//xref//xref").each do |x|
          x.name = "location"
        end
        xmldoc.xpath("//xref[not(./display-text)]").each do |x|
          c = x.xpath("./*[not(self::locality or self::localityStack or " \
            "self::location)] | ./text()")
          c.empty? and next
          xref_display_text(x, c.remove)
        end
      end
    end
  end
end
