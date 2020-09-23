# frozen_string_literal: true

require "liquid/custom_blocks/key_iterator"
require "liquid/custom_filters/values"

Liquid::Template.register_tag("keyiterator", Liquid::CustomBlocks::KeyIterator)
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

      def process_text_blocks(document, input_lines, context_variables={})
        line = input_lines.next
        block_match = line.match(/^\[#{config[:block_name]},(.+?),(.+?)\]/)
        return [line] if block_match.nil?

        mark = input_lines.next
        current_block = []
        have_nested_macroses = false
        context_items = content_from_file(document, block_match[1])
        context_variables = context_variables.merge(block_match[2] => context_items)

        while (block_line = input_lines.next) != mark
          if nested_match = block_line.match(/^\[#{config[:block_name]},(.+?),(.+?)\]/)
            current_block.push(block_line)
            nested_mark = input_lines.next
            current_block.push(nested_mark)
            current_block.push('{% raw  %}')
            while (block_line = input_lines.next) != nested_mark
              current_block.push(block_line)
            end
            current_block.push(block_line)
            current_block.push('{% endraw  %}')
          else
            current_block.push(block_line)
          end
        end
        parse_template(document,
          current_block,
          context_variables)
      end

      def parse_template(document, current_block, context_variables)
        transformed_liquid_lines = current_block.map(&method(:transform_line_liquid))
        parse_context_block(document: document,
                            context_lines: transformed_liquid_lines,
                            context_variables: context_variables)
      rescue StandardError => exception
        document.logger
          .warn("Failed to parse #{config[:block_name]} \
            block: #{exception.message}")
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
          .gsub(/{{(.+)\s+\+\s+(\d+)\s*?}}/, '{{ \1 | plus: \2 }}')
          .gsub(/{{(.+)\s+\-\s+(\d+)\s*?}}/, '{{ \1 | minus: \2 }}')
          .gsub(/{{(.+).values(.*?)}}/,
                '{% assign custom_value = \1 | values %}{{custom_value\2}}')
      end

      def parse_context_block(context_lines:,
                              context_variables:,
                              document:)
        render_result, errors = render_liquid_string(
          template_string: context_lines.join("\n"),
          context_variables: context_variables
        )
        notify_render_errors(document, errors)
        render_result.split("\n")
      end

      def render_liquid_string(template_string:, context_variables:)
        liquid_template = Liquid::Template.parse(template_string)
        rendered_string = liquid_template
          .render(context_variables,
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
