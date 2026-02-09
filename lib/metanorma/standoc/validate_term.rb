require "iev"

module Metanorma
  module Standoc
    module Validate
      SOURCELOCALITY = "./origin//locality[@type = 'clause']/" \
                       "referenceFrom".freeze

      def init_iev
        # Treat empty string as falsy (set by Asciidoctor for some attributes)
        warn "DEBUG init_iev: @no_isobib=#{@no_isobib.inspect}"
        warn "DEBUG init_iev: @iev=#{@iev.inspect}"
        warn "DEBUG init_iev: @iev_globalname=#{@iev_globalname.inspect}"
        warn "DEBUG init_iev: @iev_localname=#{@iev_localname.inspect}"

        if @no_isobib && !@no_isobib.empty?
          warn "DEBUG init_iev: RETURNING NIL because @no_isobib is non-empty"
          return nil
        end

        if @iev
          warn "DEBUG init_iev: RETURNING existing @iev"
          return @iev
        end

        begin
          # Same check: only initialize if not explicitly disabled
          if @no_isobib && !@no_isobib.empty?
            warn "DEBUG init_iev: SKIPPED Iev::Db.new because @no_isobib check"
          else
            warn "DEBUG init_iev: ATTEMPTING to create Iev::Db"
            @iev = ::Iev::Db.new(@iev_globalname,
                                 @iev_localname)
            warn "DEBUG init_iev: SUCCESS created @iev=#{@iev.inspect}"
          end
        rescue StandardError => e
          warn "IEV initialization failed: #{e.class}: #{e.message}"
          warn "  Global cache: #{@iev_globalname.inspect}"
          warn "  Local cache: #{@iev_localname.inspect}"
          warn "  Backtrace: #{e.backtrace[0..2].join("\n  ")}" if e.backtrace
          @iev = nil
        end
        warn "DEBUG init_iev: FINAL @iev=#{@iev.inspect}"
        @iev
      end

      def iev_validate(xmldoc)
        @iev = init_iev
        unless @iev
          warn "IEV validation unavailable!"
          return
        end
        xmldoc.xpath("//term").each do |t|
          t.xpath("./source | ./preferred/source | ./admitted/source | " \
            "./deprecates/source | ./related/source").each do |src|
            (/^IEC[  ]60050-/.match(src.at("./origin/@citeas")&.text) &&
          loc = src.xpath(SOURCELOCALITY)&.text) or next
            iev_validate1(t, loc, xmldoc)
          end
        end
      end

      def iev_validate1(term, loc, xmldoc)
        lang = xmldoc.at("//language")&.text || "en"
        warn "DEBUG iev_validate1: Calling @iev.fetch(#{loc.inspect}, #{lang.inspect})"
        iev = @iev.fetch(loc, lang)
        warn "DEBUG iev_validate1: @iev.fetch returned: #{iev.inspect}"
        unless iev
          warn "IEV retrieval of #{loc} failed!"
          warn "DEBUG: Attempting direct Iev.get(#{loc.inspect}, #{lang.inspect}) to test connectivity"
          begin
            # Test the HTTP fetch directly
            url = "https://www.electropedia.org/iev/iev.nsf/display?openform&ievref=#{loc}"
            warn "DEBUG: Testing direct HTTP fetch to #{url}"

            doc = ::Iev.get_doc(loc)
            warn "DEBUG: get_doc returned doc: #{doc.class}"
            warn "DEBUG: doc.nil? = #{doc.nil?}"

            if doc
              warn "DEBUG: Document title: #{doc.at('//title')&.text&.strip}"
              warn "DEBUG: Document has tables: #{doc.xpath('//table').size}"

              xpath = "//table/tr/td/div/font[.=\"#{lang}\"]/../../following-sibling::td[2]"
              warn "DEBUG: XPath query: #{xpath}"
              result_node = doc.at(xpath)
              warn "DEBUG: XPath result node: #{result_node.inspect}"

              if result_node
                children_xml = result_node.children.to_xml
                warn "DEBUG: Node children XML: #{children_xml[0..200]}"
              end
            end

            direct_result = ::Iev.get(loc, lang)
            warn "DEBUG: Direct Iev.get returned: #{direct_result.inspect}"
          rescue StandardError => e
            warn "DEBUG: Exception during testing: #{e.class}: #{e.message}"
            warn "DEBUG: Backtrace: #{e.backtrace[0..4].join("\n")}" if e.backtrace
          end
          return
        end
        pref = term.xpath("./preferred//name").inject([]) do |m, x|
          m << x.text&.downcase
        end
        pref.include?(iev.downcase) or
          @log.add("STANDOC_22", term, params: [pref[0], loc, iev])
      end

      def concept_validate(doc, tag, refterm)
        concept_validate_ids(doc)
        doc.xpath("//#{tag}/xref").each do |x|
          @concept_ids[x["target"]] and next
          @log.add("STANDOC_23", x,
                   params: [concept_validate_msg(doc, tag, refterm, x)])
        end
      end

      def concept_validate_ids(doc)
        @concept_ids ||= doc.xpath("//term | //definitions//dt")
          .each_with_object({}) { |x, m| m[x["anchor"]] = true }
        @concept_terms_tags ||= doc.xpath("//terms")
          .each_with_object({}) { |t, m| m[t["anchor"]] = true }
        nil
      end

      def concept_validate_msg(_doc, tag, refterm, xref)
        t = @doc_ids.dig(xref["target"], :anchor) || xref["target"]
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
          @log.add("STANDOC_24", v.first, params: [k, loc])
        end
      end

      def find_illegal_designations(xmldoc)
        xmldoc.xpath("//preferred | //admitted | //deprecates")
          .each_with_object({}) do |d, m|
            d.ancestors.detect { |x| x.name == "terms" } and next
            c = d.ancestors.detect do |x|
              section_containers.include?(x.name)
            end
            c["id"] or add_id(c["id"])
            m[c["id"]] ||= { clause: c, designations: [] }
            m[c["id"]][:designations] << d
        end
      end

      def termsect_validate(xmldoc)
        errors = find_illegal_designations(xmldoc)
        errors.each_value do |v|
          desgns = v[:designations].map do |x|
            @c.encode(x.text.strip, :basic, :hexadecimal)
          end.join(", ")
          @log.add("STANDOC_25", v[:clause], params: [desgns])
        end
      end
    end
  end
end
