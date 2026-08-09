# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      # Content block for amend description and new-content elements.
      # Contains block-level content: paragraphs, notes, lists, tables, etc.
      class AmendContentBlock < Lutaml::Model::Serializable
        attribute :paragraphs,
                  Metanorma::Document::Components::Paragraphs::ParagraphBlock,
                  collection: true
        attribute :note,
                  Metanorma::Document::Components::Blocks::NoteBlock,
                  collection: true
        attribute :ol,
                  Metanorma::Document::Components::Lists::OrderedList,
                  collection: true
        attribute :ul,
                  Metanorma::Document::Components::Lists::UnorderedList,
                  collection: true
        attribute :dl,
                  Metanorma::Document::Components::Lists::DefinitionList,
                  collection: true

        xml do
          map_element "p", to: :paragraphs
          map_element "note", to: :note
          map_element "ol", to: :ol
          map_element "ul", to: :ul
          map_element "dl", to: :dl
        end
      end
    end
  end
end
