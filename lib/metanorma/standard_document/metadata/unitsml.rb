# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        autoload :AmountOfSubstance, "#{__dir__}/unitsml/amount_of_substance"
        autoload :BaseQuantityAttributes, "#{__dir__}/unitsml/base_quantity"
        autoload :BaseQuantityXmlMapping, "#{__dir__}/unitsml/base_quantity"
        autoload :Dimension, "#{__dir__}/unitsml/dimension"
        autoload :DimensionSet, "#{__dir__}/unitsml/dimension_set"
        autoload :ElectricCurrent, "#{__dir__}/unitsml/electric_current"
        autoload :EnumeratedRootUnit, "#{__dir__}/unitsml/enumerated_root_unit"
        autoload :Length, "#{__dir__}/unitsml/length"
        autoload :LuminousIntensity, "#{__dir__}/unitsml/luminous_intensity"
        autoload :Mass, "#{__dir__}/unitsml/mass"
        autoload :Namespace, "#{__dir__}/unitsml/namespace"
        autoload :PlaneAngle, "#{__dir__}/unitsml/plane_angle"
        autoload :Prefix, "#{__dir__}/unitsml/prefix"
        autoload :PrefixName, "#{__dir__}/unitsml/prefix_name"
        autoload :PrefixSet, "#{__dir__}/unitsml/prefix_set"
        autoload :PrefixSymbol, "#{__dir__}/unitsml/prefix_symbol"
        autoload :Quantity, "#{__dir__}/unitsml/quantity"
        autoload :QuantityName, "#{__dir__}/unitsml/quantity_name"
        autoload :QuantitySet, "#{__dir__}/unitsml/quantity_set"
        autoload :RootUnits, "#{__dir__}/unitsml/root_units"
        autoload :ThermodynamicTemperature,
                 "#{__dir__}/unitsml/thermodynamic_temperature"
        autoload :Time, "#{__dir__}/unitsml/time"
        autoload :Unit, "#{__dir__}/unitsml/unit"
        autoload :UnitName, "#{__dir__}/unitsml/unit_name"
        autoload :UnitSet, "#{__dir__}/unitsml/unit_set"
        autoload :UnitSymbol, "#{__dir__}/unitsml/unit_symbol"
        autoload :UnitSystem, "#{__dir__}/unitsml/unit_system"
        autoload :UnitsmlRoot, "#{__dir__}/unitsml/unitsml_root"
      end
    end
  end
end
