# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # A `<name>` element contains the rendered form of a term's
      # designation. It accepts arbitrary inline content (formatting,
      # math symbols, footnotes) — see `Inline::Vocabulary` for the
      # full set.
      class TermNameElement < Lutaml::Model::Serializable
        include Metanorma::Document::Components::Inline::Vocabulary

        attribute :id, :string
        attribute :semx_id, :string
        attribute :lang, :string

        xml do
          element "name"
          map_attribute "id", to: :id
          map_attribute "semx-id", to: :semx_id
          map_attribute "lang", to: :lang
          mixed_content
          Metanorma::Document::Components::Inline::Vocabulary::VocabularyXmlMapping
            .apply_inline_mappings(self)
        end
      end
    end
  end
end
