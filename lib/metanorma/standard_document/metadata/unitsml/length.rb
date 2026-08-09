# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class Length < Lutaml::Model::Serializable
          include BaseQuantityAttributes

          xml do
            element "Length"
            namespace Unitsml::Namespace
            BaseQuantityXmlMapping.apply(self)
          end
        end
      end
    end
  end
end
