# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class PlaneAngle < Lutaml::Model::Serializable
          include BaseQuantityAttributes

          xml do
            element "PlaneAngle"
            namespace Unitsml::Namespace
            BaseQuantityXmlMapping.apply(self)
          end
        end
      end
    end
  end
end
