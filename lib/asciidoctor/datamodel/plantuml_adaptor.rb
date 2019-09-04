module Asciidoctor
  module DataModel
    module PlantumlAdaptor
      def self.yml_to_plantuml(yml, plantuml_path)
        startuml = <<-plantuml
@startuml
        plantuml

        enduml = <<-plantuml
@enduml
        plantuml

        [
          startuml,
          imports_yml_to_plantuml(yml, plantuml_path),
          class_defs_yml_to_plantuml(yml),
          class_groups_yml_to_plantuml(yml),
          class_relations_yml_to_plantuml(yml),
          fidelity_yml_to_plantuml(yml),
          enduml,
        ].compact.join("\n")
      end

      def self.imports_yml_to_plantuml(yml, plantuml_path)
        return if empty?(yml, "imports")

        <<-plantuml
'******* IMPORTS ******************************************************
#{import_models_to_plantuml(yml["imports"], plantuml_path)}
        plantuml
      end

      def self.class_defs_yml_to_plantuml(yml)
        return if empty?(yml, "classes") && empty?(yml, "enums")

        <<-plantuml
'******* CLASS DEFINITIONS ********************************************
#{classes_to_classes_plantuml(yml["classes"])}
#{enums_to_enums_plantuml(yml["enums"])}
        plantuml
      end

      def self.class_groups_yml_to_plantuml(yml)
        return if empty?(yml, "groups")

        <<-plantuml
'******* CLASS GROUPS *************************************************
#{groups_to_plantuml(yml["groups"])}
        plantuml
      end

      def self.class_relations_yml_to_plantuml(yml)
        return if empty?(yml, "classes") && empty?(yml, "relations")

        <<-plantuml
'******* CLASS RELATIONS **********************************************
#{classes_to_relations_plantuml(yml["classes"])}
#{relations_to_plantuml(nil, yml["relations"])}
        plantuml
      end

      def self.fidelity_yml_to_plantuml(yml)
        return if empty?(yml, "fidelity")

        <<-plantuml
'******* FIDELITY *****************************************************
#{fidelity_to_plantuml(yml["fidelity"])}
        plantuml
      end

      def self.import_models_to_plantuml(imported_models, plantuml_path)
        imported_models ||= []

        output = ""

        unless imported_models.empty?
          output += "!include #{plantuml_path}/style.uml.inc\n"
        end

        output += imported_models.map do |(imported_model_path, imported_model_hash)|
          "!include #{plantuml_path}/models/#{imported_model_path}.wsd"
        end.join("\n")
      end

      def self.classes_to_classes_plantuml(classes)
        classes ||= {}

        classes.map do |(class_name, class_hash)|
          class_to_plantuml(class_name, class_hash)
        end.join("\n")
      end

      def self.class_to_plantuml(class_name, class_hash)
        class_hash ||= {}

        <<-plantuml
