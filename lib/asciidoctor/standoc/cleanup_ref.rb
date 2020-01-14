require "set"
require "relaton_bib"

module Asciidoctor
  module Standoc
    module Cleanup
      # extending localities to cover ISO referencing
      LOCALITY_REGEX_STR = <<~REGEXP.freeze
        ^((?<locality>section|clause|part|paragraph|chapter|page|
                      table|annex|figure|example|note|formula|list|
                      locality:[^ \\t\\n\\r:,]+)(\\s+|=)
               (?<ref>[^"][^ \\t\\n,:-]*|"[^"]+")
                 (-(?<to>[^"][^ \\t\\n,:-]*|"[^"]"))?|
          (?<locality2>whole|locality:[^ \\t\\n\\r:,]+))[,:]?\\s*
         (?<text>.*)$
      REGEXP
      LOCALITY_RE = Regexp.new(LOCALITY_REGEX_STR.gsub(/\s/, ""),
                               Regexp::IGNORECASE | Regexp::MULTILINE)

      def tq(x)
        x.sub(/^"/, "").sub(/"$/, "")
      end

      def extract_localities(x)
        text = x&.children&.first&.remove&.text
        while (m = LOCALITY_RE.match text)
          ref = m[:ref] ? "<referenceFrom>#{tq m[:ref]}</referenceFrom>" : ""
          refto = m[:to] ? "<referenceTo>#{tq m[:to]}</referenceTo>" : ""
          loc = m[:locality]&.downcase || m[:locality2]&.downcase
          x.add_child("<locality type='#{loc}'>#{ref}#{refto}</locality>")
          text = m[:text]
        end
        x.add_child(text) if text
      end

      def xref_to_eref(x)
        x["bibitemid"] = x["target"]
        x["citeas"] = @anchors&.dig(x["target"], :xref) ||
          warn("#{x['target']} is not a real reference!")
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
        xmldoc.xpath("//origin").each do |x|
          x["citeas"] = @anchors&.dig(x["bibitemid"], :xref) ||
            warn("#{x['bibitemid']} is not a real reference!")
          extract_localities(x) unless x.children.empty?
        end
      end

      def concept_cleanup(xmldoc)
        xmldoc.xpath("//concept").each do |x|
          x.delete("term") if x["term"].empty?
          if x["termbase"] then concept_termbase_cleanup(x)
          elsif refid? x["key"] then concept_eref_cleanup(x)
          else
            concept_xref_cleanup(x)
          end
          x.delete("key")
        end
      end

      def concept_termbase_cleanup(x)
          text = x&.children&.first&.remove&.text
        x.add_child(%(<termref base="#{x['termbase']}" target="#{x['key']}">#{text}</termref>))
        x.delete("termbase")
      end

      def concept_xref_cleanup(x)
          text = x&.children&.first&.remove&.text
        x.add_child(%(<xref target="#{x['key']}">#{text}</xref>))
      end

      def concept_eref_cleanup(x)
        #require "byebug"; byebug
        x.children = "<eref>#{x.children.to_xml}</eref>"
        extract_localities(x.first_element_child)
      end

      def biblio_reorder(xmldoc)
        xmldoc.xpath("//references[title = 'Bibliography']").each do |r|
          biblio_reorder1(r)
        end
      end

      def biblio_reorder1(refs)
        bib = sort_biblio(refs.xpath("./bibitem"))
        refs.xpath("./bibitem").each { |b| b.remove }
        bib.reverse.each do |b|
          insert = refs.at("./title") and insert.next = b.to_xml or
            refs.children.first.add_previous_sibling b.to_xml
        end
        refs.xpath("./references").each { |r| biblio_reorder1(r) }
      end

      def sort_biblio(bib)
        bib
      end

      # default presuppose that all citations in biblio numbered
      # consecutively, but that standards codes are preserved as is:
      # only numeric references are renumbered
      def biblio_renumber(xmldoc)
        r = xmldoc.at("//references[title = 'Bibliography'] | "\
                      "//clause[title = 'Bibliography'][.//bibitem]") or return
        r.xpath(".//bibitem[not(ancestor::bibitem)]").each_with_index do |b, i|
          next unless docid = b.at("./docidentifier[@type = 'metanorma']")
          next unless  /^\[\d+\]$/.match(docid.text)
          docid.children = "[#{i + 1}]"
        end
      end

      # move ref before p
      def ref_cleanup(xmldoc)
        xmldoc.xpath("//p/ref").each do |r|
          parent = r.parent
          parent.previous = r.remove
        end
      end

      def normref_cleanup(xmldoc)
        r = xmldoc.at(NORM_REF) || return
        r.elements.each do |n|
          n.remove unless ["title", "bibitem"].include? n.name
        end
      end

      def biblio_cleanup(xmldoc)
        biblio_reorder(xmldoc)
        biblio_renumber(xmldoc)
        xmldoc.xpath("//references[references]").each do |t|
          t.name = "clause"
        end
      end

      def docid_prefix(prefix, docid)
        docid = "#{prefix} #{docid}" unless omit_docid_prefix(prefix)
        docid
      end

      def omit_docid_prefix(prefix)
        return true if prefix.nil? || prefix.empty?
        %(ISO IEC IEV ITU).include? prefix
      end

      def format_ref(ref, type, isopub)
        return docid_prefix(type, ref) if isopub
        return "[#{ref}]" if /^\d+$/.match(ref) && !/^\[.*\]$/.match(ref)
        ref
      end

      ISO_PUBLISHER_XPATH =
        "./contributor[role/@type = 'publisher']/"\
        "organization[abbreviation = 'ISO' or abbreviation = 'IEC' or "\
        "name = 'International Organization for Standardization' or "\
        "name = 'International Electrotechnical Commission']".freeze

      def reference_names(xmldoc)
        xmldoc.xpath("//bibitem[not(ancestor::bibitem)]").each do |ref|
          isopub = ref.at(ISO_PUBLISHER_XPATH)
          docid = ref.at("./docidentifier[not(@type = 'DOI')]") or next
          reference = format_ref(docid.text, docid["type"], isopub)
          @anchors[ref["id"]] = { xref: reference }
        end
      end

      def ref_dl_cleanup(xmldoc)
        xmldoc.xpath("//clause[@bibitem = 'true']").each do |c|
          bib = dl_bib_extract(c) or next
          bibitemxml = RelatonBib::BibliographicItem.new(
            RelatonBib::HashConverter::hash_to_bib(bib)).to_xml or next
          bibitem = Nokogiri::XML(bibitemxml)
          bibitem["id"] = c["id"] if c["id"]
          c.replace(bibitem.root)
        end
      end

      def extract_from_p(tag, bib, key)
        return unless bib[tag]
        "<#{key}>#{bib[tag].at('p').children}</#{key}>"
      end

      # if the content is a single paragraph, replace it with its children
      # single links replaced with uri
      def p_unwrap(p)
        elems = p.elements
        if elems.size == 1 && elems[0].name == "p"
          link_unwrap(elems[0]).children.to_xml.strip
        else
          p.to_xml.strip
        end
      end

      def link_unwrap(p)
        elems = p.elements
        if elems.size == 1 && elems[0].name == "link"
          p.at("./link").replace(elems[0]["target"].strip)
        end
        p
      end

      def dd_bib_extract(dtd)
        return nil if dtd.children.empty?
        dtd.at("./dl") and return dl_bib_extract(dtd)
        elems = dtd.remove.elements
        return p_unwrap(dtd) unless elems.size == 1 &&
          %w(ol ul).include?(elems[0].name)
        ret = []
        elems[0].xpath("./li").each do |li|
          ret << p_unwrap(li)
        end
        ret
      end

      def add_to_hash(bib, key, val)
        Utils::set_nested_value(bib, key.split(/\./), val)
      end

      # definition list, with at most one level of unordered lists
      def dl_bib_extract(c, nested = false)
        dl = c.at("./dl") or return
        bib = {}
        key = ""
        dl.xpath("./dt | ./dd").each do |dtd|
          dtd.name == "dt" and key = dtd.text.sub(/:+$/, "") or
            add_to_hash(bib, key, dd_bib_extract(dtd))
        end
        c.xpath("./clause").each do |c1|
          key = c1&.at("./title")&.text&.downcase&.strip
          next unless %w(contributor relation series).include? key
          add_to_hash(bib, key, dl_bib_extract(c1, true))
        end
        if !nested and c.at("./title")
          title = c.at("./title").remove.children.to_xml
          bib["title"] = bib["title"] ? Array(bib["title"]) : []
          bib["title"] << title if !title.empty?
        end
        bib
      end
    end
  end
end
