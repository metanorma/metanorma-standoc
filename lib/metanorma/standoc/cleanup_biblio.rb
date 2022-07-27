require "set"
require "relaton_bib"

module Metanorma
  module Standoc
    module Cleanup
      def ref_dl_cleanup(xmldoc)
        xmldoc.xpath("//clause[@bibitem = 'true']").each do |c|
          bib = dl_bib_extract(c) or next
          validate_ref_dl(bib, c)
          bibitemxml = RelatonBib::BibliographicItem.from_hash(bib).to_xml or next
          bibitem = Nokogiri::XML(bibitemxml)
          bibitem.root["id"] = c["id"] if c["id"] && !/^_/.match(c["id"])
          c.replace(bibitem.root)
        end
      end

      # do not accept implicit id
      def validate_ref_dl(bib, clause)
        id = bib["id"]
        id ||= clause["id"] unless /^_/.match?(clause["id"])
        unless id
          @log.add("Anchors", clause,
                   "The following reference is missing an anchor:\n"\
                   "#{clause.to_xml}")
          return
        end
        @refids << id
        validate_ref_dl1(bib, id, clause)
      end

      def validate_ref_dl1(bib, id, clause)
        bib["title"] or
          @log.add("Bibliography", clause, "Reference #{id} is missing a title")
        bib["docid"] or
          @log.add("Bibliography", clause,
                   "Reference #{id} is missing a document identifier (docid)")
      end

      def extract_from_p(tag, bib, key)
        return unless bib[tag]

        "<#{key}>#{bib[tag].at('p').children}</#{key}>"
      end

      # if the content is a single paragraph, replace it with its children
      # single links replaced with uri
      def p_unwrap(para)
        elems = para.elements
        if elems.size == 1 && elems[0].name == "p"
          link_unwrap(elems[0]).children.to_xml.strip
        else
          para.to_xml.strip
        end
      end

      def link_unwrap(para)
        elems = para.elements
        if elems.size == 1 && elems[0].name == "link"
          para.at("./link").replace(elems[0]["target"].strip)
        end
        para
      end

      def dd_bib_extract(dtd)
        return nil if dtd.children.empty?

        dtd.at("./dl") and return dl_bib_extract(dtd)
        elems = dtd.remove.elements
        return p_unwrap(dtd) unless elems.size == 1 &&
          %w(ol ul).include?(elems[0].name)

        elems[0].xpath("./li").each_with_object([]) do |li, ret|
          ret << p_unwrap(li)
        end
      end

      def add_to_hash(bib, key, val)
        Metanorma::Utils::set_nested_value(bib, key.split("."), val)
      end

      # definition list, with at most one level of unordered lists
      def dl_bib_extract(clause, nested = false)
        dl = clause.at("./dl") or return
        key = ""
        bib = dl.xpath("./dt | ./dd").each_with_object({}) do |dtd, m|
          (dtd.name == "dt" and key = dtd.text.sub(/:+$/, "")) or
            add_to_hash(m, key, dd_bib_extract(dtd))
        end
        clause.xpath("./clause").each do |c1|
          key = c1&.at("./title")&.text&.downcase&.strip
          next unless %w(contributor relation series).include? key

          add_to_hash(bib, key, dl_bib_extract(c1, true))
        end
        dl_bib_extract_title(bib, clause, nested)
      end

      def dl_bib_extract_title(bib, clause, nested)
        (!nested && clause.at("./title")) or return bib
        title = clause.at("./title").remove.children.to_xml
        bib["title"] = [bib["title"]] if bib["title"].is_a?(Hash) ||
          bib["title"].is_a?(String)
        bib["title"] ||= []
        bib["title"] << title if !title.empty?
        bib
      end

      # ---

      def formattedref_spans(xmldoc)
        xmldoc.xpath("//bibitem[formattedref//span]").each do |b|
          b << spans_to_bibitem(spans_preprocess(extract_content(b)))
        end
      end

      def extract_content(bib)
        extract_docid(bib) + extract_spans(bib)
      end

      def extract_spans(bib)
        bib.xpath("./formattedref//span").each_with_object([]) do |s, m|
          m << { key: s["class"].sub(/\..*$/, ""),
                 type: if /\./.match?(s["class"])
                         s["class"].sub(/^.*?\./, "")
                       end,
                 val: s.children.to_xml }
          s.replace(s.children)
        end
      end

      def extract_docid(bib)
        bib.xpath("./docidentifier").each_with_object([]) do |d, m|
          m << { key: "docid", type: d["type"], val: d.text }
          d.remove
        end
      end

      def spans_preprocess(spans)
        ret = { contributor: [], docid: [], uri: [], date: [] }
        spans.each do |s|
          case s[:key]
          when "uri", "docid"
            ret[s[:key].to_sym] << { type: s[:type], val: s[:val] }
          when "pubyear" then ret[:date] << { type: "published", val: s[:val] }
          when "pubplace", "title" then ret[s[:key].to_sym] = s[:val]
          when "publisher"
            ret[:contributor] << { role: "publisher", entity: "organization",
                                   name: s[:val] }
          when "surname", "initials", "givenname"
            ret[:contributor] = spans_preprocess_contrib(s, ret[:contributor])
          end
        end
        ret
      end

      def spans_preprocess_contrib(span, contrib)
        spans_preprocess_new_contrib?(span, contrib) and
          contrib << { role: span[:type] || "author", entity: "person" }
        contrib[-1][span[:key].to_sym] = span[:val]
        contrib
      end

      def spans_preprocess_new_contrib?(span, contrib)
        contrib.empty? ||
          (if span[:key] == "surname" then contrib[-1][:surname]
           else (contrib[-1][:initials] || contrib[-1][:givenname])
           end) ||
          contrib[-1][:role] != (span[:type] || "author")
      end

      def spans_to_bibitem(spans)
        ret = ""
        spans[:title] and ret += "<title>#{spans[:title]}</title>"
        spans[:uri].each { |s| ret += span_to_docid(s, "uri") }
        spans[:docid].each { |s| ret += span_to_docid(s, "docidentifier") }
        spans[:date].each { |s| ret += span_to_docid(s, "date") }
        spans[:contributor].each { |s| ret += span_to_contrib(s) }
        spans[:pubplace] and ret += "<place>#{spans[:place]}</place>"
        ret
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
            else
              pre = (span[:initials] and
                     "<initial>#{span[:initials]}</initial>") ||
                "<forename>#{span[:givenname]}</forename>"
              "<person><name>#{pre}<surname>#{span[:surname]}</surname></name>"\
                "</person>"
            end
        "<contributor><role type='#{span[:role]}'/>#{e}</contributor>"
      end
    end
  end
end
