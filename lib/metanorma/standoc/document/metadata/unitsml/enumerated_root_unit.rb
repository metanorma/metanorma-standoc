# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Metadata
      module Unitsml
        class EnumeratedRootUnit < Lutaml::Model::Serializable
          attribute :unit, :string
          attribute :prefix, :string
          attribute :power_numerator, :integer
          attribute :power_denominator, :integer

          xml do
            element "EnumeratedRootUnit"
            namespace Unitsml::Namespace
            map_attribute "unit", to: :unit
            map_attribute "prefix", to: :prefix
            map_attribute "powerNumerator", to: :power_numerator
            map_attribute "powerDenominator", to: :power_denominator
          end
        end
      end
    end
  end
end
