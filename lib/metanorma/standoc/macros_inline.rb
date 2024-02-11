module Metanorma
  module Standoc
    class InheritInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :inherit
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<inherit>#{out}</inherit>}
      end
    end

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
        parent.converter.log.add("Index", parent, e, severity: 0)
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

    class HTML5RubyMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :ruby
      parse_content_as :text

      # ruby:{annotation}[lang=ja,script=Hira,type=pronunciation|annotation,text]

      def preprocess_attrs(text)
        ret = {}
        while m = /^(?<key>lang|script|type)=(?<val>[^,]+),(?<rest>.+)$/
            .match(text)
          text = m[:rest]
          ret[m[:key].to_sym] = m[:val]
        end
        ret[:text] = text
        ret[:type] ||= "pronunciation"
        ret[:type] == "annotation" or ret[:type] = "pronunciation"
        ret
      end

      def process(parent, target, attributes)
        args = preprocess_attrs(attributes["text"])
        out = Nokogiri::XML(
          create_block(parent, :paragraph, [args[:text]], {},
                       subs: [:macros], content_model: :simple).convert,
        ).root.children.to_xml # force recurse macros
        attrs = " value='#{target}'"
        x = args[:lang] and attrs += " lang='#{x}'"
        x = args[:script] and attrs += " script='#{x}'"
        "<ruby><#{args[:type]} #{attrs}/>#{out}</ruby>"
      end
    end

    class AutonumberInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :autonumber
      parse_content_as :text

      def process(parent, target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<autonumber type='#{target}'>#{out}</autonumber>}
      end
    end

    class VariantInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :lang
      parse_content_as :text

      def process(parent, target, attrs)
        /^(?<lang>[^-]*)(?:-(?<script>.*))?$/ =~ target
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        if script
          %{<variant lang='#{lang}' script='#{script}'>#{out}</variant>}
        else
          %{<variant lang='#{lang}'>#{out}</variant>}
        end
      end
    end

    class DateInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :date
      using_format :short

      def process(_parent, _target, attrs)
        format = "%F"
        attrs.size >= 2 and format = attrs[2]
        %{<date format='#{format}' value='#{attrs[1]}'/>}
      end
    end

    class AddMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :add
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<add>#{out}</add>}
      end
    end

    class DelMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :del
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<del>#{out}</del>}
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

    # inject ZWNJ to prevent Asciidoctor from attempting regex substitutions
    class PassInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :"pass-format"

      def process(parent, target, attrs)
        format = target || "metanorma"
        out = Asciidoctor::Inline.new(parent, :quoted, attrs[1]).convert
          .gsub(/((?![<>&])[[:punct:]])/, "\\1&#x200c;")
        %{<passthrough-inline formats="#{format}">#{out}</passthrough-inline>}
      end
    end

    class IdentifierInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :identifier
      parse_content_as :raw
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
          .gsub(/((?![<>&])[[:punct:]])/, "\\1&#x200c;")
        %{<identifier>#{out}</identifier>}
      end
    end

    class StdLinkInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :"std-link"
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        create_anchor(parent, "hidden%#{attrs['text']}",
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
  end
end
