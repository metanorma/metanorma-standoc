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
        parent.converter.log.add("STANDOC_3", parent,
                                 params: [target, target, attrs.values.join(",")])
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
        t = if t.include?(",")
              t.sub(/,/, "%")
            else "#{t}%"
            end
        target = attrs["text"].sub(/,.*$/, "").gsub(":", "_") # special char
        create_anchor(parent, "hidden=#{t}", type: :xref, target: target)
      end
    end

    class SourceIncludeInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :source_include

      def process(_parent, target, _attrs)
        "<source-include path='#{target}'/>"
      end
    end
  end
end
