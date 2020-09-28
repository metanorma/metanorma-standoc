module Liquid
  module CustomBlocks
    class WithYamlNestedContext < Block
      def initialize(tag_name, markup, tokens)
        super
        @context_file_variable, @context_name = markup.split(",").map(&:strip)
      end

      def render(context)
        context_file = context[@context_file_variable].to_s.strip
        context[@context_name] = YAML.safe_load(
          File.read(context_file, encoding: "utf-8"),
          [Date, Time]
        )
        super
      end
    end
  end
end
