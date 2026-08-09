# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class EnumeratedRootUnit < Lutaml::Model::Serializable
          attribute :unit, :string
          attribute :prefix, :string
          attribute :power_numerator, :integer

          xml do
            element "EnumeratedRootUnit"
            namespace Unitsml::Namespace
            map_attribute "unit", to: :unit
            map_attribute "prefix", to: :prefix
            map_attribute "powerNumerator", to: :power_numerator
          end
        end
      end
    end
  end
end
