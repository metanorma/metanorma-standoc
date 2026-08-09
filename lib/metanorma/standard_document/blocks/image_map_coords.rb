# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      # Coordinate point to be used within an image map.
      class ImageMapCoords < Lutaml::Model::Serializable
        attribute :x, :float
        attribute :y, :float

        xml do
          element "image-map-coords"
          map_attribute "x", to: :x
          map_attribute "y", to: :y
        end
      end
    end
  end
end
