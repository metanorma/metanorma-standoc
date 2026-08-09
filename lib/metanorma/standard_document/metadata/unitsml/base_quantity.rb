# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        # Shared attributes for the eight UnitsML base-quantity elements
        # (Length, Mass, Time, ElectricCurrent, AmountOfSubstance,
        # ThermodynamicTemperature, LuminousIntensity, PlaneAngle).
        module BaseQuantityAttributes
          def self.included(base)
            base.class_eval do
              attribute :symbol, :string
              attribute :power_numerator, :integer
              attribute :power_denominator, :integer
            end
          end
        end

        # Shared attribute mappings for the base-quantity elements.
        # lutaml-model does not inherit xml mappings, so each per-tag class
        # applies this inside its own `xml do` block (same pattern as
        # StandardDocument::RootXmlMapping).
        module BaseQuantityXmlMapping
          def self.apply(mapping)
            mapping.map_attribute "symbol", to: :symbol
            mapping.map_attribute "powerNumerator", to: :power_numerator
            mapping.map_attribute "powerDenominator", to: :power_denominator
          end
        end
      end
    end
  end
end
