# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      # The type of area in an image map to be hyperlinked.
      class ImageMapAreaTypeType < Lutaml::Model::Serializable
        attribute :value, :string

        xml do
          element "image-map-area-type-type"
          map_content to: :value
        end

        def self.values
          %w[rect circle ellipse poly]
        end
      end
    end
  end
end
