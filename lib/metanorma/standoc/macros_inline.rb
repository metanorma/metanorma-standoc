require_relative "utils"

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
      include ::Metanorma::Standoc::Utils

      use_dsl
      named :number
      parse_content_as :text

      MATHML_NS = "http://www.w3.org/1998/Math/MathML".freeze

      def unquote(str)
        str.sub(/^(["'])(.+)\1$/, "\\2")
      end

      def format(attrs)
        # a="," => "a=,"
        quoted_csv_split(attrs || "", ",").map do |x|
          m = /^(.+?)=(.+)?$/.match(x) or next
          "#{m[1]}='#{m[2]}'"
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
        <<~OUTPUT
          <stem type="MathML"><math xmlns='#{MATHML_NS}'><mn#{fmt}>#{number(target)}</mn></math></stem>
        OUTPUT
      end
    end
  end
end
