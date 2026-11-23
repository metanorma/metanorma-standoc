# frozen_string_literal: true

module Metanorma
  module Standoc
    class Validate
      module UniversalSchema
        # Canonical ISO SDK realization of the inherited Standoc structure.
        # Generated converter metadata is optional in a genuine SDK model;
        # content/datatype constraints and exact QName/flavor guards remain.
        module ISOModelGrammar
          XMLNS = { "r" => NS }.freeze

          def self.adapt(xml)
            document = Nokogiri::XML(xml) { |config| config.strict.nonet }
            grammar = document.root
            raise Error, "ISO model realization requires the Standoc namespace" unless grammar["ns"] == "https://www.metanorma.org/ns/standoc"

            %w(version schema-version).each do |name|
              optional(document, "/r:grammar/r:define[@name='Root-Attributes']/r:attribute[@name='#{name}']")
            end
            optional(document, "/r:grammar/r:define[@name='section-title']/r:element[@name='title']/r:ref[@name='RequiredId']")
            optional(document, "/r:grammar/r:define[@name='TdAttributes']/r:ref[@name='RequiredId']")
            optional(document, "/r:grammar/r:define[@name='BibDataExtensionType']//r:ref[@name='flavor']")
            language = one(document, "/r:grammar/r:define[@name='language']/r:element[@name='language']")
            language.add_child(boolean_attribute("current"))
            flavor = one(document, "/r:grammar/r:define[@name='flavor']/r:element[@name='flavor']")
            flavor.element_children.each(&:remove)
            flavor.add_child(%(<value xmlns="#{NS}" datatypeLibrary="#{XSD}" type="string">iso</value>))
            grammar.xpath(".//r:element[@name='clause' or @name='annex']", XMLNS).each do |element|
              element.add_child(boolean_attribute("hidden"))
            end
            output = document.to_xml
            Nokogiri::XML::RelaxNG(output)
            output
          end

          def self.boolean_attribute(name)
            %(<optional xmlns="#{NS}"><attribute name="#{name}"><data type="boolean" datatypeLibrary="#{XSD}"/></attribute></optional>)
          end

          def self.one(document, path)
            nodes = document.xpath(path, XMLNS)
            raise Error, "ISO model source pattern is not unique: #{path}" unless nodes.size == 1

            nodes.first
          end

          def self.optional(document, path)
            node = one(document, path)
            wrapper = Nokogiri::XML::Node.new("optional", document)
            wrapper.namespace = node.namespace
            node.add_previous_sibling(wrapper)
            wrapper.add_child(node)
          end
          private_class_method :boolean_attribute, :one, :optional
        end
      end
    end
  end
end
