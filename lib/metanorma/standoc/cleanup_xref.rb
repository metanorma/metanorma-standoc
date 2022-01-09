module Metanorma
  module Standoc
    module Cleanup
      # extending localities to cover ISO referencing
      LOCALITY_REGEX_STR = <<~REGEXP.freeze
        ^((?<locality>section|clause|part|paragraph|chapter|page|
                      table|annex|figure|example|note|formula|list|time|anchor|
                      locality:[^ \\t\\n\\r:,;=]+)(\\s+|=)
               (?<ref>[^"][^ \\t\\n,:-]*|"[^"]+")
                 (-(?<to>[^"][^ \\t\\n,:-]*|"[^"]"))?|
          (?<locality2>whole|locality:[^ \\t\\n\\r:,;=]+))(?<punct>[,:;]?)\\s*
         (?<text>.*)$
      REGEXP
      LOCALITY_RE = Regexp.new(LOCALITY_REGEX_STR.gsub(/\s/, ""),
                               Regexp::IGNORECASE | Regexp::MULTILINE)

      def tq(text)
        text.sub(/^"/, "").sub(/"$/, "")
      end

      def extract_localities(elem)
        f = elem&.children&.first or return
        f.text? or return
        head = f.remove.text
        tail = elem&.children&.remove
        extract_localities1(elem, head)
        tail and elem << tail
      end

      def extract_localities1(elem, text)
        b = elem.add_child("<localityStack/>").first if LOCALITY_RE.match text
        while (m = LOCALITY_RE.match text)
          ref = m[:ref] ? "<referenceFrom>#{tq m[:ref]}</referenceFrom>" : ""
          refto = m[:to] ? "<referenceTo>#{tq m[:to]}</referenceTo>" : ""
          b.add_child("<locality type='#{locality_label(m)}'>#{ref}#{refto}"\
                      "</locality>")
          text = m[:text]
          b = elem.add_child("<localityStack/>").first if m[:punct] == ";"
        end
        elem.add_child(text) if text
      end

      def locality_label(match)
        loc = match[:locality] || match[:locality2]
        /^locality:/.match?(loc) ? loc : loc&.downcase
      end

      def xref_to_eref(elem)
        elem["bibitemid"] = elem["target"]
        unless elem["citeas"] = @anchors&.dig(elem["target"], :xref)
          @internal_eref_namespaces.include?(elem["type"]) or
            @log.add("Crossreferences", elem,
                     "#{elem['target']} does not have a corresponding "\
                     "anchor ID in the bibliography!")
        end
        elem.delete("target")
        extract_localities(elem) unless elem.children.empty?
      end

      def xref_cleanup(xmldoc)
        xmldoc.xpath("//xref").each do |x|
          /:/.match(x["target"]) and xref_to_internal_eref(x)
          next unless x.name == "xref"

          if refid? x["target"]
            x.name = "eref"
            xref_to_eref(x)
          else x.delete("type")
          end
        end
      end

      def xref_to_internal_eref(elem)
        a = elem["target"].split(":", 3)
        unless a.size < 2 || a[0].empty? || a[1].empty?
          elem["target"] = "#{a[0]}_#{a[1]}"
          a.size > 2 and
            elem.children = %{anchor="#{a[2..-1].join}",#{elem&.children&.text}}
          elem["type"] = a[0]
          @internal_eref_namespaces << a[0]
          elem.name = "eref"
          xref_to_eref(elem)
        end
      end

      def quotesource_cleanup(xmldoc)
        xmldoc.xpath("//quote/source | //terms/source").each do |x|
          xref_to_eref(x)
        end
      end

      def origin_cleanup(xmldoc)
        xmldoc.xpath("//origin/concept[termref]").each do |x|
          t = x.at("./termref")
          x.replace(t)
        end
        xmldoc.xpath("//origin").each do |x|
          x["citeas"] = @anchors&.dig(x["bibitemid"], :xref) or
            @log.add("Crossreferences", x,
                     "#{x['bibitemid']} does not have a corresponding anchor "\
                     "ID in the bibliography!")
          extract_localities(x) unless x.children.empty?
        end
      end
    end
  end
end
