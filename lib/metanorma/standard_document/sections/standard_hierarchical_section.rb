# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      # A hierarchical section containing other sections, within a _StandardDocument_.
      class StandardHierarchicalSection < Metanorma::StandardDocument::Sections::StandardSection
        attribute :subsections,
                  Metanorma::StandardDocument::Sections::StandardSection, collection: true

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :autonum, :string
        attribute :displayorder, :integer
        attribute :inline_header, :boolean

        xml do
          element "standard-hierarchical-section"
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
