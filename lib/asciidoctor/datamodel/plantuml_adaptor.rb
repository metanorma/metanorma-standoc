module Asciidoctor
  module DataModel
    module PlantumlAdaptor
      def self.join_as_plantuml(*ary)
        ary.compact.join("\n").sub(/\s+\Z/, "")
      end

      def self.yml_to_plantuml(yml, plantuml_path)
        startuml = <<-plantuml
@startuml
        plantuml

        enduml = <<-plantuml
@enduml
        plantuml

        join_as_plantuml(
          startuml,
          diagram_options_yml_to_plantuml(yml),
          class_groups_yml_to_plantuml(yml),
          imports_yml_to_plantuml(yml, plantuml_path),
          class_defs_yml_to_plantuml(yml),
          class_relations_yml_to_plantuml(yml),
          fidelity_yml_to_plantuml(yml),
          bottom_yml_to_plantuml(yml),
          enduml,
        )
      end

      def self.imports_yml_to_plantuml(yml, plantuml_path)
        return if empty?(yml, "imports")

        <<-plantuml
'******* IMPORTS ******************************************************
#{
  join_as_plantuml(
    import_models_to_plantuml(yml["imports"], plantuml_path)
  )
}
        plantuml
      end

      def self.class_defs_yml_to_plantuml(yml)
        return if empty?(yml, "classes") && empty?(yml, "enums")

        <<-plantuml
'******* CLASS DEFINITIONS ********************************************
#{
  join_as_plantuml(
    classes_to_classes_plantuml(yml["classes"]),
    enums_to_enums_plantuml(yml["enums"])
  )
}
        plantuml
      end

      def self.class_groups_yml_to_plantuml(yml)
        return if empty?(yml, "groups")

        <<-plantuml
'******* CLASS GROUPS *************************************************
#{
  join_as_plantuml(
    groups_to_plantuml(yml["groups"])
  )
}
        plantuml
      end

      def self.class_relations_yml_to_plantuml(yml)
        return if empty?(yml, "classes") && empty?(yml, "relations")

        <<-plantuml
'******* CLASS RELATIONS **********************************************
#{
  join_as_plantuml(
    classes_to_relations_plantuml(yml["classes"]),
    relations_to_plantuml(nil, yml["relations"])
  )
}
        plantuml
      end

      def self.diagram_options_yml_to_plantuml(yml)
        return if empty?(yml, "diagram_options")

        <<-plantuml
'******* DIAGRAM SPECIFIC CONFIG **************************************
#{
  join_as_plantuml(
    diagram_options_to_plantuml(yml["diagram_options"])
  )
}
        plantuml
      end

      def self.bottom_yml_to_plantuml(yml)
        return if empty?(yml, "bottom")

        <<-plantuml
'******* BOTTOM OVERRIDE CONFIG **************************************
#{
  join_as_plantuml(
    bottom_to_plantuml(yml["bottom"])
  )
}
        plantuml
      end

      def self.fidelity_yml_to_plantuml(yml)
        return if empty?(yml, "fidelity")

        <<-plantuml
'******* FIDELITY *****************************************************
#{
  join_as_plantuml(
    fidelity_to_plantuml(yml["fidelity"])
  )
}
        plantuml
      end

      def self.import_models_to_plantuml(imported_models, plantuml_path)
        imported_models ||= []

        return if imported_models.empty?

        output = ""

        unless imported_models.empty?
          output += "!include #{plantuml_path}/style.uml.inc\n"
        end

        output += imported_models.map do |(imported_model_path, imported_model_hash)|
          "!include #{plantuml_path}/models/#{imported_model_path}.wsd"
        end.join("\n").strip
      end

      def self.classes_to_classes_plantuml(classes)
        classes ||= {}

        return if classes.empty?

        classes.map do |(class_name, class_hash)|
          class_to_plantuml(class_name, class_hash)
        end.join("\n")
      end

      def self.class_to_plantuml(class_name, class_hash)
        class_hash ||= {}

        <<-plantuml
