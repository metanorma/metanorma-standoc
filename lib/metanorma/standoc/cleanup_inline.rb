require "metanorma-utils"
require "digest"

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
        return unless elem.children[0].text?

        if /\S/.match?(elem.children[0].text)
          elem.children[0].content = elem.children[0].text.gsub(/^ /, "")
        else
          elem.children[0].remove
        end
      end

      def bookmark_cleanup(xmldoc)
        li_bookmark_cleanup(xmldoc)
        dt_bookmark_cleanup(xmldoc)
      end

      def bookmark_to_id(elem, bookmark)
        parent = bookmark.parent
        elem["id"] = bookmark.remove["id"]
        strip_initial_space(parent)
      end

      def li_bookmark_cleanup(xmldoc)
        xmldoc.xpath("//li[descendant::bookmark]").each do |x|
          if x.at("./*[1][local-name() = 'p']/"\
                  "*[1][local-name() = 'bookmark']") &&
              empty_text_before_first_element(x.elements[0])
            bookmark_to_id(x, x.elements[0].elements[0])
          end
        end
      end

      def dt_bookmark_cleanup(xmldoc)
        xmldoc.xpath("//dt[descendant::bookmark]").each do |x|
          if x.at("./*[1][local-name() = 'p']/"\
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
        if /:/.match?(elem["key"]) then concept_termbase_cleanup(elem)
        elsif refid? elem["key"] then concept_eref_cleanup(elem)
        else concept_xref_cleanup(elem)
        end
        elem.delete("key")
      end

      def related_cleanup(xmldoc)
        xmldoc.xpath("//related[not(termxref)]").each do |x|
          term = x.at("./refterm")
          term.replace("<preferred>#{term_expr(term.children.to_xml)}"\
                       "</preferred>")
          concept_cleanup1(x)
        end
      end

      def key_extract_locality(elem)
        return unless /,/.match?(elem["key"])

        elem.add_child("<locality>#{elem['key'].sub(/^[^,]+,/, '')}</locality>")
        elem["key"] = elem["key"].sub(/,.*$/, "")
      end

      def concept_termbase_cleanup(elem)
        t = elem&.at("./xrefrender")&.remove&.children
        termbase, key = elem["key"].split(/:/, 2)
        elem.add_child(%(<termref base="#{termbase}" target="#{key}">) +
                       "#{t&.to_xml}</termref>")
      end

      def concept_xref_cleanup(elem)
        t = elem&.at("./xrefrender")&.remove&.children
        elem.add_child(%(<xref target="#{elem['key']}">#{t&.to_xml}</xref>))
      end

      def concept_eref_cleanup(elem)
        t = elem&.at("./xrefrender")&.remove&.children&.to_xml
        l = elem&.at("./locality")&.remove&.children&.to_xml
        elem.add_child "<eref bibitemid='#{elem['key']}'>#{l}</eref>"
        extract_localities(elem.elements[-1])
        elem.elements[-1].add_child(t) if t
      end

      def to_xreftarget(str)
        return Metanorma::Utils::to_ncname(str) unless /^[^#]+#.+$/.match?(str)

        /^(?<pref>[^#]+)#(?<suff>.+)$/ =~ str
        pref = pref.gsub(%r([#{Metanorma::Utils::NAMECHAR}])o, "_")
        suff = suff.gsub(%r([#{Metanorma::Utils::NAMECHAR}])o, "_")
        "#{pref}##{suff}"
      end

      IDREF = "//*/@id | //review/@from | //review/@to | "\
              "//callout/@target | //citation/@bibitemid | "\
              "//eref/@bibitemid".freeze

      def anchor_cleanup(elem)
        anchor_cleanup1(elem)
        xreftarget_cleanup(elem)
        contenthash_id_cleanup(elem)
      end

      def anchor_cleanup1(elem)
        elem.xpath(IDREF).each do |s|
          if (ret = Metanorma::Utils::to_ncname(s.value)) != (orig = s.value)
            s.value = ret
            output = s.parent.dup
            output.children.remove
            @log.add("Anchors", s.parent,
                     "normalised identifier in #{output} from #{orig}")
          end
        end
      end

      def xreftarget_cleanup(elem)
        elem.xpath("//xref/@target").each do |s|
          if (ret = to_xreftarget(s.value)) != (orig = s.value)
            s.value = ret
            output = s.parent.dup
            output.children.remove
            @log.add("Anchors", s.parent,
                     "normalised identifier in #{output} from #{orig}")
          end
        end
      end

      def guid?(str)
        /^_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
          .match?(str)
      end

      def contenthash_id_cleanup(doc)
        ids = contenthash_id_make(doc)
        contenthash_id_update_refs(doc, ids)
      end

      def contenthash_id_make(doc)
        doc.xpath("//*[@id]").each_with_object({}) do |x, m|
          next unless guid?(x["id"])

          m[x["id"]] = contenthash(x)
          x["id"] = m[x["id"]]
        end
      end

      def contenthash_id_update_refs(doc, ids)
        [%w(review from), %w(review to), %w(callout target), %w(eref bibitemid),
         %w(citation bibitemid), %w(xref target), %w(xref to)].each do |a|
          doc.xpath("//#{a[0]}").each do |x|
            ids[x[a[1]]] and x[a[1]] = ids[x[a[1]]]
          end
        end
      end

      def contenthash(elem)
        Digest::MD5.hexdigest("#{elem.path}////#{elem.text}")
          .sub(/^(.{8})(.{4})(.{4})(.{4})(.{12})$/, "_\\1-\\2-\\3-\\4-\\5")
      end
    end
  end
end
