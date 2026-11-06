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
          xml.bookmark nil, **attr_code(id_attr(node))
        end
      end

      def inline_anchor_xref(node)
        noko do |xml|
          attrs = inline_anchor_xref_attrs(node)
          c = attrs[:text]
          attrs.delete(:text) unless c.nil?
          xml.xref **attr_code(attrs) do |x|
            x << c
          end
        end
      end

      def inline_anchor_xref_attrs(node)
        text = concatenate_attributes_to_xref_text(node)
        t = node.target.gsub(/^#/, "").gsub(%r{(\.xml|\.adoc)(#.*$)}, "\\2")
        attrs, text = inline_anchor_xref_match(text)
        attrs.empty? and
          return { target: t, type: "inline", text:, defaultstyle: @xrefstyle }
        inline_anchor_xref_attrs1(attrs, t, text)
      end

      def concatenate_attributes_to_xref_text(node)
        node.attributes.each_with_object([]) do |(k, v), m|
          %w(path fragment refid).include?(k) and next
          m << "#{k}=#{v}%"
        end.map { |x| x.sub(/%+/, "%") }.join + (node.text || "")
      end

      def inline_anchor_xref_attrs1(attrs, target, text)
        { target:, hidden: attrs["hidden"],
          type: attrs.key?("fn") ? "footnote" : "inline",
          case: %w(capital lowercase).detect { |x| attrs.key?(x) },
          label: attrs["label"],
          style: attrs["style"],
          defaultstyle: @xrefstyle,
          droploc: attrs.key?("droploc") || nil,
          text: }.compact
      end

      XREF_ATTRS = "hidden|style|droploc|capital|lowercase|label".freeze

      def inline_anchor_xref_match(text)
        attrs = {}
        while m = /^(#{XREF_ATTRS})(=[^%]+)?%(.*)$/o.match(text)
          text = m[3]
          attrs[m[1]] = m[2]&.sub(/^=/, "")
        end
        if m = /^(fn:?\s*)(\S.*)?$/.match(text)
          text = m[2]
          attrs["fn"] = ""
        end
        [attrs, text]
      end

      def inline_anchor_xref_text(match, text)
        if %i[case fn drop drop2 hidden style].any? { |x| !match[x].nil? }
          match[:text]
        else text
        end
      end

      def inline_anchor_link(node)
        contents, attributes = inline_anchor_link_attrs(node)
        noko do |xml|
          link_hardbreak_segments(xml, contents, attr_code(attributes))
        end
      end

      # A hard break inside link macro text is a " +" at end of line
      # (asciidoctor HardLineBreakRx). Inline macros are substituted
      # before post-replacements, so the break still arrives here in
      # the raw node text, and the anchor's own markup is already in
      # the paragraph string when sub_post_replacements expands that
      # break: the expansion re-emits the whole preceding line through
      # the break node, and the fragment parse of that line closes the
      # still-open <link> early, leaking the tail as text with an
      # orphaned close (metanorma-pdfa#102). Consume the break here
      # instead: emit one link per break-separated segment, reopening
      # the same target after each break, so no " +" survives into
      # post-replacements and the emitted markup is well-formed.
      HARD_BREAK_RX = / \+\n| \+\z/.freeze

      def link_hardbreak_segments(xml, contents, attributes)
        segs = contents.split(HARD_BREAK_RX, -1)
        if segs.size <= 1
          xml.link **attributes do |l|
            l << contents
          end
          return
        end
        trailing = segs.last.empty?
        segs.pop if trailing
        segs.each_with_index do |seg, i|
          xml.link **attributes do |l|
            l << seg
          end
          last = i == segs.size - 1
          br = !last || trailing
          xml.br if br
          xml << "\n" if br && !last
        end
      end

      def inline_anchor_link_attrs(node)
        contents = node.text
        contents = "" if node.target.gsub(%r{^mailto:}, "") == node.text
        attributes = { target: node.target, alt: node.attr("title"),
                       style: node.attr("style")&.sub(/%$/, ""),
                       "update-type": node.attr("updatetype") ||
                         node.attr("update-type") }
        [contents, attributes]
      end

      def inline_anchor_bibref(node)
        eref_contents = inline_anchor_bibref_contents(node)
        @refids << (node.target || node.id)
        noko do |xml|
          xml.ref **attr_code(id: node.target || node.id) do |r|
            r << eref_contents
          end
        end
      end

      def inline_anchor_bibref_contents(node)
        @c.decode(node.text || node.target || node.id)
          &.sub(/^\[?([^\[\]]+?)\]?$/, "[\\1]")
      end

      def inline_callout(node)
        noko do |xml|
          xml.callout node.text
        end
      end

      def inline_footnote(node)
        @fn_number ||= 0
        noko do |xml|
          @fn_number += 1
          xml.fn **attr_code(id_attr(nil).merge(reference: @fn_number)) do |fn|
            fn.p { |p| p << node.text }
          end
        end
      end
    end
  end
end
