# frozen_string_literal: true

module Metanorma
  module Standoc
    class Validate
      module Rules
        # Built-in checks. Those with a +schematron+ mapping are portable;
        # the others are code-backed and are reported as such on export.
        module Checks
          ATTRIBUTE_NAME = /\A[A-Za-z_][\w.-]*\z/

          module_function

          def install(registry)
            install_structural(registry)
            install_attribute_in(registry)
            registry.register("empty_block") do |subject, _args, validator|
              validator or raise RuleError, "empty_block needs a validator"
              validator.empty_block?(subject)
            end
          end

          def install_structural(registry)
            registry.register("required", needs_target: true,
                                          schematron: ->(target, _args) { target }) do |subject, _, _|
              subject.nil?
            end
            registry.register("forbidden", needs_target: true,
                                           schematron: ->(target, _args) { "not(#{target})" }) do |subject, _, _|
              !subject.nil?
            end
          end

          def install_attribute_in(registry)
            registry.register(
              "attribute_in", required: %w(attribute values),
                              validate_args: method(:validate_attribute_in),
                              schematron: method(:attribute_in_test)
            ) do |subject, args, _|
              value = subject && subject[args["attribute"]]
              !value.nil? && !args["values"].include?(value)
            end
          end

          # YAML turns bare yes/no/off into booleans, which would silently
          # never match an attribute value, so only strings are accepted.
          def validate_attribute_in(args)
            ATTRIBUTE_NAME.match?(args["attribute"].to_s) or
              raise RuleError, "invalid attribute #{args['attribute'].inspect}"
            values = args["values"]
            values.is_a?(Array) && values.any? &&
              values.all?(String) or
              raise RuleError, "values must be a non-empty list of strings"
          end

          def attribute_in_test(target, args)
            attr = "@#{args['attribute']}"
            path = target ? "(#{target})[1]/#{attr}" : attr
            allowed = args["values"].map { |v| ". = #{xpath_literal(v)}" }
            "not(#{path}[not(#{allowed.join(' or ')})])"
          end

          def xpath_literal(value)
            !value.include?("'") and return "'#{value}'"
            !value.include?('"') and return "\"#{value}\""
            parts = value.split("'", -1).map { |p| "'#{p}'" }
            "concat(#{parts.join(%q(, "'", ))})"
          end
        end
      end
    end
  end
end
