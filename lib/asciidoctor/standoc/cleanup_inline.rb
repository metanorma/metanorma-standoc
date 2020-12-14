module Asciidoctor
  module Standoc
    module Cleanup
      def empty_text_before_first_element(x)
        x.children.each do |c|
          return false if c.text? and /\S/.match(c.text)
          return true if c.element?
        end
        true
      end

      def strip_initial_space(x)
        if x.children[0].text?
          if !/\S/.match(x.children[0].text)
            x.children[0].remove
          else
            x.children[0].content = x.children[0].text.gsub(/^ /, "")
          end
        end
      end

      def bookmark_cleanup(xmldoc)
        xmldoc.xpath("//li[descendant::bookmark]").each do |x|
          if x&.elements&.first&.name == "p" &&
              x&.elements&.first&.elements&.first&.name == "bookmark"
            if empty_text_before_first_element(x.elements[0])
              x["id"] = x.elements[0].elements[0].remove["id"]
              strip_initial_space(x.elements[0])
            end
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

      def tq(x)
        x.sub(/^"/, "").sub(/"$/, "")
      end

      def extract_localities(x)
        f = x&.children&.first or return
        f.text? or return
        head = f.remove.text
        tail = x&.children&.remove
        extract_localities1(x, head)
        tail and x << tail
      end

      def extract_localities1(x, text)
        b = x.add_child("<localityStack/>").first if LOCALITY_RE.match text
        while (m = LOCALITY_RE.match text)
          ref = m[:ref] ? "<referenceFrom>#{tq m[:ref]}</referenceFrom>" : ""
          refto = m[:to] ? "<referenceTo>#{tq m[:to]}</referenceTo>" : ""
          loc = m[:locality]&.downcase || m[:locality2]&.downcase
          b.add_child("<locality type='#{loc}'>#{ref}#{refto}</locality>")
          text = m[:text]
          b = x.add_child("<localityStack/>").first if m[:punct] == ";"
        end
        x.add_child(text) if text
      end

      def xref_to_eref(x)
        x["bibitemid"] = x["target"]
        x["citeas"] = @anchors&.dig(x["target"], :xref) ||
          @log.add("Crossreferences", x,
                   "#{x['target']} does not have a corresponding anchor ID "\
                   "in the bibliography!")
        x.delete("target")
        extract_localities(x) unless x.children.empty?
      end

      def xref_cleanup(xmldoc)
        xmldoc.xpath("//xref").each do |x|
          if refid? x["target"]
            x.name = "eref"
            xref_to_eref(x)
          else
            x.delete("type")
          end
        end
      end

      def quotesource_cleanup(xmldoc)
        xmldoc.xpath("//quote/source | //terms/source").each do |x|
          xref_to_eref(x)
        end
      end

      def origin_cleanup(xmldoc)
        xmldoc.xpath("//origin/concept[termref]").each do |x|
          x.replace(x.children)
        end
        xmldoc.xpath("//origin").each do |x|
          x["citeas"] = @anchors&.dig(x["bibitemid"], :xref) ||
            @log.add("Crossreferences", x,
                     "#{x['bibitemid']} does not have a corresponding anchor "\
                     "ID in the bibliography!")
          extract_localities(x) unless x.children.empty?
        end
      end

      def concept_cleanup(xmldoc)
        xmldoc.xpath("//concept").each do |x|
          x.delete("term") if x["term"].empty?
          if /:/.match(x["key"]) then concept_termbase_cleanup(x)
          elsif refid? x["key"] then concept_eref_cleanup(x)
          else
            concept_xref_cleanup(x)
          end
          x.delete("key")
        end
      end

      def concept_termbase_cleanup(x)
        text = x&.children&.first&.remove&.text
        termbase, key = x["key"].split(/:/, 2)
        x.add_child(%(<termref base="#{termbase}" target="#{key}">) +
                    "#{text}</termref>")
      end

      def concept_xref_cleanup(x)
        text = x&.children&.first&.remove&.text
        x.add_child(%(<xref target="#{x['key']}">#{text}</xref>))
      end

      def concept_eref_cleanup(x)
        x.children = "<eref>#{x.children.to_xml}</eref>"
        extract_localities(x.first_element_child)
      end

      NAMECHAR = "\u0000-\u0022\u0024\u002c\u002f\u003a-\u0040\\u005b-\u005e"\
        "\u0060\u007b-\u00b6\u00b8-\u00bf\u00d7\u00f7\u037e\u2000-\u200b"\
        "\u200e-\u203e\u2041-\u206f\u2190-\u2bff\u2ff0-\u3000".freeze
      #"\ud800-\uf8ff\ufdd0-\ufdef\ufffe-\uffff".freeze
      NAMESTARTCHAR = "\\u002d\u002e\u0030-\u0039\u00b7\u0300-\u036f"\
        "\u203f-\u2040".freeze

      def to_ncname(s)
        start = s[0]
        ret1 = %r([#{NAMECHAR}#]).match(start) ? "_" :
          (%r([#{NAMESTARTCHAR}#]).match(start) ? "_#{start}" : start)
        ret2 = s[1..-1] || ""
        ret = (ret1 || "") + ret2.gsub(%r([#{NAMECHAR}#]), "_")
        ret
      end

      module_function :to_ncname

      def to_xreftarget(s)
        return to_ncname(s) unless /^[^#]+#.+$/.match(s)
          /^(?<pref>[^#]+)#(?<suff>.+)$/ =~ s
        pref = pref.gsub(%r([#{NAMECHAR}]), "_")
        suff = suff.gsub(%r([#{NAMECHAR}]), "_")
        "#{pref}##{suff}"
      end

      IDREF = "//*/@id | //review/@from | //review/@to | "\
        "//callout/@target | //citation/@bibitemid | //eref/@bibitemid".freeze

      def anchor_cleanup(x)
        anchor_cleanup1(x)
        xreftarget_cleanup(x)
      end

      def anchor_cleanup1(x)
        x.xpath(IDREF).each do |s|
          if (ret = to_ncname(s.value)) != (orig = s.value)
            s.value = ret
            output = s.parent.dup
            output.children.remove
            @log.add("Anchors", s.parent, "normalised identifier in #{output} "\
                     "from #{orig}")
          end
        end
      end

      def xreftarget_cleanup(x)
        x.xpath("//xref/@target").each do |s|
          if (ret = to_xreftarget(s.value)) != (orig = s.value)
            s.value = ret
            output = s.parent.dup
            output.children.remove
            @log.add("Anchors", s.parent, "normalised identifier in #{output} "\
                     "from #{orig}")
          end
        end
      end
    end
  end
end
