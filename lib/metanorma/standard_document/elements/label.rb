# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Elements
      # Label associated with form input element
      class Label < Metanorma::Document::Components::ReferenceElements::ReferenceToIdElement
        attribute :semx_id, :string
        attribute :original_id, :string
        xml do
          element "label"

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
