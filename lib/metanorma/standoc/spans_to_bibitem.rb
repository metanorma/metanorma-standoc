require_relative "spans_to_bibitem_preprocessing"

module Metanorma
  module Standoc
    module Cleanup
      class SpansToBibitem
        include ::Metanorma::Standoc::Utils

        attr_reader :err, :out

        def initialize(bib)
          @bib = bib
          @err = []
          @spans = spans_preprocess(extract_spans(bib))
          ids = spans_preprocess(extract_docid(bib))
          @spans[:docid] = override_docids(ids[:docid], @spans[:docid])
        end

        # override old values with new values if type is the same
        # comparison is case-insensitive
        # if types differ in case, use the old value's type, not the new
        def override_docids(old, new)
          ret = new
          keys = new.map { |a| a[:type]&.upcase }
          old.each do |e|
            if keys.include?(e[:type]&.upcase)
              ret.each do |a|
                a[:type]&.upcase == e[:type]&.upcase and a[:type] = e[:type]
              end
            else ret << e
            end
          end
          ret
        end

        def convert
          ret = spans_to_bibitem(@spans)
          @out = Nokogiri::XML("<bibitem>#{ret}</bibitem>").root
          %i(type language script locale).each do |k|
            @spans[k] and @out[k.to_s] = @spans[k]
          end
          self
        end

        def spans_to_bibitem(spans)
          ret = ""
          spans[:title] and ret += "<title>#{spans[:title]}</title>"
          ret += spans_to_bibitem_docid(spans)
          ret += spans_to_contribs(spans)
          ret += spans_to_bibitem_edn(spans)
          ret += spans_to_bibitem_i18n(spans)
          spans[:abstract] and ret += "<abstract>#{spans[:abstract]}</abstract>"
          ret += spans_to_series(spans)
          spans[:pubplace] and ret += "<place>#{spans[:pubplace]}</place>"
          ret += spans_to_bibitem_host(spans)
          ret += spans_to_bibitem_extent(spans[:extent])
          spans[:classification]&.each do |s|
            ret += span_to_docid(s, "classification")
          end
          spans[:keyword]&.each do |s|
            ret += span_to_docid(s, "keyword")
          end
          spans[:image]&.each do |s|
            ret += "<depiction>#{s[:val]}</depiction>"
          end
          ret
        end

        def spans_to_bibitem_i18n(spans)
          ret = ""
          spans[:language] and ret += "<language>#{spans[:language]}</language>"
          spans[:script] and ret += "<script>#{spans[:script]}</script>"
          spans[:locale] and ret += "<locale>#{spans[:locale]}</locale>"
          ret
        end

        def spans_to_series(spans)
          spans[:series] or return ""
          "<series><title>#{spans[:series]}</title></series>"
        end

        def spans_to_bibitem_host(spans)
          spans[:in].nil? || spans[:in].empty? and return ""
          ret =
            "<relation type='includedIn'><bibitem type='#{spans[:in][:type]}'>"
          spans[:in].delete(:type)
          ret + "#{spans_to_bibitem(spans[:in])}</bibitem></relation>"
        end

        def spans_to_bibitem_docid(spans)
          ret = ""
          spans[:uri]&.each { |s| ret += span_to_docid(s, "uri") }
          spans[:docid]&.each { |s| ret += span_to_docid(s, "docidentifier") }
          spans[:date]&.each { |s| ret += span_to_date(s) }
          ret
        end

        def spans_to_bibitem_edn(spans)
          ret = ""
          spans[:edition] and ret += "<edition>#{spans[:edition]}</edition>"
          spans[:version] and ret += "<version>#{spans[:version]}</version>"
          spans[:note] and
            ret += "<note type='#{spans[:note][:type]}'>#{spans[:note][:val]}" \
                   "</note>".sub(/<note type=''>/, "<note>")
          ret
        end

        def spans_to_bibitem_extent(spans)
          spans.nil? and return ""
          ret = ""
          { volume: "volume", issue: "issue", pages: "page" }.each do |k, v|
            spans[k]&.each { |s| ret += span_to_extent(s, v) }
          end
          ret.empty? and return ""
          "<extent>#{ret}</extent>"
        end

        def span_to_extent(span, key)
          values = span.split(/[-–]/)
          ret = "<locality type='#{key}'>" \
                "<referenceFrom>#{values[0]}</referenceFrom>"
          values[1] and
            ret += "<referenceTo>#{values[1]}</referenceTo>"
          "#{ret}</locality>"
        end

        def span_to_docid(span, key)
          if span[:type]
            "<#{key} type='#{span[:type]}'>#{span[:val]}</#{key}>"
          else "<#{key}>#{span[:val]}</#{key}>"
          end
        end

        def span_to_date(span)
          val = if /[-–](?=\d{4})/.match?(span[:val])
                  from, to = span[:val].split(/[-–](?=\d{4})/, 2)
                  "<from>#{from}</from><to>#{to}</to>"
                else "<on>#{span[:val]}</on>"
                end
          type = span[:type] ? " type='#{span[:type]}'" : ""
          "<date#{type}>#{val}</date>"
        end

        def spans_to_contribs(spans)
          ret = ""
          spans[:contrib]&.each do |s|
            ret += span_to_contrib(s, spans[:title])
          end
          ret
        end

        def span_to_contrib(span, title)
          e = if span[:entity] == "organization"
                "<organization><name>#{span[:name]}</name></organization>"
              else span_to_person(span, title)
              end
          "<contributor><role type='#{span[:role]}'/>#{e}</contributor>"
        end

        def validate_span_to_person(span, title)
          span[:surname] and return
          msg = "Missing surname: issue with bibliographic markup " \
                "in \"#{title}\": #{span}"
          @err << { msg:, fatal: true }
        end

        def span_to_person(span, title)
          validate_span_to_person(span, title)
          pre = (span[:"formatted-initials"] and
                       "<formatted-initials>" \
                       "#{span[:"formatted-initials"]}</formatted-initials>") ||
            Array(span[:givenname]).map do |x|
              "<forename>#{x}</forename>"
            end.join
          "<person><name>#{pre}<surname>#{span[:surname]}</surname></name>" \
            "</person>"
        end
      end
    end
  end
end
