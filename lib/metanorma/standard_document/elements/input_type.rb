# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Elements
      # Type of simple Input element
      class InputType < Lutaml::Model::Serializable
        attribute :value, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "input-type"
          map_content to: :value

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end

        def self.values
          %w[button checkbox date file password radio submit text]
        end
      end
    end
  end
end
