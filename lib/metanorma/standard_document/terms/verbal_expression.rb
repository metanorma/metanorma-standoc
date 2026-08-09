# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # Verbal expression of the term.
      class VerbalExpression < Lutaml::Model::Serializable
        attribute :paragraph,
                  Metanorma::Document::Components::Paragraphs::ParagraphBlock, collection: true
        attribute :ol, Metanorma::Document::Components::Lists::OrderedList,
                  collection: true
        attribute :ul, Metanorma::Document::Components::Lists::UnorderedList,
                  collection: true
        attribute :dl, Metanorma::Document::Components::Lists::DefinitionList,
                  collection: true

        # Presentation-specific attributes

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "verbal-definition"
          map_element "p", to: :paragraph
          map_element "ol", to: :ol
          map_element "ul", to: :ul
          map_element "dl", to: :dl

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
