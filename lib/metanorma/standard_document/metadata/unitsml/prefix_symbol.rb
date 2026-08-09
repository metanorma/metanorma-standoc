# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class PrefixSymbol < Lutaml::Model::Serializable
          attribute :type, :string
          attribute :text, :string

          xml do
            element "PrefixSymbol"
            namespace Unitsml::Namespace
            map_attribute "type", to: :type
            map_content to: :text
          end
        end
      end
    end
  end
end
