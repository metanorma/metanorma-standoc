module Metanorma
  module Standoc
    module Cleanup
      class SpansToBibitem
        def extract_spans(bib)
          ret = bib.xpath("./formattedref//span").each_with_object([]) do |s, m|
            s.at("./ancestor::span") and next
            extract_spans1(s, m)
          end
          bib.xpath("./formattedref//image").each do |i|
            i.delete("id")
            ret << { key: "image", type: nil, val: i.remove.to_xml }
          end
          ret
        end

        def extract_spans1(span, acc)
          keys = span["class"].split(".", 2)
          acc << { key: keys[0], type: keys[1],
                   val: span.children.to_xml }
          (span["class"] == "type" and span.remove) or
            span.replace(span.children)
        end

        def extract_docid(bib)
          bib.xpath("./docidentifier").each_with_object([]) do |d, m|
            m << { key: "docid", type: d["type"], val: d.text }
            d.remove unless bib.at("./title")
          end
        end

        def empty_span_hash
          { contrib: [], docid: [], uri: [], date: [], classification: [],
            keyword: [], image: [], note: [], extent: {}, in: {} }
        end

        def spans_preprocess(spans)
          ret = empty_span_hash
          spans.each { |s| span_preprocess1(s, ret) }
          spans_defaults(host_rearrange(ret))
        end

        def span_preprocess1(span, ret)
          case span[:key]
          when "uri", "docid", "classification", "keyword"
            val = link_unwrap(Nokogiri::XML.fragment(span[:val])).to_xml
            ret[span[:key].to_sym] << { type: span[:type], val: }
          when "date"
            ret[span[:key].to_sym] << { type: span[:type] || "published",
                                        val: span[:val] }
          when "pages", "volume", "issue"
            ret[:extent][span[:key].to_sym] ||= []
            ret[:extent][span[:key].to_sym] << span[:val]
          when "pubplace", "title", "type", "series", "edition", "version",
            "abstract", "language", "script", "locale"
            ret[span[:key].to_sym] = span[:val]
          when "image", "note"
            ret[span[:key].to_sym] << { type: span[:type], val: span[:val] }
          when "in_title"
            ret[:in][:title] = span[:val]
          when "publisher"
            ret[:contrib] << { role: "publisher", entity: "organization",
                               name: span[:val] }
          when "surname", "initials", "givenname", "formatted-initials"
            ret[:contrib] = spans_preprocess_contrib(span, ret[:contrib])
          when "fullname"
            ret[:contrib] = spans_preprocess_fullname(span, ret[:contrib])
          when "organization"
            ret[:contrib] = spans_preprocess_org(span, ret[:contrib])
          when "in_surname", "in_initials", "in_givenname",
            "in_formatted-initials"
            ret[:in][:contrib] ||= []
            span[:key].sub!(/^in_/, "")
            ret[:in][:contrib] =
              spans_preprocess_contrib(span, ret[:in][:contrib])
          when "in_fullname"
            ret[:in][:contrib] ||= []
            span[:key].sub!(/^in_/, "")
            ret[:in][:contrib] =
              spans_preprocess_fullname(span, ret[:in][:contrib])
          when "in_organization"
            ret[:in][:contrib] ||= []
            span[:key].sub!(/^in_/, "")
            ret[:in][:contrib] =
              spans_preprocess_org(span, ret[:in][:contrib])
          else
            msg = "unrecognised key '#{span[:key]}' in " \
                  "`span:#{span[:key]}[#{span[:val]}]`"
            @err << { msg: }
          end
        end

        def spans_defaults(spans)
          spans[:language] && !spans[:script] and
            spans[:script] = ::Metanorma::Utils.default_script(spans[:language])
          spans
        end

        def host_rearrange(ret)
          ret[:in][:title] or return ret
          ret[:in].merge!(empty_span_hash, { type: "misc" }) { |_, o, _| o }
          %i(series).each do |k|
            ret[:in][k] = ret[k]
            ret.delete(k)
          end
          /^in/.match?(ret[:type]) and
            ret[:in][:type] = ret[:type].sub(/^in/, "")
          ret
        end

        def spans_preprocess_contrib(span, contrib)
          span[:key] == "initials" and span[:key] = "formatted-initials"
          spans_preprocess_new_contrib?(span, contrib) and
            contrib << { role: span[:type] || "author", entity: "person" }
          if multiple_givennames?(span, contrib)
            contrib[-1][:givenname] = [contrib[-1][:givenname],
                                       span[:val]].flatten
          else contrib[-1][span[:key].to_sym] = span[:val]
          end
          contrib
        end

        def spans_preprocess_new_contrib?(span, contrib)
          contrib.empty? || contrib[-1][:entity] == "organization" ||
            (span[:key] == "surname" && contrib[-1][:surname]) ||
            contrib[-1][:role] != (span[:type] || "author")
        end

        def multiple_givennames?(span, contrib)
          (%w(formatted-initials givenname).include?(span[:key]) &&
            (contrib[-1][:"formatted-initials"] || contrib[-1][:givenname])) or
            return false
          if contrib[-1][:"formatted-initials"]
            contrib[-1][:givenname] = contrib[-1][:"formatted-initials"]
            contrib[-1].delete(:"formatted-initials")
          end
          true
        end

        def spans_preprocess_fullname(span, contrib)
          name = span[:val].gsub(/\.(?=\p{Alpha})/, ". ").split(/ /)
          out = { role: span[:type] || "author", entity: "person",
                  surname: name[-1] }
          if name.size > 1 && name[0..-2].all? { |x| /\.$/.match?(x) }
            out[:"formatted-initials"] = name[0..-2].join(" ")
          else out[:givenname] = name[0..-2]
          end
          contrib << out
          contrib
        end

        def spans_preprocess_org(span, contrib)
          contrib << { role: span[:type] || "author", entity: "organization",
                       name: span[:val] }
          contrib
        end
      end
    end
  end
end
