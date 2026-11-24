# frozen_string_literal: true

module Metanorma
  module Standoc
    class Validate
      module Rules
        # A named predicate: call(subject, args, validator) is truthy when
        # the subject violates the rule. +schematron+, when present, maps
        # (target, args) to an equivalent XPath 1.0 assertion. +expand+,
        # when present, replaces the predicate for checks that yield several
        # findings per context node: expand(node, args, namespaces) returns
        # [finding_node, related_node] pairs.
        Check = Data.define(:name, :required, :optional, :needs_target,
                            :validate_args, :predicate, :schematron, :expand)

        # The allowlist of checks a rule file may name.
        class CheckRegistry
          def self.default
            @default ||= new.tap { |r| Checks.install(r) }.freeze
          end

          def initialize
            @checks = {}
          end

          def initialize_copy(source)
            super
            @checks = source.checks.dup
          end

          def freeze
            @checks.freeze
            super
          end

          # rubocop:disable Metrics/ParameterLists
          def register(name, required: [], optional: [], needs_target: false,
                       validate_args: nil, schematron: nil, expand: nil,
                       &predicate)
            key = name.to_s
            predicate || expand or
              raise RuleError, "check #{key} needs a predicate"
            @checks.key?(key) and
              raise RuleError, "check #{key} is already registered"
            @checks[key] = Check.new(
              name: key, required: required.map(&:to_s),
              optional: optional.map(&:to_s), needs_target: needs_target,
              validate_args: validate_args, predicate: predicate,
              schematron: schematron, expand: expand
            )
            self
          end
          # rubocop:enable Metrics/ParameterLists

          def fetch(name)
            @checks.fetch(name.to_s) do
              raise RuleError, "unknown check #{name.inspect} " \
                               "(registered: #{names.join(', ')})"
            end
          end

          def names
            @checks.keys.sort
          end

          protected

          attr_reader :checks
        end
      end
    end
  end
end
