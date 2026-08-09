# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Elements
      class StandardPageBreakElement < Metanorma::Document::Components::EmptyElements::PageBreakElement
        attribute :orientation, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "standard-page-break-element"
          map_attribute "orientation", to: :orientation

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
