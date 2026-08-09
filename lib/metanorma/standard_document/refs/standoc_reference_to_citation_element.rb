# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Refs
      # Cross-reference to an bibliographic reference within a _StandardDocument_.
      class StandocReferenceToCitationElement < Metanorma::Document::Components::ReferenceElements::ReferenceToCitationElement
        attribute :case, :string
        attribute :droploc, :boolean
        attribute :style, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "standoc-reference-to-citation-element"
          map_attribute "case", to: :case
          map_attribute "droploc", to: :droploc
          map_attribute "style", to: :style

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
