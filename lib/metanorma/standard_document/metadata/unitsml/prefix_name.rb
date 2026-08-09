# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class PrefixName < Lutaml::Model::Serializable
          attribute :lang, :string
          attribute :text, :string

          xml do
            element "PrefixName"
            namespace Unitsml::Namespace
            map_attribute "lang", to: :lang
            map_content to: :text
          end
        end
      end
    end
  end
end
