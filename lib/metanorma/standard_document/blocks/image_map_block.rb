# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      # Wrapper around an image file, to specify an image map, with areas of an image being hyperlinked.
      class ImageMapBlock < Metanorma::StandardDocument::Blocks::StandardBlockNoNotes
        attribute :source, :string
        attribute :alt, :string
        attribute :area, Metanorma::StandardDocument::Blocks::ImageMapAreaType,
                  collection: true

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :autonum, :string
        attribute :displayorder, :integer

        xml do
          element "image-map-block"
          map_attribute "source", to: :source
          map_attribute "alt", to: :alt
          map_element "area", to: :area

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "autonum", to: :autonum
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
