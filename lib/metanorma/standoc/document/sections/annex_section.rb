# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Sections
      # An annex section in the document.
      # Corresponds to isodoc.rnc `Annex-Section-Body`:
      #   Annex-Section-Attributes, title?,
      #   ( BasicBlock*,
      #     (annex-subsection | terms | definitions | references | floating-title)* )
      #
      # Uses `ordered` to enable `each_mixed_content` for document-order iteration.
      class AnnexSection < Lutaml::Model::Serializable
        include Metanorma::Standoc::Document::BlockAttributes
        include Metanorma::Standoc::Document::PresentationAttributes
        include Metanorma::Standoc::Document::OrderedContent

        # Section identity and classification
        attribute :id, :string
        attribute :number, :string
        attribute :obligation, :string
        attribute :unnumbered, :boolean
        attribute :toc, :string
        attribute :inline_header, :boolean
        attribute :title,
                  Metanorma::Document::Components::Inline::TitleWithAnnotationElement

        # Language/script (unique to annex)
        attribute :language, :string
        attribute :script, :string

        # Sub-clauses within annex (recursive)
        attribute :clause, AnnexSection, collection: true

        # Appendix (sub-sections unique to annex)
        attribute :appendix, ClauseSection, collection: true

        # Terms, definitions, references within annex
        attribute :terms,
                  Metanorma::Standoc::Document::Sections::TermsSection,
                  collection: true
        attribute :definitions,
                  Metanorma::Standoc::Document::Sections::DefinitionSection,
                  collection: true
        attribute :references,
                  Metanorma::Standoc::Document::Sections::StandardReferencesSection,
                  collection: true

        # Floating titles
        attribute :floating_title,
                  Metanorma::Standoc::Document::Sections::FloatingTitle,
                  collection: true

        # Page breaks
        attribute :pagebreak,
                  Metanorma::Document::Components::EmptyElements::PageBreakElement,
                  collection: true

        xml do
          element "annex"
          ordered

          Metanorma::Standoc::Document::SectionXmlMapping.apply_annex_attributes(self)
          Metanorma::Standoc::Document::SectionXmlMapping.apply_annex_elements(self)
        end
      end
    end
  end
end
