# frozen_string_literal: true

module Metanorma
  module Standoc
    class Validate
      module Rules
        # Prose pattern matching (metanorma-standoc#1381). Code-backed: XPath
        # 1.0 has no regular expressions, so there is no Schematron mapping.
        module TextPatternChecks
          FLAGS = { "i" => Regexp::IGNORECASE, "m" => Regexp::MULTILINE,
                    "x" => Regexp::EXTENDED }.freeze
          REPORTS = %w(each once).freeze
          DEFAULT_EXCLUDE = %w(stem fmt-stem).freeze
          DEFAULT_LANGUAGE = "en"
          TIMEOUT = 2

          module_function

          def install(registry)
            registry.register(
              "text_pattern",
              optional: %w(pattern words flags report message exclude language),
              validate_args: method(:validate),
              expand: method(:findings)
            )
          end

          # The text of the context node (descendants named in +exclude+
          # removed; default stem and fmt-stem, which are not prose) is
          # searched for +pattern+ (a Ruby regular expression) or +words+
          # (whole words, any of them). +flags+ is a string drawn from
          # i, m, x. With +language+ (a list of codes) the check runs only
          # when bibdata/language, or its primary subtag (fr for fr-FR), is
          # one of them (en if the document names none). +report+ is each (default: one finding per distinct
          # match, using the capture groups if the pattern has any, as
          # String#scan) or once (one finding if anything matches). The
          # finding is on the context node. Values: +match+ (once: the
          # first match) and +message+, +message+ argument with each %s
          # replaced by the match (default: the match).
          def validate(args)
            pattern_source(args)
            validate_flags(args["flags"])
            validate_report(args["report"])
            validate_message(args["message"])
            validate_names("exclude", args["exclude"], Checks::ELEMENT_NAME)
            validate_names("language", args["language"], /\A[A-Za-z][\w-]*\z/)
            compile(args)
          end

          def pattern_source(args)
            pattern = args["pattern"]
            words = args["words"]
            pattern.nil? == words.nil? and
              raise RuleError, "give exactly one of pattern or words"
            if pattern
              pattern.is_a?(String) && !pattern.empty? or
                raise RuleError, "pattern must be a non-empty string"
              return pattern
            end
            words.is_a?(Array) && words.any? &&
              words.all? { |w| w.is_a?(String) && !w.strip.empty? } or
              raise RuleError, "words must be a non-empty list of strings"
            "\\b(?:#{words.map { |w| Regexp.escape(w) }.join('|')})\\b"
          end

          def validate_flags(flags)
            flags.nil? and return
            flags.is_a?(String) && flags.chars.all? { |c| FLAGS.key?(c) } or
              raise RuleError, "flags must be a string of i, m, x"
          end

          def validate_report(report)
            report.nil? || REPORTS.include?(report) or
              raise RuleError, "report must be one of #{REPORTS.join(', ')}"
          end

          def validate_message(message)
            message.nil? || message.is_a?(String) or
              raise RuleError, "message must be a string"
          end

          def validate_names(label, list, format)
            list.nil? and return
            list.is_a?(Array) && list.any? &&
              list.all? { |n| n.is_a?(String) && format.match?(n) } or
              raise RuleError, "#{label} must be a non-empty list of names"
          end

          def compile(args)
            options = args.fetch("flags", "").chars.sum { |c| FLAGS[c] }
            Regexp.new(pattern_source(args), options, timeout: TIMEOUT)
          rescue RegexpError => e
            raise RuleError, "invalid pattern: #{e.message}"
          end

          def findings(node, args, _namespaces)
            language_ok?(node, args["language"]) or return []
            text = prose(node, args.fetch("exclude", DEFAULT_EXCLUDE))
            text.empty? and return []
            regex = compile(args)
            matches = text.scan(regex).flatten.compact.uniq
            args["report"] == "once" and matches = text.match?(regex) ? [text[regex]] : []
            matches.map { |m| [node, node, values(args, m)] }
          end

          def values(args, match)
            { "match" => match,
              "message" => args["message"] ? args["message"].gsub("%s") { match } : match }
          end

          def prose(node, exclude)
            copy = node.dup
            exclude.each do |name|
              copy.xpath(".//*[local-name() = '#{name}']").each(&:remove)
            end
            copy.text.strip
          end

          def language_ok?(node, languages)
            languages.nil? and return true
            doc = node.document
            lang = doc.at_xpath("//*[local-name() = 'bibdata']/" \
                                "*[local-name() = 'language']")&.text&.strip
            lang = DEFAULT_LANGUAGE if lang.nil? || lang.empty?
            languages.include?(lang) || languages.include?(lang.split("-").first)
          end
        end
      end
    end
  end
end
