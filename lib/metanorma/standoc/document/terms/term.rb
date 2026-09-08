# frozen_string_literal: true

module Metanorma
  module Standoc::Document
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
        attribute :anchor, :string
        attribute :preferred, Metanorma::Standoc::Document::Terms::Designation,
                  collection: true
        attribute :admitted, Metanorma::Standoc::Document::Terms::Designation,
                  collection: true
        attribute :related, Metanorma::Standoc::Document::Terms::RelatedTerm,
                  collection: true
        attribute :deprecates, Metanorma::Standoc::Document::Terms::Designation,
                  collection: true
        attribute :fmt_deprecates,
                  Metanorma::Standoc::Document::Terms::FmtDeprecates
        attribute :fmt_related,
                  "Metanorma::Standoc::Document::Terms::FmtRelated"
        attribute :domain, Metanorma::Document::Components::DataTypes::LocalizedString
        attribute :subject, Metanorma::Document::Components::DataTypes::LocalizedString
        attribute :usage_info,
                  Metanorma::Document::Components::Blocks::BasicBlock, collection: true
        attribute :definition, Metanorma::Standoc::Document::Terms::TermDefinition,
                  collection: true
        attribute :note, Metanorma::Standoc::Document::Terms::TermNote,
                  collection: true
        attribute :example, Metanorma::Standoc::Document::Terms::TermExample,
                  collection: true
        attribute :source, Metanorma::Standoc::Document::Terms::TermSource,
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
          map_attribute "anchor", to: :anchor
          map_element "preferred", to: :preferred
          map_element "admitted", to: :admitted
          map_element "related", to: :related
          map_element "deprecates", to: :deprecates
          map_element "fmt-deprecates", to: :fmt_deprecates
          map_element "fmt-related", to: :fmt_related
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
