# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Terms
      # The definition of a term applied in the current
      # document.
      class TermDefinition < Lutaml::Model::Serializable
        attribute :verbalexpression, Metanorma::Standoc::Document::Terms::VerbalExpression
        attribute :nonverbalrepresentation, Metanorma::Standoc::Document::Terms::NonVerbalRepresentation
        attribute :source, Metanorma::Standoc::Document::Terms::TermSource,
                  collection: true

        # Legacy presentation XML states the definition's blocks
        # directly under <definition> (<p>, <formula>, lists) instead
        # of wrapping them in <verbal-definition>.
        attribute :p, Metanorma::Document::Components::Paragraphs::ParagraphBlock,
                  collection: true
        attribute :termnote, Metanorma::Standoc::Document::Terms::TermNote,
                  collection: true
        attribute :dl, Metanorma::Document::Components::Lists::DefinitionList
        attribute :ol, Metanorma::Document::Components::Lists::OrderedList,
                  collection: true
        attribute :ul, Metanorma::Document::Components::Lists::UnorderedList,
                  collection: true
        attribute :formula, Metanorma::Document::Components::AncillaryBlocks::FormulaBlock,
                  collection: true

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "definition"
          ordered
          map_element "verbal-definition", to: :verbalexpression
          map_element "nonverbalrepresentation", to: :nonverbalrepresentation
          map_element "source", to: :source
          map_element "p", to: :p
          map_element "termnote", to: :termnote
          map_element "dl", to: :dl
          map_element "ol", to: :ol
          map_element "ul", to: :ul
          map_element "formula", to: :formula

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
