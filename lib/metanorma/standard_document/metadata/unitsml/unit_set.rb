# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class UnitSet < Lutaml::Model::Serializable
          attribute :unit, Unit, collection: true

          xml do
            element "UnitSet"
            namespace Unitsml::Namespace
            map_element "Unit", to: :unit
          end
        end
      end
    end
  end
end
