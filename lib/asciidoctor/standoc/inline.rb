require "asciidoctor/extensions"
require "htmlentities"
require "unicode2latex"
require "mime/types"
require "base64"

module Asciidoctor
  module Standoc
    module Inline
      def refid?(x)
        @refids.include? x
      end

      def inline_anchor(node)
        case node.type
        when :ref
          inline_anchor_ref node
        when :xref
          inline_anchor_xref node
        when :link
          inline_anchor_link node
        when :bibref
          inline_anchor_bibref node
        end
      end

      def inline_anchor_ref(node)
        noko do |xml|
          xml.bookmark nil, **attr_code(id: node.id)
        end.join
      end

      def inline_anchor_xref(node)
        matched = /^fn(:\s*(?<text>.*))?$/.match node.text
        f = matched.nil? ? "inline" : "footnote"
        c = matched.nil? ? node.text : matched[:text]
        t = node.target.gsub(/^#/, "").gsub(%r{(\.xml|\.adoc)(#.*$)}, "\\2")
        noko do |xml|
          xml.xref **attr_code(target: t, type: f) do |x|
            x << c
          end
        end.join
      end

      def inline_anchor_link(node)
        contents = node.text
        contents = "" if node.target.gsub(%r{^mailto:}, "") == node.text
        attributes = { "target": node.target, "alt": node.attr("title") }
        noko do |xml|
          xml.link **attr_code(attributes) do |l|
            l << contents
          end
        end.join
      end

      def inline_anchor_bibref(node)
        eref_contents = (node.text || node.target || node.id)&.
          sub(/^\[?([^\[\]]+?)\]?$/, "[\\1]")
        eref_attributes = { id: node.target || node.id }
        @refids << (node.target || node.id)
        noko do |xml|
          xml.ref **attr_code(eref_attributes) do |r|
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
          xml.fn **{ reference: @fn_number } do |fn|
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
        noko { |xml| xml.pagebreak **attr_code(attrs)}.join
      end

      def thematic_break(_node)
        noko { |xml| xml.hr }.join
      end

      def xml_encode(text)
        HTMLEntities.new.encode(text, :basic, :hexadecimal).
          gsub(/&amp;gt;/, ">").gsub(/\&amp;lt;/, "<").gsub(/&amp;amp;/, "&").
          gsub(/&gt;/, ">").gsub(/&lt;/, "<").gsub(/&amp;/, "&").
          gsub(/&quot;/, '"').gsub(/&#xa;/, "\n")
      end

      def stem_parse(text, xml, style)
        if /&lt;([^:>&]+:)?math(\s+[^>&]+)?&gt; |
          <([^:>&]+:)?math(\s+[^>&]+)?>/x.match text
          math = xml_encode(text)
          xml.stem math, **{ type: "MathML" }
        elsif style == :latexmath
          latex_cmd = Metanorma::Standoc::Requirements[:latexml].cmd
          latexmlmath_input =
            Unicode2LaTeX::unicode2latex(HTMLEntities.new.decode(text)).
            gsub(/'/, '\\').gsub(/\n/, " ")
          latex = IO.popen(latex_cmd, "r+", external_encoding: "UTF-8") do |io|
            io.write(latexmlmath_input)
            io.close_write
            io.read
          end
          xml.stem **{ type: "MathML" } do |s|
            s << latex.sub(/<\?[^>]+>/, "")
          end
        else
          xml.stem text, **{ type: "AsciiMath" }
        end
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
          else
            case node.role
              # the following three are legacy, they are now handled by macros
            when "alt" then xml.admitted { |a| a << node.text }
            when "deprecated" then xml.deprecates { |a| a << node.text }
            when "domain" then xml.domain { |a| a << node.text }

            when "strike" then xml.strike { |s| s << node.text }
            when "smallcap" then xml.smallcap { |s| s << node.text }
            when "keyword" then xml.keyword { |s| s << node.text }
            else
              xml << node.text
            end
          end
        end.join
      end

      def datauri(uri)
        return uri if /^data:/.match(uri)
        types = MIME::Types.type_for(@localdir + uri)
        type = types ? types.first.to_s : 'text/plain; charset="utf-8"'
        path = File.file?(uri) ? uri : @localdir + uri
        bin = File.open(path, 'rb') {|io| io.read}
        data = Base64.strict_encode64(bin)
        "data:#{type};base64,#{data}"
      end

      def image_attributes(node)
        uri = node.image_uri (node.attr("target") || node.target)
        types = /^data:/.match(uri) ? datauri2mime(uri) : MIME::Types.type_for(uri)
        type = types.first.to_s
        uri = uri.sub(%r{^data:image/\*;}, "data:#{type};")
        attr_code(src: @datauriimage ? datauri(uri) : uri,
          id: Utils::anchor_or_uuid,
          mimetype: type,
          height: node.attr("height") || "auto",
          width: node.attr("width") || "auto" ,
          filename: node.attr("filename"),
          title: node.attr("titleattr"),
          alt: node.alt == node.attr("default-alt") ? nil : node.alt)
      end

      def inline_image(node)
        noko do |xml|
          xml.image **(image_attributes(node))
        end.join("")
      end

      def inline_indexterm(node)
        noko do |xml|
          node.type == :visible and xml << node.text
          terms = node.attr("terms") ||
            [Nokogiri::XML("<a>#{node.text}</a>").xpath("//text()").text]
          xml.index nil, **attr_code(primary: terms[0],
                                     secondary: terms.dig(1),
                                     tertiary: terms.dig(2))
        end.join
      end
    end
  end
end
