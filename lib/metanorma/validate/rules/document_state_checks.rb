# frozen_string_literal: true

require "vectory"

module Metanorma
  module Standoc
    class Validate
      module Rules
        # Checks whose result depends on document-wide state, the file system
        # or validator options (metanorma-standoc#1381). They are code-backed
        # (no Schematron mapping). Findings may carry computed values, read
        # by params as +{value: key}+. Checks taking a fourth parameter
        # receive the validator.
        module DocumentStateChecks
          module_function

          def install(registry)
            install_concept_reference(registry)
            install_file_missing(registry)
            install_value_too_long(registry)
            install_duplicate_value(registry)
          end

          # The context node is an xref inside a concept. It is flagged
          # when its target is not among the anchors selected by +known+
          # (XPath over the whole document). The message names the
          # +label+, the text found by +refterm+ (XPath from the xref), and
          # the target's anchor, looked up by @id; when the target is
          # among the anchors selected by +subterm+ the message adds a
          # hint. Value: +message+.
          def install_concept_reference(registry)
            registry.register(
              "concept_reference", required: %w(known label refterm subterm),
                                   validate_args: method(:validate_concept_reference),
                                   expand: method(:concept_reference_findings)
            )
          end

          def validate_concept_reference(args, namespaces = {})
            args["label"].is_a?(String) && !args["label"].empty? or
              raise RuleError, "label must be a non-empty string"
            %w(known refterm subterm).each do |key|
              Checks.validate_xpath_nodes(args[key], namespaces, key)
            end
          end

          def concept_reference_findings(xref, args, namespaces)
            anchors = ->(path) { xref.document.xpath(path, namespaces).map(&:value) }
            known = anchors.call(args["known"])
            target = xref["target"]
            known.include?(target) and return []
            [[xref, xref, { "message" => concept_message(xref, args, namespaces,
                                                         anchors.call(args["subterm"])) }]]
          end

          def concept_message(xref, args, namespaces, subterms)
            target = xref["target"]
            anchor = xref.document.at_xpath("//*[@id][@id = #{Checks.xpath_literal(target.to_s)}]")&.[]("anchor")
            text = xref.at_xpath(args["refterm"], namespaces)&.text
            msg = "#{args['label']} #{text} is pointing to #{anchor || target}, " \
                  "which is not a term or symbol"
            # Legacy messages end in a newline, except with the hint.
            subterms.include?(target) and
              return "#{msg}. Did you mean to point to a subterm?"
            "#{msg}\n"
          end

          # The context node is an image or other element with a @src
          # attribute (or the attribute named by +attribute+). Finding on its
          # parent unless the element has no parent element, when a src is
          # neither a URL nor a data URI and names no file, relative to the
          # working directory or the document directory. Value: +src+.
          def install_file_missing(registry)
            registry.register(
              "file_missing", optional: %w(attribute),
                              validate_args: method(:validate_file_missing),
                              expand: method(:file_missing_findings)
            )
          end

          def validate_file_missing(args)
            attr = args.fetch("attribute", "src")
            Checks::ATTRIBUTE_NAME.match?(attr.to_s) or
              raise RuleError, "invalid attribute #{attr.inspect}"
          end

          def file_missing_findings(node, args, _namespaces, validator)
            validator or raise RuleError, "file_missing needs a validator"
            src = node[args.fetch("attribute", "src")] or return []
            Vectory::Utils.url?(src) || Vectory::Utils.datauri?(src) and return []
            file_present?(src, validator.localdir) and return []
            [[node.parent, node, { "src" => src }]]
          end

          # As Image#expand_path; without a document directory only the
          # path as given is tried.
          def file_present?(src, localdir)
            paths = [src]
            localdir and paths << File.join(localdir, src)
            paths.any? { |p| File.exist?(p) }
          end

          # The context node's +attribute+ value is longer than the limit
          # held by the validator option named by +limit+ (only
          # dataurimaxsize is available). A zero limit disables the check.
          # The finding is on the parent of the context node.
          OPTIONS = %w(dataurimaxsize).freeze

          def install_value_too_long(registry)
            registry.register(
              "value_too_long", required: %w(attribute limit),
                                validate_args: method(:validate_value_too_long),
                                expand: method(:value_too_long_findings)
            )
          end

          def validate_value_too_long(args)
            Checks::ATTRIBUTE_NAME.match?(args["attribute"].to_s) or
              raise RuleError, "invalid attribute #{args['attribute'].inspect}"
            OPTIONS.include?(args["limit"]) or
              raise RuleError, "limit must be one of #{OPTIONS.join(', ')}"
          end

          def value_too_long_findings(node, args, _namespaces, validator)
            validator or raise RuleError, "value_too_long needs a validator"
            limit = validator.public_send(args["limit"]).to_i
            limit.zero? and return []
            value = node[args["attribute"]] or return []
            value.size > limit ? [[node.parent, node]] : []
          end

          # The context node is the document root. Each element selected
          # by +nodes+ whose +attribute+ value was already seen on an earlier
          # selected element is a finding on it. Values: +value+, and
          # +line+ (the line of the first element holding it).
          def install_duplicate_value(registry)
            registry.register(
              "duplicate_value", required: %w(nodes attribute),
                                 validate_args: method(:validate_duplicate_value),
                                 expand: method(:duplicate_value_findings)
            )
          end

          def validate_duplicate_value(args, namespaces = {})
            Checks::ATTRIBUTE_NAME.match?(args["attribute"].to_s) or
              raise RuleError, "invalid attribute #{args['attribute'].inspect}"
            Checks.validate_xpath_nodes(args["nodes"], namespaces, "nodes")
          end

          def duplicate_value_findings(root, args, namespaces)
            first = {}
            root.xpath(args["nodes"], namespaces).filter_map do |elem|
              value = elem[args["attribute"]]
              unless first.key?(value)
                first[value] = elem
                next
              end
              [elem, elem, { "value" => value, "line" => first[value].line }]
            end
          end
        end
      end
    end
  end
end
