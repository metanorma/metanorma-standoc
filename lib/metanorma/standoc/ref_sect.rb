module Metanorma
  module Standoc
    module Section
      def in_biblio?
        @biblio
      end

      def in_norm_ref?
        @norm_ref
      end

      def bibliography_parse(attrs, xml, node)
        x = biblio_prep(attrs, xml, node) and return x
        @biblio = true
        attrs = attrs.merge(normative: node.attr("normative") || false)
        xml.references **attr_code(attrs) do |xml_section|
          xml_section.title { |t| t << node.title }
          xml_section << node.content
        end
        @biblio = false
      end

      def bibitem_parse(attrs, xml, node)
        norm_ref = @norm_ref
        biblio = @biblio
        @biblio = false
        @norm_ref = false
        ret = clause_parse(attrs, xml, node)
        @biblio = biblio
        @norm_ref = norm_ref
        ret
      end

      def norm_ref_parse(attrs, xml, node)
        x = biblio_prep(attrs, xml, node) and return x
        @norm_ref = true
        attrs = attrs.merge(normative: node.attr("normative") || true)
        xml.references **attr_code(attrs) do |xml_section|
          xml_section.title { |t| t << node.title }
          xml_section << node.content
        end
        @norm_ref = false
      end

      def biblio_prep(attrs, xml, node)
        if node.option? "bibitem"
          bibitem_parse(attrs, xml, node)
        else
          node.attr("style") == "bibliography" or
            @log.add("AsciiDoc Input", node,
                     "Section not marked up as [bibliography]!")
          nil
        end
      end

      def emend_biblio(xml, code, title, usrlbl)
        emend_biblio_id(xml, code)
        emend_biblio_title(xml, code, title)
        emend_biblio_usrlbl(xml, usrlbl)
      end

      def emend_biblio_id(xml, code)
        unless xml.at("/bibitem/docidentifier[not(@type = 'DOI')][text()]") ||
            /^doi:/.match?(code)
          @log.add("Bibliography", nil,
                   "ERROR: No document identifier retrieved for #{code}")
          xml.root << "<docidentifier>#{code}</docidentifier>"
        end
      end

      # supply title if missing;
      # add title with spans in it as formattedref, to emend bibitem with later
      def emend_biblio_title(xml, code, title)
        fmt = /<span class=|<fn/.match?(title)
        unless xml.at("/bibitem/title[text()]")
          @log.add("Bibliography", nil,
                   "ERROR: No title retrieved for #{code}")
          !fmt and
          xml.root << "<title>#{title || '(MISSING TITLE)'}</title>"
        end
        fmt and xml.root << "<formattedref>#{title}</formattedref>"
      end

      def emend_biblio_usrlbl(xml, usrlbl)
        usrlbl or return
        xml.at("/bibitem/docidentifier").next =
          "<docidentifier type='metanorma'>#{mn_code(usrlbl)}</docidentifier>"
      end
    end
  end
end
