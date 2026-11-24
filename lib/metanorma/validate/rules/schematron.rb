# frozen_string_literal: true

module Metanorma
  module Standoc
    class Validate
      module Rules
        # One-way export to ISO Schematron. Code-backed rules have no XPath
        # equivalent, so they are listed rather than approximated.
        module Schematron
          NS = "http://purl.oclc.org/dsdl/schematron"

          Export = Data.define(:xml, :code_backed)
          Failure = Data.define(:id, :message, :node)

          module_function

          def test_for(rule)
            rule.check.schematron&.call(rule.target, rule.args)
          end

          def export(rule_set)
            portable, code_backed = rule_set.rules.partition { |r| test_for(r) }
            portable.each { |rule| validate_context(rule) }
            Export.new(xml: build(portable, rule_set.namespaces).to_xml,
                       code_backed: code_backed.map(&:id))
          end

          # Runs a Schematron document (xslt queryBinding, XPath 1.0 only:
          # no let, phases, abstract patterns or XSLT functions) against an
          # XML document, so exported rules can be checked without an
          # external processor. Like Schematron, a node fires only the first
          # rule of a pattern that matches it. Returns Failure values for
          # failed asserts and for reports whose test holds.
          def evaluate(schema_xml, doc)
            schema = Nokogiri::XML(schema_xml) { |c| c.strict.nonet }
            ns = { "s" => NS }
            bindings = schema.xpath("//s:ns", ns).to_h { |n| [n["prefix"], n["uri"]] }
            schema.xpath("//s:pattern", ns).flat_map do |pattern|
              pattern_failures(pattern, doc, bindings, ns)
            end
          end

          def pattern_failures(pattern, doc, bindings, ns)
            seen = {}.compare_by_identity
            pattern.xpath("s:rule", ns).flat_map do |rule|
              doc.xpath(rule["context"], bindings).flat_map do |node|
                next [] if seen.key?(node)

                seen[node] = true
                rule_failures(rule, node, bindings, ns)
              end
            end
          end

          def rule_failures(rule, node, bindings, ns)
            rule.xpath("s:assert|s:report", ns).filter_map do |check|
              held = node.xpath("boolean(#{check['test']})", bindings)
              next unless check.name == "assert" ? !held : held

              Failure.new(id: check["id"], message: check.text, node: node)
            end
          end

          # Each rule gets its own pattern: within a pattern, Schematron
          # fires only the first rule matching a node.
          def build(rules, namespaces)
            Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
              xml.schema(xmlns: NS, queryBinding: "xslt") do
                namespaces.each { |prefix, uri| xml.ns(prefix: prefix, uri: uri) }
                rules.each do |r|
                  xml.pattern(id: "pattern-#{r.id}") do
                    xml.rule(context: r.context) do
                      xml.assert(r.code, id: r.id, test: test_for(r))
                    end
                  end
                end
              end
            end
          end

          # XPath selection is broader than XSLT match syntax. Reject a rule
          # that cannot be executed by an xslt-queryBinding processor instead
          # of exporting a plausible but unusable Schematron document.
          def validate_context(rule)
            sheet = Nokogiri::XML::Builder.new do |xml|
              attrs = { "xmlns:xsl" => "http://www.w3.org/1999/XSL/Transform",
                        "version" => "1.0" }
              rule.namespaces.each { |prefix, uri| attrs["xmlns:#{prefix}"] = uri }
              xml["xsl"].stylesheet(attrs) do
                xml["xsl"].template(match: rule.context)
              end
            end
            Nokogiri::XSLT(sheet.to_xml)
          rescue RuntimeError, Nokogiri::XML::SyntaxError => e
            raise RuleError, "rule #{rule.id}: nonportable Schematron context: #{e.message}"
          end
        end
      end
    end
  end
end
