require 'erb'

module Asciidoctor
  module Datamodel
    class PlantumlRenderer
      TEMPLATES_PATH = File.expand_path('../../views/datamodel', __FILE__).freeze

      attr_reader :yml, :plantuml_path

      def initialize(yml, plantuml_path)
        @yml = yml
        @plantuml_path = plantuml_path
      end

      def join_as_plantuml(*ary)
        ary.compact.join("\n").sub(/\s+\Z/, "")
      end

      def render
        ERB.new(
          File.read(
            File.join(TEMPLATES_PATH, 'plantuml_representation.adoc.erb')
          )
        ).result(binding)
      end

      def diagram_caption
        yml['caption']
      end

      def imports_yml_to_plantuml
        return if empty?(yml, "imports")

        <<~TEMPLATE
          '******* IMPORTS ******************************************************
          !include #{plantuml_path}/style.uml.inc
        TEMPLATE
      end

      def class_defs_yml_to_plantuml
        return if empty?(yml, "classes") && empty?(yml, "enums")

        <<~TEMPLATE
          '******* CLASS DEFINITIONS ********************************************
          #{
            join_as_plantuml(
              classes_to_classes_plantuml(yml['classes']),
              enums_to_enums_plantuml(yml['enums'])
            )
          }
        TEMPLATE
      end

      def class_groups_yml_to_plantuml
        return if empty?(yml, "groups")

        <<~TEMPLATE
          '******* CLASS GROUPS *************************************************
          #{
            join_as_plantuml(
              groups_to_plantuml(yml['groups'])
            )
          }
        TEMPLATE
      end

      def class_relations_yml_to_plantuml
        return if empty?(yml, 'classes') && empty?(yml, 'relations')

        <<~TEMPLATE
          '******* CLASS RELATIONS **********************************************
          #{
            join_as_plantuml(
              classes_to_relations_plantuml(yml['classes']),
              relations_to_plantuml(nil, yml['relations'])
            )
          }
        TEMPLATE
      end

      def diagram_options_yml_to_plantuml
        return if empty?(yml, 'diagram_options')

        <<~TEMPLATE
          '******* DIAGRAM SPECIFIC CONFIG **************************************
          #{
            join_as_plantuml(
              diagram_options_to_plantuml(yml['diagram_options'])
            )
          }
        TEMPLATE
      end

      def bottom_yml_to_plantuml
        return if empty?(yml, 'bottom')

        <<~TEMPLATE
          '******* BOTTOM OVERRIDE CONFIG **************************************
          #{
            join_as_plantuml(
              bottom_to_plantuml(yml['bottom'])
            )
          }
        TEMPLATE
      end

      def fidelity_yml_to_plantuml
        return if empty?(yml, 'fidelity')

        <<~TEMPLATE
          '******* FIDELITY *****************************************************
          #{
            join_as_plantuml(
              fidelity_to_plantuml(yml['fidelity'])
            )
          }
        TEMPLATE
      end

      def classes_to_classes_plantuml(classes)
        classes ||= {}

        return if classes.empty?

        classes.map do |(class_name, class_hash)|
          class_to_plantuml(class_name, class_hash)
        end.join("\n")
      end

      def class_to_plantuml(class_name, class_hash)
        return unless class_name

        class_hash ||= {}

        <<~TEMPLATE
          class #{class_name}#{model_stereotype_to_plantuml(class_hash['type'])} {
          #{
            join_as_plantuml(
              attributes_to_plantuml(class_hash['attributes']),
              constraints_to_plantuml(class_hash['constraints'])
            )
          }
          }
        TEMPLATE
      end

      def attributes_to_plantuml(attributes)
        return unless attributes

        attributes.map do |(attr_name, attr_hash)|
          attribute_to_plantuml(attr_name, attr_hash)
        end.join('').sub(/\n\Z/, '')
      end

      def attribute_to_plantuml(attr_name, attr_hash)
        <<~TEMPLATE
          +#{attr_name}: #{attr_hash['type']}#{attribute_cardinality_plantuml(attr_hash['cardinality'])}
        TEMPLATE
      end

      def attribute_cardinality_plantuml(cardinality, with_bracket = true)
        return "" unless cardinality

        min_card = cardinality['min'] || 1
        max_card = cardinality['max'] || 1

        return "" if min_card == 1 && max_card == 1

        card = "#{min_card}..#{max_card}"

        return card unless with_bracket

        "[#{card}]"
      end

      def constraints_to_plantuml(constraints)
        constraints ||= []

        return if constraints.empty?

        constraints_output = constraints.map do |constraint|
          "  {#{constraint}}"
        end

        <<~TEMPLATE
            __ constraints __
          #{
            join_as_plantuml(
              *constraints_output
            )
          }
        TEMPLATE
      end

      def classes_to_relations_plantuml(classes)
        output_ary = classes.map do |(class_name, class_hash)|
          class_hash ||= {}
          relations = class_hash['relations']
          relations_to_plantuml(class_name, relations)
        end

        join_as_plantuml(*output_ary)
      end

      def relations_to_plantuml(class_name, relations)
        return unless relations

        output_ary = relations.map do |relation|
          source = class_name || relation['source']
          relation_to_plantuml(source, relation)
        end

        join_as_plantuml(*output_ary)
      end

      def relation_to_plantuml(source, relation)
        target = relation['target']
        relationship = {}.merge(relation['relationship'] || {})

        relationship['source'] ||= {}
        relationship['target'] ||= {}

        arrow = [
          relationship_type_to_plantuml('source', relationship['source']['type']),
          "#{relation['direction']}",
          relationship_type_to_plantuml('target', relationship['target']['type']),
        ].compact.join("-")

        action = relation['action'] || {}

        label = case action['direction']
          when 'source'
            " : < #{action['verb']}"
          when 'target'
            " : #{action['verb']} >"
          else
            ''
          end

        source_attribute = relationship_cardinality_to_plantuml(
          relationship['source']['attribute']
        )
        source_arrow_end = [source, source_attribute].join(" ")

        target_attribute = relationship_cardinality_to_plantuml(
          relationship['target']['attribute']
        )
        target_arrow_end = [target_attribute, target].join(" ")

        output_lines = ["#{source_arrow_end} #{arrow} #{target_arrow_end}#{label}"]

        if relationship['association']
          output_lines.push("(#{source}, #{target}) . #{relationship['association']}")
        end

        join_as_plantuml(*output_lines)
      end

      def relationship_type_to_plantuml(relation_end, relationship_type)
        is_source = relation_end == 'source'

        case relationship_type
        when 'direct'
          is_source ? "<" : ">"
        when 'inheritance'
          is_source ? "<|" : "|>"
        when 'composition'
          "*"
        when 'aggregation'
          "o"
        else
          ""
        end
      end

      def relationship_cardinality_to_plantuml(attribute)
        attribute_name = (attribute || {}).keys.first

        return unless attribute_name

        attribute_hash = attribute[attribute_name] || {}
        attribute_cardinality = attribute_hash['cardinality']
        cardinality = ""

        if attribute_cardinality
          cardinality = attribute_cardinality_plantuml(
            attribute_cardinality,
            false
          )

          cardinality = " #{cardinality}"
        end

        "\"+#{attribute_name}#{cardinality}\""
      end

      def enums_to_enums_plantuml(enums)
        enums ||= {}

        enums.map do |(enum_name, enum_hash)|
          enum_to_plantuml(enum_name, enum_hash)
        end.join("\n\n")
      end

      def enum_to_plantuml(enum_name, enum_hash)
        enum_hash ||= {}

        <<~TEMPLATE
          enum #{enum_name}#{model_stereotype_to_plantuml(enum_hash['type'])} {
          #{
            join_as_plantuml(
              enum_values_to_plantuml(enum_hash['values'])
            )
          }
          }
        TEMPLATE
      end

      def model_stereotype_to_plantuml(model_stereotype)
        return "" unless model_stereotype

        " <<#{model_stereotype}>>"
      end

      def enum_values_to_plantuml(enum_values)
        output_ary = enum_values.map do |(enum_value, enum_value_hash)|
          "  #{enum_value}"
        end

        join_as_plantuml(*output_ary)
      end

      def groups_to_plantuml(groups)
        groups ||= []
        return if groups.empty?

        output = ""
        groups.each do |group|
          output += "\ntogether {\n"
          group.each do |class_name|
                      output += "\nclass #{class_name}\n"
                    end
          output += "\n}\n"
        end
        output
      end

      def diagram_options_to_plantuml(diagram_options)
        diagram_options ||= []
        return if diagram_options.empty?

        "#{diagram_options.join("\n")}\n"
      end

      def bottom_to_plantuml(bottom)
        bottom ||= []
        return if bottom.empty?

        "#{bottom.join("\n")}\n"
      end

      def hide_other_classes(fidelity)
        output = "";
        fidelity_classes = fidelity['classes'] || {}

        hidden_classes = fidelity_classes.reduce({}) do |acc, (class_name, class_hash)|
          relations = class_hash['relations'] || []
          relations.each do |relation|
            ["source", "target"].each do |type|
              if relation[type] && !fidelity_classes.has_key?(relation[type])
                acc = acc.merge({
                  relation[type] => true
                })
              end
            end
            relationship = relation['relationship'] || {}
            association = relationship['association']
            if association && !fidelity_classes.has_key?(association)
              acc = acc.merge({
                association => true
              })
            end
          end
          acc
        end

        hidden_classes.keys.each do |hidden_class_name|
          output += <<~TEMPLATE
            hide #{hidden_class_name}
          TEMPLATE
        end
        output
      end

      def fidelity_to_plantuml(fidelity)
        output = "";
        fidelity ||= {}

        if fidelity['hideOtherClasses']
          output += hide_other_classes(fidelity)
        end

        if fidelity['hideMembers']
          output += <<~TEMPLATE
            hide members
          TEMPLATE
        end

        output.empty? ? nil : output
      end

      def empty?(yml, prop)
        !yml[prop] || yml[prop].empty?
      end
    end
  end
end
