# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      # Input form, for use under HTML.
      class Form < Metanorma::StandardDocument::Blocks::StandardBlockNoNotes
        attribute :id, :string
        attribute :name, :string
        attribute :action, :string
        attribute :class_attr, :string
        attribute :text,
                  Metanorma::Document::Components::TextElements::TextElement, collection: true
        attribute :input, Metanorma::StandardDocument::Elements::FormInput,
                  collection: true
        attribute :label, Metanorma::StandardDocument::Elements::Label,
                  collection: true
        attribute :p, Metanorma::Document::Components::Paragraphs::ParagraphBlock,
                  collection: true
        attribute :table, Metanorma::Document::Components::Tables::TableBlock,
                  collection: true

        xml do
          element "form"
          map_attribute "id", to: :id
          map_attribute "name", to: :name
          map_attribute "action", to: :action
          map_attribute "class", to: :class_attr
          map_element "text", to: :text
          map_element "input", to: :input
          map_element "label", to: :label
          map_element "p", to: :p
          map_element "table", to: :table
        end
      end
    end
  end
end
