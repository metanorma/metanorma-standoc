require 'ostruct'

module Asciidoctor
  module Standoc
    class YamlContext
      attr_reader :context_object, :context_name, :parent_context, :__iter_id__

      def initialize(context_object:,
                    context_name:,
                    parent_context: nil,
                    __iter_id__: nil)
        @context_object = if context_object.is_a?(Hash)
                            OpenStruct.new(context_object)
                          else
                            context_object
                          end
        @context_name = context_name
        @parent_context = parent_context
        @__iter_id__ = __iter_id__
      end

      def to_s
        context_object.to_s
      end

      def respond_to?(name)
        return true if context_name.to_s == name.to_s

        parent_context.respond_to?(name)
      end

      def respond_to_missing?(name)
        respond_to?(name)
      end

      def method_missing(name, *args)
        args = args.map do |argument|
          argument.is_a?(YamlContext) ? argument.context_object : argument
        end
        if context_object.respond_to?(name) &&
            (context_object.is_a?(OpenStruct) || context_object.is_a?(Array))
          return context_object.send(name, *args)
        end

        parent_context.send(name, *args)
      end
    end

    class YamlContextRenderer
      attr_reader :context_object, :context_name

      def initialize(context_object:)
        @context_object = context_object
      end

      def respond_to_missing?(name)
        respond_to?(name)
      end

      def method_missing(name, *_args)
        return context_object if context_object.respond_to?(name)

        name
      end

      def render(template)
        ERB.new(template).result(binding)
      end
    end

    class Yaml2TextPreprocessor < Asciidoctor::Extensions::Preprocessor
      BLOCK_START_REGEXP = '^\{%s.?(?<nested_context>.*)\.\*,(?<name>.+),(?<block_mark>.+)\}'.freeze
      # serch document for block `yaml2text`
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
      #       symbol: the situation is message like spaghetti at a kid's meal
      #
      #   will produce:
      #     === spaghetti
      #     wheat noodles of 9mm diameter
      #
      #     SPAG:: the situation is message like spaghetti at a kid's meal
      def process(document, reader)
        input_lines = reader.readlines.to_enum
        doc_attrs = document.attributes
        Reader.new(processed_lines(doc_attrs, input_lines))
      end

      private

      def processed_lines(_doc_attrs, input_lines)
        result = []
        loop do
          line = input_lines.next
          if yaml_block_match = line.match(/^\[yaml2text,(.+?),(.+?)\]/)
            mark = input_lines.next
            current_yaml_block = []
            while (yaml_block_line = input_lines.next) != mark
              current_yaml_block.push(yaml_block_line)
            end
            content = YAML.safe_load(File.read(yaml_block_match[1]))
            result.push(*
              parse_blocks_recursively(lines: current_yaml_block,
                                       attributes: content,
                                       context_name: yaml_block_match[2]))
          else
            result.push(line)
          end
        end
        result
      end

      def parse_blocks_recursively(lines:,
                                   attributes:,
                                   context_name:,
                                   parent_context: nil,
                                   __iter_id__: nil)
        lines = lines.to_enum
        result = []
        block_start_regexp = BLOCK_START_REGEXP % context_name

        loop do
          line = lines.next
          if (match = line.match(block_start_regexp))
            result.push(*read_and_parse_context_block(lines,
                                                      attributes,
                                                      match,
                                                      context_name))
          end
          result.push(line) unless line.match(block_start_regexp)
        end
        result = parse_context_block(context_lines: result,
                                     context_items: attributes,
                                     context_name: context_name,
                                     parent_context: parent_context,
                                     __iter_id__: __iter_id__)
        result
      end

      def read_and_parse_context_block(lines,
                                       attributes,
                                       match,
                                       context_name)
        result = []
        mark = match[:block_mark]
        block_lines = []
        variable_identifier = match[:nested_context].split('.')
        block_attrs = if variable_identifier.length.zero?
                        attributes.is_a?(Hash) ? attributes.keys : attributes
                      else
                        attributes.dig(*variable_identifier)
                      end
        while (context_block_line = lines.next) != "{#{mark}}"
          block_lines.push(context_block_line)
        end
        new_parent_context = YamlContext.new(context_object: attributes,
                                             context_name: context_name)
        if block_attrs.is_a?(Array)
          block_attrs.each.with_index do |current_block_attrs, index|
            result.push(
              *parse_blocks_recursively(lines: block_lines,
                                        attributes: current_block_attrs,
                                        context_name: match[:name],
                                        parent_context: new_parent_context,
                                        __iter_id__: index),
            )
          end
        else
          result.push(
            *parse_blocks_recursively(lines: block_lines,
                                      attributes: current_block_attrs,
                                      context_name: match[:name],
                                      parent_context: new_parent_context),
          )
        end
        result
      end

      def parse_context_block(context_lines:,
                              context_items:,
                              context_name:,
                              parent_context: nil,
                              __iter_id__: nil)
        if context_items.is_a?(Array) && parent_context.nil?
          return context_lines
        end

        context = YamlContext.new(context_object: context_items,
                                  context_name: context_name,
                                  __iter_id__: __iter_id__,
                                  parent_context: parent_context)
        renderer = YamlContextRenderer.new(context_object: context)
        context_lines.map do |line|
          renderer.render(line.
                          gsub(/(?<=\.)\#(?=\]|}|\s)/, '__iter_id__').
                          gsub(/{(.+?[^}]*)}/, '<%= \1 %>'))
        end
      end

      def wrap_array(object)
        if object.nil?
          []
        elsif object.respond_to?(:to_ary)
          object.to_ary || [object]
        else
          [object]
        end
      end
    end
  end
end
