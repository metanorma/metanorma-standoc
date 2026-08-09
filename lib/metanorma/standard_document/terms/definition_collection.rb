# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # Collection of definitions, constituting the core content of a DefinitionSection.
      class DefinitionCollection < Lutaml::Model::Serializable
        attribute :definitions,
                  Metanorma::Document::Components::Lists::Definition, collection: true

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "definition-collection"
          map_element "definitions", to: :definitions

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
