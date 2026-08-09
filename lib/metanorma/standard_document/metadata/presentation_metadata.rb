# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      # <presentation-metadata> carries rendering hints for the document.
      #
      # Current serialization uses typed children (toc-heading-levels,
      # document-scheme, the OGC color-* family, OIML doctype-alias/fonts,
      # isodoc html-details-open). The legacy serialization (still emitted
      # into misc-container by some flavors) uses <name>/<value> pairs
      # instead. Both shapes are mapped here so either round-trips
      # losslessly. map_element order matches the order emitted by
      # metanorma across spec fixtures.
      class PresentationMetadata < Lutaml::Model::Serializable
        attribute :doctype_alias, :string
        attribute :document_scheme, :string
        attribute :color_admonition_caution, :string
        attribute :color_admonition_editor, :string
        attribute :color_admonition_important, :string
        attribute :color_admonition_note, :string
        attribute :color_admonition_safety_precaution, :string
        attribute :color_admonition_tip, :string
        attribute :color_admonition_todo, :string
        attribute :color_admonition_warning, :string
        attribute :color_background_definition_description, :string
        attribute :color_background_definition_term, :string
        attribute :color_background_page, :string
        attribute :color_background_table_header, :string
        attribute :color_background_table_row_even, :string
        attribute :color_background_table_row_odd, :string
        attribute :color_background_term_admitted_label, :string
        attribute :color_background_term_deprecated_label, :string
        attribute :color_background_term_preferred_label, :string
        attribute :color_background_text_label_legacy, :string
        attribute :color_secondary_shade1, :string
        attribute :color_secondary_shade2, :string
        attribute :color_text, :string
        attribute :color_text_title, :string
        attribute :toc_heading_levels, :string
        attribute :html_toc_heading_levels, :string
        attribute :doc_toc_heading_levels, :string
        attribute :pdf_toc_heading_levels, :string
        attribute :html_details_open, :string
        attribute :fonts, :string, collection: true
        attribute :name, :string
        attribute :value, :string

        xml do
          element "presentation-metadata"
          map_element "doctype-alias", to: :doctype_alias
          map_element "document-scheme", to: :document_scheme
          map_element "color-admonition-caution",
                      to: :color_admonition_caution
          map_element "color-admonition-editor",
                      to: :color_admonition_editor
          map_element "color-admonition-important",
                      to: :color_admonition_important
          map_element "color-admonition-note",
                      to: :color_admonition_note
          map_element "color-admonition-safety-precaution",
                      to: :color_admonition_safety_precaution
          map_element "color-admonition-tip",
                      to: :color_admonition_tip
          map_element "color-admonition-todo",
                      to: :color_admonition_todo
          map_element "color-admonition-warning",
                      to: :color_admonition_warning
          map_element "color-background-definition-description",
                      to: :color_background_definition_description
          map_element "color-background-definition-term",
                      to: :color_background_definition_term
          map_element "color-background-page",
                      to: :color_background_page
          map_element "color-background-table-header",
                      to: :color_background_table_header
          map_element "color-background-table-row-even",
                      to: :color_background_table_row_even
          map_element "color-background-table-row-odd",
                      to: :color_background_table_row_odd
          map_element "color-background-term-admitted-label",
                      to: :color_background_term_admitted_label
          map_element "color-background-term-deprecated-label",
                      to: :color_background_term_deprecated_label
          map_element "color-background-term-preferred-label",
                      to: :color_background_term_preferred_label
          map_element "color-background-text-label-legacy",
                      to: :color_background_text_label_legacy
          map_element "color-secondary-shade-1",
                      to: :color_secondary_shade1
          map_element "color-secondary-shade-2",
                      to: :color_secondary_shade2
          map_element "color-text", to: :color_text
          map_element "color-text-title", to: :color_text_title
          map_element "toc-heading-levels", to: :toc_heading_levels
          map_element "html-toc-heading-levels", to: :html_toc_heading_levels
          map_element "doc-toc-heading-levels", to: :doc_toc_heading_levels
          map_element "pdf-toc-heading-levels", to: :pdf_toc_heading_levels
          map_element "html-details-open", to: :html_details_open
          map_element "fonts", to: :fonts
          map_element "name", to: :name
          map_element "value", to: :value
        end
      end
    end
  end
end
