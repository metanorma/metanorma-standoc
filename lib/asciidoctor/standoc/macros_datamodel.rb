require 'asciidoctor/datamodel/plantuml_adaptor'

module Asciidoctor
  module Standoc
    class DatamodelPreprocessor < Asciidoctor::Extensions::Preprocessor
      BLOCK_START_REGEXP = /\{(.+?)\.\*,(.+),(.+)\}/
      BLOCK_END_REGEXP = /\A\{[A-Z]+\}\z/
      MARCO_REGEXP = /\[datamodel,([^,]+),?(.+)?\]/
      # search document for block `datamodel`
      #  read include derectives that goes after that in block and transform
      #  them into:
      #   [yaml2text,definition]
      #   ----
      #   == {definition.name}
      #
      #   %{definition.description}
      #   |===
      #   {definition.attributes.*,attribute,EOF}
      #   {attribute.*,key,EOD}
      #   |key
      #   {EOD}
      #   {attribute.*,key,EOK}
      #   |attribute[key]
      #   {EOK}
      #   {EOF}
      #   |===
      #   ----
      def process(document, reader)
        input_lines = reader.readlines.to_enum
        Reader.new(processed_lines(document, input_lines))
      end

      private

      def processed_lines(document, input_lines)
        result = []
        loop do
          line = input_lines.next
          if match = line.match(MARCO_REGEXP)
            yaml_path = match[1]
            include_path = match[2]
            result.push(*parse_datamodel_marco(yaml_path, include_path, document))
          else
            result.push(line)
          end
        end
        result
      end

      def parse_datamodel_marco(yaml_path, include_path, document)
        include_path ||= File.join(File.dirname(yaml_path), '..', 'models')
        include_path = yaml_relative_path(include_path, document)
        yaml_relative_to_doc_path = yaml_relative_path(yaml_path, document)
        view_hash = YAML.safe_load(File.read(yaml_relative_to_doc_path))
        fidelity = view_hash['fidelity'] || {}
        result = [
          plantuml(view_hash, File.dirname(yaml_relative_to_doc_path), include_path).split("\n"),
        ].flatten
        unless fidelity['hideMembers']
          result << models_representations(view_hash['imports'], include_path)
        end
        result.flatten
      end

      def plantuml(view_hash, yaml_directory, include_path)
        imports = view_hash['imports']
                    .each
                    .with_object({}) do |(import_name, values), res|
                      next if values && values['skipSection']

                      model_content = YAML.safe_load(File.read(File.join(include_path, "#{import_name}.yml")))
                      res[model_content['name'] || import_name] = model_content
                    end
        imports_classes = imports.select { |_name, import| import['modelType'] == 'class' }
        imports_enums = imports.select { |_name, import| import['modelType'] == 'enum' }
        view_hash = view_hash.merge({
          "classes" => imports_classes,
          "enums" => imports_enums,
          "relations" => view_hash["relations"] || [],
          "fidelity" => (view_hash["fidelity"] || {}).merge({
            "classes" => view_hash["classes"]
          }),
        })
        <<~TEXT
        [plantuml]
        ....
        #{Asciidoctor::DataModel::PlantumlAdaptor.yml_to_plantuml(view_hash, File.join(yaml_directory, '..'))}
        ....
        TEXT
      end

      def models_representations(imports, include_path)
        imports
          .keys
          .map do |import_name|
            model_representation(File.join(include_path, "#{import_name}.yml"))
              .split("\n")
          end
          .flatten
      end

      def model_representation(model_path)
        <<~TEMPLATE

        [yaml2text,#{model_path},definition]
        ----

        {if definition.name}
        === {definition.name}
        {end}
        {definition.definition}

        {if definition.attributes}
        {if definition.name}
        .{definition.name} attributes
        {end}
        [cols=5*,options="header"]
        |===
        |Name
        |Definition
        |Mandatory/ Optional/ Conditional
        |Max Occur
        |Data Type

        {definition.attributes&.*,key,EOK}

        |{key}
        |{definition.attributes[key].definition || "TODO: enum " + key + "'s definition"}
        |{definition.attributes[key]&.cardinality&.min == 0 ? "O" : "M"}
        |{definition.attributes[key]&.cardinality&.max == "*" ? "N" : "1"}
        |{definition.attributes[key].origin ? "<<" + definition.attributes[key].origin + ">>" : ""}`{definition.attributes[key].type}`

        {EOK}

        |===
        {end}

        {if definition['values']}
        {if definition.name}
        .{definition.name} values
        {end}
        [cols=2*,options="header"]
        |===
        |Name
        |Definition

        {definition['values']&.*,key,EOK}

        |{key}
        |{definition['values'][key].definition}

        {EOK}
        |===
        {end}

        ----

        TEMPLATE
      end

      def format_model(model_attributes)
        model_attributes
      end

      def yaml_relative_path(file_path, document)
        docfile_directory = File.dirname(document.attributes['docfile'] || '.')
        document.path_resolver.system_path(file_path, docfile_directory)
      end
    end
  end
end
