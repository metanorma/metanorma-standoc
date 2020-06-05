require 'erb'

module Asciidoctor
  module Standoc
    module Datamodel
      class AttributesTablePreprocessor < Asciidoctor::Extensions::Preprocessor
        BLOCK_START_REGEXP = /\{(.+?)\.\*,(.+),(.+)\}/
        BLOCK_END_REGEXP = /\A\{[A-Z]+\}\z/
        MARCO_REGEXP = /\[datamodel_attributes_table,([^,]+),?(.+)?\]/
        TEMPLATES_PATH = File.expand_path('../../views/datamodel', __FILE__).freeze
        # search document for block `datamodel_attributes_table`
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
          model_representation(yaml_relative_path(yaml_path, document))
            .split("\n")
        end

        def model_representation(model_path)
          template = File.read(File.join(
                                        TEMPLATES_PATH,
                                        'model_representation.adoc.erb'
                                      ))
          file_name = File.basename(model_path).gsub(/\.ya?ml/, '')
          ERB
            .new(template)
            .result(binding)
        end

        def yaml_relative_path(file_path, document)
          docfile_directory = File.dirname(document.attributes['docfile'] || '.')
          document.path_resolver.system_path(file_path, docfile_directory)
        end
      end
    end
  end
end
