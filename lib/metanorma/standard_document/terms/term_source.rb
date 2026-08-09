# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # The bibliographic source where a term is defined in the
      # sense applicable in this _StandardDocument_.
      class TermSource < Lutaml::Model::Serializable
        attribute :status, Metanorma::StandardDocument::Terms::TermSourceStatus
        attribute :status, :string
        attribute :origin, Metanorma::Document::Components::ReferenceElements::Citation
        attribute :modification, Metanorma::Document::Components::Paragraphs::ParagraphBlock

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "termsource"
          map_attribute "status", to: :status
          map_element "origin", to: :origin
          map_element "modification", to: :modification

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
