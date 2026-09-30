# frozen_string_literal: true

module Metanorma
  module Standoc::Document
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
        # <metanorma><source> carries the semantic vocabulary tree
        # (semantic__* elements).
        attribute :metanorma,
                  "Metanorma::Standoc::Document::Metadata::MetanormaSourceContainer"

        xml do
          element "metanorma-extension"
          map_element "semantic-metadata", to: :semantic_metadata
          map_element "presentation-metadata", to: :presentation_metadata
          map_element "UnitsML", to: :unitsml
          map_element "source-highlighter-css", to: :source_highlighter_css
          map_element "metanorma", to: :metanorma
        end
      end

      # Wrapper for <metanorma-extension><metanorma>: the semantic
      # source container.
      class MetanormaSourceContainer < Lutaml::Model::Serializable
        attribute :source,
                  "Metanorma::Standoc::Document::Metadata::MetanormaSemanticSource"

        xml do
          element "metanorma"
          map_element "source", to: :source
        end
      end

      # <metanorma><source>: the semantic vocabulary roots. One
      # collection receives every flavor root element.
      class MetanormaSemanticSource < Lutaml::Model::Serializable
        attribute :semantic_roots,
                  Metanorma::Document::Components::Semantic::Node,
                  collection: true

        xml do
          element "source"
          # Flavor roots are dynamic (semantic__*-standard); the
          # catch-all collects every root element.
          map_any_element to: :semantic_roots
        end
      end
    end
  end
end