class #{class_name} {
#{attributes_to_plantuml(class_hash["attributes"])}
}
        plantuml
      end

      def self.attributes_to_plantuml(attributes)
        return "" unless attributes

        attributes.map do |(attr_name, attr_hash)|
          attribute_to_plantuml(attr_name, attr_hash)
        end.join("").sub(/\n\Z/, "")
      end

      def self.attribute_to_plantuml(attr_name, attr_hash)
        <<-plantuml
  +#{attr_name}: #{attr_hash["type"]}#{attribute_cardinality_plantuml(attr_hash["cardinality"])}
        plantuml
      end

      def self.attribute_cardinality_plantuml(cardinality, withBracket = true)
        return "" unless cardinality

        min_card = cardinality["min"] || 1
        max_card = cardinality["max"] || 1

        return "" if min_card == 1 && max_card == 1

        card = "#{min_card}..#{max_card}"

        return card unless withBracket

        "[#{card}]"
      end

      def self.classes_to_relations_plantuml(classes)
        classes.map do |(class_name, class_hash)|
          class_hash ||= {}
          relations = class_hash["relations"]
          relations_to_plantuml(class_name, relations)
        end.join("\n").strip
      end

      def self.relations_to_plantuml(class_name, relations)
        return "" unless relations

        # binding.pry
        relations.map do |relation|
          source = class_name || relation["source"]
          relation_to_plantuml(source, relation)
        end.compact.join("\n").strip
      end

      def self.relation_to_plantuml(source, relation)
        target = relation["target"]
        relationship = {}.merge(relation["relationship"] || {})

        relationship["source"] ||= {}
        relationship["target"] ||= {}

        arrow = [
          relationship_type_to_plantuml("source", relationship["source"]["type"]),
          "#{relation["direction"]}--",
          relationship_type_to_plantuml("target", relationship["target"]["type"]),
        ].compact.join("-")

        action = relation["action"] || {}

        label = case action["direction"]
          when "source"
            " : < #{action["verb"]}"
          when "target"
            " : #{action["verb"]} >"
          else
            ""
          end

        source_attribute = relationship_cardinality_to_plantuml(
          relationship["source"]["attribute"]
        )
        source_arrow_end = [source, source_attribute].join(" ")

        target_attribute = relationship_cardinality_to_plantuml(
          relationship["target"]["attribute"]
        )
        target_arrow_end = [target_attribute, target].join(" ")

        output_lines = ["#{source_arrow_end} #{arrow} #{target_arrow_end}#{label}"]

        if relationship["association"]
          output_lines.push("(#{source}, #{target}) .. #{relationship["association"]}")
        end

        # binding.pry
        output_lines.join("\n")
      end

      def self.relationship_type_to_plantuml(relation_end, relationship_type)
        is_source = relation_end == "source"

        case relationship_type
        when "direct"
          is_source ? "<" : ">"
        when "inheritance"
          is_source ? "<|" : "|>"
        when "composition"
          "*"
        when "aggregation"
          "o"
        else
          ""
        end
      end

      def self.relationship_cardinality_to_plantuml(attribute)
        attribute_name = (attribute || {}).keys.first

        return unless attribute_name

        attribute_hash = attribute[attribute_name]
        attribute_cardinality = attribute_hash["cardinality"]
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

      def self.enums_to_enums_plantuml(enums)
        enums ||= {}

        enums.map do |(enum_name, enum_hash)|
          enum_to_plantuml(enum_name, enum_hash)
        end.join("\n\n")
      end

      def self.enum_to_plantuml(enum_name, enum_hash)
        enum_hash ||= {}

        <<-plantuml
enum #{enum_name}#{enum_type_to_plantuml(enum_hash["type"])} {
#{enum_values_to_plantuml(enum_hash["values"])}
}
        plantuml
      end

      def self.enum_type_to_plantuml(enum_type)
        return "" unless enum_type

        " <<#{enum_type}>>"
      end

      def self.enum_values_to_plantuml(enum_values)
        enum_values.map do |(enum_value, enum_value_hash)|
          "  #{enum_value}"
        end.join("\n")
      end

      def self.groups_to_plantuml(groups)
        output = ""
        groups ||= []

        groups.each do |group|
          output += <<-plantuml
together {
          plantuml

          group.each do |class_name|
            output += <<-plantuml
  class #{class_name}
            plantuml
          end

          output += <<-plantuml
}
          plantuml
        end

        output
      end

      def self.fidelity_to_plantuml(fidelity)
        output = "";
        fidelity ||= {}

        if fidelity["hideOtherClasses"]
          fidelity_classes = fidelity["classes"] || {}

          hidden_classes = fidelity_classes.reduce({}) do |acc, (class_name, class_hash)|
            relations = class_hash["relations"] || []

            relations.each do |relation|
              ["source", "target"].each do |type|
                if relation[type] && !fidelity_classes.has_key?(relation[type])
                  acc = acc.merge({
                    relation[type] => true
                  })
                end
              end
            end

            acc
          end

          hidden_classes.keys.each do |hidden_class_name|
            output += <<-plantuml
hide #{hidden_class_name}
            plantuml
          end
        end

        if fidelity["hideMembers"]
          output += <<-plantuml
hide members
          plantuml
        end

        output
      end

      def self.empty?(yml, prop)
        !yml[prop] || yml[prop].empty?
      end
    end
  end
end