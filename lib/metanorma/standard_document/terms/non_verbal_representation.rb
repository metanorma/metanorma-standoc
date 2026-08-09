# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # Non-verbal representation of the term.
      class NonVerbalRepresentation < Lutaml::Model::Serializable
        attribute :figure,
                  Metanorma::Document::Components::AncillaryBlocks::FigureBlock, collection: true
        attribute :formula,
                  Metanorma::Document::Components::AncillaryBlocks::FormulaBlock, collection: true
        attribute :table, Metanorma::Document::Components::Tables::TableBlock,
                  collection: true
        attribute :sources, Metanorma::StandardDocument::Terms::TermSource,
                  collection: true

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "non-verbal-representation"
          map_element "figure", to: :figure
          map_element "formula", to: :formula
          map_element "table", to: :table
          map_element "sources", to: :sources

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
