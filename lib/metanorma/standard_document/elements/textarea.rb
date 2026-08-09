# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Elements
      # Input involving extended text. The value attribute is used instead of text area content
      class Textarea < Metanorma::StandardDocument::Elements::FormInput
        attribute :rows, :integer
        attribute :cols, :integer

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "textarea"
          map_attribute "rows", to: :rows
          map_attribute "cols", to: :cols

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
