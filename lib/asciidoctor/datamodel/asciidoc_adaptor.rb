require "uuidtools"

module Asciidoctor
  module DataModel
    module AsciidocAdaptor
      CLASS_COLUMN_MAP = {
        name: "Name",
        definition: "Definition",
        mandatory: "Mandatory/ Optional/ Conditional",
        maxOccur: "Max Occur",
        dataType: "Data Type",
      }

      ENUM_COLUMN_MAP = {
        name: "Name",
        definition: "Definition",
      }

      def self.yml_to_asciidoc(yml, model_name, plantuml_path, level=2)
        class_level = level + 1

        <<-asciidoc
#{header_to_asciidoc(yml["title"], yml, level)}

.#{yml["title"]} data model
[plantuml]
....
include::#{plantuml_path}/#{model_name}.wsd[]
....

#{classes_to_asciidoc(yml["classes"], class_level, yml["fidelity"])}
#{enums_to_asciidoc(yml["enums"], class_level, yml["fidelity"])}
        asciidoc
      end

      def self.yml_to_asciidocs(yml, level=3)
        fidelity ||= {}

        AsciidocAdaptor.for_each("classes", yml, level) do |class_name, class_hash, level|
          yield(
            class_name,
            AsciidocAdaptor.class_to_asciidoc(class_name, class_hash, level)
          )
        end

        AsciidocAdaptor.for_each("enums", yml, level) do |enum_name, enum_hash, level|
          yield(
            enum_name,
            AsciidocAdaptor.enum_to_asciidoc(enum_name, enum_hash, level)
          )
        end
      end

      def self.for_each(keys, yml, level=3)
        keys = keys.is_a?(Array) ? keys : [keys]
        keys.each do |key|
          classes = yml[key] || {}

          classes.each do |(class_name, class_hash)|
            yield(class_name, class_hash, level)
          end
        end
      end

      def self.classes_to_asciidoc(classes, level, fidelity)
        fidelity ||= {}
        return "" if fidelity["hideMembers"]

        classes.map do |(class_name, class_hash)|
          class_to_asciidoc(class_name, class_hash, level)
        end.compact.join("\n")
      end

      def self.class_to_asciidoc(class_name, class_hash, level)
        class_hash ||= {}
        class_fidelity = class_hash["fidelity"] || {}

        return if class_fidelity["skipDefinition"]

        <<-asciidoc
#{header_to_asciidoc(class_name, class_hash, level)}
#{class_hash["definition"] || "TODO: class #{class_name}'s definition"}

#{class_attributes_to_asciidoc(class_name, class_hash["attributes"])}
        asciidoc
      end


      def self.class_attributes_to_asciidoc(class_name, attributes)
        attributes ||= []

        return "" if attributes.empty?

        max_space_map = compute_max_columns_space(attributes, CLASS_COLUMN_MAP)

        <<-asciidoc
