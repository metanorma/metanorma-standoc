# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Terms
      # Grammatical information about a designation: gender and number
      # values, part-of-speech markers, and miscellaneous grammar notes.
      # Child ELEMENTS per the grammar (standoc.rnc Grammar define) —
      # the is* markers are boolean elements, not attributes.
      class GrammarInfo < Lutaml::Model::Serializable
        attribute :gender, Metanorma::Standoc::Document::Terms::GrammarGender,
                  collection: true
        attribute :number, Metanorma::Standoc::Document::Terms::GrammarNumber,
                  collection: true
        attribute :is_preposition, :boolean
        attribute :is_participle, :boolean
        attribute :is_adjective, :boolean
        attribute :is_verb, :boolean
        attribute :is_adverb, :boolean
        attribute :is_noun, :boolean
        attribute :grammar_value, :string, collection: true

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "grammar"
          map_element "gender", to: :gender
          map_element "number", to: :number
          map_element "isPreposition", to: :is_preposition
          map_element "isParticiple", to: :is_participle
          map_element "isAdjective", to: :is_adjective
          map_element "isVerb", to: :is_verb
          map_element "isAdverb", to: :is_adverb
          map_element "isNoun", to: :is_noun
          map_element "grammar-value", to: :grammar_value

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
