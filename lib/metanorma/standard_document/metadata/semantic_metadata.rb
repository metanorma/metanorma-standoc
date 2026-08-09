# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      # <semantic-metadata> carries semantic flags about the document
      # (only <stage-published> has been observed in the wild).
      class SemanticMetadata < Lutaml::Model::Serializable
        attribute :stage_published, :string

        xml do
          element "semantic-metadata"
          map_element "stage-published", to: :stage_published
        end
      end
    end
  end
end
