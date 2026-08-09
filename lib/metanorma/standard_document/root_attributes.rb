# frozen_string_literal: true

module Metanorma
  module StandardDocument
    # Mixin that declares the common attributes for every <metanorma> Root class.
    #
    # Every flavor Root class includes this module and adds its own
    # flavor-specific attributes (e.g. bibdata type, preface/sections types).
    module RootAttributes
      def self.included(base)
        base.class_eval do
          attribute :version,             :string
          attribute :type,                :string
          attribute :schema_version,      :string
          attribute :flavor,              :string

          attribute :bibliography,
                    Metanorma::StandardDocument::Sections::BibliographySection
          attribute :boilerplate,
                    Metanorma::StandardDocument::Boilerplate
          attribute :metanorma_extension,
                    Metanorma::StandardDocument::Metadata::MetanormaExtension
          attribute :annotation_container,
                    Metanorma::StandardDocument::AnnotationContainer
          attribute :localized_strings,
                    Metanorma::Document::Components::Inline::LocalizedStringsElement
          attribute :fmt_footnote_container,
                    Metanorma::Document::Components::Inline::FmtFootnoteContainerElement
          attribute :colophon,
                    Metanorma::StandardDocument::Sections::Colophon

          attribute :term_sources,
                    Metanorma::Document::Components::ReferenceElements::Citation,
                    collection: true
          attribute :indexsect,
                    Metanorma::Document::Components::Sections::BasicSection

          attribute :autonum,             :string
          attribute :fmt_xref_label,      :string
        end
      end
    end

    # Adds common XML root element mappings for all flavor Root classes.
    # Call inside an `xml do` block:
    #
    #   xml do
    #     element "metanorma"
    #     namespace StandardDocument::Namespace
    #     RootXmlMapping.apply(self)
    #     # ... flavor-specific mappings (bibdata, preface, sections, annex)
    #   end
    module RootXmlMapping
      def self.apply(mapping)
        mapping.map_attribute "type",               to: :type
        mapping.map_attribute "version",            to: :version
        mapping.map_attribute "schema-version",     to: :schema_version
        mapping.map_attribute "flavor",             to: :flavor
        mapping.map_attribute "autonum",            to: :autonum
        mapping.map_attribute "fmt-xref-label",     to: :fmt_xref_label
        mapping.map_element   "bibdata",            to: :bibdata
        mapping.map_element   "preface",            to: :preface
        mapping.map_element   "sections",           to: :sections
        mapping.map_element   "annex",              to: :annex
        mapping.map_element   "bibliography",       to: :bibliography
        mapping.map_element   "boilerplate",        to: :boilerplate
        mapping.map_element   "metanorma-extension", to: :metanorma_extension
        mapping.map_element   "annotation-container", to: :annotation_container
        mapping.map_element   "localized-strings", to: :localized_strings
        mapping.map_element   "fmt-footnote-container",
                              to: :fmt_footnote_container
        mapping.map_element   "colophon",           to: :colophon
        mapping.map_element   "termdocsource",      to: :term_sources
        mapping.map_element   "indexsect",          to: :indexsect
      end
    end
  end
end
