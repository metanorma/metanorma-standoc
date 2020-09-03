module Liquid
  module CustomBlocks
    class KeyIterator < Block
      def initialize(tag_name, markup, tokens)
        super
        @context_name, @var_name = markup.split(',').map(&:strip)
      end

      def render(context)
        res = ''
        iterator = context[@context_name].is_a?(Hash) ? context[@context_name].keys : context[@context_name]
        iterator.each.with_index do |key, index|
          context['index'] = index
          context[@var_name] = key
          res += super
        end
        res
      end
    end
  end
end
