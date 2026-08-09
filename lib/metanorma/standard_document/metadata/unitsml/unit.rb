# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class Unit < Lutaml::Model::Serializable
          attribute :dimension_url, :string
          attribute :id, :string
          attribute :semx_id, :string

          attribute :unit_system, UnitSystem
          attribute :unit_name, UnitName
          attribute :unit_symbol, UnitSymbol, collection: true
          attribute :root_units, RootUnits

          xml do
            element "Unit"
            namespace Unitsml::Namespace
            map_attribute "dimensionURL", to: :dimension_url
            map_attribute "id", to: :id
            map_attribute "semx-id", to: :semx_id
            map_element "UnitSystem", to: :unit_system
            map_element "UnitName", to: :unit_name
            map_element "UnitSymbol", to: :unit_symbol
            map_element "RootUnits", to: :root_units
          end
        end
      end
    end
  end
end
