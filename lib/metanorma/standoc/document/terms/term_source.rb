# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Terms
      # The bibliographic source where a term is defined in the
      # sense applicable in this _StandardDocument_.
      class TermSource < Lutaml::Model::Serializable
        include Metanorma::Document::Components::Inline::Vocabulary

        attribute :status, Metanorma::Standoc::Document::Terms::TermSourceStatus
        attribute :status, :string
        attribute :origin, Metanorma::Document::Components::ReferenceElements::Citation
        attribute :modification,
                  Metanorma::Document::Components::ReferenceElements::SourceModification

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "termsource"
          # Legacy presentation XML states the termsource's rendered form
          # directly as inline content (<termsource status="modified">
          # [Modified from: [<xref>6</xref>] – definition 1.1]
          # </termsource>) with no <origin>/<modification> children:
          # accept the full inline vocabulary so nothing is dropped at
          # parse time.
          mixed_content
          map_content to: :text
          map_attribute "status", to: :status
          map_element "origin", to: :origin
          map_element "modification", to: :modification

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id

          Metanorma::Document::Components::Inline::Vocabulary::VocabularyXmlMapping
            .apply_inline_mappings(self)
        end
      end
    end
  end
end
