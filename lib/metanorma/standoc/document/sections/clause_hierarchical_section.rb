# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Sections
      # Clauses in which all textual content belongs in a strict clause hierarchy. such that no blocks of
      # text
      # are siblings to subclauses.
      class ClauseHierarchicalSection < Metanorma::Standoc::Document::Sections::ClauseSection
        attribute :subsections,
                  Metanorma::Standoc::Document::Sections::ClauseHierarchicalSection, collection: true

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :autonum, :string
        attribute :displayorder, :integer
        attribute :inline_header, :boolean

        xml do
          element "clause-hierarchical-section"
          map_element "subsections", to: :subsections

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "autonum", to: :autonum
          map_attribute "displayorder", to: :displayorder
          map_attribute "inline-header", to: :inline_header
        end
      end
    end
  end
end
