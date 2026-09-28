# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Terms
      # A name under which a managed term is known.
      class Designation < Lutaml::Model::Serializable
        include Metanorma::Document::Components::Inline::Vocabulary

        attribute :absent, :boolean
        attribute :geographic_area,
                  Metanorma::Document::Components::DataTypes::Iso3166Code, collection: true
        attribute :sources, Metanorma::Standoc::Document::Terms::TermSource,
                  collection: true
        attribute :expression, Metanorma::Standoc::Document::Terms::TermExpression

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "designation"
          # Legacy presentation XML states the designation's rendered
          # form directly as inline content of <preferred>/<admitted>/
          # <deprecates> (<preferred><strong>Process input:</strong>
          # </preferred>) with no <expression> wrapper: accept the full
          # inline vocabulary so nothing is dropped at parse time.
          mixed_content
          map_content to: :text
          map_attribute "absent", to: :absent
          map_element "geographic-area", to: :geographic_area
          map_element "sources", to: :sources
          map_element "expression", to: :expression

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id

          Metanorma::Document::Components::Inline::Vocabulary::VocabularyXmlMapping
            .apply_inline_mappings(self)
        end
      end
    end
  end
end
