# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      class TermExpression < Lutaml::Model::Serializable
        attribute :name, TermNameElement, collection: true
        attribute :usage, :string
        attribute :abbreviation_type, :string

        xml do
          element "expression"
          map_element "name", to: :name
          map_element "usage", to: :usage
          map_element "abbreviation-type", to: :abbreviation_type
        end
      end
    end
  end
end
