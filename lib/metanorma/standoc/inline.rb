require "asciidoctor/extensions"
require "unicode2latex"
require "mime/types"
require "base64"
require "English"
require "plurimath"

module Metanorma
  module Standoc
    module Inline
      def refid?(ref)
        @refids.include? ref
      end

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
        { target: target,
          type: match[:fn].nil? ? "inline" : "footnote",
          case: match[:case]&.sub(/%$/, ""),
          style: match[:style]&.sub(/^style=/, "")&.sub(/%$/, "") || @xrefstyle,
          droploc: match[:drop].nil? && match[:drop2].nil? ? nil : true,
          text: inline_anchor_xref_text(match, text),
          hidden: match[:hidden] }
      end

      def inline_anchor_xref_match(text)
        /^(?:hidden%(?<hidden>[^,]+),?)?
          (?<style>style=[^%]+%)?
          (?<drop>droploc%)?(?<case>capital%|lowercase%)?(?<drop2>droploc%)?
          (?<fn>fn:?\s*)?(?<text>.*)$/x.match text
      end

      def inline_anchor_xref_text(match, text)
        if %i[case fn drop drop2 hidden style].any? do |x|
             !match[x].nil?
           end
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

      def inline_break(node)
        noko do |xml|
          xml << node.text
          xml.br
        end.join
      end

      def page_break(node)
        attrs = {}
        node.option?("landscape") and attrs[:orientation] = "landscape"
        node.option?("portrait") and attrs[:orientation] = "portrait"
        noko { |xml| xml.pagebreak **attr_code(attrs) }.join
      end

      def thematic_break(_node)
        noko { |xml| xml.hr }.join
      end

      def latex_parse1(text)
        lxm_input = Unicode2LaTeX.unicode2latex(@c.decode(text))
        results = Plurimath::Math.parse(lxm_input, "latex").to_mathml
        if results.nil?
          @log.add("Math", nil,
                   "latexmlmath failed to process equation:\n#{lxm_input}")
          return
        end
        results.sub(%r{<math ([^>]+ )?display="block"}, "<math \\1")
      end

      def stem_parse(text, xml, style)
        if /&lt;([^:>&]+:)?math(\s+[^>&]+)?&gt; |
          <([^:>&]+:)?math(\s+[^>&]+)?>/x.match? text
          math = xml_encode(text)
          xml.stem type: "MathML" do |s|
            s << math
          end
        elsif style == :latexmath then latex_parse(text, xml)
        else
          xml.stem text&.gsub(/&amp;#/, "&#"), type: "AsciiMath"
        end
      end

      def latex_parse(text, xml)
        latex = latex_parse1(text) or return xml.stem type: "MathML"
        xml.stem type: "MathML" do |s|
          math = Nokogiri::XML.fragment(latex.sub(/<\?[^>]+>/, ""))
            .elements[0]
          math.delete("alttext")
          s.parent.children = math
          s << "<latexmath>#{text}</latexmath>"
        end
      end

      def highlight_parse(text, xml)
        xml << text
      end

      def inline_quoted(node)
        noko do |xml|
          case node.type
          when :emphasis then xml.em { |s| s << node.text }
          when :strong then xml.strong { |s| s << node.text }
          when :monospaced then xml.tt { |s| s << node.text }
          when :double then xml << "\"#{node.text}\""
          when :single then xml << "'#{node.text}'"
          when :superscript then xml.sup { |s| s << node.text }
          when :subscript then xml.sub { |s| s << node.text }
          when :asciimath then stem_parse(node.text, xml, :asciimath)
          when :latexmath then stem_parse(node.text, xml, :latexmath)
          when :mark then highlight_parse(node.text, xml)
          else
            case node.role
              # the following three are legacy, they are now handled by macros
            when "alt"
              term_designation(xml, node, "admitted", node.text)
            when "deprecated"
              term_designation(xml, node, "deprecates", node.text)
            when "domain" then xml.domain { |a| a << node.text }

            when "strike" then xml.strike { |s| s << node.text }
            when "underline" then xml.underline { |s| s << node.text }
            when "smallcap" then xml.smallcap { |s| s << node.text }
            when "keyword" then xml.keyword { |s| s << node.text }
            when /^css /
              xml.span style: node.role.sub(/^css /, "") do |s|
                s << node.text
              end
            else
              xml << node.text
            end
          end
        end.join
      end

      def image_attributes(node)
        nodetarget = node.attr("target") || node.target
        if Gem.win_platform? && /^[a-zA-Z]:/.match?(nodetarget)
          nodetarget.prepend("/")
        end
        uri = node.image_uri (nodetarget)
        if Gem.win_platform? && /^\/[a-zA-Z]:/.match?(uri)
          uri = uri[1..-1]
        end
        types = if /^data:/.match?(uri) then Metanorma::Utils::datauri2mime(uri)
                else MIME::Types.type_for(uri)
                end
        type = types.first.to_s
        uri = uri.sub(%r{^data:image/\*;}, "data:#{type};")
        image_attributes1(node, uri, type)
      end

      def image_attributes1(node, uri, type)
        attr_code(src: uri,
                  id: Metanorma::Utils::anchor_or_uuid,
                  mimetype: type,
                  height: node.attr("height") || "auto",
                  width: node.attr("width") || "auto",
                  filename: node.attr("filename"),
                  title: node.attr("titleattr"),
                  alt: node.alt == node.attr("default-alt") ? nil : node.alt)
      end

      def inline_image(node)
        noko do |xml|
          xml.image **image_attributes(node)
        end.join
      end

      def inline_indexterm(node)
        noko do |xml|
          node.type == :visible and xml << node.text
          terms = (node.attr("terms") || [node.text]).map { |x| xml_encode(x) }
          inline_indexterm1(xml, terms)
        end.join
      end

      def inline_indexterm1(xml, terms)
        xml.index do |i|
          i.primary { |x| x << terms[0] }
          a = terms[1] and i.secondary { |x| x << a }
          a = terms[2] and i.tertiary { |x| x << a }
        end
      end
    end
  end
end
