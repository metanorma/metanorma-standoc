# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Lists
      class StandardDefinition < Metanorma::Document::Components::Lists::Definition
        attribute :item,
                  Metanorma::StandardDocument::Lists::StandardDefinitionTerm, collection: true

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :displayorder, :integer

        xml do
          element "standard-definition"
          map_element "item", to: :item
          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
