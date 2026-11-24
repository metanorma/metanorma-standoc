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
