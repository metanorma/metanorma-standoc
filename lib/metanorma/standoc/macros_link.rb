module Metanorma
  module Standoc
    class IndexXrefInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :index

      def preprocess_attrs(attrs)
        ret = { primary: attrs[1], target: attrs[attrs.size] }
        ret[:secondary] = attrs[2] if attrs.size > 2
        ret[:tertiary] = attrs[3] if attrs.size > 3
        ret
      end

      def validate(parent, target, attrs)
        attrs.size > 1 && attrs.size < 5 and return true
        e = "invalid index \"#{target}\" cross-reference: wrong number of " \
            "attributes in `index:#{target}[#{attrs.values.join(',')}]`"
        parent.converter.log.add("Crossreferences", parent, e, severity: 0)
        false
      end

      def process(parent, target, attr)
        validate(parent, target, attr) or return
        args = preprocess_attrs(attr)
        ret = "<index-xref also='#{target == 'also'}'>" \
              "<primary>#{args[:primary]}</primary>"
        ret += "<secondary>#{args[:secondary]}</secondary>" if args[:secondary]
        ret += "<tertiary>#{args[:tertiary]}</tertiary>" if args[:tertiary]
        ret + "<target>#{args[:target]}</target></index-xref>"
      end
    end

    class IndexRangeInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :"index-range"
      parse_content_as :text

      def process(parent, target, attr)
        text = attr["text"]
        text = "((#{text}))" unless /^\(\(.+\)\)$/.match?(text)
        out = parent.sub_macros(text)
        out.sub("<index>", "<index to='#{target}'>")
      end
    end

    class ToCInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :toc
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        content = CSV.parse_line(out).map do |x|
          x.sub!(/^(["'])(.+)\1/, "\\2")
          m = /^(.*?)(:\d+)?$/.match(x)
          %{<toc-xpath depth='#{m[2]&.sub(':', '') || 1}'>#{m[1]}</toc-xpath>}
        end.join
        "<toc>#{content}</toc>"
      end
    end

    class StdLinkInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :"std-link"
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        t = attrs["text"]
        t = if /,/.match?(t)
              t.sub(/,/, "%")
            else
              "#{t}%"
            end
        create_anchor(parent, "hidden=#{t}",
                      type: :xref, target: "_#{UUIDTools::UUID.random_create}")
      end
    end

    class SpanInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :span
      parse_content_as :text

      def process(parent, target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<span class="#{target}">#{out}</span>}
      end
    end

    class NumberInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :number
      parse_content_as :text

      MATHML_NS = "http://www.w3.org/1998/Math/MathML".freeze

      def unquote(str)
        str.sub(/^(["'])(.+)\1$/, "\\2")
      end

      def format(attrs)
        # a="," => "a=,"
        attrs.gsub!(/([a-z]+)="/, %("\\1=))
        (CSV.parse_line(attrs) || []).map do |x|
          m = /^(.+?)=(.+)?$/.match(unquote(x)) or next
          arg = HTMLEntities.new.encode(unquote(m[2]), :hexadecimal)
          "#{m[1]}='#{arg}'"
        end.join(",")
      end

      def number(text)
        n = BigDecimal(text)
        trailing_zeroes = 0
        m = /\.[1-9]*(0+)/.match(text) and trailing_zeroes += m[1].size
        n.to_s("E").sub("e", "0" * trailing_zeroes + "e")
      end

      def process(parent, target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        fmt = format(out)
        fmt.empty? and fmt = "notation='basic'"
        fmt = %( data-metanorma-numberformat="#{fmt}")
        %(<math ns='#{MATHML_NS}'><mn#{fmt}>#{number(target)}</mn></math>)
      end
    end
  end
end
