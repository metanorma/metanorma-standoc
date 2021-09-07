require "metanorma-utils"

module Asciidoctor
  module Standoc
    module Cleanup
      def empty_text_before_first_element(elem)
        elem.children.each do |c|
          return false if c.text? && /\S/.match(c.text)
          return true if c.element?
        end
        true
      end

      def strip_initial_space(elem)
        return unless elem.children[0].text?

        if /\S/.match?(elem.children[0].text)
          elem.children[0].content = elem.children[0].text.gsub(/^ /, "")
        else
          elem.children[0].remove
        end
      end

      def bookmark_cleanup(xmldoc)
        li_bookmark_cleanup(xmldoc)
        dt_bookmark_cleanup(xmldoc)
      end

      def bookmark_to_id(elem, bookmark)
        parent = bookmark.parent
        elem["id"] = bookmark.remove["id"]
        strip_initial_space(parent)
      end

      def li_bookmark_cleanup(xmldoc)
        xmldoc.xpath("//li[descendant::bookmark]").each do |x|
          if x.at("./*[1][local-name() = 'p']/"\
                  "*[1][local-name() = 'bookmark']") &&
              empty_text_before_first_element(x.elements[0])
            bookmark_to_id(x, x.elements[0].elements[0])
          end
        end
      end

      def dt_bookmark_cleanup(xmldoc)
        xmldoc.xpath("//dt[descendant::bookmark]").each do |x|
          if x.at("./*[1][local-name() = 'p']/"\
                  "*[1][local-name() = 'bookmark']") &&
              empty_text_before_first_element(x.elements[0])
            bookmark_to_id(x, x.elements[0].elements[0])
          elsif x.at("./*[1][local-name() = 'bookmark']") &&
              empty_text_before_first_element(x)
            bookmark_to_id(x, x.elements[0])
          end
        end
      end

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

      def concept_cleanup(xmldoc)
        xmldoc.xpath("//concept[not(termxref)]").each do |x|
          term = x.at("./refterm")
          term&.remove if term&.text&.empty?
          x.children.remove if x&.children&.text&.strip&.empty?
          key_extract_locality(x)
          if /:/.match?(x["key"]) then concept_termbase_cleanup(x)
          elsif refid? x["key"] then concept_eref_cleanup(x)
          else concept_xref_cleanup(x)
          end
          x.delete("key")
        end
      end

      def key_extract_locality(elem)
        return unless /,/.match?(elem["key"])

        elem.add_child("<locality>#{elem['key'].sub(/^[^,]+,/, '')}</locality>")
        elem["key"] = elem["key"].sub(/,.*$/, "")
      end

      def concept_termbase_cleanup(elem)
        t = elem&.at("./xrefrender")&.remove&.children
        termbase, key = elem["key"].split(/:/, 2)
        elem.add_child(%(<termref base="#{termbase}" target="#{key}">) +
                       "#{t&.to_xml}</termref>")
      end

      def concept_xref_cleanup(elem)
        t = elem&.at("./xrefrender")&.remove&.children
        elem.add_child(%(<xref target="#{elem['key']}">#{t&.to_xml}</xref>))
      end

      def concept_eref_cleanup(elem)
        t = elem&.at("./xrefrender")&.remove&.children&.to_xml
        l = elem&.at("./locality")&.remove&.children&.to_xml
        elem.add_child "<eref bibitemid='#{elem['key']}'>#{l}</eref>"
        extract_localities(elem.elements[-1])
        elem.elements[-1].add_child(t) if t
      end

      def to_xreftarget(str)
        return Metanorma::Utils::to_ncname(str) unless /^[^#]+#.+$/.match?(str)

        /^(?<pref>[^#]+)#(?<suff>.+)$/ =~ str
        pref = pref.gsub(%r([#{Metanorma::Utils::NAMECHAR}])o, "_")
        suff = suff.gsub(%r([#{Metanorma::Utils::NAMECHAR}])o, "_")
        "#{pref}##{suff}"
      end

      IDREF = "//*/@id | //review/@from | //review/@to | "\
              "//callout/@target | //citation/@bibitemid | "\
              "//eref/@bibitemid".freeze

      def anchor_cleanup(elem)
        anchor_cleanup1(elem)
        xreftarget_cleanup(elem)
      end

      def anchor_cleanup1(elem)
        elem.xpath(IDREF).each do |s|
          if (ret = Metanorma::Utils::to_ncname(s.value)) != (orig = s.value)
            s.value = ret
            output = s.parent.dup
            output.children.remove
            @log.add("Anchors", s.parent,
                     "normalised identifier in #{output} from #{orig}")
          end
        end
      end

      def xreftarget_cleanup(elem)
        elem.xpath("//xref/@target").each do |s|
          if (ret = to_xreftarget(s.value)) != (orig = s.value)
            s.value = ret
            output = s.parent.dup
            output.children.remove
            @log.add("Anchors", s.parent,
                     "normalised identifier in #{output} from #{orig}")
          end
        end
      end
    end
  end
end
