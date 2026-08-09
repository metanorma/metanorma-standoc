# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Elements
      # Input element for forms, associated with name/value pair to be submitted
      class FormInput < Lutaml::Model::Serializable
        attribute :id, :string
        attribute :name, :string
        attribute :value, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "form-input"
          map_attribute "id", to: :id
          map_attribute "name", to: :name
          map_attribute "value", to: :value

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
