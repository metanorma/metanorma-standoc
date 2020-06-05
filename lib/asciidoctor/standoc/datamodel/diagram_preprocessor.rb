require 'erb'
require 'asciidoctor/standoc/datamodel/plantuml_renderer'

module Asciidoctor
  module Standoc
    module Datamodel
      class DiagramPreprocessor < Asciidoctor::Extensions::Preprocessor
        BLOCK_START_REGEXP = /\{(.+?)\.\*,(.+),(.+)\}/
        BLOCK_END_REGEXP = /\A\{[A-Z]+\}\z/
        MARCO_REGEXP = /\[datamodel_diagram,([^,]+),?(.+)?\]/
        TEMPLATES_PATH = File.expand_path('../../views/datamodel', __FILE__).freeze
        # search document for block `datamodel_diagram`
        #  read include derectives that goes after that in block and transform
        #  into plantuml block
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
          plantuml_representations(view_hash, yaml_relative_to_doc_path, include_path)
        end

        def yaml_relative_path(file_path, document)
          docfile_directory = File.dirname(document.attributes['docfile'] || '.')
          document.path_resolver.system_path(file_path, docfile_directory)
        end

        def format_import_directives(imports, include_path)
          imports
            .each_with_object({}) do |(import_name, values), res|
              full_model_name = import_name.split('/').join
              include_content = File.read(File.join(
                                                    include_path,
                                                    "#{import_name}.yml"))
              content = YAML.safe_load(include_content)
              if values
                content['skipSection'] = values['skipSection']
              end
              res[content['name'] || full_model_name] = content
            end.compact
        end

        def plantuml_representations(view_hash, view_path, include_path)
          yaml_directory = File.dirname(view_path)
          all_imports = format_import_directives(view_hash['imports'], include_path)
          imports_classes = all_imports.select do |_name, elem|
                              elem['modelType'] == 'class'
                            end
          imports_enums = all_imports.select do |_name, elem|
                            elem['modelType'] == 'enum'
                          end
          fidelity = (view_hash['fidelity'] || {})
                      .merge({ 'classes' => imports_classes })
          view_hash = view_hash.merge(
                                  'classes' => imports_classes,
                                  'enums' => imports_enums,
                                  'relations' => view_hash['relations'] || [],
                                  'fidelity' => fidelity)
          Asciidoctor::Datamodel::PlantumlRenderer
            .new(view_hash, File.join(yaml_directory, '..'))
            .render
            .split("\n")
        end
      end
    end
  end
end
