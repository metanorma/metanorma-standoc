# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      # Wrapper around an SVG file, to update its hyperlinks with potentially document-specific
      # links, so that the SVG file can hyperlink to anchors within the document.
      class SvgMapBlock < Metanorma::StandardDocument::Blocks::StandardBlockNoNotes
        attribute :source, :string
        attribute :alt, :string
        attribute :target, Metanorma::StandardDocument::Blocks::SvgTargetType,
                  collection: true

        xml do
          element "svg-map-block"
          map_attribute "source", to: :source
          map_attribute "alt", to: :alt
          map_element "target", to: :target
        end
      end
    end
  end
end
