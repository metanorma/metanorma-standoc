# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      # Block expressing a machine-readable change in a document.
      class AmendBlock < Metanorma::StandardDocument::Blocks::StandardBlockNoNotes
        attribute :change, :string
        attribute :bib_locality, Metanorma::Document::Relaton::BibItemLocality,
                  collection: true
        attribute :path, :string
        attribute :path_end, :string
        attribute :position, :string
        attribute :name, :string
        attribute :description,
                  AmendContentBlock, collection: true
        attribute :auto_number, Metanorma::StandardDocument::Blocks::AutoNumber,
                  collection: true
        attribute :new_content,
                  AmendContentBlock, collection: true

        # Presentation-specific attributes

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :autonum, :string
        attribute :displayorder, :integer

        xml do
          element "amend"
          mixed_content
          map_attribute "change", to: :change
          map_element "bib-locality", to: :bib_locality
          map_attribute "path", to: :path
          map_attribute "position", to: :position

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "autonum", to: :autonum
          map_attribute "displayorder", to: :displayorder
          map_attribute "path-end", to: :path_end
          map_attribute "name", to: :name
          map_element "autonumber", to: :auto_number
          map_element "description", to: :description
          map_element "newcontent", to: :new_content
        end
      end
    end
  end
end
