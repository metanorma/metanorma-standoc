# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Metadata
      # The extension point of the bibliographic description of a _StandardDocument_.
      class StandardBibDataExtensionType < Metanorma::Document::Components::BibData::BibDataExtensionType
        attribute :doctype, :string
        attribute :doctype_abbreviation, :string
        attribute :subdoctype, :string
        attribute :editorial_group, Metanorma::Standoc::Document::Metadata::EditorialGroupType
        attribute :ics, Metanorma::Standoc::Document::Metadata::IcsType,
                  collection: true
        attribute :structuredidentifier, Metanorma::Standoc::Document::Metadata::StructuredIdentifierType,
                  collection: true

        # Presentation-specific attributes

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "ext"
          map_attribute "doctype", to: :doctype
          map_attribute "doctype-abbreviation", to: :doctype_abbreviation
          map_element "subdoctype", to: :subdoctype
          map_element "editorial-group", to: :editorial_group
          map_element "ics", to: :ics
          map_element "structuredidentifier", to: :structuredidentifier

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
