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
                   "The following reference is missing an anchor:\n" \
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
          (dtd.name == "dt" and key = dtd.text.sub(/:+$/, "")) and next
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
    end
  end
end
