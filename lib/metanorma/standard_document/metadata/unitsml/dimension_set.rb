# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class DimensionSet < Lutaml::Model::Serializable
          attribute :dimension, Dimension, collection: true

          xml do
            element "DimensionSet"
            namespace Unitsml::Namespace
            map_element "Dimension", to: :dimension
          end
        end
      end
    end
  end
end
