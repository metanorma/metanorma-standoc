# frozen_string_literal: true

require "erb"
require "asciidoctor/standoc/datamodel/plantuml_renderer"

module Asciidoctor
  module Standoc
    module Datamodel
      class DiagramPreprocessor < Asciidoctor::Extensions::Preprocessor
        BLOCK_START_REGEXP = /\{(.+?)\.\*,(.+),(.+)\}/.freeze
        BLOCK_END_REGEXP = /\A\{[A-Z]+\}\z/.freeze
        MARCO_REGEXP = /\[datamodel_diagram,([^,]+),?(.+)?\]/.freeze
        TEMPLATES_PATH = File.expand_path("../views/datamodel", __dir__).freeze
        # search document for block `datamodel_diagram`
        #  read include derectives that goes after that in block and transform
        #  into plantuml block
        def process(document, reader)
          input_lines = reader.readlines.to_enum
          Reader.new(processed_lines(document, input_lines))
        end

        private

        def processed_lines(document, input_lines)
          input_lines.each_with_object([]) do |line, result|
            if match = line.match(MARCO_REGEXP)
              result
                .push(*parse_datamodel_marco(match[1], match[2], document))
            else
              result.push(line)
            end
          end
        end

        def parse_datamodel_marco(yaml_path, include_path, document)
          include_path ||= File.join(File.dirname(yaml_path), "..", "models")
          include_path = yaml_relative_path(include_path, document)
          yaml_relative_to_doc_path = yaml_relative_path(yaml_path, document)
          view_hash = YAML.safe_load(File.read(yaml_relative_to_doc_path))
          plantuml_representations(view_hash,
                                   yaml_relative_to_doc_path,
                                   include_path)
        end

        def yaml_relative_path(file_path, document)
          docfile = document.attributes["docfile"] || "."
          docfile_directory = File.dirname(docfile)
          document.path_resolver.system_path(file_path, docfile_directory)
        end

        def import_format(include_path, import_name, values)
          include_content = File.read(File.join(
                                        include_path,
                                        "#{import_name}.yml",
                                      ))
          content = YAML.safe_load(include_content)
          if values
            content["skipSection"] = values["skipSection"]
          end
          content
        end

        def format_import_directives(imports, include_path)
          imports
            .each_with_object({}) do |(import_name, values), res|
              full_model_name = import_name.split("/").join
              content = import_format(include_path, import_name, values)
              res[content["name"] || full_model_name] = content
            end.compact
        end

        def prepare_view_hash(view_hash, all_imports)
          view_hash.merge!(
            "classes" => model_type(all_imports, "class"),
            "enums" => model_type(all_imports, "enum"),
            "relations" => view_hash["relations"] || [],
            "fidelity" => (view_hash["fidelity"] || {})
                          .merge!("classes" => model_type(all_imports,
                                                          "class")),
          )
        end

        def model_type(imports, type)
          imports
            .select do |_name, elem|
              elem["modelType"] == type
            end
        end

        def plantuml_representations(view_hash, view_path, include_path)
          yaml_directory = File.dirname(view_path)
          all_imports = format_import_directives(view_hash["imports"],
                                                 include_path)
          prepare_view_hash(view_hash, all_imports)
          Asciidoctor::Datamodel::PlantumlRenderer
            .new(view_hash, File.join(yaml_directory, ".."))
            .render
            .split("\n")
        end
      end
    end
  end
end
