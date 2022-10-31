module Metanorma
  module Standoc
    module Cleanup
      def formattedref_spans(xmldoc)
        xmldoc.xpath("//bibitem[formattedref//span]").each do |b|
          spans = spans_preprocess(extract_content(b))
          ret = spans_to_bibitem(spans)
          spans[:type] and b["type"] = spans[:type]
          b << ret
        end
      end

      def extract_content(bib)
        extract_docid(bib) + extract_spans(bib)
      end

      def extract_spans(bib)
        bib.xpath("./formattedref//span").each_with_object([]) do |s, m|
          next if s.at("./ancestor::span")

          extract_spans1(s, m)
        end
      end

      def extract_spans1(span, acc)
        keys = span["class"].split(".", 2)
        acc << { key: keys[0], type: keys[1],
                 val: span.children.to_xml }
        (span["class"] == "type" and span.remove) or span.replace(span.children)
      end

      def extract_docid(bib)
        bib.xpath("./docidentifier").each_with_object([]) do |d, m|
          m << { key: "docid", type: d["type"], val: d.text }
          d.remove
        end
      end

      def empty_span_hash
        { contrib: [], docid: [], uri: [], date: [], extent: {}, in: {} }
      end

      def spans_preprocess(spans)
        ret = empty_span_hash
        spans.each { |s| span_preprocess1(s, ret) }
        host_rearrange(ret)
      end

      def span_preprocess1(span, ret)
        case span[:key]
        when "uri", "docid"
          val = link_unwrap(Nokogiri::XML.fragment(span[:val])).to_xml
          ret[span[:key].to_sym] << { type: span[:type], val: val }
        when "date"
          ret[span[:key].to_sym] << { type: span[:type] || "published",
                                      val: span[:val] }
        when "pages", "volume", "issue"
          ret[:extent][span[:key].to_sym] ||= []
          ret[:extent][span[:key].to_sym] << span[:val]
        when "pubplace", "title", "type", "series"
          ret[span[:key].to_sym] = span[:val]
        when "in_title"
          ret[:in][:title] = span[:val]
        when "publisher"
          ret[:contrib] << { role: "publisher", entity: "organization",
                             name: span[:val] }
        when "surname", "initials", "givenname", "formatted-initials"
          ret[:contrib] = spans_preprocess_contrib(span, ret[:contrib])
        when "organization"
          ret[:contrib] = spans_preprocess_org(span, ret[:contrib])
        when "in_surname", "in_initials", "in_givenname",
          "in_formatted-initials"
          ret[:in][:contrib] ||= []
          span[:key].sub!(/^in_/, "")
          ret[:in][:contrib] =
            spans_preprocess_contrib(span, ret[:in][:contrib])
        when "in_organization"
          ret[:in][:contrib] ||= []
          span[:key].sub!(/^in_/, "")
          ret[:in][:contrib] =
            spans_preprocess_org(span, ret[:in][:contrib])
        end
      end

      def host_rearrange(ret)
        ret[:in][:title] or return ret
        ret[:in].merge!(empty_span_hash, { type: "misc" }) { |_, old, _| old }

        %i(series).each do |k|
          ret[:in][k] = ret[k]
          ret.delete(k)
        end
        /^in/.match?(ret[:type]) and ret[:in][:type] =
                                       ret[:type].sub(/^in/, "")
        ret
      end

      def spans_preprocess_contrib(span, contrib)
        span[:key] = "formatted-initials" if span[:key] == "initials"

        spans_preprocess_new_contrib?(span, contrib) and
          contrib << { role: span[:type] || "author", entity: "person" }
        contrib[-1][span[:key].to_sym] = span[:val]
        contrib
      end

      def spans_preprocess_new_contrib?(span, contrib)
        contrib.empty? ||
          (if span[:key] == "surname" then contrib[-1][:surname]
           else (contrib[-1][:"formatted-initials"] || contrib[-1][:givenname])
           end) ||
          contrib[-1][:role] != (span[:type] || "author")
      end

      def spans_preprocess_org(span, contrib)
        contrib << { role: span[:type] || "author", entity: "organization",
                     name: span[:val] }
        contrib
      end

      def spans_to_bibitem(spans)
        ret = ""
        spans[:title] and ret += "<title>#{spans[:title]}</title>"
        ret += spans_to_bibitem_docid(spans)
        spans[:contrib].each { |s| ret += span_to_contrib(s) }
        spans[:series] and
          ret += "<series><title>#{spans[:series]}</title></series>"
        spans[:pubplace] and ret += "<place>#{spans[:pubplace]}</place>"
        ret += spans_to_bibitem_host(spans)
        ret + spans_to_bibitem_extent(spans[:extent])
      end

      def spans_to_bibitem_host(spans)
        return "" if spans[:in].empty?

        ret =
          "<relation type='includedIn'><bibitem type='#{spans[:in][:type]}'>"
        spans[:in].delete(:type)
        ret + "#{spans_to_bibitem(spans[:in])}</bibitem></relation>"
      end

      def spans_to_bibitem_docid(spans)
        ret = ""
        spans[:uri].each { |s| ret += span_to_docid(s, "uri") }
        spans[:docid].each { |s| ret += span_to_docid(s, "docidentifier") }
        spans[:date].each { |s| ret += span_to_docid(s, "date") }
        ret
      end

      def spans_to_bibitem_extent(spans)
        ret = ""
        { volume: "volume", issue: "issue", pages: "page" }.each do |k, v|
          spans[k]&.each { |s| ret += span_to_extent(s, v) }
        end
        ret
      end

      def span_to_extent(span, key)
        values = span.split(/[-–]/)
        ret = "<extent type='#{key}'><locality>" \
              "<referenceFrom>#{values[0]}</referenceFrom>"
        values[1] and
          ret += "<referenceTo>#{values[1]}</referenceTo>"
        "#{ret}</locality></extent>"
      end

      def span_to_docid(span, key)
        if span[:type]
          "<#{key} type='#{span[:type]}'>#{span[:val]}</#{key}>"
        else
          "<#{key}>#{span[:val]}</#{key}>"
        end
      end

      def span_to_contrib(span)
        e = if span[:entity] == "organization"
              "<organization><name>#{span[:name]}</name></organization>"
            else span_to_person(span)
            end
        "<contributor><role type='#{span[:role]}'/>#{e}</contributor>"
      end

      def span_to_person(span)
        pre = (span[:"formatted-initials"] and
                     "<formatted-initials>" \
                     "#{span[:"formatted-initials"]}</formatted-initials>") ||
          "<forename>#{span[:givenname]}</forename>"
        "<person><name>#{pre}<surname>#{span[:surname]}</surname></name>" \
          "</person>"
      end
    end
  end
end
