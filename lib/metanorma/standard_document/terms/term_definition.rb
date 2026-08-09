# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # The definition of a term applied in the current
      # document.
      class TermDefinition < Lutaml::Model::Serializable
        attribute :verbalexpression, Metanorma::StandardDocument::Terms::VerbalExpression
        attribute :nonverbalrepresentation, Metanorma::StandardDocument::Terms::NonVerbalRepresentation
        attribute :source, Metanorma::StandardDocument::Terms::TermSource,
                  collection: true

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "definition"
          map_element "verbal-definition", to: :verbalexpression
          map_element "nonverbalrepresentation", to: :nonverbalrepresentation
          map_element "source", to: :source

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
