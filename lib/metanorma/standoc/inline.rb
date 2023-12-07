require "unicode2latex"
require "mime/types"
require "base64"
require "English"
require "plurimath"

module Metanorma
  module Standoc
    module Inline
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

      def latex_parse1(text, block)
        lxm_input = Unicode2LaTeX.unicode2latex(@c.decode(text))
        results = Plurimath::Math.parse(lxm_input, "latex")
          .to_mathml(display_style: block)
        if results.nil?
          @log.add("Math", nil,
                   "latexmlmath failed to process equation:\n#{lxm_input}",
                   severity: 1)
          return
        end
        results.sub(%r{<math ([^>]+ )?display="block"}, "<math \\1")
      end

      def stem_parse(text, xml, style, block)
        if /&lt;([^:>&]+:)?math(\s+[^>&]+)?&gt; |
          <([^:>&]+:)?math(\s+[^>&]+)?>/x.match? text
          math = xml_encode(text)
          xml.stem type: "MathML", block: block do |s|
            s << math
          end
        elsif style == :latexmath then latex_parse(text, xml, block)
        else
          xml.stem text&.gsub("&amp;#", "&#"), type: "AsciiMath", block: block
        end
      end

      def latex_parse(text, xml, block)
        latex = latex_parse1(text, block) or
          return xml.stem type: "MathML", block: block
        xml.stem type: "MathML", block: block do |s|
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
          when :asciimath then stem_parse(node.text, xml, :asciimath, false)
          when :latexmath then stem_parse(node.text, xml, :latexmath, false)
          when :mark then highlight_parse(node.text, xml)
          else
            case node.role
              # the following three are legacy, they are now handled by macros
            when "alt"
              term_designation(xml, node, "admitted", node.text)
            when "deprecated"
              term_designation(xml, node, "deprecates", node.text)
            when "domain", "strike", "underline", "smallcap", "keyword"
              xml.send(node.role) { |s| s << node.text }
            when /^css /
              xml.span style: node.role.sub(/^css /, "") do |s|
                s << node.text
              end
            when /:/
              xml.span **attr_code(hash2styles(node.role)) do |s|
                s << node.text
              end
            else
              xml << node.text
            end
          end
        end.join
      end

      def hash2styles(role)
        CSV.parse_line(role, liberal_parsing: true)
          .each_with_object({}) do |r, m|
          kv = r.split(":", 2).map(&:strip)
          case kv[0]
          when "custom-charset"
            m[kv[0]] = kv[1]
          end
        end
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
        attr_code(src: uri, mimetype: type,
                  id: Metanorma::Utils::anchor_or_uuid,
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
