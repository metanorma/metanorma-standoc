# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Lists
      class StandardDefinitionTerm < Lutaml::Model::Serializable
        attribute :id, :string
        attribute :content,
                  Metanorma::Document::Components::TextElements::TextElement, collection: true

        # Presentation-specific attributes
        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :displayorder, :integer

        xml do
          element "standard-definition-term"
          map_attribute "id", to: :id
          map_element "content", to: :content
          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
