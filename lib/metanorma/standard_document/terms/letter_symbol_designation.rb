# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # A designation realised as a letter or symbol.
      class LetterSymbolDesignation < Lutaml::Model::Serializable
        attribute :text, :string, collection: true
        attribute :stem, Metanorma::Document::Components::TextElements::StemElement
        attribute :is_international, :boolean

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "letter-symbol"
          map_element "text", to: :text
          map_element "stem", to: :stem
          map_attribute "isInternational", to: :is_international

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
