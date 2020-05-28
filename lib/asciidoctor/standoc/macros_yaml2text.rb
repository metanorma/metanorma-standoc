require 'ostruct'

module Asciidoctor
  module Standoc
    class YamlBlockStruct < OpenStruct
      def to_a
        @table.to_h.keys
      end

      def values
        @table.to_h.values
      end

      def each
        return to_a.each unless block_given?

        to_a.each do |key|
          yield(key)
        end
      end
    end

    class YamlContextRenderer
      attr_reader :context_object, :context_name, :__file_name

      def initialize(context_object:, context_name:, file_name:)
        @context_object = context_object
        @context_name = context_name
        @__file_name = file_name
      end

      def respond_to_missing?(name)
        respond_to?(name)
      end

      def method_missing(name, *_args)
        return context_object if name.to_s == context_name

        super
      end

      def render(template)
        ERB.new(template).result(binding)
      rescue Exception
        require 'byebug'
        byebug
        i = 20
      end
    end

    class Yaml2TextPreprocessor < Asciidoctor::Extensions::Preprocessor
      BLOCK_START_REGEXP = /\{(.+?)\.\*,(.+),(.+)\}/
      BLOCK_END_REGEXP = /\A\{[A-Z]+\}\z/
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
      #       symbol_def: the situation is message like spaghetti at a kid's meal
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
          line = input_lines.next
          if yaml_block_match = line.match(/^\[yaml2text,(.+?),(.+?)\]/)
            mark = input_lines.next
            current_yaml_block = []
            while (yaml_block_line = input_lines.next) != mark
              current_yaml_block.push(yaml_block_line)
            end
            content = nested_open_struct_from_yaml(yaml_block_match[1], document)
            result.push(*
              parse_blocks_recursively(lines: current_yaml_block,
                                       attributes: content,
                                       context_name: yaml_block_match[2],
                                       yaml_path: yaml_block_match[1]))
          else
            result.push(line)
          end
        end
        result
      end

      def nested_open_struct_from_yaml(file_path, document)
        docfile_directory = File.dirname(document.attributes['docfile'] || '.')
        yaml_file_path = document.path_resolver.system_path(file_path, docfile_directory)
        content = YAML.safe_load(File.read(yaml_file_path))
        # Load content as json, then parse with JSON as nested open_struct
        JSON.parse(content.to_json, object_class: YamlBlockStruct)
      end

      def parse_blocks_recursively(lines:,
                                   attributes:,
                                   context_name:,
                                   yaml_path:)
        lines = lines.to_enum
        result = []
        loop do
          line = lines.next
          if line.match(BLOCK_START_REGEXP)
            line.gsub!(BLOCK_START_REGEXP, '<% \1.each&.with_index do |\2,index| %>')
          end

          if line.strip.match(BLOCK_END_REGEXP)
            line.gsub!(BLOCK_END_REGEXP, '<% end %>')
          end
          line.gsub!(/{\s*if\s*([^}]+)}/, '<% if \1 %>')
          line.gsub!(/{\s*?end\s*?}/, '<% end %>')
          line = line.gsub(/{(.+?[^}]*)}/, '<%= \1 %>').gsub(/[a-z\.]+\#/, 'index')
          result.push(line)
        end
        result = parse_context_block(context_lines: result,
                                     context_items: attributes,
                                     context_name: context_name,
                                     yaml_path: yaml_path)
        result
      end

      def parse_context_block(context_lines:,
                              context_items:,
                              context_name:,
                              yaml_path:)
        yaml_name = File.basename(yaml_path).gsub(/\.(yaml|yml)/, '')
        renderer = YamlContextRenderer.new(
                    context_object: context_items,
                    context_name: context_name,
                    file_name: yaml_name)
        renderer.render(context_lines.join("\n")).split("\n")
      end
    end
  end
end
