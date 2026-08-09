# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class QuantityName < Lutaml::Model::Serializable
          attribute :lang, :string
          attribute :text, :string

          xml do
            element "QuantityName"
            namespace Unitsml::Namespace
            map_attribute "lang", to: :lang
            map_content to: :text
          end
        end
      end
    end
  end
end
