module Metanorma
  module Standoc
    module Validate
      SOURCELOCALITY = "./origin//locality[@type = 'clause']/" \
                       "referenceFrom".freeze

      def init_iev
        @no_isobib and return nil
        @iev and return @iev
        @iev = Iev::Db.new(@iev_globalname, @iev_localname) unless @no_isobib
        @iev
      end

      def iev_validate(xmldoc)
        @iev = init_iev or return
        xmldoc.xpath("//term").each do |t|
          t.xpath(".//termsource").each do |src|
            (/^IEC[  ]60050-/.match(src.at("./origin/@citeas")&.text) &&
          loc = src.xpath(SOURCELOCALITY)&.text) or next
            iev_validate1(t, loc, xmldoc)
          end
        end
      end

      def iev_validate1(term, loc, xmldoc)
        iev = @iev.fetch(loc,
                         xmldoc.at("//language")&.text || "en") or return
        pref = term.xpath("./preferred//name").inject([]) do |m, x|
          m << x.text&.downcase
        end
        pref.include?(iev.downcase) or
          @log.add("Bibliography", term, %(Term "#{pref[0]}" does not match ) +
                   %(IEV #{loc} "#{iev}"))
      end

      def concept_validate(doc, tag, refterm)
        found = false
        concept_validate_ids(doc)
        doc.xpath("//#{tag}/xref").each do |x|
          @concept_ids[x["target"]] and next
          @log.add("Anchors", x, concept_validate_msg(doc, tag, refterm, x))
          found = true
        end
        found and @fatalerror << "#{tag.capitalize} not cross-referencing " \
                                 "term or symbol"
      end

      def concept_validate_ids(doc)
        @concept_ids ||= doc.xpath("//term | //definitions//dt")
          .each_with_object({}) { |x, m| m[x["id"]] = true }
        @concept_terms_tags ||= doc.xpath("//terms")
          .each_with_object({}) { |t, m| m[t["id"]] = true }
        nil
      end

      def concept_validate_msg(_doc, tag, refterm, xref)
        ret = <<~LOG
          #{tag.capitalize} #{xref.at("../#{refterm}")&.text} is pointing to #{xref['target']}, which is not a term or symbol
        LOG
        if @concept_terms_tags[xref["target"]]
          ret = ret.strip
          ret += ". Did you mean to point to a subterm?"
        end
        ret
      end

      def preferred_validate(doc)
        out = []
        ret = doc.xpath("//term").each_with_object({}) do |t, m|
          prefix = t.at("./domain")&.text
          t.xpath("./preferred//name").each do |n|
            ret = n.text
            prefix and ret = "<#{prefix}> #{ret}"
            (m[ret] and out << ret) or m[ret] = t
          end
        end
        preferred_validate_report(out, ret)
      end

      def preferred_validate_report(terms, locations)
        terms.each do |e|
          err = "Term #{e} occurs twice as preferred designation"
          @log.add("Terms", locations[e], err)
          @fatalerror << err
        end
      end
    end
  end
end
