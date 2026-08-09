# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Lists
      # Ordered list for standards documents.
      class StandardUnorderedList < Metanorma::Document::Components::Lists::UnorderedList
        attribute :display, :string
        attribute :display_directives, :string

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :autonum, :string
        attribute :displayorder, :integer

        xml do
          element "standard-unordered-list"
          map_attribute "display", to: :display
          map_attribute "display-directives", to: :display_directives
          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "autonum", to: :autonum
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
