# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class Dimension < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :semx_id, :string

          attribute :length, Length
          attribute :mass, Mass
          attribute :time, Time
          attribute :electric_current, ElectricCurrent
          attribute :thermodynamic_temperature, ThermodynamicTemperature
          attribute :amount_of_substance, AmountOfSubstance
          attribute :luminous_intensity, LuminousIntensity
          attribute :plane_angle, PlaneAngle

          xml do
            element "Dimension"
            namespace Unitsml::Namespace
            map_attribute "id", to: :id
            map_attribute "semx-id", to: :semx_id
            map_element "Length", to: :length
            map_element "Mass", to: :mass
            map_element "Time", to: :time
            map_element "ElectricCurrent", to: :electric_current
            map_element "ThermodynamicTemperature",
                        to: :thermodynamic_temperature
            map_element "AmountOfSubstance", to: :amount_of_substance
            map_element "LuminousIntensity", to: :luminous_intensity
            map_element "PlaneAngle", to: :plane_angle
          end
        end
      end
    end
  end
end
