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
        text = x.children.first.remove.text
        while (m = LOCALITY_RE.match text)
          ref = m[:ref] ? "<referenceFrom>#{tq m[:ref]}</referenceFrom>" : ""
          refto = m[:to] ? "<referenceTo>#{tq m[:to]}</referenceTo>" : ""
          loc = m[:locality]&.downcase || m[:locality2]&.downcase
          x.add_child("<locality type='#{loc}'>#{ref}#{refto}</locality>")
          text = m[:text]
        end
        x.add_child(text)
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

      # allows us to deal with doc relation localities,
      # temporarily stashed to "bpart"
      def bpart_cleanup(xmldoc)
        xmldoc.xpath("//relation/bpart").each do |x|
          extract_localities(x)
          x.replace(x.children)
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

      # move ref before p
      def ref_cleanup(xmldoc)
        xmldoc.xpath("//p/ref").each do |r|
          parent = r.parent
          parent.previous = r.remove
        end
      end

      def normref_cleanup(xmldoc)
        q = "//references[title = 'Normative References']"
        r = xmldoc.at(q) || return
        r.elements.each do |n|
          n.remove unless ["title", "bibitem"].include? n.name
        end
      end

      def docid_prefix(prefix, docid)
        docid = "#{prefix} #{docid}" unless omit_docid_prefix(prefix)
        docid
      end

      def omit_docid_prefix(prefix)
        return true if prefix.nil? || prefix.empty?
        ["ISO", "IEC", "IEV"].include? prefix
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
          docid = ref.at("./docidentifier[not(@type = 'DOI')]")
          reference = format_ref(docid.text, docid["type"], isopub)
          @anchors[ref["id"]] = { xref: reference }
        end
      end

      def ref_dl_cleanup(xmldoc)
        xmldoc.xpath("//clause[@bibitem = 'true']").each do |c|
          bib = dl_bib_extract(c) or next
          warn bib
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
        return p_unwrap(dtd) unless elems.size == 1 && %w(ol ul).include?(elems[0].name)
        ret = []
        elems[0].xpath("./li").each do |li|
          ret << p_unwrap(li)
        end
        ret
      end

      def add_to_hash(bib, key, val)
        bib[key] = bib[key].is_a?(Array) ?  (bib[key] << val) :
          bib[key].nil? ?  val : [bib[key], val]
      end

      # mod from https://stackoverflow.com/a/42425884
      def set_nested_value(hash, keys, new_val)
        key = keys[0]
        if keys.length == 1
          hash[key] = hash[key].is_a?(Array) ?  (hash[key] << new_val) :
            hash[key].nil? ?  new_val : [hash[key], new_val]
          return hash
        end
        if hash[key].is_a?(Array)
          hash[key][-1] = {} if hash[key][-1].nil?
          set_nested_value(hash[key][-1], keys[1..-1], new_val)
        elsif hash[key].nil? || hash[key].empty?
          hash[key] = {}
          set_nested_value(hash[key], keys[1..-1], new_val)
        elsif hash[key].is_a?(Hash) && !hash[key][keys[1]]
          set_nested_value(hash[key], keys[1..-1], new_val)
        elsif !hash[key][keys[1]]
          hash[key] = [hash[key], {}]
          set_nested_value(hash[key][-1], keys[1..-1], new_val)
        else
          set_nested_value(hash[key], keys[1..-1], new_val)
        end
      end

      def add_to_hash(bib, key, val)
        set_nested_value(bib, key.split(/\./), val)
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
