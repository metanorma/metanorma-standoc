module Metanorma
  module Standoc
    # refer https://github.com/asciidoctor/asciidoctor/blob/main/lib/asciidoctor/substitutors.rb
    # Not using TreeProcessor because that is still too close to
    # inline expressions being processed on access (e.g. titles)
    class LinkProtectPreprocessor < Asciidoctor::Extensions::Preprocessor
      def process(document, reader)
        p = Metanorma::Utils::LineStatus.new
        out = []
        buf = nil
        reader.lines.each do |t|
          p.process(t)
          if buf
            buf = "#{buf}\n#{t}"
            next unless bracket_closed?(buf)

            out << escape_line(buf, p.pass)
            buf = nil
          elsif bracket_open?(t)
            # an inline macro's bracketed text may span lines (a hard
            # break inside the link text); hold the fragment so the
            # escape pass sees the whole macro instead of the first
            # line's unclosed bracket, which it rewrites as a bare
            # empty-text link
            buf = t
          else
            out << escape_line(t, p.pass)
          end
        end
        out << buf if buf
        ::Asciidoctor::PreprocessorReader.new document, out
      end

      def escape_line(text, pass)
        !pass && text.include?(":") ? inlinelinkmacro(inlinelink(text)) : text
      end

      # Buffer only lines that open a link macro's bracketed text:
      # buffering any other open-bracket line would defer that line's
      # own substitution passes (e.g. character expansions), so the
      # bracket-unclosed test is reserved for the URL/link/mailto
      # prefixes the escape pass below actually rewrites.
      #
      # NOTE: no /x mode or comments in this pattern — TruffleRuby's
      # TRegex parser rejects /x-commented patterns in this file (see
      # PASS_INLINE_MACRO_STR).
      LINK_MACRO_OPEN_RX =
        /(?:\b(?:https?|file|ftp|irc):\/\/|\blink:(?!\+)|\bmailto:)/.freeze

      # the line opens a bracket it never closes: a multi-line link
      # macro (or a genuinely unterminated fragment, flushed verbatim
      # at EOF)
      def bracket_open?(line)
        LINK_MACRO_OPEN_RX.match?(line) or return false
        open = line.index("[") or return false
        !bracket_closed?(line)
      end

      def bracket_closed?(text)
        open = text.index("[") or return false
        close = text.index("]", open) or return false
        text[close - 1] != "\\"
      end

      PASS_INLINE_MACROS = %w(pass pass-format identifier std-link stem)
        .join("|").freeze

      # NOTE: the pattern deliberately carries no /x-mode comments —
      # TruffleRuby's TRegex parser rejects this pattern whenever any /x
      # comment is present ("missing ), unterminated subpattern",
      # https://github.com/truffleruby/truffleruby/issues/4435). /x strips
      # comments and layout whitespace before parsing, so this spelling
      # compiles to the identical regex on every engine. Anatomy, for the
      # reader:
      #   \b(?<![-\\])                      word separator, no hyphen/backslash
      #   (?:(?:MACROS):[^\s\[]* | span: [^\s\[]*)
      #       macro name + second key, OR any span: macro (e.g. span:uri,
      #       span:note.display): protect its bracketed content from
      #       URL/link rewriting so an injected link:[] cannot close the
      #       span early
      #   \[.*?(?<!\\)\]                    [...] not preceded by backslash
      PASS_INLINE_MACRO_STR = <<~REGEX.freeze
        (
          \\b(?<![-\\\\])
          (?:
            (?:#{PASS_INLINE_MACROS}):[^\\s\\[]* |
            span: [^\\s\\[]*
          )
          \\[.*?(?<!\\\\)\\]
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
          !p.pass && /(?<!")`(?!")/.match?(t) ? inlinemonospace(t) : t
        end
        ::Asciidoctor::PreprocessorReader.new document, lines
      end

      PASS_INLINE_MACROS = %w(pass pass-format identifier std-link stem)
        .join("|").freeze

      # NOTE: the pattern deliberately carries no /x-mode comments —
      # TruffleRuby's TRegex parser rejects this pattern whenever any /x
      # comment is present ("missing ), unterminated subpattern",
      # https://github.com/truffleruby/truffleruby/issues/4435). /x strips
      # comments and layout whitespace before parsing, so this spelling
      # compiles to the identical regex on every engine. Anatomy, for the
      # reader:
      #   \b(?<![-\\])                      word separator, no hyphen/backslash
      #   (?:(?:MACROS):[^\s\[]* | span: [^\s\[]*)
      #       macro name + second key, OR any span: macro (e.g. span:uri,
      #       span:note.display): protect its bracketed content from
      #       URL/link rewriting so an injected link:[] cannot close the
      #       span early
      #   \[.*?(?<!\\)\]                    [...] not preceded by backslash
      PASS_INLINE_MACRO_STR = <<~REGEX.freeze
        (
          \\b(?<![-\\\\])
          (?:
            (?:#{PASS_INLINE_MACROS}):[^\\s\\[]* |
            span: [^\\s\\[]*
          )
          \\[.*?(?<!\\\\)\\]
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
      # Avoids: the backticks of Asciidoc smart-quote markup "`...`", where a
      #   backtick abuts an enclosing " (the leading (?<![\\"]) and the (?!")
      #   guard). The (?!") guard is suppressed when the backtick run sits at a
      #   genuine monospace boundary (start, whitespace, or opening bracket), so
      #   monospace whose content itself begins with " — e.g. `"quote" A's` — is
      #   still protected from character replacements.
      MonospaceRx = /
        (?<![\\"]) (`{1,2})
        (?: (?!") | (?<=[\s(\[{<]`) | (?<=[\s(\[{<]``) | (?<=\A`) | (?<=\A``) )
        (.+?) (?<!\\) \1
      /x

      def inlinemonospace(text)
        /(?<!")`(?!")/.match?(text) or return text
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
            # Protect content from character replacements but allow quotes substitution
            # Escape unescaped ] to prevent premature closing of pass:[...]
            protected_content = content.gsub(/(?<!\\)\]/, "\\]")
            "pass:c,q,a,m,p[#{backticks}#{protected_content}#{backticks}]"
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
