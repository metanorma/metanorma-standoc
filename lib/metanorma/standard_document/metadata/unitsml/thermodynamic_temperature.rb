# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class ThermodynamicTemperature < Lutaml::Model::Serializable
          include BaseQuantityAttributes

          xml do
            element "ThermodynamicTemperature"
            namespace Unitsml::Namespace
            BaseQuantityXmlMapping.apply(self)
          end
        end
      end
    end
  end
end