class #{class_name}#{model_stereotype_to_plantuml(class_hash["type"])} {
#{
  join_as_plantuml(
    attributes_to_plantuml(class_hash["attributes"]),
    constraints_to_plantuml(class_hash["constraints"])
  )
}
}
        plantuml
      end

      def self.attributes_to_plantuml(attributes)
        return unless attributes

        attributes.map do |(attr_name, attr_hash)|
          attribute_to_plantuml(attr_name, attr_hash)
        end.join("").sub(/\n\Z/, "")
      end

      def self.attribute_to_plantuml(attr_name, attr_hash)
        <<-plantuml
  +#{attr_name}: #{attr_hash["type"]}#{attribute_cardinality_plantuml(attr_hash["cardinality"])}
        plantuml
      end

      def self.attribute_cardinality_plantuml(cardinality, with_bracket = true)
        return "" unless cardinality

        min_card = cardinality["min"] || 1
        max_card = cardinality["max"] || 1

        return "" if min_card == 1 && max_card == 1

        card = "#{min_card}..#{max_card}"

        return card unless with_bracket

        "[#{card}]"
      end

      def self.constraints_to_plantuml(constraints)
        constraints ||= []

        return if constraints.empty?

        constraints_output = constraints.map do |constraint|
          "  {#{constraint}}"
        end

        <<-plantuml
  __ constraints __
#{
  join_as_plantuml(
    *constraints_output
  )
}
        plantuml
      end

      def self.classes_to_relations_plantuml(classes)
        output_ary = classes.map do |(class_name, class_hash)|
          class_hash ||= {}
          relations = class_hash["relations"]
          relations_to_plantuml(class_name, relations)
        end

        join_as_plantuml(*output_ary)
      end

      def self.relations_to_plantuml(class_name, relations)
        return unless relations

        output_ary = relations.map do |relation|
          source = class_name || relation["source"]
          relation_to_plantuml(source, relation)
        end

        join_as_plantuml(*output_ary)
      end

      def self.relation_to_plantuml(source, relation)
        target = relation["target"]
        relationship = {}.merge(relation["relationship"] || {})

        relationship["source"] ||= {}
        relationship["target"] ||= {}

        arrow = [
          relationship_type_to_plantuml("source", relationship["source"]["type"]),
          "#{relation["direction"]}",
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
          output_lines.push("(#{source}, #{target}) . #{relationship["association"]}")
        end

        join_as_plantuml(*output_lines)
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

        attribute_hash = attribute[attribute_name] || {}
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
enum #{enum_name}#{model_stereotype_to_plantuml(enum_hash["type"])} {
#{
  join_as_plantuml(
    enum_values_to_plantuml(enum_hash["values"])
  )
}
}
        plantuml
      end

      def self.model_stereotype_to_plantuml(model_stereotype)
        return "" unless model_stereotype

        " <<#{model_stereotype}>>"
      end

      def self.enum_values_to_plantuml(enum_values)
        output_ary = enum_values.map do |(enum_value, enum_value_hash)|
          "  #{enum_value}"
        end

        join_as_plantuml(*output_ary)
      end

      def self.groups_to_plantuml(groups)
        groups ||= []

        return if groups.empty?

        output = ""

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

      def self.diagram_options_to_plantuml(diagram_options)
        diagram_options ||= []
        return if diagram_options.empty?

        "#{diagram_options.join("\n")}\n"
      end

      def self.bottom_to_plantuml(bottom)
        bottom ||= []
        return if bottom.empty?

        "#{bottom.join("\n")}\n"
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

              relationship = relation["relationship"] || {}
              association = relationship["association"]

              if association && !fidelity_classes.has_key?(association)
                acc = acc.merge({
                  association => true
                })
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

        output.empty? ? nil : output
      end

      def self.empty?(yml, prop)
        !yml[prop] || yml[prop].empty?
      end
    end
  end
end