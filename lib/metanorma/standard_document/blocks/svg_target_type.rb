# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      # Specification of (potentially document-specific) cross-references, to overwrite the
      # links within an SVG file, so that the SVG file can hyperlink to anchors within the document.
      class SvgTargetType < Lutaml::Model::Serializable
        attribute :href, :string
        attribute :reference_element, Metanorma::Document::Components::ReferenceElements::ReferenceElement

        xml do
          element "svg-target-type"
          map_attribute "href", to: :href
          map_element "reference-element", to: :reference_element
        end
      end
    end
  end
end
