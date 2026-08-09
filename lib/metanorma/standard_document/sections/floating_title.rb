# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      # A floating title, outside of the clause hierarchy
      class FloatingTitle < Metanorma::StandardDocument::Blocks::StandardBlockNoNotes
        attribute :depth, :integer

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :autonum, :string
        attribute :displayorder, :integer

        xml do
          element "floating-title"
          map_attribute "depth", to: :depth

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "autonum", to: :autonum
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
