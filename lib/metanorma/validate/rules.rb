# frozen_string_literal: true

require "nokogiri"
require "yaml"

module Metanorma
  module Standoc
    class Validate
      # Declarative model validation (metanorma-standoc#1381).
      #
      # Rules are data: an XPath context, an optional target, and the name
      # of a check registered in Ruby. Rule files cannot supply executable
      # code. Severity and citation stay with the code's log registration,
      # and findings go through the log, so suppression applies unchanged.
      module Rules
        class RuleError < ArgumentError; end

        # Mixed into Validate. No rule files are configured by default, so
        # validation behaviour is unchanged until a flavor opts in.
        module DeclarativeValidation
          def validation_rule_files
            []
          end

          def validation_check_registry
            CheckRegistry.default
          end

          def validation_rule_set
            files = validation_rule_files
            return if files.empty?

            @validation_rule_set ||= files.map do |path|
              RuleSet.load_file(path, registry: validation_check_registry)
            end.reduce(RuleSet.new([]), :merge)
          end

          # The portable subset of the configured rules as Schematron, or
          # nil when no rule files are configured.
          def validation_schematron
            rule_set = validation_rule_set or return
            Schematron.export(rule_set)
          end

          def declarative_rules_validate(doc)
            rule_set = validation_rule_set or return
            Engine.new(rule_set, validator: self, log: @log).run(doc)
          end
        end
      end
    end
  end
end

require_relative "rules/check_registry"
require_relative "rules/checks"
require_relative "rules/rule"
require_relative "rules/rule_set"
require_relative "rules/document_projection"
require_relative "rules/engine"
require_relative "rules/schematron"
