# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class AmountOfSubstance < Lutaml::Model::Serializable
          include BaseQuantityAttributes

          xml do
            element "AmountOfSubstance"
            namespace Unitsml::Namespace
            BaseQuantityXmlMapping.apply(self)
          end
        end
      end
    end
  end
end
