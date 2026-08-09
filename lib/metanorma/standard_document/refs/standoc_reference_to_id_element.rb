# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Refs
      # Cross-reference to an identified element within a _StandardDocument_.
      class StandocReferenceToIdElement < Metanorma::Document::Components::ReferenceElements::ReferenceToIdElement
        attribute :case, :string
        attribute :droploc, :boolean
        attribute :style, :string
        attribute :label, :string
        attribute :to, Metanorma::Document::Components::IdElements::IdElement
        attribute :xref_target, Metanorma::StandardDocument::Refs::XrefTargetType,
                  collection: true
        attribute :display_text, Metanorma::Document::Components::Inline::DisplayTextElement

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "standoc-reference-to-id-element"
          map_attribute "case", to: :case
          map_attribute "droploc", to: :droploc
          map_attribute "style", to: :style
          map_attribute "label", to: :label
          map_element "to", to: :to
          map_element "xref-target", to: :xref_target
          map_element "display-text", to: :display_text

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
