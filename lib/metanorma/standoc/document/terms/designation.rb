# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Terms
      # A name under which a managed term is known.
      class Designation < Lutaml::Model::Serializable
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
          map_attribute "absent", to: :absent
          map_element "geographic-area", to: :geographic_area
          map_element "sources", to: :sources
          map_element "expression", to: :expression

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
