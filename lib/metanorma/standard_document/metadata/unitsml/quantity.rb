# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class Quantity < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :quantity_type, :string
          attribute :dimension_url, :string
          attribute :semx_id, :string

          attribute :quantity_name, QuantityName, collection: true

          xml do
            element "Quantity"
            namespace Unitsml::Namespace
            map_attribute "id", to: :id
            map_attribute "quantityType", to: :quantity_type
            map_attribute "dimensionURL", to: :dimension_url
            map_attribute "semx-id", to: :semx_id
            map_element "QuantityName", to: :quantity_name
          end
        end
      end
    end
  end
end
