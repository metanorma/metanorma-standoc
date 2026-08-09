# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class UnitSystem < Lutaml::Model::Serializable
          attribute :name, :string
          attribute :type, :string
          attribute :lang, :string

          xml do
            element "UnitSystem"
            namespace Unitsml::Namespace
            map_attribute "name", to: :name
            map_attribute "type", to: :type
            map_attribute "lang", to: :lang
          end
        end
      end
    end
  end
end
