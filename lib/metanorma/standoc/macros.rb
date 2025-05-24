require "uuidtools"
require "yaml"
require "csv"
require_relative "macros_inline"
require_relative "macros_plantuml"
require_relative "macros_terms"
require_relative "macros_form"
require_relative "macros_note"
require_relative "macros_embed"
require_relative "macros_link"
require_relative "datamodel/attributes_table_preprocessor"
require_relative "datamodel/diagram_preprocessor"
require "metanorma-plugin-glossarist"
require "metanorma-plugin-lutaml"

module Metanorma
  module Standoc
    class PseudocodeBlockMacro < Asciidoctor::Extensions::BlockProcessor
      use_dsl
      named :pseudocode
      on_context :example, :sourcecode

      def init_indent(line)
        /^(?<prefix>[ \t]*)(?![ \t])(?<suffix>.*)$/ =~ line
        prefix = prefix.gsub("\t", "\u00a0\u00a0\u00a0\u00a0")
          .tr(" ", "\u00a0")
        prefix + suffix
      end

      def supply_br(lines)
        ignore = false
        lines.each_with_index do |l, i|
          /^(--+|====+|\|===|\.\.\.\.+|\*\*\*\*+|\+\+\+\++|````+|____\+)$/
            .match(l) and (ignore = !ignore)
          next if l.empty? || l.match(/ \+$/) || /^\[.*\]$/.match?(l) ||
            ignore || i == lines.size - 1 ||
            (i < lines.size - 1 && lines[i + 1].empty?)

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

    class NamedEscapePreprocessor < Asciidoctor::Extensions::Preprocessor
      def process(document, reader)
        c = HTMLEntities.new
        p = Metanorma::Utils::LineStatus.new
        lines = reader.lines.map do |l|
          p.process(l)
          p.pass ? l : convert(l, c)
        end
        ::Asciidoctor::PreprocessorReader.new document, lines
      end

      def convert(line, esc)
        line.split(/(&[A-Za-z][^&;]*;)/).map do |s|
          /^&[A-Za-z]/.match?(s) ? esc.encode(esc.decode(s), :hexadecimal) : s
        end.join
      end
    end

    class ColumnBreakBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
      use_dsl
      named :columnbreak

      def process(parent, _reader, _attrs)
        create_pass_block parent, "<columnbreak/>", {}, subs: nil
      end
    end

    # refer https://github.com/asciidoctor/asciidoctor/blob/main/lib/asciidoctor/substitutors.rb
    # Not using TreeProcessor because that is still too close to
    # inline expressions being processed on access (e.g. titles)
    class LinkProtectPreprocessor < Asciidoctor::Extensions::Preprocessor
      def process(document, reader)
        p = Metanorma::Utils::LineStatus.new
        lines = reader.lines.map do |t|
          p.process(t)
          !p.pass && t.include?(":") and t = inlinelinkmacro(inlinelink(t))
          t
        end
        ::Asciidoctor::PreprocessorReader.new document, lines
      end

      PASS_INLINE_MACROS = %w(pass pass-format identifier std-link stem)
        .join("|").freeze

      PASS_INLINE_MACRO_STR = <<~REGEX.freeze
        (
          \\b(?<![-\\\\])                        # word-separator, no hyphen or backslash
          (?:                                    # don't capture these!
            (?:#{PASS_INLINE_MACROS}):[^\\s\\[]* | # macro name, :, second key. OR:
            span:uri \\b [^\\s\\[]*              # span:uri, third key
          )
          \\[.*?(?<!\\\\)\\]                     # [ ... ] not preceded by \\
        )
      REGEX
      PASS_INLINE_MACRO_RX = /#{PASS_INLINE_MACRO_STR}/xo

      def pass_inline_split(text)
        text.split(PASS_INLINE_MACRO_RX).each.map do |x|
          PASS_INLINE_MACRO_RX.match?(x) ? x : yield(x)
        end
      end

      # InlineLinkRx = %r((^|link:|#{CG_BLANK}|&lt;|[>\(\)\[\];"'])(\\?(?:https?|file|ftp|irc)://)(?:([^\s\[\]]+)\[(|#{CC_ALL}*?[^\\])\]|([^\s\[\]<]*([^\s,.?!\[\]<\)]))))m
      #
      InlineLinkRx = %r((^|(?<![-\\])\blink:(?!\+)|\p{Blank}|&lt;|[<>\(\)\[\];"'])((?:https?|file|ftp|irc)://)(?:([^\s\[\]]+)(?:(\[(|.*?[^\\])\])|([^\s\[\]<]*([^\s,.?!\[\]<\)])))))m

      def inlinelink(text)
        text.include?("://") or return text
        /^\[.*\]\s*$/.match?(text) and return text
        pass_inline_split(text) do |x|
          inlinelink_escape(x)
        end.join
      end

      def inlinelink_escape(text)
        text.gsub(InlineLinkRx) do
          p = $1 and s = $2 and body = $3
          suffix = $4.nil? ? "[]" : ""
          wrapper = $6
          if (!/^(&lt;|[<\(\["'])$/.match?($1) || $6 != BRACKETS[$1]) && $4.nil?
            body += $6
            wrapper = ""
          end
          # body, suffix = $4.nil? ? [$3 + $6, "[]"] : [$3, ""]
          b = linkcontents_escape($4)
          if p == "link:"
            "#{p}++#{s}#{body}++#{b}#{suffix}"
          else
            "#{p}link:++#{s}#{body}++#{b}#{suffix}#{wrapper}"
          end
        end
      end

      BRACKETS = {
        "<" => ">",
        "&lt;" => "&gt;",
        "[" => "]",
        '"' => '"',
        "'" => "'",
      }.freeze

      # because links are escaped, https within link text also need
      # to be escaped, # otherwise they will be treated as links themselves
      def linkcontents_escape(text)
        text.nil? and return nil
        text
          # .gsub(InlineLinkMacroRx) do
          # $1.empty? ? "\\#{$2}#{$3}#{$4}" : text
          # end
          .gsub(InlineLinkRx) do
          esc = $1 == "link:" ? "" : "\\"
          x = $4 || "#{$5}#{$6}"
          "#{$1}#{esc}#{$2}#{$3}#{x}"
        end
      end

      # InlineLinkMacroRx = /\\?(?:link|(mailto)):(|[^:\s\[][^\s\[]*)\[(|#{CC_ALL}*?[^\\])\]/m
      InlineLinkMacroRx1 = <<~REGEX.freeze
        (\\\\?)(\\b(?<!-)                  # optional backslash, no hyphen, word boundary
          (?:link|mailto):)              # link: or mailto:
        (?!\\+)                          # no link:+ passthrough
        (|[^:\\s\\[][^\\s\\[]*)          # link: ... up to [
        (\\[(|.*?[^\\\\])\\])            # [ ... ], no ]
      REGEX
      InlineLinkMacroRx = /#{InlineLinkMacroRx1}/x

      def inlinelinkmacro(text)
        (text.include?("[") &&
          ((text.include? "link:") || (text.include? "ilto:"))) or return text
        pass_inline_split(text) do |x|
          x.gsub(InlineLinkMacroRx) do
            "#{$1}#{$2}++#{$3}++#{linkcontents_escape($4)}"
          end
        end.join
      end
    end
  end
end
