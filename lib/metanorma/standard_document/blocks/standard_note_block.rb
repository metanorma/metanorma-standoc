# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      class StandardNoteBlock < Metanorma::StandardDocument::Blocks::StandardBlockNoNotes
        attribute :keep_lines_together, :boolean
        attribute :keep_with_next, :boolean
        attribute :number, :string
        attribute :subsequence, :string
        attribute :unnumbered, :boolean
        attribute :cover_page, :boolean
        attribute :notag, :boolean
        attribute :type, :string
        attribute :ul, Metanorma::Document::Components::Lists::UnorderedList,
                  collection: true
        attribute :ol, Metanorma::Document::Components::Lists::OrderedList,
                  collection: true
        attribute :dl, Metanorma::Document::Components::Lists::DefinitionList,
                  collection: true
        attribute :formula,
                  Metanorma::Document::Components::AncillaryBlocks::FormulaBlock, collection: true
        attribute :sourcecode,
                  Metanorma::Document::Components::AncillaryBlocks::SourcecodeBlock, collection: true
        attribute :quotes,
                  Metanorma::Document::Components::MultiParagraph::QuoteBlock, collection: true

        # Presentation-specific attributes

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :autonum, :string
        attribute :fmt_name, :string
        attribute :fmt_xref_label, :string
        attribute :displayorder, :integer

        xml do
          element "standard-note-block"
          map_attribute "keep-lines-together", to: :keep_lines_together
          map_attribute "keep-with-next", to: :keep_with_next
          map_attribute "number", to: :number
          map_attribute "subsequence", to: :subsequence
          map_attribute "unnumbered", to: :unnumbered
          map_attribute "cover-page", to: :cover_page
          map_attribute "notag", to: :notag
          map_attribute "type", to: :type
          map_element "ul", to: :ul
          map_element "ol", to: :ol
          map_element "dl", to: :dl
          map_element "formula", to: :formula
          map_element "sourcecode", to: :sourcecode
          map_element "quote", to: :quotes

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "autonum", to: :autonum
          map_element "fmt-name", to: :fmt_name
          map_element "fmt-xref-label", to: :fmt_xref_label
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
