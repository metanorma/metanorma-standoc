# frozen_string_literal: true

require "liquid/custom_blocks/key_iterator"
require "liquid/custom_filters/values"

Liquid::Template.register_tag("keyiterator", Liquid::CustomBlocks::KeyIterator)
Liquid::Template.register_filter(Liquid::CustomFilters)

module Asciidoctor
  module Standoc
    class Yaml2TextPreprocessor < Asciidoctor::Extensions::Preprocessor
      BLOCK_START_REGEXP = /\{(.+?)\.\*,(.+),(.+)\}/
      BLOCK_END_REGEXP = /\A\{[A-Z]+\}\z/

      attr_reader :document

      # search document for block `yaml2text`
      #   after that take template from block and read file into this template
      #   example:
      #     [yaml2text,foobar.yaml]
      #     ----
      #     === {item.name}
      #     {item.desc}
      #
      #     {item.symbol}:: {item.symbol_def}
      #     ----
      #
      #   with content of `foobar.yaml` file equal to:
      #     - name: spaghetti
      #       desc: wheat noodles of 9mm diameter
      #       symbol: SPAG
      #       symbol_def: the situation is message like spaghetti at a kid's
      #
      #   will produce:
      #     === spaghetti
      #     wheat noodles of 9mm diameter
      #
      #     SPAG:: the situation is message like spaghetti at a kid's meal
      def process(document, reader)
        input_lines = reader.readlines.to_enum
        Reader.new(processed_lines(document, input_lines))
      end

      private

      def processed_lines(document, input_lines)
        result = []
        loop do
          result.push(*process_yaml2text_blocks(document, input_lines))
        end
        result
      end

      def content_from_yaml(document, file_path)
        docfile_directory = File.dirname(document.attributes["docfile"] || ".")
        yaml_file_path = document
          .path_resolver
          .system_path(file_path, docfile_directory)
        YAML.safe_load(File.read(yaml_file_path))
      end

      def process_yaml2text_blocks(document, input_lines)
        line = input_lines.next
        yaml_block_match = line.match(/^\[yaml2text,(.+?),(.+?)\]/)
        return [line] if yaml_block_match.nil?

        mark = input_lines.next
        current_yaml_block = []
        while (yaml_block_line = input_lines.next) != mark
          current_yaml_block.push(yaml_block_line)
        end
        read_yaml_and_parse_template(document,
                                     current_yaml_block,
                                     yaml_block_match)
      end

      def read_yaml_and_parse_template(document, current_block, block_match)
        transformed_liquid_lines = current_block
          .map(&method(:transform_line_liquid))
        context_items = content_from_yaml(document, block_match[1])
        parse_context_block(document: document,
                            context_lines: transformed_liquid_lines,
                            context_items: context_items,
                            context_name: block_match[2])
      rescue StandardError => exception
        document.logger
          .warn("Failed to parse yaml2text block: #{exception.message}")
        []
      end

      def transform_line_liquid(line)
        if line.match?(BLOCK_START_REGEXP)
          line.gsub!(BLOCK_START_REGEXP,
                     '{% keyiterator \1, \2 %}')
        end

        if line.strip.match?(BLOCK_END_REGEXP)
          line.gsub!(BLOCK_END_REGEXP, "{% endkeyiterator %}")
        end
        line
          .gsub(/(?<!{){(?!%)([^{}]+)(?<!%)}(?!})/, '{{\1}}')
          .gsub(/[a-z\.]+\#/, "index")
          .gsub(/{{(.+).values(.*?)}}/,
                '{% assign custom_value = \1 | values %}{{custom_value\2}}')
      end

      def parse_context_block(context_lines:,
                              context_items:,
                              context_name:,
                              document:)
        render_result, errors = render_liquid_string(
          template_string: context_lines.join("\n"),
          context_items: context_items,
          context_name: context_name
        )
        notify_render_errors(document, errors)
        render_result.split("\n")
      end

      def render_liquid_string(template_string:, context_items:, context_name:)
        liquid_template = Liquid::Template.parse(template_string)
        rendered_string = liquid_template
          .render(context_name => context_items,
                  strict_variables: true,
                  error_mode: :warn)
        [rendered_string, liquid_template.errors]
      end

      def notify_render_errors(document, errors)
        errors.each do |error_obj|
          document
            .logger
            .warn("Liquid render error: #{error_obj.message}")
        end
      end
    end
  end
end
