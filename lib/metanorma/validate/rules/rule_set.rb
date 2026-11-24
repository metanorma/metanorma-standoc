# frozen_string_literal: true

module Metanorma
  module Standoc
    class Validate
      module Rules
        # An ordered, validated rule collection (schema
        # metanorma-validation-rules/1). Rules run in file order.
        class RuleSet
          SCHEMA_VERSION = "metanorma-validation-rules/1"
          TOP_LEVEL_KEYS = %w(schema rules disable namespaces).freeze
          PREFIX = /\A[A-Za-z_][\w.-]*\z/

          attr_reader :rules, :disabled, :namespaces

          def self.load_file(path, registry: CheckRegistry.default)
            parse(File.read(path, encoding: "UTF-8"), registry: registry)
          rescue RuleError, Psych::Exception => e
            raise RuleError, "validation rules #{path}: #{e.message}"
          end

          # safe_load: no object tags, symbols or aliases.
          def self.parse(text, registry: CheckRegistry.default)
            data = YAML.safe_load(text, aliases: false)
            data.is_a?(Hash) or raise RuleError, "rule file must be a map"
            check_header(data)
            namespaces = validate_namespaces(data.fetch("namespaces", {}))
            new(Array(data["rules"]).map do |rule|
              Rule.from_h(rule, registry: registry, namespaces: namespaces)
            end, disabled: Array(data["disable"]), namespaces: namespaces)
          end

          def self.validate_namespaces(value)
            value.is_a?(Hash) or raise RuleError, "namespaces must be a map"
            value.each do |prefix, uri|
              prefix.is_a?(String) && PREFIX.match?(prefix) &&
                prefix != "xmlns" && uri.is_a?(String) && !uri.strip.empty? or
                raise RuleError, "invalid namespace binding #{prefix.inspect}"
              if prefix == "xml" && uri != "http://www.w3.org/XML/1998/namespace"
                raise RuleError, "the xml prefix has a fixed namespace"
              end
            end
            value.dup.freeze
          end

          def self.check_header(data)
            data["schema"] == SCHEMA_VERSION or
              raise RuleError, "unsupported schema #{data['schema'].inspect} " \
                               "(supported: #{SCHEMA_VERSION})"
            unknown = data.keys - TOP_LEVEL_KEYS
            unknown.empty? or
              raise RuleError, "unknown keys #{unknown.join(', ')}"
          end

          def initialize(rules, disabled: [], namespaces: {})
            ids = rules.map(&:id)
            dupes = ids.select { |id| ids.count(id) > 1 }.uniq
            dupes.empty? or
              raise RuleError, "duplicate rule ids: #{dupes.join(', ')}"
            @rules = rules.dup.freeze
            @disabled = disabled.map(&:to_s).freeze
            @namespaces = self.class.validate_namespaces(namespaces)
            rules.each do |rule|
              @namespaces = merge_namespaces(@namespaces, rule.namespaces)
            end
            freeze
          end

          # +higher+ replaces rules by id in place, appends new rules, and
          # removes the ids it disables. Disabling an unknown id is an error
          # so that a typo cannot leave a rule silently active.
          def merge(higher)
            base = resolved
            known = base.rules.map(&:id) + higher.rules.map(&:id)
            missing = higher.disabled - known
            missing.empty? or
              raise RuleError, "cannot disable unknown rules: " \
                               "#{missing.join(', ')}"
            replaced = higher.rules.to_h { |r| [r.id, r] }
            kept = base.rules.map { |r| replaced.delete(r.id) || r }
            self.class.new((kept + replaced.values).reject do |r|
              higher.disabled.include?(r.id)
            end, namespaces: merge_namespaces(namespaces, higher.namespaces))
          end

          # A parsed layer may disable inherited ids, so resolve it only once
          # it has a base. Never silently ignore disable on a standalone set.
          def resolved
            return self if disabled.empty?

            unknown = disabled - rules.map(&:id)
            unknown.empty? or
              raise RuleError, "cannot disable unknown rules: #{unknown.join(', ')}"
            self.class.new(rules.reject { |rule| disabled.include?(rule.id) },
                           namespaces: namespaces)
          end

          private

          def merge_namespaces(left, right)
            right.each do |prefix, uri|
              if left.key?(prefix) && left[prefix] != uri
                raise RuleError, "conflicting namespace binding for #{prefix}"
              end
            end
            left.merge(right).freeze
          end
        end
      end
    end
  end
end
