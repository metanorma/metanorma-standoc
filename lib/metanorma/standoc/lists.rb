module Metanorma
  module Standoc
    module Lists
      def li(xml_ul, item)
        xml_ul.li do |xml_li|
          if item.blocks?
            xml_li.p(**attr_code(id_attr(item))) { |t| t << item.text }
            xml_li << item.content
          else
            xml_li.p(**attr_code(id_attr(item))) { |t| t << item.text }
          end
        end
      end

      def ul_li(xml_ul, item)
        xml_ul.li **ul_li_attrs(item) do |xml_li|
          xml_li.p(**attr_code(id_attr(item))) { |t| t << item.text }
          if item.blocks?
            xml_li << item.content
          end
        end
      end

      def ul_attrs(node)
        attr_code(id_attr(node).merge(keep_attrs(node)))
      end

      def ul_li_attrs(node)
        c = node.attr?("checked")
        attr_code(
          uncheckedcheckbox: node.attr?("checkbox") ? !c : nil,
          checkedcheckbox: node.attr?("checkbox") ? c : nil,
        )
      end

      def ulist(node)
        return reference(node) if in_norm_ref? || in_biblio?

        noko do |xml|
          xml.ul **ul_attrs(node) do |xml_ul|
            list_caption(node, xml_ul)
            node.items.each { |item| ul_li(xml_ul, item) }
          end
        end
      end

      def olist_style(style)
        style = style&.to_s
        return "alphabet" if style == "loweralpha"
        return "roman" if style == "lowerroman"
        return "roman_upper" if style == "upperroman"
        return "alphabet_upper" if style == "upperalpha"

        style
      end

      # node.attributes[1] == node.style only if style explicitly set
      # as a positional attribute
      def ol_attrs(node)
        attr_code(id_attr(node).merge(keep_attrs(node)
          .merge(type: olist_style(node.style),
                 start: node.attr("start"),
                 "explicit-type": olist_style(node.attributes[1]))))
      end

      def olist(node)
        noko do |xml|
          xml.ol **ol_attrs(node) do |xml_ol|
            list_caption(node, xml_ol)
            node.items.each { |item| li(xml_ol, item) }
          end
        end
      end

      def dt(terms, xml_dl)
        terms.each_with_index do |dt, idx|
          xml_dl.dt { |xml_dt| xml_dt << dt.text }
          if idx < terms.size - 1
            xml_dl.dd
          end
        end
      end

      def dd(ddefn, xml_dl)
        if ddefn.nil?
          xml_dl.dd
          return
        end
        xml_dl.dd **dl_attrs(ddefn) do |xml_dd|
          xml_dd.p { |t| t << ddefn.text } if ddefn.text?
          xml_dd << ddefn.content if ddefn.blocks?
        end
      end

      def dl_attrs(node)
        attr_code(id_attr(node).merge(keep_attrs(node)
          .merge(
            metadata: node.option?("metadata") ? "true" : nil,
            key: node.option?("key") ? "true" : nil,
          )))
      end

      def dlist(node)
        noko do |xml|
          xml.dl **dl_attrs(node) do |xml_dl|
            list_caption(node, xml_dl)
            node.items.each do |terms, dd|
              dt(terms, xml_dl)
              dd(dd, xml_dl)
            end
          end
        end
      end

      def colist(node)
        noko do |xml|
          node.items.each_with_index do |item, i|
            xml.callout_annotation **attr_code(id: i + 1) do |xml_li|
              xml_li.p { |p| p << item.text }
            end
          end
        end
      end

      def list_caption(node, out)
        block_title(node, out)
      end
    end
  end
end
