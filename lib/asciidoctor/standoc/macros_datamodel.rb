require 'asciidoctor/datamodel/plantuml_adaptor'
require 'erb'

module Asciidoctor
  module Standoc
    class DatamodelPreprocessor < Asciidoctor::Extensions::Preprocessor
      BLOCK_START_REGEXP = /\{(.+?)\.\*,(.+),(.+)\}/
      BLOCK_END_REGEXP = /\A\{[A-Z]+\}\z/
      MARCO_REGEXP = /\[datamodel,([^,]+),?(.+)?\]/
      TEMPLATES_PATH = File.expand_path('../views/macros_datamodel', __FILE__).freeze
      # search document for block `datamodel`
      #  read include derectives that goes after that in block and transform
      #  into yaml2text blocks
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
          plantuml(view_hash, yaml_relative_to_doc_path, include_path).split("\n"),
        ].flatten
        unless fidelity['hideMembers']
          result << models_representations(view_hash['imports'], include_path)
        end
        result.flatten
      end

      def plantuml(view_hash, view_path, include_path)
        default_styles_path = File.join(File.dirname(view_path), '..', 'style.uml.inc')
        imports = view_hash['imports']
                    .map do |(import_name, values)|
                      next if values && values['skipSection']

                      File.join(include_path, "#{import_name}.yml")
                    end.compact
        ERB.new(
          File.read(
            File.join(TEMPLATES_PATH, 'plantuml_representation.adoc.erb')
          )
        ).result(binding)
        # view_hash = view_hash.merge({
        #   "classes" => imports_classes,
        #   "enums" => imports_enums,
        #   "relations" => view_hash["relations"] || [],
        #   "fidelity" => (view_hash["fidelity"] || {}).merge({
        #     "classes" => view_hash["classes"]
        #   }),
        # })
        # require 'byebug'
        # byebug
        # <<~TEXT
        # [plantuml]
        # ....
        # #{Asciidoctor::DataModel::PlantumlAdaptor.yml_to_plantuml(view_hash, File.join(yaml_directory, '..'))}
        # ....
        # TEXT
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
        ERB.new(
          File.read(
            File.join(TEMPLATES_PATH, 'model_representation.adoc.erb')
          )
        ).result(binding)
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
