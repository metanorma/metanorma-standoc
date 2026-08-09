# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Metadata
      module Unitsml
        class ElectricCurrent < Lutaml::Model::Serializable
          include BaseQuantityAttributes

          xml do
            element "ElectricCurrent"
            namespace Unitsml::Namespace
            BaseQuantityXmlMapping.apply(self)
          end
        end
      end
    end
  end
end
