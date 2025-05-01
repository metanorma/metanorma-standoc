require "iev"

module Metanorma
  module Standoc
    module Validate
      SOURCELOCALITY = "./origin//locality[@type = 'clause']/" \
                       "referenceFrom".freeze

      def init_iev
        @no_isobib and return nil
        @iev and return @iev
        @iev = ::Iev::Db.new(@iev_globalname, @iev_localname) unless @no_isobib
        @iev
      end

      def iev_validate(xmldoc)
        @iev = init_iev or return
        xmldoc.xpath("//term").each do |t|
          t.xpath("./source | ./preferred/source | ./admitted/source | ./deprecates/source | ./related/source").each do |src|
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
                   %(IEV #{loc} "#{iev}"), severity: 1)
      end

      def concept_validate(doc, tag, refterm)
        concept_validate_ids(doc)
        doc.xpath("//#{tag}/xref").each do |x|
          @concept_ids[x["target"]] and next
          @log.add("Anchors", x, concept_validate_msg(doc, tag, refterm, x),
                   severity: 0)
        end
      end

      def concept_validate_ids(doc)
        @concept_ids ||= doc.xpath("//term | //definitions//dt")
          .each_with_object({}) { |x, m| m[x["id"]] = true }
        @concept_terms_tags ||= doc.xpath("//terms")
          .each_with_object({}) { |t, m| m[t["id"]] = true }
        nil
      end

      def concept_validate_msg(_doc, tag, refterm, xref)
        t = @doc_ids[xref["target"]][:anchor] || xref["target"]
        ret = <<~LOG
          #{tag.capitalize} #{xref.at("../#{refterm}")&.text} is pointing to #{t}, which is not a term or symbol
        LOG
        if @concept_terms_tags[xref["target"]]
          ret = ret.strip
          ret += ". Did you mean to point to a subterm?"
        end
        ret
      end

      def preferred_validate(doc)
        ret = doc.xpath("//term").each_with_object({}) do |t, m|
          prefix = t.at("./domain")&.text
          t.xpath("./preferred//name").each do |n|
            ret = n.text
            prefix and ret = "<#{prefix}> #{ret}"
            m[ret] ||= []
            m[ret] << t
          end
        end
        preferred_validate_report(ret)
      end

      def preferred_validate_report(terms)
        terms.each do |k, v|
          v.size > 1 or next
          loc = v.map { |x| x["anchor"] }.join(", ")
          err = "Term #{k} occurs twice as preferred designation: #{loc}"
          @log.add("Terms", v.first, err, severity: 1)
        end
      end

      def find_illegal_designations(xmldoc)
        xmldoc.xpath("//preferred | //admitted | //deprecates")
          .each_with_object({}) do |d, m|
          d.ancestors.detect { |x| x.name == "terms" } and next
          c = d.ancestors.detect do |x|
            section_containers.include?(x.name)
          end
          c["id"] ||= "_#{UUIDTools::UUID.random_create}"
          m[c["id"]] ||= { clause: c, designations: [] }
          m[c["id"]][:designations] << d
        end
      end

      def termsect_validate(xmldoc)
        errors = find_illegal_designations(xmldoc)
        errors.each_value do |v|
          desgns = v[:designations].map do |x|
            @c.encode(x.text.strip,  :basic, :hexadecimal)
          end.join(", ")
          err = <<~ERROR
            Clause not recognised as a term clause, but contains designation markup
             (<code>preferred:[], admitted:[], alt:[], deprecated:[]</code>):<br/>
            #{desgns}</br>
            Ensure the parent clause is recognised as a terms clause by inserting <code>[heading=terms and definitions]</code> above the title,
            in case the heading is not automatically recognised. See also <a href="https://www.metanorma.org/author/topics/sections/concepts/#clause-title">Metanorma documentation</a>.
          ERROR
          @log.add("Terms", v[:clause], err, severity: 0)
        end
      end
    end
  end
end
