# frozen_string_literal: true

module Metanorma
  module StandardDocument
    # Mixin that declares individually-typed block collection attributes
    # for section-level models (ClauseSection, AnnexSection, ContentSection, etc.).
    #
    # Include this module in any Serializable class that represents a section
    # body containing heterogeneous block-level content (paragraphs, tables,
    # figures, etc.).
    module BlockAttributes
      def self.included(base)
        base.class_eval do
          attribute :paragraphs,
                    Metanorma::Document::Components::Paragraphs::ParagraphBlock,
                    collection: true
          attribute :unordered_lists,
                    Metanorma::Document::Components::Lists::UnorderedList,
                    collection: true
          attribute :ordered_lists,
                    Metanorma::Document::Components::Lists::OrderedList,
                    collection: true
          attribute :tables,
                    Metanorma::Document::Components::Tables::TableBlock,
                    collection: true
          attribute :figures,
                    Metanorma::Document::Components::AncillaryBlocks::FigureBlock,
                    collection: true
          attribute :formulas,
                    Metanorma::Document::Components::AncillaryBlocks::FormulaBlock,
                    collection: true
          attribute :examples,
                    Metanorma::Document::Components::AncillaryBlocks::ExampleBlock,
                    collection: true
          attribute :notes,
                    Metanorma::Document::Components::Blocks::NoteBlock,
                    collection: true
          attribute :admonitions,
                    Metanorma::Document::Components::MultiParagraph::AdmonitionBlock,
                    collection: true
          attribute :sourcecode_blocks,
                    Metanorma::Document::Components::AncillaryBlocks::SourcecodeBlock,
                    collection: true
          attribute :quote_blocks,
                    Metanorma::Document::Components::MultiParagraph::QuoteBlock,
                    collection: true
          attribute :definition_lists,
                    Metanorma::Document::Components::Lists::DefinitionList,
                    collection: true
        end
      end
    end

    # Provides `blocks` method for ordered-content section types.
    # Returns child block-level nodes in document order via `each_mixed_content`,
    # excluding metadata/inline elements like titles and annotations.
    module OrderedContent
      NON_BLOCK_TYPES = [
        Metanorma::Document::Components::Inline::TitleWithAnnotationElement,
        Metanorma::Document::Components::Inline::FmtTitleElement,
        Metanorma::Document::Components::Inline::VariantTitleElement,
        Metanorma::Document::Components::Inline::FmtXrefLabelElement,
        Metanorma::Document::Components::Inline::FmtAnnotationStartElement,
        Metanorma::Document::Components::Inline::FmtAnnotationEndElement,
      ].freeze

      def blocks
        @blocks ||=
          begin
            result = []
            each_mixed_content do |node|
              next if node.is_a?(String)
              next if NON_BLOCK_TYPES.any? { |t| node.is_a?(t) }

              result << node
            end
            result
          end
      end
    end

    # Presentation/formatting attributes shared by all section types.
    # Include in any section class that supports presentation metadata.
    module PresentationAttributes
      def self.included(base)
        base.class_eval do
          attribute :anchor, :string
          attribute :semx_id, :string
          attribute :autonum, :string
          attribute :displayorder, :integer
          attribute :fmt_title,
                    Metanorma::Document::Components::Inline::FmtTitleElement
          attribute :fmt_xref_label,
                    Metanorma::Document::Components::Inline::FmtXrefLabelElement,
                    collection: true
          attribute :variant_title,
                    Metanorma::Document::Components::Inline::VariantTitleElement,
                    collection: true
          attribute :fmt_annotation_start,
                    Metanorma::Document::Components::Inline::FmtAnnotationStartElement,
                    collection: true
          attribute :fmt_annotation_end,
                    Metanorma::Document::Components::Inline::FmtAnnotationEndElement,
                    collection: true
        end
      end
    end

    # Adds XML element mappings for block-level content to a mapping builder.
    # Call inside an `xml do` block:
    #
    #   xml do
    #     element "clause"
    #     ordered
    #     BlockXmlMapping.apply_block_mappings(self)
    #     # ... additional mappings
    #   end
    module BlockXmlMapping
      BLOCK_MAPPINGS = {
        "p" => :paragraphs,
        "ul" => :unordered_lists,
        "ol" => :ordered_lists,
        "table" => :tables,
        "figure" => :figures,
        "formula" => :formulas,
        "example" => :examples,
        "note" => :notes,
        "admonition" => :admonitions,
        "sourcecode" => :sourcecode_blocks,
        "quote" => :quote_blocks,
        "dl" => :definition_lists,
      }.freeze

      def self.apply_block_mappings(mapping)
        BLOCK_MAPPINGS.each do |element_name, attr_name|
          mapping.map_element(element_name, to: attr_name)
        end
      end
    end

    # Shared XML mapping helpers for section-level elements.
    # Extracts the common attribute/element mappings duplicated across
    # ClauseSection, AnnexSection, and their flavor-specific subclasses.
    module SectionXmlMapping
      # Common XML attribute mappings for clause sections.
      def self.apply_clause_attributes(mapping)
        mapping.map_attribute "id",            to: :id
        mapping.map_attribute "anchor",        to: :anchor
        mapping.map_attribute "type",          to: :type
        mapping.map_attribute "number",        to: :number
        mapping.map_attribute "obligation",    to: :obligation
        mapping.map_attribute "inline-header", to: :inline_header
        mapping.map_attribute "unnumbered",    to: :unnumbered
        mapping.map_attribute "toc",           to: :toc
        mapping.map_attribute "class",         to: :class_attr
        mapping.map_attribute "semx-id",       to: :semx_id
        mapping.map_attribute "autonum",       to: :autonum
        mapping.map_attribute "displayorder",  to: :displayorder
      end

      # Common XML element mappings for clause sections.
      def self.apply_clause_elements(mapping)
        mapping.map_element "title",                to: :title
        mapping.map_element "variant-title",        to: :variant_title
        mapping.map_element "fmt-title",            to: :fmt_title
        mapping.map_element "fmt-xref-label",       to: :fmt_xref_label

        BlockXmlMapping.apply_block_mappings(mapping)

        mapping.map_element "amend",                to: :amend
        mapping.map_element "clause",               to: :clause
        mapping.map_element "terms",                to: :terms
        mapping.map_element "definitions",          to: :definitions
        mapping.map_element "references",           to: :references
        mapping.map_element "floating-title",       to: :floating_title
        mapping.map_element "form",                 to: :form
        mapping.map_element "requirement",          to: :requirement
        mapping.map_element "recommendation",       to: :recommendation
        mapping.map_element "permission",           to: :permission
        mapping.map_element "pagebreak",            to: :pagebreak
        mapping.map_element "bookmark",             to: :bookmark
        mapping.map_element "fmt-annotation-start", to: :fmt_annotation_start
        mapping.map_element "fmt-annotation-end",   to: :fmt_annotation_end
      end

      # Common XML attribute mappings for annex sections.
      def self.apply_annex_attributes(mapping)
        mapping.map_attribute "id",            to: :id
        mapping.map_attribute "number",        to: :number
        mapping.map_attribute "obligation",    to: :obligation,
                                               render_empty: true
        mapping.map_attribute "unnumbered",    to: :unnumbered
        mapping.map_attribute "toc",           to: :toc
        mapping.map_attribute "anchor",        to: :anchor
        mapping.map_attribute "semx-id",       to: :semx_id
        mapping.map_attribute "autonum",       to: :autonum
        mapping.map_attribute "displayorder",  to: :displayorder
        mapping.map_attribute "inline-header", to: :inline_header
        mapping.map_attribute "language",      to: :language, render_empty: true
        mapping.map_attribute "script",        to: :script, render_empty: true
      end

      # Common XML element mappings for annex sections.
      def self.apply_annex_elements(mapping)
        mapping.map_element "title",                to: :title
        mapping.map_element "variant-title",        to: :variant_title
        mapping.map_element "fmt-title",            to: :fmt_title
        mapping.map_element "fmt-xref-label",       to: :fmt_xref_label

        BlockXmlMapping.apply_block_mappings(mapping)

        mapping.map_element "clause",               to: :clause
        mapping.map_element "appendix",             to: :appendix
        mapping.map_element "terms",                to: :terms
        mapping.map_element "definitions",          to: :definitions
        mapping.map_element "references",           to: :references
        mapping.map_element "floating-title",       to: :floating_title
        mapping.map_element "pagebreak",            to: :pagebreak
        mapping.map_element "fmt-annotation-start", to: :fmt_annotation_start
        mapping.map_element "fmt-annotation-end",   to: :fmt_annotation_end
      end

      # Common XML element/attribute mappings for the sections container.
      def self.apply_sections_elements(mapping)
        mapping.map_element "clause",         to: :clause
        mapping.map_element "terms",          to: :terms
        mapping.map_element "definitions",    to: :definitions
        mapping.map_element "floating-title", to: :floating_title
        mapping.map_element "references",     to: :references
      end

      def self.apply_sections_attributes(mapping)
        mapping.map_attribute "semx-id",      to: :semx_id
        mapping.map_attribute "displayorder", to: :displayorder
      end

      # Common XML element/attribute mappings for preface containers.
      def self.apply_preface_elements(mapping)
        mapping.map_element "abstract",          to: :abstract
        mapping.map_element "foreword",          to: :foreword
        mapping.map_element "introduction",      to: :introduction
        mapping.map_element "acknowledgements",  to: :acknowledgements
        mapping.map_element "executivesummary",  to: :executivesummary
      end

      def self.apply_preface_attributes(mapping)
        mapping.map_attribute "semx-id",      to: :semx_id
        mapping.map_attribute "displayorder", to: :displayorder
      end

      # Common XML attribute/element mappings for ContentSection subclasses.
      def self.apply_content_section_attributes(mapping)
        mapping.map_attribute "id",             to: :id
        mapping.map_attribute "anchor",         to: :anchor
        mapping.map_attribute "type",           to: :type
        mapping.map_attribute "number",         to: :number
        mapping.map_attribute "obligation",     to: :obligation
        mapping.map_attribute "inline-header",  to: :inline_header
        mapping.map_attribute "unnumbered",     to: :unnumbered
        mapping.map_attribute "toc",            to: :toc
        mapping.map_attribute "class",          to: :class_attr
        mapping.map_attribute "semx-id",        to: :semx_id
        mapping.map_attribute "autonum",        to: :autonum
        mapping.map_attribute "displayorder",   to: :displayorder
      end

      def self.apply_content_section_elements(mapping)
        mapping.map_element "title",                to: :title
        mapping.map_element "variant-title",        to: :variant_title
        mapping.map_element "fmt-title",            to: :fmt_title
        mapping.map_element "fmt-xref-label",       to: :fmt_xref_label

        BlockXmlMapping.apply_block_mappings(mapping)

        mapping.map_element "clause",               to: :subsection
        mapping.map_element "fmt-annotation-start", to: :fmt_annotation_start
        mapping.map_element "fmt-annotation-end",   to: :fmt_annotation_end
      end
    end
  end
end
