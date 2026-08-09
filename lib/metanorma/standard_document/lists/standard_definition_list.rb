# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Lists
      class StandardDefinitionList < Metanorma::Document::Components::Lists::DefinitionList
        attribute :keep_lines_together, :boolean
        attribute :keep_with_next, :boolean
        attribute :key, :boolean

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :autonum, :string
        attribute :displayorder, :integer

        xml do
          element "standard-definition-list"
          map_attribute "keep-lines-together", to: :keep_lines_together
          map_attribute "keep-with-next", to: :keep_with_next
          map_attribute "key", to: :key

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "autonum", to: :autonum
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
