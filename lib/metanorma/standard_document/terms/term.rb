# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # A term (`Term`) represents a terminology entry with
      # its definition.
      #
      # NOTE: The `Term` definition fully aligns with the structure
      # and requirements of terms in ISO/IEC DIR 2, 16.6.
      class Term < Lutaml::Model::Serializable
        attribute :language, :string
        attribute :script, :string
        attribute :tag, :string
        attribute :multilingual_rendering, :string
        attribute :id, :string
        attribute :preferred, Metanorma::StandardDocument::Terms::Designation,
                  collection: true
        attribute :admitted, Metanorma::StandardDocument::Terms::Designation,
                  collection: true
        attribute :related, Metanorma::StandardDocument::Terms::RelatedTerm,
                  collection: true
        attribute :deprecates, Metanorma::StandardDocument::Terms::Designation,
                  collection: true
        attribute :domain, Metanorma::Document::Components::DataTypes::LocalizedString
        attribute :subject, Metanorma::Document::Components::DataTypes::LocalizedString
        attribute :usage_info,
                  Metanorma::Document::Components::Blocks::BasicBlock, collection: true
        attribute :definition, Metanorma::StandardDocument::Terms::TermDefinition,
                  collection: true
        attribute :note,
                  Metanorma::Document::Components::Paragraphs::ParagraphBlock, collection: true
        attribute :example,
                  Metanorma::Document::Components::Paragraphs::ParagraphBlock, collection: true
        attribute :source, Metanorma::StandardDocument::Terms::TermSource,
                  collection: true

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "term"
          map_attribute "language", to: :language
          map_attribute "script", to: :script
          map_attribute "tag", to: :tag
          map_attribute "multilingual-rendering", to: :multilingual_rendering
          map_attribute "id", to: :id
          map_element "preferred", to: :preferred
          map_element "admitted", to: :admitted
          map_element "related", to: :related
          map_element "deprecates", to: :deprecates
          map_element "domain", to: :domain
          map_element "subject", to: :subject
          map_element "usage-info", to: :usage_info
          map_element "definition", to: :definition
          map_element "termnote", to: :note
          map_element "termexample", to: :example
          map_element "source", to: :source

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
