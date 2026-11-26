# frozen_string_literal: true

module Metanorma
  module Standoc
    class Validate
      module Rules
        Finding = Data.define(:rule_id, :code, :node, :params, :source_model)

        # Evaluates a RuleSet. Severity, citation and suppression are applied
        # by the log when each finding is added.
        class Engine
          def initialize(rule_set, validator: nil, log: nil)
            @rule_set = rule_set.resolved
            @validator = validator
            @log = log
          end

          def findings(doc, modes: %w(enforce))
            projection = DocumentProjection.for(doc)
            @rule_set.rules.select { |r| modes.include?(r.mode) }
              .flat_map { |rule| rule_findings(projection, rule) }
          end

          def run(doc)
            findings(doc).each do |f|
              @log.add(f.code, f.node, params: f.params)
            end
          end

          private

          def rule_findings(projection, rule)
            rule.check.expand and return expanded_findings(projection, rule)
            projection.xml.xpath(rule.context, rule.namespaces).filter_map do |node|
              subject = rule.target ? node.at_xpath(rule.target, rule.namespaces) : node
              rule.check.predicate.call(subject, rule.args, @validator) or next
              Finding.new(rule_id: rule.id, code: rule.code,
                          node: subject || node,
                          params: rule.resolve_params(node, subject),
                          source_model: projection.source_model)
            end
          end

          # Checks that yield several findings per context node, such as
          # pair iteration. Each pair is [finding node, related node]; the
          # related node is available to params as +related+; an optional third
          # element of computed values is available as +{value: key}+.
          def expanded_findings(projection, rule)
            projection.xml.xpath(rule.context, rule.namespaces).flat_map do |node|
              rule.check.expand.call(node, rule.args, rule.namespaces)
                .map do |subject, related, values|
                Finding.new(rule_id: rule.id, code: rule.code, node: subject,
                            params: rule.resolve_params(node, subject,
                                                        related: related,
                                                        values: values),
                            source_model: projection.source_model)
              end
            end
          end
        end
      end
    end
  end
end
