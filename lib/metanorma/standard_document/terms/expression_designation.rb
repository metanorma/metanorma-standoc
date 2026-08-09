# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # A designation realised as a linguistic form.
      class ExpressionDesignation < Lutaml::Model::Serializable
        attribute :language, :string
        attribute :script, :string
        attribute :type, :string
        attribute :text, :string, collection: true
        attribute :pronunciation, Metanorma::Document::Components::DataTypes::LocalizedString,
                  collection: true
        attribute :is_international, :boolean
        attribute :abbreviation_type, :string
        attribute :grammar_info, Metanorma::StandardDocument::Terms::GrammarInfo

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "expression"
          map_attribute "language", to: :language
          map_attribute "script", to: :script
          map_attribute "type", to: :type
          map_element "text", to: :text
          map_element "pronunciation", to: :pronunciation
          map_attribute "is-international", to: :is_international
          map_attribute "abbreviation-type", to: :abbreviation_type
          map_element "grammar-info", to: :grammar_info

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
