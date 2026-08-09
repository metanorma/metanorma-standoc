# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class Mass < Lutaml::Model::Serializable
          include BaseQuantityAttributes

          xml do
            element "Mass"
            namespace Unitsml::Namespace
            BaseQuantityXmlMapping.apply(self)
          end
        end
      end
    end
  end
end
