# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      # Definition sections consist of one or more definition lists,
      # used to define symbols and abbreviations used in the remainder of
      # the document.
      #
      # Corresponds to isodoc.rnc:
      #   definitions = element definitions {
      #     Section-Attributes,
      #     ( (BasicBlock+) | (dl+) )?,
      #     definitions*
      #   }
      class DefinitionSection < Lutaml::Model::Serializable
        include Metanorma::StandardDocument::PresentationAttributes

        attribute :id, :string
        attribute :type, :string
        attribute :number, :string
        attribute :obligation, :string
        attribute :inline_header, :boolean
        attribute :unnumbered, :boolean
        attribute :toc, :string
        attribute :class_attr, :string
        attribute :title,
                  Metanorma::Document::Components::Inline::TitleWithAnnotationElement

        # Block content
        attribute :paragraphs,
                  Metanorma::Document::Components::Paragraphs::ParagraphBlock,
                  collection: true
        attribute :unordered_lists,
                  Metanorma::Document::Components::Lists::UnorderedList,
                  collection: true
        attribute :tables,
                  Metanorma::Document::Components::Tables::TableBlock,
                  collection: true
        attribute :definition_lists,
                  Metanorma::Document::Components::Lists::DefinitionList,
                  collection: true
        attribute :examples,
                  Metanorma::Document::Components::AncillaryBlocks::ExampleBlock,
                  collection: true

        # Recursive definitions
        attribute :definitions, DefinitionSection, collection: true

        xml do
          element "definitions"
          ordered

          Metanorma::StandardDocument::SectionXmlMapping.apply_content_section_attributes(self)

          map_element "title",          to: :title
          map_element "variant-title",  to: :variant_title
          map_element "p",              to: :paragraphs
          map_element "ul",             to: :unordered_lists
          map_element "table",          to: :tables
          map_element "dl",             to: :definition_lists
          map_element "example",        to: :examples
          map_element "definitions",    to: :definitions
          map_element "fmt-title",      to: :fmt_title
          map_element "fmt-xref-label", to: :fmt_xref_label
          map_element "fmt-annotation-start", to: :fmt_annotation_start
          map_element "fmt-annotation-end",   to: :fmt_annotation_end
        end
      end
    end
  end
end
