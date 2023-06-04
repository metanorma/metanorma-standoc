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
        return unless attrs.size > 1 && attrs.size < 5

        ret = { primary: attrs[1], target: attrs[attrs.size] }
        ret[:secondary] = attrs[2] if attrs.size > 2
        ret[:tertiary] = attrs[3] if attrs.size > 3
        ret
      end

      def process(_parent, target, attr)
        args = preprocess_attrs(attr) or return
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
        out.sub(/<index>/, "<index to='#{target}'>")
      end
    end

    class HTML5RubyMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :ruby
      parse_content_as :text
      option :pos_attrs, %w(rpbegin rt rpend)

      # for example, html5ruby:楽聖少女[がくせいしょうじょ]
      def process(_parent, target, attributes)
        rpbegin = "("
        rpend = ")"
        if (attributes.size == 1) && attributes.key?("text")
          rt = attributes["text"]
        elsif (attributes.size == 2) && attributes.key?(1) &&
            attributes.key?("rpbegin")
          rt = attributes[1] || ""
        else
          rpbegin = attributes["rpbegin"]
          rt = attributes["rt"]
          rpend = attributes["rpend"]
        end

        "<ruby>#{target}<rp>#{rpbegin}</rp><rt>#{rt}</rt>" \
          "<rp>#{rpend}</rp></ruby>"
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
          %{<toc-xpath depth='#{m[2]&.sub(/:/, '') || 1}'>#{m[1]}</toc-xpath>}
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
