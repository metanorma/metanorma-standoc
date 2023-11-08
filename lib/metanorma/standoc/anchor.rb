require "asciidoctor/extensions"

module Metanorma
  module Standoc
    module Inline
      def inline_anchor(node)
        case node.type
        when :ref then inline_anchor_ref node
        when :xref then inline_anchor_xref node
        when :link then inline_anchor_link node
        when :bibref then inline_anchor_bibref node
        end
      end

      def inline_anchor_ref(node)
        noko do |xml|
          xml.bookmark nil, **attr_code(id: node.id)
        end.join
      end

      def inline_anchor_xref(node)
        noko do |xml|
          attrs = inline_anchor_xref_attrs(node)
          c = attrs[:text]
          attrs.delete(:text) unless c.nil?
          xml.xref **attr_code(attrs) do |x|
            x << c
          end
        end.join
      end

      def inline_anchor_xref_attrs(node)
        text = concatenate_attributes_to_xref_text(node)
        m = inline_anchor_xref_match(text)
        t = node.target.gsub(/^#/, "").gsub(%r{(\.xml|\.adoc)(#.*$)}, "\\2")
        m.nil? and return { target: t, type: "inline", text: text }
        inline_anchor_xref_attrs1(m, t, text)
      end

      def concatenate_attributes_to_xref_text(node)
        node.attributes.each_with_object([]) do |(k, v), m|
          %w(path fragment refid).include?(k) and next
          m << "#{k}=#{v}%"
        end.map { |x| x.sub(/%+/, "%") }.join + (node.text || "")
      end

      def inline_anchor_xref_attrs1(match, target, text)
        { target: target, hidden: match[:hidden],
          type: match[:fn].nil? ? "inline" : "footnote",
          case: match[:case]&.sub(/%$/, ""),
          style: match[:style]&.sub(/^style=/, "")&.sub(/%$/, "") || @xrefstyle,
          droploc: match[:drop].nil? && match[:drop2].nil? ? nil : true,
          text: inline_anchor_xref_text(match, text) }
      end

      def inline_anchor_xref_match(text)
        /^(?:hidden%(?<hidden>[^,]+),?)?
          (?<style>style=[^%]+%)?
          (?<drop>droploc%)?(?<case>capital%|lowercase%)?(?<drop2>droploc%)?
          (?<fn>fn:?\s*)?(?<text>.*)$/x.match text
      end

      def inline_anchor_xref_text(match, text)
        if %i[case fn drop drop2 hidden style].any? { |x| !match[x].nil? }
          match[:text]
        else text
        end
      end

      def inline_anchor_link(node)
        contents = node.text
        contents = "" if node.target.gsub(%r{^mailto:}, "") == node.text
        attributes = { target: node.target, alt: node.attr("title"),
                       "update-type": node.attr("updatetype") ||
                         node.attr("update-type") }
        noko do |xml|
          xml.link **attr_code(attributes) do |l|
            l << contents
          end
        end.join
      end

      def inline_anchor_bibref(node)
        eref_contents =
          @c.decode(node.text || node.target || node.id)
          &.sub(/^\[?([^\[\]]+?)\]?$/, "[\\1]")
        @refids << (node.target || node.id)
        noko do |xml|
          xml.ref **attr_code(id: node.target || node.id) do |r|
            r << eref_contents
          end
        end.join
      end

      def inline_callout(node)
        noko do |xml|
          xml.callout node.text
        end.join
      end

      def inline_footnote(node)
        @fn_number ||= 0
        noko do |xml|
          @fn_number += 1
          xml.fn reference: @fn_number do |fn|
            fn.p { |p| p << node.text }
          end
        end.join
      end
    end
  end
end
