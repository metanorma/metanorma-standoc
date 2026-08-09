# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      # <metanorma-extension> holds processor-generated metadata.
      # Children, when present, appear in this fixed order:
      # semantic-metadata, presentation-metadata, UnitsML,
      # source-highlighter-css.
      class MetanormaExtension < Lutaml::Model::Serializable
        attribute :semantic_metadata, SemanticMetadata
        attribute :presentation_metadata, PresentationMetadata
        attribute :unitsml, Unitsml::UnitsmlRoot
        attribute :source_highlighter_css, :string

        xml do
          element "metanorma-extension"
          map_element "semantic-metadata", to: :semantic_metadata
          map_element "presentation-metadata", to: :presentation_metadata
          map_element "UnitsML", to: :unitsml
          map_element "source-highlighter-css", to: :source_highlighter_css
        end
      end
    end
  end
end
