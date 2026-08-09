# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      # How a block element may be rendered in a multilingual document.
      class MultilingualRenderingType < Lutaml::Model::Serializable
        attribute :value, :string

        xml do
          element "multilingual-rendering-type"
          map_content to: :value
        end

        def self.values
          %w[common all-columns parallel tag]
        end
      end
    end
  end
end
