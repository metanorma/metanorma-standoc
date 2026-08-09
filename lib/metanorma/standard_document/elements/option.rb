# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Elements
      # Option of a Select input
      class Option < Lutaml::Model::Serializable
        attribute :disabled, :boolean
        attribute :value, :string
        attribute :content, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "option"
          map_attribute "disabled", to: :disabled
          map_attribute "value", to: :value
          map_content to: :content

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
