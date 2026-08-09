# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      # Radius of a circle area within an image map.
      class ImageMapRadius < Lutaml::Model::Serializable
        attribute :x, :float
        attribute :y, :float

        xml do
          element "image-map-radius"
          map_attribute "x", to: :x
          map_attribute "y", to: :y
        end
      end
    end
  end
end
