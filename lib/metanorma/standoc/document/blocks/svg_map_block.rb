# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Blocks
      # Wrapper around an SVG file, to update its hyperlinks with potentially document-specific
      # links, so that the SVG file can hyperlink to anchors within the document.
      class SvgMapBlock < Metanorma::Standoc::Document::Blocks::StandardBlockNoNotes
        attribute :source, :string
        attribute :alt, :string
        attribute :target, Metanorma::Standoc::Document::Blocks::SvgTargetType,
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
