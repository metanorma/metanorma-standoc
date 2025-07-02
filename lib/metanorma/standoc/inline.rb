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
        end
      end

      def pass(node)
        "<passthrough-inline formats='metanorma'>#{node.content}</passthrough-inline>"
      end

      def page_break(node)
        attrs = {}
        node.option?("landscape") and attrs[:orientation] = "landscape"
        node.option?("portrait") and attrs[:orientation] = "portrait"
        noko { |xml| xml.pagebreak **attr_code(attrs) }
      end

      def thematic_break(_node)
        # noko(&:hr).join # Do not do this, noko blows up
        noko { |xml| xml.hr } # rubocop:disable Style/SymbolProc
      end

      def latex_parse1(text, block)
        lxm_input = @c.decode(text)
        results = Plurimath::Math.parse(lxm_input, "latex")
          .to_mathml(display_style: block)
        if results.nil?
          @log.add("Maths", nil,
                   "latexmlmath failed to process equation:\n#{lxm_input}",
                   severity: 1)
          return
        end
        results.sub(%r{<math ([^>]+ )?display="block"}, "<math \\1")
      end

      def stem_parse(text, xml, style, node)
        attrs, text = stem_attrs(node, text)
        if /&lt;([^:>&]+:)?math(\s+[^>&]+)?&gt; |
          <([^:>&]+:)?math(\s+[^>&]+)?>/x.match? text
          xml.stem **attrs.merge(type: "MathML") do |s|
            s << xml_encode(text)
          end
        elsif style == :latexmath then latex_parse(text, xml, attrs)
        else
          xml.stem text&.gsub("&amp;#", "&#"), **attrs.merge(type: "AsciiMath")
        end
      end

      STEM_ATTRS = "number-format".freeze

      def stem_attrs(node, text)
        attrs = STEM_ATTRS.split("|").each_with_object({}) do |k, m|
          n = node.attr(k) and m[k.to_sym] = n
        end
        while m = /^(#{STEM_ATTRS})(=[^%]+)?%(.*)$/o.match(text)
          text = m[3]
          attrs[m[1].to_sym] = m[2]&.sub(/^=/, "")
        end
        [{ block: node.block? }.merge(attrs), text]
      end

      def latex_parse(text, xml, attr)
        latex = latex_parse1(text, attr[:block]) or
          return xml.stem **attr.merge(type: "MathML")
        xml.stem **attr.merge(type: "MathML") do |s|
          math = Nokogiri::XML.fragment(latex.sub(/<\?[^>]+>/, ""))
            .elements[0]
          math.delete("alttext")
          s.parent.children = math
          s << "<latexmath>#{text}</latexmath>"
        end
      end

      def highlight_parse(text, xml)
        xml.span **{ class: "fmt-hi" } do |s|
          s << text
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
          when :asciimath then stem_parse(node.text, xml, :asciimath, node)
          when :latexmath then stem_parse(node.text, xml, :latexmath, node)
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
        end
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

      def image_mimetype(uri)
        types = if /^data:/.match?(uri) then Vectory::Utils::datauri2mime(uri)
                else MIME::Types.type_for(uri)
                end
        types.first.to_s
      end

      def image_attributes(node)
        sourceuri = image_src_uri(node)
        uri = sourceuri
        type = image_mimetype(uri)
        uri = uri.sub(%r{^data:image/\*;}, "data:#{type};")
        image_attributes1(node, uri, sourceuri, type)
      end

      def image_src_uri(node)
        nodetarget = node.attr("target") || node.target
        if Gem.win_platform? && /^[a-zA-Z]:/.match?(nodetarget)
          nodetarget.prepend("/")
        end
        uri = node.image_uri(nodetarget)
        if Gem.win_platform? && /^\/[a-zA-Z]:/.match?(uri)
          uri = uri[1..]
        end
        uri
      end

      def image_attributes1(node, uri, sourceuri, type)
        /^data:/.match?(sourceuri) and sourceuri = nil
        attr_code(id_attr(node)
          .merge(src: uri, mimetype: type,
                 height: node.attr("height") || "auto",
                 width: node.attr("width") || "auto",
                 filename: node.attr("filename") || sourceuri,
                 title: node.attr("titleattr"),
                 alt: node.alt == node.attr("default-alt") ? nil : node.alt))
      end

      def inline_image(node)
        noko do |xml|
          xml.image **image_attributes(node)
        end
      end

      def inline_indexterm(node)
        noko do |xml|
          node.type == :visible and xml << node.text
          terms = (node.attr("terms") || [node.text]).map { |x| xml_encode(x) }
          inline_indexterm1(xml, terms)
        end
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
