# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Elements
      # Input allowing the selection of a value from a list of values. The value attribute is used instead
      # of a selected
      # attribute on a component option
      class Select < Metanorma::StandardDocument::Elements::FormInput
        attribute :disabled, :boolean
        attribute :multiple, :boolean
        attribute :size, :integer
        attribute :option, Metanorma::StandardDocument::Elements::Option,
                  collection: true

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "select"
          map_attribute "disabled", to: :disabled
          map_attribute "multiple", to: :multiple
          map_attribute "size", to: :size
          map_element "option", to: :option

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
