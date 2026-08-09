# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class QuantitySet < Lutaml::Model::Serializable
          attribute :quantity, Quantity, collection: true

          xml do
            element "QuantitySet"
            namespace Unitsml::Namespace
            map_element "Quantity", to: :quantity
          end
        end
      end
    end
  end
end
