# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      # A content section used for preface elements (abstract, foreword,
      # introduction, acknowledgements, executivesummary) and generic clauses
      # within preface.
      # Corresponds to isodoc.rnc `Content-Section`:
      #   Section-Attributes, type?, title?,
      #   ( BasicBlock*, content-subsection* )
      class ContentSection < Lutaml::Model::Serializable
        include Metanorma::StandardDocument::BlockAttributes
        include Metanorma::StandardDocument::PresentationAttributes

        # Section identity
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

        # Nested content subsections (recursive)
        attribute :subsection, ContentSection, collection: true

        xml do
          element "clause"
          ordered

          Metanorma::StandardDocument::SectionXmlMapping.apply_content_section_attributes(self)
          Metanorma::StandardDocument::SectionXmlMapping.apply_content_section_elements(self)
        end
      end
    end
  end
end
