require "asciidoctor/extensions"
require "fileutils"
require "uuidtools"
require "yaml"
require "csv"
require_relative "./macros_plantuml"
require_relative "./macros_terms"
require_relative "./macros_form"
require_relative "./macros_note"
require_relative "./datamodel/attributes_table_preprocessor"
require_relative "./datamodel/diagram_preprocessor"
require "metanorma-plugin-datastruct"
require "metanorma-plugin-lutaml"

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
        ret = "<index-xref also='#{target == 'also'}'>"\
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

    class PseudocodeBlockMacro < Asciidoctor::Extensions::BlockProcessor
      use_dsl
      named :pseudocode
      on_context :example, :sourcecode

      def init_indent(line)
        /^(?<prefix>[ \t]*)(?<suffix>.*)$/ =~ line
        prefix = prefix.gsub(/\t/, "\u00a0\u00a0\u00a0\u00a0")
          .gsub(/ /, "\u00a0")
        prefix + suffix
      end

      def supply_br(lines)
        ignore = false
        lines.each_with_index do |l, i|
          /^(--+|====+|\|===|\.\.\.\.+|\*\*\*\*+|\+\+\+\++|````+|____\+)$/
            .match(l) && (ignore = !ignore)
          next if l.empty? || l.match(/ \+$/) || /^\[.*\]$/.match?(l) || ignore
          next if i == lines.size - 1 ||
            i < lines.size - 1 && lines[i + 1].empty?

          lines[i] += " +"
        end
        lines
      end

      def process(parent, reader, attrs)
        attrs["role"] = "pseudocode"
        lines = reader.lines.map { |m| init_indent(m) }
        create_block(parent, :example, supply_br(lines),
                     attrs, content_model: :compound)
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

        "<ruby>#{target}<rp>#{rpbegin}</rp><rt>#{rt}</rt>"\
          "<rp>#{rpend}</rp></ruby>"
      end
    end

    class AutonumberInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :autonumber
      parse_content_as :text

      def process(parent, target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<autonumber type=#{target}>#{out}</autonumber>}
      end
    end

    class VariantInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :lang
      parse_content_as :text

      def process(parent, target, attrs)
        /^(?<lang>[^-]*)(-(?<script>.*))?$/ =~ target
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        if script
          %{<variant lang=#{lang} script=#{script}>#{out}</variant>}
        else
          %{<variant lang=#{lang}>#{out}</variant>}
        end
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

    class PassInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :"pass-format"

      def process(parent, target, attrs)
        format = target || "metanorma"
        out = Asciidoctor::Inline.new(parent, :quoted, attrs[1]).convert
        %{<passthrough formats="#{format}">#{out}</passthrough>}
      end
    end
  end
end
