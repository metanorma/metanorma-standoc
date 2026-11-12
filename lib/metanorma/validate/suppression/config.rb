# frozen_string_literal: true

require "lutaml/model"

module Metanorma
  module Standoc
    class Validate
      # Declarative validation suppression (metanorma-standoc#1369).
      module Suppression
        # One suppression rule, keyed by log code: a severity action
        # (off / reclassify) optionally narrowed by message-text content
        # matching. `allow:` patterns whitelist matching message text
        # (routed to the audited suppressed store); `exclude:` patterns
        # drop matching message text the same way. Line-level and
        # element-scope (xpath/anchor) matching remain out for the
        # coradoc era.
        class RuleEntry < Lutaml::Model::Serializable
          SEVERITY_VOCABULARY = %w(off info warning error).freeze

          # Log severity scale (utils Log): 0 abort; 1 serious;
          # 2 not serious; 3 info only.
          RECLASSIFY_LEVELS = { "info" => 3, "warning" => 2,
                                "error" => 1 }.freeze

          attribute :code, :string
          attribute :severity, :string, values: SEVERITY_VOCABULARY
          attribute :allow, :string, collection: true
          attribute :exclude, :string, collection: true

          yaml do
            map "code", to: :code
            map "severity", to: :severity
            map "allow", to: :allow
            map "exclude", to: :exclude
          end

          # YAML 1.1 parses a bare `off` as false (lutaml-model casts it
          # to "false"); normalize the keyword back so `severity: off`
          # (the frozen schema's spelling) works.
          def normalized_severity
            s = severity
            s = "off" if s == false || s == "false"
            s.to_s.downcase
          end

          def content_rule?
            Array(allow).any? || Array(exclude).any?
          end

          # The Log hook action for an entry of this code. Content
          # matching first: an `allow` pattern matching the message text
          # yields :allow, an `exclude` pattern yields :exclude (both
          # audited in the suppressed store with the pattern as reason).
          # Otherwise the configured severity action applies, or nil
          # when the rule carries no severity.
          def action(message: nil)
            if (pattern = matching_pattern(compiled_allow, message))
              return { action: :allow,
                       reason: "allowed by config: #{pattern}" }
            end
            if (pattern = matching_pattern(compiled_exclude, message))
              return { action: :exclude,
                       reason: "excluded by config: #{pattern}" }
            end

            severity_action
          end

          def severity_action
            case normalized_severity
            when "" then nil
            when "off" then { action: :off,
                              reason: "suppressed by validation " \
                                      "rule (#{code})" }
            else { action: :reclassify,
                   severity: RECLASSIFY_LEVELS.fetch(normalized_severity),
                   reason: "reclassified by validation rule " \
                           "(#{code}: #{normalized_severity})" }
            end
          end

          def matching_pattern(compiled, message)
            return if message.nil?

            compiled.each do |(pattern, regexp)|
              regexp.match?(message) and return pattern
            end
            nil
          end

          def compiled_allow
            @compiled_allow ||= compile_patterns(allow, "allow")
          end

          def compiled_exclude
            @compiled_exclude ||= compile_patterns(exclude, "exclude")
          end

          def compile_patterns(patterns, kind)
            Array(patterns).map do |p|
              [p.to_s, Regexp.new(p.to_s)]
            rescue RegexpError, StandardError => e
              raise ArgumentError,
                    "invalid #{kind} pattern #{p.inspect} for code " \
                    "#{code}: #{e.message}"
            end
          end

          def valid_rule!
            normalized_severity.empty? && !content_rule? and
              raise ArgumentError,
                    "rule for code #{code} carries no severity, " \
                    "allow or exclude"
            valid_severity!
            compiled_allow
            compiled_exclude
          end

          def valid_severity!
            return if normalized_severity.empty? && content_rule?
            return if SEVERITY_VOCABULARY.include?(normalized_severity)

            raise ArgumentError,
                  "invalid severity #{severity.inspect} for code #{code} " \
                  "(allowed: #{SEVERITY_VOCABULARY.join(', ')})"
          end
        end

        # The validation-suppression configuration document
        # (schema metanorma-validation-suppression/1):
        #
        #   schema: metanorma-validation-suppression/1
        #   rules:
        #     ISO_53:
        #       severity: off
        #     STANDOC_48:
        #       severity: warning
        #       allow:
        #         - 'a PDF\b'
        #   category_rules:            # optional, whole-family selection
        #     category:
        #       Style:
        #         severity: off
        #
        # All (de)serialization goes through lutaml-model (attribute +
        # mapping); category_rules stays a framework-parsed hash because
        # lutaml-model 0.8.x child_mappings are single-level and the
        # family map nests two levels.
        class Config < Lutaml::Model::Serializable
          SCHEMA_VERSION = "metanorma-validation-suppression/1"
          FAMILIES = %w(mn_category category source).freeze

          attribute :schema_version, :string, default: SCHEMA_VERSION
          attribute :rules, RuleEntry, collection: true
          attribute :category_rules, :hash

          yaml do
            map "schema", to: :schema_version
            map "rules", to: :rules,
                         child_mappings: { code: :key, severity: :severity,
                                           allow: :allow,
                                           exclude: :exclude }
            map "category_rules", to: :category_rules
          end

          class << self
            # Path form: reads the YAML file at +path+. The framework's
            # text-parsing entry point stays available under its declared
            # name, from_yaml_string — here from_yaml is deliberately
            # repurposed to the file form the suppression layers need.
            def from_yaml(path, options = {})
              from_yaml_string(File.read(path), options)
            rescue StandardError => e
              raise e.class,
                    "validation suppression config #{path}: #{e.message}"
            end

            def from_yaml_string(text, options = {})
              from(:yaml, text, options).tap(&:validate_config!)
            end
          end

          # Optional family-metadata callback injected by the converter:
          # ->(family, id) { ... } returning the code's registered policy
          # metadata (e.g. its mn_category) for the mn_category/source
          # families. Without it, only `category` family rules match
          # (against the message's log category).
          attr_accessor :registry_lookup

          def validate_config!
            version = schema_version || SCHEMA_VERSION
            unless version == SCHEMA_VERSION
              raise ArgumentError,
                    "unsupported validation-suppression schema version " \
                    "#{version.inspect} (supported: #{SCHEMA_VERSION.inspect})"
            end
            (rules || []).each(&:valid_rule!)
            validate_category_rules!
          end

          # The Log hook. Code rules first, then whole-family rules.
          # severity and location are part of the frozen hook contract
          # but v1 matches on code, family, and message text (allow /
          # exclude patterns) alone.
          def action_for(id:, message: nil, category: nil, severity: nil,
                         location: nil)
            rule = code_rule(id)
            return rule.action(message: message) if rule

            family_action(id, category)
          end

          def code_rule(id)
            (rules || []).find { |r| r.code.to_s.casecmp(id.to_s).zero? }
          end

          def family_action(id, category)
            (category_rules || {}).each do |family, names|
              family_names(family.to_s, id, category).each do |name|
                entry = names[name] or next
                return family_result(family.to_s, name, entry)
              end
            end
            nil
          end

          def family_names(family, id, category)
            case family
            when "category"
              [category].compact.map(&:to_s)
            when "mn_category", "source"
              if registry_lookup
                [registry_lookup.call(family, id)].compact.map(&:to_s)
              else
                []
              end
            else []
            end
          end

          def normalized_family_severity(entry)
            sev = entry.is_a?(::Hash) ? entry["severity"] : entry
            sev = "off" if sev == false || sev == "false"
            sev.to_s.downcase
          end

          def family_result(family, name, entry)
            sev = normalized_family_severity(entry)
            unless RuleEntry::SEVERITY_VOCABULARY.include?(sev)
              raise ArgumentError,
                    "invalid severity #{entry.inspect} in category_rules " \
                    "#{family}/#{name} " \
                    "(allowed: #{RuleEntry::SEVERITY_VOCABULARY.join(', ')})"
            end
            rule = RuleEntry.new(code: name, severity: sev)
            { **rule.severity_action,
              reason: "#{rule.severity_action[:reason]} [#{family}=#{name}]" }
          end

          # validates each family entry and normalizes the stored
          # severities (YAML-1.1 `off` arrives as false)
          def validate_category_rules!
            normalized = {}
            (category_rules || {}).each do |family, names|
              names.is_a?(::Hash) or raise ArgumentError,
                                           "category_rules #{family} must " \
                                           "be a map of name to action"
              normalized[family] = names.each_with_object({}) do |(name, e), m|
                family_result(family.to_s, name, e)
                m[name] = { "severity" => normalized_family_severity(e) }
              end
            end
            @category_rules = normalized
          end

          # Layered resolution: +higher+ (document over taste over flavor)
          # wins the severity action per code and per family name; the
          # content-matching lists (allow, exclude) concatenate across
          # layers.
          def merge(higher)
            cfg = Config.new
            cfg.schema_version = SCHEMA_VERSION
            cfg.rules = merged_rules(higher)
            cfg.category_rules = merged_category_rules(higher)
            cfg.registry_lookup = higher.registry_lookup || registry_lookup
            cfg
          end

          def merged_rules(higher)
            lower_rules = rules || []
            higher_rules = higher.rules || []
            codes = (lower_rules + higher_rules).map { |r| r.code.to_s }.uniq
            codes.map do |code|
              lower = lower_rules.find { |r| r.code.to_s == code }
              higher_rule = higher_rules.find { |r| r.code.to_s == code }
              merged_rule(lower, higher_rule)
            end
          end

          def merged_rule(lower, higher)
            return higher if lower.nil?
            return lower if higher.nil?

            RuleEntry.new(
              code: lower.code,
              severity: higher.severity || lower.severity,
              allow: uniq_patterns(Array(lower.allow) + Array(higher.allow)),
              exclude: uniq_patterns(Array(lower.exclude) +
                                     Array(higher.exclude)),
            )
          end

          def uniq_patterns(patterns)
            patterns.map(&:to_s).uniq
          end

          def merged_category_rules(higher)
            merged = (category_rules || {}).dup
            (higher.category_rules || {}).each do |family, names|
              merged[family] = (merged[family] || {}).merge(names)
            end
            merged.empty? ? nil : merged
          end

          def empty?
            (rules.nil? || rules.empty?) &&
              (category_rules.nil? || category_rules.empty?)
          end

          def rules_count
            off = (rules || []).count { |r| r.normalized_severity == "off" }
            { total: (rules || []).size, off: off,
              reclassified: (rules || []).count do |r|
                r.normalized_severity != "" && r.normalized_severity != "off"
              end,
              allow: (rules || []).sum { |r| Array(r.allow).size },
              exclude: (rules || []).sum { |r| Array(r.exclude).size },
              family: (category_rules || {}).values.sum(&:size) }
          end
        end
      end
    end
  end
end
