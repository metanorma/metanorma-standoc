# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        # Root <UnitsML> element embedded in metanorma-extension.
        # Child sets serialize in schema order:
        # UnitSet, QuantitySet, DimensionSet, PrefixSet.
        class UnitsmlRoot < Lutaml::Model::Serializable
          attribute :unit_set, UnitSet
          attribute :quantity_set, QuantitySet
          attribute :dimension_set, DimensionSet
          attribute :prefix_set, PrefixSet

          xml do
            element "UnitsML"
            namespace Unitsml::Namespace
            map_element "UnitSet", to: :unit_set
            map_element "QuantitySet", to: :quantity_set
            map_element "DimensionSet", to: :dimension_set
            map_element "PrefixSet", to: :prefix_set
          end
        end
      end
    end
  end
end
