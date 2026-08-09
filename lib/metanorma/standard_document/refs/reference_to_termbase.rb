# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Refs
      # Cross-reference to a term defined within a termbase.
      class ReferenceToTermbase < Lutaml::Model::Serializable
        attribute :base, :string
        attribute :target, :string
        attribute :text, Metanorma::Document::Components::TextElements::TextElement

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "reference-to-termbase"
          map_attribute "base", to: :base
          map_attribute "target", to: :target
          map_element "text", to: :text

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
