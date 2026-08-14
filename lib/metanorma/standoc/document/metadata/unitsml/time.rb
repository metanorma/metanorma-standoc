# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Metadata
      module Unitsml
        class Time < Lutaml::Model::Serializable
          include BaseQuantityAttributes

          xml do
            element "Time"
            namespace Unitsml::Namespace
            BaseQuantityXmlMapping.apply(self)
          end
        end
      end
    end
  end
end
