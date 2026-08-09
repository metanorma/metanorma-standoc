# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      # Extension point for extraneous elements that need to be added to
      # standards documents from other schemas.
      #
      # Observed payload: legacy-serialization <presentation-metadata>
      # name/value pairs (e.g. metanorma/demo-ab import_from_metanorma).
      class MiscContainer < Lutaml::Model::Serializable
        attribute :presentation_metadata,
                  Metanorma::StandardDocument::Metadata::PresentationMetadata,
                  collection: true

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :displayorder, :integer

        xml do
          element "misc-container"
          map_element "presentation-metadata", to: :presentation_metadata

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
