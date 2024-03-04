require "uuidtools"
require "yaml"
require "csv"
require_relative "macros_inline"
require_relative "macros_plantuml"
require_relative "macros_terms"
require_relative "macros_form"
require_relative "macros_note"
require_relative "macros_embed"
require_relative "datamodel/attributes_table_preprocessor"
require_relative "datamodel/diagram_preprocessor"
require "metanorma-plugin-datastruct"
require "metanorma-plugin-glossarist"
require "metanorma-plugin-lutaml"

module Metanorma
  module Standoc
    class PseudocodeBlockMacro < Asciidoctor::Extensions::BlockProcessor
      use_dsl
      named :pseudocode
      on_context :example, :sourcecode

      def init_indent(line)
        /^(?<prefix>[ \t]*)(?<suffix>.*)$/ =~ line
        prefix = prefix.gsub("\t", "\u00a0\u00a0\u00a0\u00a0")
          .gsub(/ /, "\u00a0")
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
      def process(_document, reader)
        c = HTMLEntities.new
        lines = reader.readlines.map do |l|
          l.split(/(&[A-Za-z][^&;]*;)/).map do |s|
            /^&[A-Za-z]/.match?(s) ? c.encode(c.decode(s), :hexadecimal) : s
          end.join
        end
        ::Asciidoctor::Reader.new lines
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
      def init
        pass = true # process as passthrough: init = true until
        # hit end of doc header
        is_delim = false # current line is a no-substititon block delimiter
        pass_delim = false # current line is a passthrough delimiter
        delimln = "" # delimiter line of current block(s);
        # init value looks for end of doc header
        { pass: pass, is_delim: is_delim, pass_delim: pass_delim,
          delimln: delimln }
      end

      def process(_document, reader)
        p = init
        lines = reader.readlines.map do |t|
          p = pass_status(p, t.rstrip)
          !p[:pass] && t.include?(":") and t = inlinelinkmacro(inlinelink(t))
          t
        end
        ::Asciidoctor::Reader.new lines
      end

      def pass_status(status, text)
        text == "++++" && !status[:delimln] and status[:pass] = !status[:pass]
        status[:midline_docattr] && !/^:[^ :]+: /.match?(text) and
          status[:midline_docattr] = false
        if (status[:is_delim] && /^(-+|\*+|=+|_+)$/.match?(text)) ||
            (!status[:is_delim] && !status[:delimln] && text == "----")
          status[:delimln] = text
          status[:pass] = true
        elsif status[:pass_delim]
          status[:delimln] = "" # end of paragraph for paragraph with [pass]
        elsif status[:delimln] && text == status[:delimln]
          status[:pass] = false
          status[:delimln] = nil
        elsif /^:[^ :]+: /.match?(text) &&
            (status[:prev_line].empty? || status[:midline_docattr])
          status[:pass] = true
          status[:midline_docattr] = true
        end
        status[:is_delim] = /^\[(source|listing|literal|pass)\b/.match?(text)
        status[:pass_delim] = /^\[(pass)\b/.match?(text)
        status[:prev_line] = text.strip
        status
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
      PASS_INLINE_MACRO_RX = /#{PASS_INLINE_MACRO_STR}/xo.freeze

      def pass_inline_split(text)
        text.split(PASS_INLINE_MACRO_RX).each.map do |x|
          PASS_INLINE_MACRO_RX.match?(x) ? x : yield(x)
        end
      end

      # InlineLinkRx = %r((^|link:|#{CG_BLANK}|&lt;|[>\(\)\[\];"'])(\\?(?:https?|file|ftp|irc)://)(?:([^\s\[\]]+)\[(|#{CC_ALL}*?[^\\])\]|([^\s\[\]<]*([^\s,.?!\[\]<\)]))))m
      #
      InlineLinkRx = %r((^|(?<![-\\])\blink:(?!\+)|\p{Blank}|&lt;|[<>\(\)\[\];"'])((?:https?|file|ftp|irc)://)(?:([^\s\[\]]+)(?:(\[(|.*?[^\\])\])|([^\s\[\]<]*([^\s,.?!\[\]<\)])))))m.freeze

      def inlinelink(text)
        text.include?("://") or return text
        /^\[.*\]\s*$/.match?(text) and return text
        pass_inline_split(text) do |x|
          inlinelink_escape(x)
        end.join
      end

      def inlinelink_escape(text)
        text.gsub(InlineLinkRx) do
          body, suffix = $4.nil? ? [$3 + $6, "[]"] : [$3, ""]
          p = $1 and s = $2 and b = $4
          if p == "link:" then "#{p}++#{s}#{body}++#{b}#{suffix}"
          elsif p == "<"
            "#{p}link:++#{s}#{body.sub(/>$/, '')}++#{b}#{suffix}>"
          else "#{p}link:++#{s}#{body}++#{b}#{suffix}"
          end
        end
      end

      # InlineLinkMacroRx = /\\?(?:link|(mailto)):(|[^:\s\[][^\s\[]*)\[(|#{CC_ALL}*?[^\\])\]/m
      InlineLinkMacroRx1 = <<~REGEX.freeze
        (\\\\?\\b(?<!-)                  # optional backslash, no hyphen, word boundary
          (?:link|mailto):)              # link: or mailto:
        (?!\\+)                          # no link:+ passthrough
        (|[^:\\s\\[][^\\s\\[]*)          # link: ... up to [
        (\\[(|.*?[^\\\\])\\])            # [ ... ], no ]
      REGEX
      InlineLinkMacroRx = /#{InlineLinkMacroRx1}/x.freeze

      def inlinelinkmacro(text)
        (text.include?("[") &&
          ((text.include? "link:") || (text.include? "ilto:"))) or return text
        pass_inline_split(text) do |x|
          x.gsub(InlineLinkMacroRx) do
            "#{$1}++#{$2}++#{$3}"
          end
        end.join
      end
    end
  end
end
