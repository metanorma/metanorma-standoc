# frozen_string_literal: true

module Metanorma
  module Standoc
    class Validate
      module Rules
        # One validated rule. +enforce+ rules log findings at runtime;
        # +shadow+ rules are evaluated only on request, for parity testing
        # against the code they are intended to replace.
        class Rule
          KEYS = %w(id code mode context target check args params
                    description).freeze
          REGISTRY_OWNED = %w(severity citation category).freeze
          MODES = %w(enforce shadow).freeze
          ID = /\A[A-Za-z][\w.-]*\z/
          CODE = /\A[A-Z][A-Z0-9]*_\w+\z/
          NODE_PARAMS = %w(name text xml).freeze
          RELATION_PARAMS = NODE_PARAMS
          PROBE = Nokogiri::XML("<probe/>").root

          attr_reader :id, :code, :mode, :context, :target, :check, :args,
                      :params, :description, :namespaces

          def self.from_h(hash, registry:, namespaces: {})
            hash.is_a?(Hash) or raise RuleError, "rule must be a map"
            check_keys(hash)
            new(hash, registry, namespaces: namespaces)
          end

          def self.check_keys(hash)
            owned = hash.keys & REGISTRY_OWNED
            owned.empty? or
              raise RuleError, "rule #{hash['id']}: #{owned.join(', ')} " \
                               "belongs to the log registry, not the rule"
            unknown = hash.keys - KEYS
            unknown.empty? or
              raise RuleError, "rule #{hash['id']}: unknown keys " \
                               "#{unknown.join(', ')}"
          end

          def initialize(hash, registry, namespaces: {})
            @namespaces = namespaces.dup.freeze
            @id = hash["id"]
            @code = hash["code"]
            @mode = hash.fetch("mode", "enforce")
            @context = hash["context"]
            @target = hash["target"]
            @description = hash["description"]
            @args = hash.fetch("args", {})
            @params = hash.fetch("params", [])
            validate_identity
            @check = registry.fetch(hash["check"])
            validate_paths
            validate_args
            validate_params
            freeze
          end

          # +context+ and +related+ params read the rule's context node and
          # the second node of a pair (see CheckRegistry's +expand+).
          def resolve_params(context_node, subject, related: nil)
            node = subject || context_node
            params.map do |param|
              next param unless param.is_a?(Hash)

              key, value = param.first
              case key
              when "attribute" then node[value]
              when "count" then node.xpath("count(#{value})", namespaces).to_i
              when "context" then node_param(context_node, value)
              when "related" then node_param(related, value)
              else node_param(node, value)
              end
            end
          end

          private

          def node_param(node, value)
            case value
            when "name" then node.name
            when "xml" then node.to_xml
            else node.text
            end
          end

          def fail_rule(message)
            raise RuleError, "rule #{id || '(no id)'}: #{message}"
          end

          def validate_identity
            ID.match?(id.to_s) or fail_rule("invalid id")
            CODE.match?(code.to_s) or fail_rule("invalid code #{code.inspect}")
            MODES.include?(mode) or fail_rule("invalid mode #{mode.inspect}")
          end

          def validate_paths
            validate_xpath("context", context)
            target.nil? or validate_xpath("target", target)
            check.needs_target && target.nil? and
              fail_rule("check #{check.name} needs a target")
          end

          # Must compile and select nodes. Evaluated on an inert probe, with
          # no custom function handler available to the expression.
          def validate_xpath(label, path)
            path.is_a?(String) && !path.strip.empty? or
              fail_rule("#{label} must be an XPath string")
            PROBE.xpath(path, namespaces).is_a?(Nokogiri::XML::NodeSet) or
              fail_rule("#{label} must select nodes")
          rescue Nokogiri::XML::XPath::SyntaxError => e
            fail_rule("invalid #{label} XPath: #{e.message}")
          end

          def validate_args
            args.is_a?(Hash) or fail_rule("args must be a map")
            missing = check.required - args.keys
            missing.empty? or fail_rule("missing args #{missing.join(', ')}")
            unknown = args.keys - check.required - check.optional
            unknown.empty? or fail_rule("unknown args #{unknown.join(', ')}")
            run_arg_validator
          rescue RuleError => e
            e.message.start_with?("rule ") ? raise : fail_rule(e.message)
          end

          def run_arg_validator
            validator = check.validate_args or return
            if validator.arity == 1 then validator.call(args)
            else validator.call(args, namespaces)
            end
          end

          def validate_params
            params.is_a?(Array) or fail_rule("params must be a list")
            params.each { |param| validate_param(param) }
          end

          def validate_param(param)
            return if param.is_a?(String) || param.is_a?(Integer)

            param.is_a?(Hash) && param.size == 1 or
              fail_rule("invalid param #{param.inspect}")
            key, value = param.first
            return if key == "node" && NODE_PARAMS.include?(value)
            return if key == "context" && RELATION_PARAMS.include?(value)
            return if key == "related" && RELATION_PARAMS.include?(value) &&
              check.expand
            return if key == "attribute" &&
              Checks::ATTRIBUTE_NAME.match?(value.to_s)
            return if key == "count" && count_xpath?(value)

            fail_rule("invalid param #{param.inspect}")
          end

          # A count param is the number of nodes an XPath selects from the
          # context node, e.g. {count: ./body/callout}.
          def count_xpath?(value)
            value.is_a?(String) && !value.strip.empty? &&
              PROBE.xpath("count(#{value})", namespaces).is_a?(Float)
          rescue Nokogiri::XML::XPath::SyntaxError
            false
          end
        end
      end
    end
  end
end
