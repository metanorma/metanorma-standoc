require "asciidoctor/extensions"
require "htmlentities"
require "unicode2latex"

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
        eref_contents = node.target == node.text ? nil : node.text
        eref_attributes = { id: node.target }
        @refids << node.target
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
        end.join("\n")
      end

      def inline_break(node)
        noko do |xml|
          xml << node.text
          xml.br
        end.join("\n")
      end

      def page_break(_node)
        noko { |xml| xml.pagebreak }.join("\n")
      end

      def thematic_break(_node)
        noko { |xml| xml.hr }.join("\n")
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
          latexmlmath_input = Unicode2LaTeX::unicode2latex(text).gsub(/'/, '\\').gsub(/\n/, " ")
          latex = IO.popen('latexmlmath --preload=amsmath  -- -', 'r+', :external_encoding=>'UTF-8') do |io|
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
    end
  end
end