.#{class_name} attributes
[options="header"]
|===
#{attributes_table_head_asciidoc(max_space_map, CLASS_COLUMN_MAP).strip}
#{
  attributes.map do |(attr_name, attr_hash)|
    class_attribute_to_asciidoc(attr_name, attr_hash, max_space_map)
  end.join("").strip
}
|===
        asciidoc
      end

      def self.compute_max_columns_space(attributes, column_map)
        max_space_map = column_map.reduce({}) do |acc, (column_key, column_name)|
          acc.merge({ column_key => column_name.length })
        end

        max_space_map = attributes.reduce(max_space_map) do |acc, (attr_name, attr_hash)|
          column_map.each do |(column_key, column_name)|
            meta_data = get_attribute_meta_data(attr_name, attr_hash, column_key)
            acc[column_key] = [acc[column_key], meta_data.length].max
          end

          acc
        end

        max_space_map[column_map.keys.last] = 0
        max_space_map
      end

      # TODO: make column headers show as "header" either via
      # "h|" or "options=header"
      def self.attributes_table_head_asciidoc(max_space_map, column_map)
        line = column_map.map do |(column_key, column_name)|
          add_whitespaces_to_table_cell(column_key, column_name, max_space_map)
        end.join("|")

        line_to_table_row(line)
      end

      def self.class_attribute_to_asciidoc(attr_name, attr_hash, max_space_map)
        line = CLASS_COLUMN_MAP.map do |(column_key, column_name)|
          meta_data = get_attribute_meta_data(attr_name, attr_hash, column_key)
          add_whitespaces_to_table_cell(column_key, meta_data, max_space_map)
        end.join("|")

        line_to_table_row(line)
      end

      def self.add_whitespaces_to_table_cell(column_key, cell_value, max_space_map)
        max_column_space = max_space_map[column_key]
        whitespaces_needed = max_column_space == 0 ?
          0:
          max_column_space - cell_value.length + 1

        "#{cell_value}#{" " * whitespaces_needed}"
      end

      def self.get_attribute_meta_data(attr_name, attr_hash, column_key)
        case column_key
        when :name
          attr_name
        when :definition
          get_attribute_definition(attr_name, attr_hash)
        when :mandatory
          get_attribute_mandatory(attr_hash)
        when :maxOccur
          get_attribute_max_occur(attr_hash)
        when :dataType
          get_attribute_data_type(attr_hash)
        end
      end

      def self.get_attribute_definition(attr_name, attr_hash)
        attr_hash["definition"] || "TODO: attribute #{attr_name}'s definition"
      end

      def self.get_attribute_mandatory(attr_hash)
        cardinality = attr_hash["cardinality"] || {}
        case cardinality["min"]
        when 0
          "O"
        else
          "M"
        end
      end

      def self.get_attribute_max_occur(attr_hash)
        cardinality = attr_hash["cardinality"] || {}
        case cardinality["max"]
        when "*"
          "N"
        else
          "1"
        end
      end

      def self.get_attribute_data_type(attr_hash)
        origin = attr_hash["origin"] ?
          "<<#{attr_hash["origin"]}>> ":
          ""
        "#{origin}`#{attr_hash["type"]}`"
      end

      def self.enums_to_asciidoc(enums, level, fidelity)
        fidelity ||= {}
        return "" if fidelity["hideMembers"]

        enums ||= {}

        return "" if enums.empty?

        enums.map do |(enum_name, enum_hash)|
          enum_to_asciidoc(enum_name, enum_hash, level)
        end.join("\n")
      end

      def self.enum_to_asciidoc(enum_name, enum_hash, level)
        <<-asciidoc
#{header_to_asciidoc(enum_name, enum_hash, level)}
#{enum_hash["definition"] || "TODO: enum #{enum_name}'s definition"}

#{enum_values_to_asciidoc(enum_name, enum_hash["values"])}
        asciidoc
      end

      def self.enum_values_to_asciidoc(enum_name, values)
        values ||= []

        return "" if values.empty?

        max_space_map = compute_max_columns_space(values, ENUM_COLUMN_MAP)

        <<-asciidoc
.#{enum_name} values
[options="header"]
|===
#{attributes_table_head_asciidoc(max_space_map, ENUM_COLUMN_MAP).strip}
#{
  values.map do |(val_name, val_hash)|
    enum_value_to_asciidoc(val_name, val_hash, max_space_map)
  end.join("").strip
}
|===
        asciidoc
      end

      def self.enum_value_to_asciidoc(val_name, val_hash, max_space_map)
        line = ENUM_COLUMN_MAP.map do |(column_key, column_name)|
          meta_data = get_enum_value_meta_data(val_name, val_hash, column_key)
          add_whitespaces_to_table_cell(column_key, meta_data, max_space_map)
        end.join("|")

        line_to_table_row(line)
      end

      def self.get_enum_value_meta_data(val_name, val_hash, column_key)
        case column_key
        when :name
          val_name
        when :definition
          get_enum_value_definition(val_name, val_hash)
        end
      end

      def self.get_enum_value_definition(val_name, val_hash)
        val_hash["definition"] || "TODO: value #{val_name}'s definition"
      end

      def self.header_to_asciidoc(name, hash, level)
        [
          directive_to_asciidoc(hash),
          "#{"=" * level} #{name}",
        ].compact.join("\n")
      end

      # introduce UUID suffix, cannot use classname natively because it potentially 
      # clashes with other headers with same text in the document
      def self.directive_to_asciidoc(hash)
        directive = (hash || {})["directive"]
        #directive ? "[[#{directive}]]" : nil
        "[[#{UUIDTools::UUID.random_create}]]"
      end

      def self.line_to_table_row(line)
        <<-asciidoc
|#{line}
        asciidoc
      end
    end
  end
end
