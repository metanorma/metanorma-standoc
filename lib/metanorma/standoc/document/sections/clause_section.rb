# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Sections
      # A numbered clause in the document body.
      # Corresponds to isodoc.rnc `Clause-Section`:
      #   Section-Attributes, type?, title?,
      #   ( (BasicBlock+ | amend) |
      #     (clause-subsection | terms | definitions | floating-title)+ )
      #
      # Uses `ordered` to enable `each_mixed_content` for document-order iteration.
      class ClauseSection < Lutaml::Model::Serializable
        include Metanorma::Standoc::Document::BlockAttributes
        include Metanorma::Standoc::Document::PresentationAttributes
        include Metanorma::Standoc::Document::OrderedContent

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
                  Metanorma::Standoc::Document::Blocks::AmendBlock

        # Terms sections nested inside clauses
        attribute :terms,
                  Metanorma::Standoc::Document::Sections::TermsSection,
                  collection: true

        # Definitions sections nested inside clauses
        attribute :definitions,
                  Metanorma::Standoc::Document::Sections::DefinitionSection,
                  collection: true

        # References sections nested inside clauses
        attribute :references,
                  Metanorma::Standoc::Document::Sections::StandardReferencesSection,
                  collection: true

        # Floating titles
        attribute :floating_title,
                  Metanorma::Standoc::Document::Sections::FloatingTitle,
                  collection: true

        # Forms
        attribute :form,
                  Metanorma::Standoc::Document::Blocks::Form,
                  collection: true

        # Requirements / recommendations / permissions
        attribute :requirement,
                  Metanorma::Standoc::Document::Blocks::RequirementModel,
                  collection: true
        attribute :recommendation,
                  Metanorma::Standoc::Document::Blocks::RecommendationModel,
                  collection: true
        attribute :permission,
                  Metanorma::Standoc::Document::Blocks::PermissionModel,
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

          Metanorma::Standoc::Document::SectionXmlMapping.apply_clause_attributes(self)
          Metanorma::Standoc::Document::SectionXmlMapping.apply_clause_elements(self)
        end
      end
    end
  end
end
