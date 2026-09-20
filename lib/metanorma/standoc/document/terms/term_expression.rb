# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Terms
      class TermExpression < Lutaml::Model::Serializable
        attribute :name, TermNameElement, collection: true
        attribute :usage, :string
        attribute :abbreviation_type, :string
        attribute :pronunciation,
                  Metanorma::Document::Components::DataTypes::LocalizedString,
                  collection: true
        attribute :grammar,
                  "Metanorma::Standoc::Document::Terms::GrammarInfo"

        xml do
          element "expression"
          map_element "name", to: :name
          map_element "usage", to: :usage
          map_element "abbreviation-type", to: :abbreviation_type
          map_element "pronunciation", to: :pronunciation
          map_element "grammar", to: :grammar
        end
      end
    end
  end
end
