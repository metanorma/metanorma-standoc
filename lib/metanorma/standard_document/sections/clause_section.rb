# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      # A numbered clause in the document body.
      # Corresponds to isodoc.rnc `Clause-Section`:
      #   Section-Attributes, type?, title?,
      #   ( (BasicBlock+ | amend) |
      #     (clause-subsection | terms | definitions | floating-title)+ )
      #
      # Uses `ordered` to enable `each_mixed_content` for document-order iteration.
      class ClauseSection < Lutaml::Model::Serializable
        include Metanorma::StandardDocument::BlockAttributes
        include Metanorma::StandardDocument::PresentationAttributes
        include Metanorma::StandardDocument::OrderedContent

        # Section identity and classification
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

        # Sub-clauses (recursive)
        attribute :clause, ClauseSection, collection: true

        # Amend blocks (for amendment documents)
        attribute :amend,
                  Metanorma::StandardDocument::Blocks::AmendBlock

        # Terms sections nested inside clauses
        attribute :terms,
                  Metanorma::StandardDocument::Sections::TermsSection,
                  collection: true

        # Definitions sections nested inside clauses
        attribute :definitions,
                  Metanorma::StandardDocument::Sections::DefinitionSection,
                  collection: true

        # References sections nested inside clauses
        attribute :references,
                  Metanorma::StandardDocument::Sections::StandardReferencesSection,
                  collection: true

        # Floating titles
        attribute :floating_title,
                  Metanorma::StandardDocument::Sections::FloatingTitle,
                  collection: true

        # Forms
        attribute :form,
                  Metanorma::StandardDocument::Blocks::Form,
                  collection: true

        # Requirements / recommendations / permissions
        attribute :requirement,
                  Metanorma::StandardDocument::Blocks::RequirementModel,
                  collection: true
        attribute :recommendation,
                  Metanorma::StandardDocument::Blocks::RecommendationModel,
                  collection: true
        attribute :permission,
                  Metanorma::StandardDocument::Blocks::PermissionModel,
                  collection: true

        # Page breaks and bookmarks
        attribute :pagebreak,
                  Metanorma::Document::Components::EmptyElements::PageBreakElement,
                  collection: true
        attribute :bookmark,
                  Metanorma::Document::Components::IdElements::Bookmark,
                  collection: true

        xml do
          element "clause"
          ordered

          Metanorma::StandardDocument::SectionXmlMapping.apply_clause_attributes(self)
          Metanorma::StandardDocument::SectionXmlMapping.apply_clause_elements(self)
        end
      end
    end
  end
end
