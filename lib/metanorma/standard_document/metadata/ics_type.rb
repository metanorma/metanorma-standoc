# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      # Classification taken from the International Classification of Standards.
      # ICS is defined by ISO here -- https://www.iso.org/publication/PUB100033.html
      class IcsType < Lutaml::Model::Serializable
        attribute :code, :string
        attribute :text, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "ics"
          map_attribute "code", to: :code
          map_attribute "text", to: :text

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
