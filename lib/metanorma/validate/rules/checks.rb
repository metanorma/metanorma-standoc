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
            install_xpath_assert(registry)
            install_nested(registry)
            install_reference_exists(registry)
            GridTermChecks.install(registry)
            DocumentStateChecks.install(registry)
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
          def validate_attribute_in(args, _namespaces = {})
            ATTRIBUTE_NAME.match?(args["attribute"].to_s) or
              raise RuleError, "invalid attribute #{args['attribute'].inspect}"
            values = args["values"]
            values.is_a?(Array) && values.any? &&
              values.all?(String) or
              raise RuleError, "values must be a non-empty list of strings"
          end

          # A free-form XPath 1.0 assertion evaluated with the target (or
          # the context node) as its context. It is data, not code: no
          # extension functions are available to it.
          def install_xpath_assert(registry)
            registry.register(
              "xpath_assert", required: %w(test),
                              validate_args: method(:validate_xpath_assert),
                              schematron: method(:xpath_assert_test)
            ) do |subject, args, _|
              !subject.nil? && !subject.xpath("boolean(#{args['test']})")
            end
          end

          def validate_xpath_assert(args, namespaces = {})
            test = args["test"]
            test.is_a?(String) && !test.strip.empty? or
              raise RuleError, "test must be an XPath string"
            Rule::PROBE.xpath("boolean(#{test})", namespaces)
          rescue Nokogiri::XML::XPath::SyntaxError => e
            raise RuleError, "invalid test XPath: #{e.message}"
          end

          def xpath_assert_test(target, args)
            target or return args["test"]
            "not(#{target}) or boolean((#{target})[1][#{args['test']}])"
          end

          ELEMENT_NAME = /\A[A-Za-z_][\w.-]*\z/
          EXCEPTION = %r{\A[A-Za-z_][\w.-]*/[A-Za-z_][\w.-]*\z}

          # Pair iteration. The context node is the outer node; each
          # descendant named in +inner+ forms a pair with it, except pairs
          # listed in +except+ as "outer/inner". Every remaining pair is one
          # finding on the inner node. With +referenced_by+ (XPath
          # expressions selecting attribute nodes) a pair is reported only
          # when the inner node's @anchor is referenced, and the finding is
          # raised on the element holding the last such reference.
          def install_nested(registry)
            registry.register(
              "nested", required: %w(inner), optional: %w(except referenced_by),
                        validate_args: method(:validate_nested),
                        schematron: method(:nested_test),
                        expand: method(:nested_pairs)
            )
          end

          def validate_nested(args, namespaces = {})
            names_list("inner", args["inner"])
            Array(args["except"]).each do |e|
              EXCEPTION.match?(e.to_s) or
                raise RuleError, "invalid except #{e.inspect}, " \
                                 "expected outer/inner"
            end
            refs = args["referenced_by"] or return
            refs.is_a?(Array) && refs.any? or
              raise RuleError, "referenced_by must be a non-empty list"
            refs.each { |r| validate_xpath_nodes(r, namespaces, "referenced_by") }
          end

          def names_list(label, names)
            names.is_a?(Array) && names.any? &&
              names.all? { |n| n.is_a?(String) && ELEMENT_NAME.match?(n) } or
              raise RuleError, "#{label} must be a non-empty list of element names"
          end

          def validate_xpath_nodes(path, namespaces, label)
            path.is_a?(String) && !path.strip.empty? &&
              Rule::PROBE.xpath(path, namespaces).is_a?(Nokogiri::XML::NodeSet) or
              raise RuleError, "invalid #{label} #{path.inspect}"
          rescue Nokogiri::XML::XPath::SyntaxError => e
            raise RuleError, "invalid #{label} XPath: #{e.message}"
          end

          def nested_pairs(outer, args, namespaces)
            skip = Array(args["except"])
            inner_path = args["inner"].map { |n| ".//#{n}" }.join(" | ")
            outer.xpath(inner_path, namespaces).filter_map do |inner|
              skip.include?("#{outer.name}/#{inner.name}") and next
              args["referenced_by"] or next [inner, inner]
              ref = last_reference(inner, args["referenced_by"], namespaces)
              ref && [ref, inner]
            end
          end

          # Later reference kinds and later nodes win, as a hash filled in
          # that order would.
          def last_reference(inner, paths, namespaces)
            anchor = inner["anchor"] or return
            paths.flat_map { |p| inner.document.xpath(p, namespaces).to_a }
              .select { |a| a.value == anchor }.last&.parent
          end

          # Evaluated per outer node: Schematron reports one failure for an
          # outer node with any offending pair, on that node.
          def nested_test(_target, args)
            skip = Array(args["except"]).map { |e| e.split("/") }
            conds = args["inner"].map do |n|
              outers = skip.select { |_, i| i == n }.map { |o, _| "self::#{o}" }
              guard = outers.empty? ? "" : "not(#{outers.join(' or ')}) and "
              "#{guard}.//#{n}#{nested_reference(args)}"
            end
            "not(#{conds.join(' or ')})"
          end

          def nested_reference(args)
            refs = args["referenced_by"] or return ""
            "[@anchor = (#{refs.join(' | ')})]"
          end

          # An attribute value must appear among the string values of the
          # nodes selected by +known+ (an XPath over the whole document).
          def install_reference_exists(registry)
            registry.register(
              "reference_exists", required: %w(attribute known),
                                  validate_args: method(:validate_reference_exists),
                                  schematron: method(:reference_exists_test)
            ) do |subject, args, _|
              subject && subject[args["attribute"]] &&
                !subject.xpath("boolean(@#{args['attribute']} = (#{args['known']}))")
            end
          end

          def validate_reference_exists(args, namespaces = {})
            ATTRIBUTE_NAME.match?(args["attribute"].to_s) or
              raise RuleError, "invalid attribute #{args['attribute'].inspect}"
            validate_xpath_nodes(args["known"], namespaces, "known")
          end

          def reference_exists_test(target, args)
            attr = "@#{args['attribute']}"
            path = target ? "(#{target})[1]/#{attr}" : attr
            "not(#{path}) or #{path} = (#{args['known']})"
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
