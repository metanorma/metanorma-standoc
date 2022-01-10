# frozen_string_literal: true

require "erb"

module Metanorma
  module Datamodel
    class PlantumlRenderer
      TEMPLATES_PATH = File.expand_path("../views/datamodel", __dir__).freeze

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
            File.join(TEMPLATES_PATH, "plantuml_representation.adoc.erb")
          )
        ).result(binding)
      end

      def diagram_caption
        yml["caption"]
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
          #{join_as_plantuml(
            classes_to_classes_plantuml(yml['classes']),
            enums_to_enums_plantuml(yml['enums'])
          )}
        TEMPLATE
      end

      def class_groups_yml_to_plantuml
        return if empty?(yml, "groups")

        <<~TEMPLATE
          '******* CLASS GROUPS *************************************************
          #{join_as_plantuml(
            groups_to_plantuml(yml['groups'])
          )}
        TEMPLATE
      end

      def class_relations_yml_to_plantuml
        return if empty?(yml, "classes") && empty?(yml, "relations")

        <<~TEMPLATE
          '******* CLASS RELATIONS **********************************************
          #{join_as_plantuml(
            classes_to_relations_plantuml(yml['classes']),
            relations_to_plantuml(nil, yml['relations'])
          )}
        TEMPLATE
      end

      def diagram_options_yml_to_plantuml
        return if empty?(yml, "diagram_options")

        <<~TEMPLATE
          '******* DIAGRAM SPECIFIC CONFIG **************************************
          #{join_as_plantuml(
            diagram_options_to_plantuml(yml['diagram_options'])
          )}
        TEMPLATE
      end

      def bottom_yml_to_plantuml
        return if empty?(yml, "bottom")

        <<~TEMPLATE
          '******* BOTTOM OVERRIDE CONFIG **************************************
          #{join_as_plantuml(bottom_to_plantuml(yml['bottom']))}
        TEMPLATE
      end

      def fidelity_yml_to_plantuml
        return if empty?(yml, "fidelity")

        <<~TEMPLATE
          '******* FIDELITY *****************************************************
          #{join_as_plantuml(fidelity_to_plantuml(yml['fidelity']))}
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
          #{join_as_plantuml(
            attributes_to_plantuml(class_hash['attributes']),
            constraints_to_plantuml(class_hash['constraints'])
          )}
          }
        TEMPLATE
      end

      def attributes_to_plantuml(attributes)
        return unless attributes

        attributes.map do |(attr_name, attr_hash)|
          attribute_to_plantuml(attr_name, attr_hash)
        end.join("").sub(/\n\Z/, "")
      end

      def attribute_to_plantuml(attr_name, attr_hash)
        <<~TEMPLATE
          +#{attr_name}: #{attr_hash['type']}#{attribute_cardinality_plantuml(attr_hash['cardinality'])}
        TEMPLATE
      end

      def attribute_cardinality_plantuml(cardinality, with_bracket = true)
        return "" if cardinality.nil? ||
          (cardinality["min"] == cardinality["max"] &&
            cardinality["min"] == 1)

        card = "#{cardinality['min']}..#{cardinality['max']}"
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
          #{join_as_plantuml(
            *constraints_output
          )}
        TEMPLATE
      end

      def classes_to_relations_plantuml(classes)
        output_ary = classes.map do |(class_name, class_hash)|
          class_hash ||= {}
          relations = class_hash["relations"]
          relations_to_plantuml(class_name, relations)
        end

        join_as_plantuml(*output_ary)
      end

      def relations_to_plantuml(class_name, relations)
        return unless relations

        output_ary = relations.map do |relation|
          source = class_name || relation["source"]
          relation_to_plantuml(source,
                               relation["target"],
                               relation)
        end

        join_as_plantuml(*output_ary)
      end

      def relation_arrow(relationship, relation)
        [
          relationship_type_to_plantuml("source",
                                        relationship["source"]["type"]),
          (relation["direction"]).to_s,
          relationship_type_to_plantuml("target",
                                        relationship["target"]["type"]),
        ].compact.join("-")
      end

      def relation_label(action)
        return "" unless action

        case action["direction"]
        when "source"
          " : < #{action['verb']}"
        when "target"
          " : #{action['verb']} >"
        else
          ""
        end
      end

      def source_arrow_end(source, relationship)
        source_attribute = relationship_cardinality_to_plantuml(
          relationship["source"]["attribute"]
        )
        [source, source_attribute].join(" ")
      end

      def target_arrow_end(target, relationship, action)
        target_attribute = relationship_cardinality_to_plantuml(
          relationship["target"]["attribute"]
        )
        [
          [target_attribute, target].join(" "),
          relation_label(action),
        ].join
      end

      def relation_association(source, target, association)
        return unless association

        "\n(#{source}, #{target}) . #{association}"
      end

      def relation_to_plantuml(source, target, relation)
        relationship = relation["relationship"] || {}
        relationship["source"] ||= {}
        relationship["target"] ||= {}
        relation_output_lines(source, target, relation, relationship)
      end

      def relation_output_lines(source, target, relation, relationship)
        output_lines = [
          source_arrow_end(source, relationship),
          relation_arrow(relationship, relation),
          target_arrow_end(target, relationship, relation["action"]),
          relation_association(source, target, relationship["association"]),
        ].join(" ")

        join_as_plantuml(*output_lines)
      end

      def relationship_type_to_plantuml(relation_end, relationship_type)
        is_source = (relation_end == "source")
        mappings = {
          "direct" => is_source ? "<" : ">",
          "inheritance" => is_source ? "<|" : "|>",
          "composition" => "*",
          "aggregation" => "o",
        }
        mappings.fetch(relationship_type, "")
      end

      def relationship_cardinality_to_plantuml(attribute)
        attribute_name = (attribute || {}).keys.first

        return unless attribute_name

        attribute_hash = attribute[attribute_name] || {}
        card = attribute_cardinality(attribute_hash["cardinality"])
        "\"+#{attribute_name}#{card}\""
      end

      def attribute_cardinality(attribute_cardinality)
        cardinality = ""
        if attribute_cardinality
          cardinality = attribute_cardinality_plantuml(
            attribute_cardinality,
            false
          )
          cardinality = " #{cardinality}"
        end
        cardinality
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
          #{join_as_plantuml(enum_values_to_plantuml(enum_hash['values']))}
          }
        TEMPLATE
      end

      def model_stereotype_to_plantuml(model_stereotype)
        return "" unless model_stereotype

        " <<#{model_stereotype}>>"
      end

      def enum_values_to_plantuml(enum_values)
        output_ary = enum_values.map do |(enum_value, _enum_value_hash)|
          "  #{enum_value}"
        end

        join_as_plantuml(*output_ary)
      end

      def groups_to_plantuml(groups)
        groups ||= []
        return if groups.empty?

        groups.reduce("") do |output, group|
          output += "\ntogether {\n"
          group.each do |class_name|
            output += "\nclass #{class_name}\n"
          end
          output += "\n}\n"
          output
        end
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

      def format_hidden_class(accum, fidelity_classes, class_hash)
        return accum if class_hash["relations"].nil?

        class_hash["relations"].each_with_object(accum) do |relation, acc|
          format_source_target_relation(relation, fidelity_classes, acc)
          format_association_relation(relation, fidelity_classes, acc)
        end
      end

      def format_source_target_relation(relation, fidelity_classes, acc)
        %w[source target].each do |type|
          next unless relation[type] && !fidelity_classes.key?(relation[type])

          acc.merge!(relation[type] => true)
        end
      end

      def format_association_relation(relation, fidelity_classes, acc)
        return unless relation["relationship"] &&
          relation["relationship"]["association"]

        association = relation["relationship"]["association"]
        return unless association && !fidelity_classes.key?(association)

        acc.merge!(association => true)
      end

      def hide_other_classes(fidelity)
        return "" if fidelity.nil? || fidelity["classes"].nil?

        output = ""
        hidden_classes = fidelity["classes"]
          .reduce({}) do |acc, (_class_name, class_hash)|
          format_hidden_class(acc, fidelity["classes"], class_hash)
        end

        hidden_classes.each_key do |hidden_class_name|
          output += "\nhide #{hidden_class_name}\n"
        end
        output
      end

      def fidelity_to_plantuml(fidelity)
        return "" if fidelity.nil?

        output = ""
        output += hide_other_classes(fidelity) if fidelity["hideOtherClasses"]
        output += "\nhide members\n" if fidelity["hideMembers"]
        output
      end

      def empty?(yml, prop)
        yml[prop].nil? || yml[prop].length.zero?
      end
    end
  end
end
