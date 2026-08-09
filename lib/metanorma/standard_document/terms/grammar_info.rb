# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # Grammatical information about a designation.
      class GrammarInfo < Lutaml::Model::Serializable
        attribute :gender, Metanorma::StandardDocument::Terms::GrammarGender,
                  collection: true
        attribute :is_preposition, :boolean
        attribute :is_participle, :boolean
        attribute :is_adjective, :boolean
        attribute :is_verb, :boolean
        attribute :is_adverb, :boolean
        attribute :is_noun, :boolean

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "grammar-info"
          map_element "gender", to: :gender
          map_attribute "is-preposition", to: :is_preposition
          map_attribute "is-participle", to: :is_participle
          map_attribute "is-adjective", to: :is_adjective
          map_attribute "is-verb", to: :is_verb
          map_attribute "is-adverb", to: :is_adverb
          map_attribute "is-noun", to: :is_noun

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
