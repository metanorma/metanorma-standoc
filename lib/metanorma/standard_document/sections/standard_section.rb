# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      class StandardSection < Metanorma::Document::Components::Sections::BasicSection
        attribute :variant_title, Metanorma::Document::Relaton::TypedTitleString,
                  collection: true
        attribute :status, :string
        attribute :amend, Metanorma::StandardDocument::Blocks::AmendBlock
        attribute :number, :string
        attribute :branch_number, :string
        attribute :unnumbered, :boolean
        attribute :obligation, :string

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :autonum, :string
        attribute :displayorder, :integer

        xml do
          element "standard-section"
          map_element "variant-title", to: :variant_title
          map_attribute "status", to: :status
          map_element "amend", to: :amend
          map_attribute "number", to: :number
          map_attribute "branch-number", to: :branch_number
          map_attribute "unnumbered", to: :unnumbered
          map_attribute "obligation", to: :obligation

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "autonum", to: :autonum
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
