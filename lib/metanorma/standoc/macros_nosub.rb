module Metanorma
  module Standoc
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
          if (!/^(&lt;|[<(\["'])$/.match?($1) || $6 != BRACKETS[$1]) && $4.nil?
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

    # protect monospace text from character substitutions
    class MonospaceProtectPreprocessor < Asciidoctor::Extensions::Preprocessor
      def process(document, reader)
        p = Metanorma::Utils::LineStatus.new
        lines = reader.lines.map do |t|
          p.process(t)
          !p.pass && t.include?("`") ? inlinemonospace(t) : t
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

      # Regex to match single or double backticks with content
      # Matches: `text` or ``text``
      # Avoids: escaped backticks \`
      MonospaceRx = /(?<!\\)(`{1,2})(.+?)(?<!\\)\1/

      def inlinemonospace(text)
        text.include?("`") or return text
        /^\[.*\]\s*$/.match?(text) and return text
        pass_inline_split(text) do |x|
          monospace_escape(x)
        end.join
      end

      def monospace_escape(text)
        text.gsub(MonospaceRx) do
          backticks = $1
          content = $2
          # Skip if content already starts with ++ (already protected)
          if content.start_with?("++") && content.end_with?("++")
            "#{backticks}#{content}#{backticks}"
          else
            # Protect content from substitutions by wrapping with ++...++
            # Unescape any \] in the content
            protected_content = content.gsub(/\\\]/, "]")
            "#{backticks}++#{protected_content}++#{backticks}"
          end
        end
      end
    end

    # convert pass:[] to pass-format:metanorma[]
    class PassProtectPreprocessor < LinkProtectPreprocessor
      def process(document, reader)
        p = Metanorma::Utils::LineStatus.new
        lines = reader.lines.map do |t|
          p.process(t)
          !p.pass && (t.include?("pass:") || t.include?("pass-format:")) and
            t = inlinelink(t)
          t
        end
        ::Asciidoctor::PreprocessorReader.new document, lines
      end

      def pass_inline_split(text)
        text.split(PASS_INLINE_MACRO_RX).each.map do |x|
          PASS_INLINE_MACRO_RX.match?(x) ? pass_convert(x) : x
        end
      end

      # pass:[A] => pass-format:metanorma[++A++],
      # so long as A doesn't already start with ++
      # ditto pass-format:[A] => pass-format:[++A++]
      # convert any \] in the ++...++ body to ]
      def pass_convert(text)
        text
          .gsub(/pass-format:([^\[ ]*)\[(?!\+\+)(.+?)(?<!\\)\]/) do |_m|
          "pass-format:#{$1}[++#{$2.gsub(/\\\]/, ']')}++]"
        end
          .gsub(/pass:\[(?=\+\+)(.+?)(?<!\\)\]/,
                "pass-format:metanorma[\\1]")
          .gsub(/pass:\[(?!\+\+)(.+?)(?<!\\)\]/) do |_m|
          "pass-format:metanorma[++#{$1.gsub(/\\\]/, ']')}++]"
        end
      end

      def inlinelink(text)
        /^\[.*\]\s*$/.match?(text) and return text
        pass_inline_split(text).join
      end
    end
  end
end
