# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Blocks
      # Specification of an area of an image to be hyperlinked, as part of an image map.
      class ImageMapAreaType < Lutaml::Model::Serializable
        attribute :type, :string
        attribute :element, Metanorma::Document::Components::ReferenceElements::ReferenceElement
        attribute :coords, Metanorma::Standoc::Document::Blocks::ImageMapCoords,
                  collection: true
        attribute :radius, Metanorma::Standoc::Document::Blocks::ImageMapRadius

        xml do
          element "image-map-area-type"
          map_attribute "type", to: :type
          map_element "element", to: :element
          map_element "coords", to: :coords
          map_element "radius", to: :radius
        end
      end
    end
  end
end
