# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class Prefix < Lutaml::Model::Serializable
          attribute :prefix_base, :integer
          attribute :prefix_power, :integer
          attribute :id, :string
          attribute :semx_id, :string

          attribute :prefix_name, PrefixName
          attribute :prefix_symbol, PrefixSymbol, collection: true

          xml do
            element "Prefix"
            namespace Unitsml::Namespace
            map_attribute "prefixBase", to: :prefix_base
            map_attribute "prefixPower", to: :prefix_power
            map_attribute "id", to: :id
            map_attribute "semx-id", to: :semx_id
            map_element "PrefixName", to: :prefix_name
            map_element "PrefixSymbol", to: :prefix_symbol
          end
        end
      end
    end
  end
end
