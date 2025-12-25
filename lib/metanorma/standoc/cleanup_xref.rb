require_relative "cleanup_xref_localities"

module Metanorma
  module Standoc
    module Cleanup
      def xref_to_eref(elem, name)
        elem.name = name
        elem["bibitemid"] = elem["target"]
        xref_to_eref1(elem)
        eref_style_normalise(elem)
        elem.delete("target")
        elem.delete("defaultstyle") # xrefstyle default
        extract_localities(elem)
      end

      def xref_to_eref1(elem)
        if ref = @anchors&.dig(elem["target"], :xref)
          t = @anchors.dig(elem["target"], :id, elem["style"]) and ref = t
          elem["citeas"] = @c.decode(ref)
        else
          elem["citeas"] = ""
          @internal_eref_namespaces.include?(elem["type"]) or
            @log.add("STANDOC_30", elem, params: [elem["target"]])
        end
      end

      def eref_style_normalise(elem)
        eref_style_normalise_prep(elem) or return
        s = elem["style"].gsub("-", "_")
        if @isodoc.bibrenderer.citetemplate.template_raw.key?(s.to_sym)
          elem["style"] = s
        elsif s != "short"
          @log.add("STANDOC_60", elem, params: [elem["style"]])
        end
      end

      def eref_style_normalise_prep(elem)
        !elem["style"] && @erefstyle and
          elem["style"] = @erefstyle
        elem["style"] or return
        @anchors.dig(elem["target"], :id, elem["style"]) and return
        # else style is not docidentifier, so it's relaton-render style
        true
      end

      def xref_cleanup(xmldoc)
        anchor_alias(xmldoc)
        xref_compound_cleanup(xmldoc)
        xref_cleanup1(xmldoc)
        xref_compound_wrapup(xmldoc)
        eref_stack(xmldoc)
      end

      def eref_stack(xmldoc)
        xmldoc.xpath("//eref/display-text[eref]").each do |e|
          e.replace(e.children)
        end
        xmldoc.xpath("//eref[eref]").each do |e|
          e.name = "erefstack"
          e.delete("bibitemid")
          e.delete("citeas")
          e.xpath("./eref").each { |e1| e1["type"] = e["type"] }
          e.delete("type")
        end
      end

      def anchor_alias(xmldoc)
        t = xmldoc.at("//metanorma-extension/table[@anchor = " \
                      "'_misccontainer_anchor_aliases']") or return
        key = ""
        t.xpath("./tbody/tr").each do |tr|
          tr.xpath("./td | ./th").each_with_index do |td, i|
            if i.zero? then key = td.text
            else anchor_alias1(key, td)
            end
          end
        end
      end

      def anchor_alias1(key, elem)
        id = elem.text.strip
        id.empty? and elem.at("./link") and
          id = elem.at("./link/@target")&.text
        (key && !id.empty?) or return
        @anchor_alias[id] = key
      end

      def xref_compound_cleanup(xmldoc)
        xmldoc.xpath("//xref").each do |x|
          x["target"].include?(";") or next
          locations = x["target"].split(";")
          x["target"] = locations.first.sub(/^[^!]*!/, "")
          xref_compound_cleanup1(x, locations)
        end
      end

      def xref_compound_cleanup1(xref, locations)
        xref.children.empty? and xref.children = "<sentinel/>"
        xref_parse_compound_locations(locations, xref).reverse_each do |y|
          xref.add_first_child "<xref target='#{y[1]}' connective='#{y[0]}'/>"
        end
        xref&.at("./sentinel")&.remove
      end

      def xref_compound_wrapup(xmldoc)
        xmldoc.xpath("//xref//xref").each do |x|
          x.name = "location"
        end
        xmldoc.xpath("//xref[not(./display-text)]").each do |x|
          c = x.xpath("./*[not(self::locality or self::localityStack or self::location)] | ./text()")
          c.empty? and next
          xref_display_text(x, c.remove)
        end
      end

      def xref_cleanup1(xmldoc)
        xmldoc.xpath("//xref").each do |x|
          %r{:(?!//)}.match?(x["target"]) and xref_to_internal_eref(x)
          x.name == "xref" or next
          if refid? x["target"] then xref_to_eref(x, "eref")
          elsif @anchor_alias[x["target"]] then xref_alias(x)
          else
            x.delete("type")
            xref_default_style(x)
          end
        end
      end

      def xref_to_internal_eref(elem)
        a = elem["target"].split(":", 3)
        unless a.size < 2 || a[0].empty? || a[1].empty?
          elem["target"] = "#{a[0]}_#{a[1]}"
          a.size > 2 and
            elem.children = %{anchor="#{a[2..].join}",#{elem.children&.text}}
          elem["type"] = a[0]
          @internal_eref_namespaces << a[0]
          xref_to_eref(elem, "eref")
        end
      end

      def xref_alias(elem)
        elem["style"] == "id" && elem.text.strip.empty? and
          elem << elem["target"]
        elem["target"] = @anchor_alias[elem["target"]]
        xref_default_style(elem)
      end

      def xref_default_style(elem)
        elem["defaultstyle"] and elem["style"] ||= elem["defaultstyle"]
        elem.delete("defaultstyle")
      end

      def quotesource_cleanup(xmldoc)
        xmldoc.xpath("//quote/source | //terms/source").each do |x|
          xref_to_eref(x, "source")
        end
      end

      def origin_cleanup(xmldoc)
        origin_default_style(xmldoc)
        xmldoc.xpath("//origin/concept[termref]").each do |x|
          x.replace(x.at("./termref"))
        end
        xmldoc.xpath("//origin").each do |x|
          x["citeas"] = @anchors&.dig(x["bibitemid"], :xref) or
            @log.add("STANDOC_32", x, params: [x["bibitemid"]])
          extract_localities(x)
        end
      end

      def origin_default_style(xmldoc)
        @originstyle or return
        xmldoc.xpath("//origin[not(@style)]")
          .each { |e| e["style"] = @originstyle }
      end

      def eref_default_style(xmldoc)
        @erefstyle or return
        xmldoc.xpath("//eref[not(@style)]")
          .each { |e| e["style"] = @erefstyle }
      end

      include ::Metanorma::Standoc::Regex
    end
  end
end
