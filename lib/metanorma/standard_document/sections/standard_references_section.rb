# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      # The `StandardReferencesSection` class within _StandardDocument_
      # is used to represent a bibliography section.
      # It is used to collate references within the document, where
      # there could be one or more of such sections within a document.
      #
      # For example, some standardization documents differentiate
      # normative or informative references, some split references into
      # sections organized by concept relevance.
      #
      # Similar to the `ReferencesSection` of the _BasicDocument_ model,
      # they are leaf nodes which contain zero or more
      # bibliographical references (as modelled in Relaton), along with
      # any prefatory text.
      class StandardReferencesSection < Metanorma::StandardDocument::Sections::StandardSection
        attribute :normative, :boolean
        attribute :obligation, :string
        attribute :hidden, :boolean
        attribute :references, Metanorma::Document::Components::BibData::BibliographicItem,
                  collection: true
        attribute :passthrough, Metanorma::StandardDocument::Blocks::Passthrough,
                  collection: true
        attribute :note,
                  Metanorma::Document::Components::Paragraphs::ParagraphBlock, collection: true
        attribute :p,
                  Metanorma::Document::Components::Paragraphs::ParagraphBlock, collection: true
        attribute :table,
                  Metanorma::Document::Components::Tables::TableBlock, collection: true

        # Presentation-specific attributes

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :autonum, :string
        attribute :displayorder, :integer
        attribute :title, Metanorma::Document::Components::Inline::TitleWithAnnotationElement
        attribute :fmt_title, Metanorma::Document::Components::Inline::FmtTitleElement
        attribute :fmt_xref_label,
                  Metanorma::Document::Components::Inline::FmtXrefLabelElement, collection: true
        attribute :fmt_annotation_start,
                  Metanorma::Document::Components::Inline::FmtAnnotationStartElement,
                  collection: true
        attribute :fmt_annotation_end,
                  Metanorma::Document::Components::Inline::FmtAnnotationEndElement,
                  collection: true

        xml do
          element "references"
          map_attribute "normative", to: :normative
          map_attribute "obligation", to: :obligation
          map_attribute "hidden", to: :hidden
          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "autonum", to: :autonum
          map_attribute "displayorder", to: :displayorder
          map_element "title", to: :title
          map_element "p", to: :p
          map_element "note", to: :note
          map_element "bibitem", to: :references
          map_element "passthrough", to: :passthrough
          map_element "table", to: :table
          map_element "fmt-title", to: :fmt_title
          map_element "fmt-xref-label", to: :fmt_xref_label
          map_element "fmt-annotation-start", to: :fmt_annotation_start
          map_element "fmt-annotation-end", to: :fmt_annotation_end
        end
      end
    end
  end
end
