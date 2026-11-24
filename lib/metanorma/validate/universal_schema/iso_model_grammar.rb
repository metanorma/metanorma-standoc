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

          # Closed rendered vocabulary used by native ISO sections, lists, tables
          # and cross-references. Semantic branches retain the source grammar.
          def self.presentation(document)
            grammar = document.root
            {
              "sections" => { "displayorder" => "integer" },
              "clause" => { "autonum" => "string", "displayorder" => "integer" },
              "annex" => { "autonum" => "string", "displayorder" => "integer" },
              "p" => { "displayorder" => "integer" },
              "table" => { "autonum" => "string", "displayorder" => "integer" },
              "li" => { "label" => "string" },
              "xref" => { "id" => "ID" },
            }.each do |name, attributes|
              grammar.xpath(".//r:element[@name='#{name}']", XMLNS).each do |element|
                attributes.each do |attribute, type|
                  next if attribute_names(document, element).include?(attribute)

                  element.add_child(%(<optional xmlns="#{NS}"><attribute name="#{attribute}"><data type="#{type}" datatypeLibrary="#{XSD}"/></attribute></optional>))
                end
              end
            end
            {
              "fmt-title" => [%w(depth id), %w(span semx strong br)],
              "fmt-name" => [%w(id), %w(span semx)],
              "fmt-xref-label" => [%w(container), %w(span semx)],
              "fmt-xref" => [%w(target type), %w(span semx)],
              "semx" => [%w(element source), %w(fmt-xref semx span strong em xref)],
            }.each do |name, (attributes, children)|
              attrs = attributes.map { |attribute| %(<optional><attribute name="#{attribute}"><text/></attribute></optional>) }.join
              refs = children.map { |child| %(<ref name="#{rendered_ref(child)}"/>) }.join
              grammar.add_child(%(<define xmlns="#{NS}" name="#{rendered_ref(name)}"><element name="#{name}">#{attrs}<zeroOrMore><choice><text/>#{refs}</choice></zeroOrMore></element></define>))
            end
            {
              "clause" => %w(fmt-title fmt-xref-label),
              "annex" => %w(fmt-title fmt-xref-label),
              "table" => %w(fmt-name fmt-xref-label),
              "li" => %w(fmt-name),
            }.each do |name, slots|
              grammar.xpath(".//r:element[@name='#{name}']", XMLNS).each do |element|
                group = Nokogiri::XML::Node.new("group", document)
                group.namespace = element.namespace
                element.element_children.to_a.each { |child| group.add_child(child) }
                interleave = Nokogiri::XML::Node.new("interleave", document)
                interleave.namespace = element.namespace
                element.add_child(interleave)
                interleave.add_child(group)
                slots.each { |slot| interleave.add_child(%(<optional xmlns="#{NS}"><ref name="#{rendered_ref(slot)}"/></optional>)) }
              end
            end
            grammar.add_child(%(<define xmlns="#{NS}" name="TextElement" combine="choice"><ref name="#{rendered_ref('semx')}"/></define>))
          end

          def self.rendered_ref(name)
            %w(fmt-title fmt-name fmt-xref-label fmt-xref semx).include?(name) ? "__iso_presentation_#{name}" : name
          end

          def self.attribute_names(document, node, seen = [])
            node.element_children.flat_map do |child|
              case child.name
              when "element" then []
              when "attribute" then [child["name"]]
              when "ref"
                name = child["name"]
                next [] if seen.include?(name)

                document.xpath("/r:grammar/r:define[@name='#{name}']", XMLNS).flat_map { |definition| attribute_names(document, definition, seen + [name]) }
              else attribute_names(document, child, seen)
              end
            end
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
          private_class_method :boolean_attribute, :one, :optional, :rendered_ref, :attribute_names
        end
      end
    end
  end
end
