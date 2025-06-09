require "metanorma-utils"
require "digest"
require "addressable/uri"

module Metanorma
  module Standoc
    module Cleanup
      def empty_text_before_first_element(elem)
        elem.children.each do |c|
          return false if c.text? && /\S/.match(c.text)
          return true if c.element?
        end
        true
      end

      def strip_initial_space(elem)
        a = elem.children[0]
        a.text? or return
        if /\S/.match?(a.text)
          a.content = a.text.lstrip
        else
          a.remove
        end
      end

      def bookmark_cleanup(xmldoc)
        redundant_bookmark_cleanup(xmldoc)
        li_bookmark_cleanup(xmldoc)
        dt_bookmark_cleanup(xmldoc)
      end

      def redundant_bookmark_cleanup(xmldoc)
        xmldoc.xpath("//bookmark").each do |b|
          p = b
          while !p.xml? && p = p.parent
            p["anchor"] == b["anchor"] or next
            b.remove
            break
          end
        end
      end

      def bookmark_to_id(elem, bookmark)
        parent = bookmark.parent
        elem["id"] = bookmark.remove["id"]
        elem["anchor"] = bookmark.remove["anchor"]
        strip_initial_space(parent)
      end

      def li_bookmark_cleanup(xmldoc)
        xmldoc.xpath("//li[descendant::bookmark]").each do |x|
          if x.at("./*[1][local-name() = 'p']/" \
                  "*[1][local-name() = 'bookmark']") &&
              empty_text_before_first_element(x.elements[0])
            bookmark_to_id(x, x.elements[0].elements[0])
          end
        end
      end

      def dt_bookmark_cleanup(xmldoc)
        xmldoc.xpath("//dt[descendant::bookmark]").each do |x|
          if x.at("./*[1][local-name() = 'p']/" \
                  "*[1][local-name() = 'bookmark']") &&
              empty_text_before_first_element(x.elements[0])
            bookmark_to_id(x, x.elements[0].elements[0])
          elsif x.at("./*[1][local-name() = 'bookmark']") &&
              empty_text_before_first_element(x)
            bookmark_to_id(x, x.elements[0])
          end
        end
      end

      def concept_cleanup(xmldoc)
        xmldoc.xpath("//concept[not(termxref)]").each do |x|
          term = x.at("./refterm")
          term&.remove if term&.text&.empty?
          concept_cleanup1(x)
        end
      end

      def concept_cleanup1(elem)
        elem.children.remove if elem&.children&.text&.strip&.empty?
        key_extract_locality(elem)
        if elem["key"].include?(":") then concept_termbase_cleanup(elem)
        elsif refid? elem["key"] then concept_eref_cleanup(elem)
        else concept_xref_cleanup(elem)
        end
        elem.delete("key")
      end

      def related_cleanup(xmldoc)
        xmldoc.xpath("//related[not(termxref)]").each do |x|
          term = x.at("./refterm")
          term.replace("<preferred>#{term_expr(term.children.to_xml)}" \
                       "</preferred>")
          concept_cleanup1(x)
        end
      end

      def key_extract_locality(elem)
        elem["key"].include?(",") or return
        elem.add_child("<locality>#{elem['key'].sub(/^[^,]+,/, '')}</locality>")
        elem["key"] = elem["key"].sub(/(^[^,]+),.*$/, "\\1")
      end

      def concept_termbase_cleanup(elem)
        t = elem&.at("./xrefrender")&.remove&.children
        termbase, key = elem["key"].split(":", 2)
        elem.add_child(%(<termref base="#{termbase}" target="#{key}">) +
                       "#{t&.to_xml}</termref>")
      end

      def concept_xref_cleanup(elem)
        t = elem&.at("./xrefrender")&.remove&.children
        elem.add_child(%(<xref target="#{elem['key']}">#{t&.to_xml}</xref>))
      end

      def concept_eref_cleanup(elem)
        t = elem.at("./xrefrender")&.remove&.children&.to_xml
        l = elem.at("./locality")&.remove&.children&.to_xml
        elem.add_child "<eref bibitemid='#{elem['key']}'>#{l}</eref>"
        extract_localities(elem.elements[-1])
        elem.elements[-1].add_child(t) if t
      end

      def to_xreftarget(str)
        /^[^#]+#.+$/.match?(str) or return Metanorma::Utils::to_ncname(str)
        /^(?<pref>[^#]+)#(?<suff>.+)$/ =~ str
        pref = pref.gsub(%r([#{Metanorma::Utils::NAMECHAR}])o, "_")
        suff = suff.gsub(%r([#{Metanorma::Utils::NAMECHAR}])o, "_")
        "#{pref}##{suff}"
      end

      def anchor_cleanup(elem)
        contenthash_id_cleanup(elem)
      end

      def contenthash_id_cleanup(doc)
        @contenthash_ids = contenthash_id_make(doc)
      end

      def contenthash_id_make(doc)
        doc.xpath("//*[@id]").each_with_object({}) do |x, m|
          # should always be true
          Metanorma::Utils::guid_anchor?(x["id"]) or next
          m[x["id"]] = contenthash(x)
          x["anchor"] and m[x["anchor"]] = m[x["id"]]
          x["id"] = m[x["id"]]
        end
      end

      def contenthash(elem)
        Digest::MD5.hexdigest("#{elem.path}////#{elem.text}")
          .sub(/^(.{8})(.{4})(.{4})(.{4})(.{12})$/, "_\\1-\\2-\\3-\\4-\\5")
      end

      def passthrough_cleanup(doc)
        doc.xpath("//passthrough-inline").each do |p|
          p.name = "passthrough"
          p.children = select_odd_chars(p.children.to_xml)
        end
        doc.xpath("//identifier").each do |p|
          p.children = select_odd_chars(p.children.to_xml)
        end
      end

      # overwrite xmldoc, so must assign result to xmldoc
      def passthrough_metanorma_cleanup(doc)
        ret = to_xml(doc)
          .gsub(%r{<passthrough formats="metanorma">([^<]*)</passthrough>}) { @c.decode($1) }
        Nokogiri::XML(ret, &:huge)
      end

      def link_cleanup(xmldoc)
        uri_cleanup(xmldoc)
      end

      def uri_cleanup(xmldoc)
        xmldoc.xpath("//link[@target]").each do |l|
          l["target"] = Addressable::URI.parse(l["target"]).to_s
        rescue Addressable::URI::InvalidURIError
          err = "Malformed URI: #{l['target']}"
          @log.add("Anchors", l, err, severity: 0)
        end
      end

      def uri_component_encode(comp)
        CGI.escape(comp).gsub("+", "%20")
      end

      def source_id_cleanup(xmldoc)
        xmldoc.xpath("//span[normalize-space(.)=''][@source]").each do |s|
          s.parent["source"] = s["source"]
          s.remove
        end
      end

      private

      # skip ZWNJ inserted to prevent regexes operating in asciidoctor
      def select_odd_chars(text)
        text.gsub(/(?!&)([[:punct:]])\u200c/, "\\1")
      end

      include ::Metanorma::Standoc::Utils
    end
  end
end
