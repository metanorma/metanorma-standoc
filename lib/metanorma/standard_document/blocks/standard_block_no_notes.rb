# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      class StandardBlockNoNotes < Metanorma::Document::Components::Blocks::BasicBlockNoNotes
        attribute :keep_with_next, :boolean
        attribute :keep_lines_together, :boolean
        attribute :tag, :string
        attribute :multilingual_rendering, :string
        attribute :columns, :string

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :autonum, :string
        attribute :displayorder, :integer

        xml do
          element "standard-block-no-notes"
          map_attribute "keep-with-next", to: :keep_with_next
          map_attribute "keep-lines-together", to: :keep_lines_together
          map_attribute "tag", to: :tag
          map_attribute "multilingual-rendering", to: :multilingual_rendering
          map_attribute "columns", to: :columns

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "autonum", to: :autonum
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
