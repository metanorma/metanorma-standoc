module Metanorma
  module Standoc
    module Cleanup
      # extending localities to cover ISO referencing
      LOCALITY_REGEX_STR = <<~REGEXP.freeze
        ^(((?<conn>and|or|from|to)!)?
            (?<locality>section|clause|part|paragraph|chapter|page|line|
                      table|annex|figure|example|note|formula|list|time|anchor|
                      locality:[^ \\t\\n\\r:,;=]+)(\\s+|=)
               (?<ref>[^"][^ \\t\\n,:;-]*|"[^"]+")
                 (-(?<to>[^"][^ \\t\\n,:;-]*|"[^"]"))?|
          (?<locality2>whole|title|locality:[^ \\t\\n\\r:,;=]+))(?<punct>[,:;]?)\\s*
         (?<text>.*)$
      REGEXP
      LOCALITY_RE = Regexp.new(LOCALITY_REGEX_STR.gsub(/\s/, ""),
                               Regexp::IGNORECASE | Regexp::MULTILINE)

      def tq(text)
        text.sub(/^"/, "").sub(/"$/, "")
      end

      def extract_localities(elem)
        elem.children.empty? and return
        f = elem.children.first
        f.text? or return
        head = f.remove.text
        tail = elem.children.remove
        extract_localities1(elem, head)
        tail and elem << tail
      end

      def extract_localities1(elem, text)
        b = elem.add_child("<localityStack/>").first if LOCALITY_RE.match text
        while (m = LOCALITY_RE.match text)
          add_locality(b, m)
          text = m[:text]
          b = elem.add_child("<localityStack/>").first if m[:punct] == ";"
        end
        fill_in_eref_connectives(elem)
        elem.add_child(text) if text
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
        return if elem.xpath("./localityStack").size < 2

        elem.xpath("./localityStack[not(@connective)]").each do |l|
          n = l.next_element
          l["connective"] = if n && n.name == "localityStack" &&
              n["connective"] == "to"
                              "from"
                            else "and"
                            end
        end
      end

      def locality_label(match)
        loc = match[:locality] || match[:locality2]
        /^locality:/.match?(loc) ? loc : loc&.downcase
      end

      def xref_to_eref(elem, name)
        elem.name = name
        elem["bibitemid"] = elem["target"]
        if ref = @anchors&.dig(elem["target"], :xref)
          t = @anchors.dig(elem["target"], :id, elem["style"]) and
            ref = t
          elem["citeas"] = @c.decode(ref)
        else xref_to_eref1(elem)
        end
        elem.delete("target")
        extract_localities(elem)
      end

      def xref_to_eref1(elem)
        elem["citeas"] = ""
        @internal_eref_namespaces.include?(elem["type"]) or
          @log.add("Crossreferences", elem,
                   "#{elem['target']} does not have a corresponding " \
                   "anchor ID in the bibliography!")
      end

      def xref_cleanup(xmldoc)
        anchor_alias(xmldoc)
        xref_compound_cleanup(xmldoc)
        xref_cleanup1(xmldoc)
        xref_compound_wrapup(xmldoc)
        eref_stack(xmldoc)
      end

      def eref_stack(xmldoc)
        xmldoc.xpath("//eref[eref]").each do |e|
          e.name = "erefstack"
          e.delete("bibitemid")
          e.delete("citeas")
          e.xpath("./eref").each do |e1|
            e1["type"] = e["type"]
          end
          e.delete("type")
        end
      end

      def anchor_alias(xmldoc)
        t = xmldoc.at("//metanorma-extension/table[@id = " \
                      "'_misccontainer_anchor_aliases']") or return
        key = ""
        t.xpath("./tbody/tr").each do |tr|
          tr.xpath("./td | ./th").each_with_index do |td, i|
            if i.zero? then key = td.text
            else anchor_alias1(key, td)
            end
          end
        end
      end

      def anchor_alias1(key, elem)
        id = elem.text.strip
        id.empty? and elem.at("./link") and
          id = elem.at("./link/@target")&.text
        (key && !id.empty?) or return
        @anchor_alias[id] = key
      end

      def xref_compound_cleanup(xmldoc)
        xmldoc.xpath("//xref").each do |x|
          x["target"].include?(";") or next
          locations = x["target"].split(";")
          x["target"] = locations.first.sub(/^[^!]*!/, "")
          xref_compound_cleanup1(x, locations)
        end
      end

      def xref_compound_cleanup1(xref, locations)
        xref.children.empty? and xref.children = "<sentinel/>"
        xref_parse_compound_locations(locations).reverse.each do |y|
          xref.children.first.previous =
            "<xref target='#{y[1]}' connective='#{y[0]}'/>"
        end
        xref&.at("./sentinel")&.remove
      end

      def xref_parse_compound_locations(locations)
        l = locations.map { |y| y.split("!", 2) }
        l.map.with_index do |y, i|
          if y.size == 1
            y.unshift(l.dig(i + 1, 0) == "to" ? "from" : "and")
          end
          y
        end
      end

      def xref_compound_wrapup(xmldoc)
        xmldoc.xpath("//xref//xref").each do |x|
          x.name = "location"
        end
      end

      def xref_cleanup1(xmldoc)
        xmldoc.xpath("//xref").each do |x|
          %r{:(?!//)}.match?(x["target"]) and xref_to_internal_eref(x)
          next unless x.name == "xref"

          if refid? x["target"]
            xref_to_eref(x, "eref")
          elsif @anchor_alias[x["target"]] then xref_alias(x)
          else x.delete("type")
          end
        end
      end

      def xref_to_internal_eref(elem)
        a = elem["target"].split(":", 3)
        unless a.size < 2 || a[0].empty? || a[1].empty?
          elem["target"] = "#{a[0]}_#{a[1]}"
          a.size > 2 and
            elem.children = %{anchor="#{a[2..-1].join}",#{elem.children&.text}}
          elem["type"] = a[0]
          @internal_eref_namespaces << a[0]
          xref_to_eref(elem, "eref")
        end
      end

      def xref_alias(elem)
        elem["style"] == "id" && elem.text.strip.empty? and
          elem << elem["target"]
        elem["target"] = @anchor_alias[elem["target"]]
      end

      def quotesource_cleanup(xmldoc)
        xmldoc.xpath("//quote/source | //terms/source").each do |x|
          xref_to_eref(x, "source")
        end
      end

      def origin_cleanup(xmldoc)
        xmldoc.xpath("//origin/concept[termref]").each do |x|
          x.replace(x.at("./termref"))
        end
        xmldoc.xpath("//origin").each do |x|
          x["citeas"] = @anchors&.dig(x["bibitemid"], :xref) or
            @log.add("Crossreferences", x,
                     "#{x['bibitemid']} does not have a corresponding anchor " \
                     "ID in the bibliography!")
          extract_localities(x)
        end
      end
    end
  end
end
