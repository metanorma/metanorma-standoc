# frozen_string_literal: true

require "liquid/custom_blocks/key_iterator"
require "liquid/custom_blocks/with_yaml_nested_context"
require "liquid/custom_blocks/with_json_nested_context"
require "liquid/custom_filters/values"

Liquid::Template.register_tag("keyiterator", Liquid::CustomBlocks::KeyIterator)
Liquid::Template
  .register_tag("with_yaml_nested_context",
                Liquid::CustomBlocks::WithYamlNestedContext)
Liquid::Template
  .register_tag("with_json_nested_context",
                Liquid::CustomBlocks::WithJsonNestedContext)
Liquid::Template.register_filter(Liquid::CustomFilters)

module Asciidoctor
  module Standoc
    # Base class for processing structured data blocks(yaml, json)
    class BaseStructuredTextPreprocessor < Asciidoctor::Extensions::Preprocessor
      BLOCK_START_REGEXP = /\{(.+?)\.\*,(.+),(.+)\}/
      BLOCK_END_REGEXP = /\A\{[A-Z]+\}\z/

      def process(document, reader)
        input_lines = reader.readlines.to_enum
        Reader.new(processed_lines(document, input_lines))
      end

      protected

      def content_from_file(_document, _file_path)
        raise ArgumentError, "Implement `content_from_file` in your class"
      end

      private

      def processed_lines(document, input_lines)
        result = []
        loop do
          result.push(*process_text_blocks(document, input_lines))
        end
        result
      end

      def relative_file_path(document, file_path)
        docfile_directory = File.dirname(document.attributes["docfile"] || ".")
        document
          .path_resolver
          .system_path(file_path, docfile_directory)
      end

      def process_text_blocks(document, input_lines)
        line = input_lines.next
        block_match = line.match(/^\[#{config[:block_name]},(.+?),(.+?)\]/)
        return [line] if block_match.nil?

        end_mark = input_lines.next
        parse_template(document,
                       collect_internal_block_lines(input_lines, end_mark),
                       block_match)
      end

      def collect_internal_block_lines(input_lines, end_mark)
        current_block = []
        nested_marks = []
        while (block_line = input_lines.next) != end_mark
          if nested_match = block_line
              .match(/^\[#{config[:block_name]},(.+?),(.+?)\]/)
            current_block
              .push(*nested_context_tag(document,
                                        nested_match[1],
                                        nested_match[2]).split("\n"))
            next nested_marks.push(input_lines.next)
          end

          if nested_marks.include?(block_line)
            current_block.push("{% endwith_#{data_file_type}_nested_context %}")
            next nested_marks.delete(block_line)
          end
          current_block.push(block_line)
        end
        current_block
      end

      def data_file_type
        @config[:block_name].split("2").first
      end

      def nested_context_tag(document, file_path, context_name)
        absolute_file_path = relative_file_path(document, file_path)
        <<~TEMPLATE
          {% capture nested_file_path %}
          #{absolute_file_path}
          {% endcapture %}
          {% with_#{data_file_type}_nested_context nested_file_path, #{context_name}  %}
        TEMPLATE
      end

      def parse_template(document, current_block, block_match)
        transformed_liquid_lines = current_block
          .map(&method(:transform_line_liquid))
        context_items = content_from_file(document, block_match[1])
        parse_context_block(document: document,
                            context_lines: transformed_liquid_lines,
                            context_items: context_items,
                            context_name: block_match[2])
      rescue StandardError => exception
        document.logger
          .warn("Failed to parse #{config[:block_name]} \
            block: #{exception.message}")
        []
      end

      def transform_line_liquid(line)
        if line.match?(BLOCK_START_REGEXP)
          line.gsub!(BLOCK_START_REGEXP, '{% keyiterator \1, \2 %}')
        end

        if line.strip.match?(BLOCK_END_REGEXP)
          line.gsub!(BLOCK_END_REGEXP, "{% endkeyiterator %}")
        end
        line
          .gsub(/(?<!{){(?!%)([^{}]+)(?<!%)}(?!})/, '{{\1}}')
          .gsub(/[a-z\.]+\#/, "index")
          .gsub(/{{(.+)\s+\+\s+(\d+)\s*?}}/, '{{ \1 | plus: \2 }}')
          .gsub(/{{(.+)\s+\-\s+(\d+)\s*?}}/, '{{ \1 | minus: \2 }}')
          .gsub(/{{(.+)\.values(.*?)}}/,
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
