# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class LuminousIntensity < Lutaml::Model::Serializable
          include BaseQuantityAttributes

          xml do
            element "LuminousIntensity"
            namespace Unitsml::Namespace
            BaseQuantityXmlMapping.apply(self)
          end
        end
      end
    end
  end
end
