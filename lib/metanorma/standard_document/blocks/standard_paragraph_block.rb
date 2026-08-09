# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      class StandardParagraphBlock < Metanorma::Document::Components::Paragraphs::ParagraphBlock
        attribute :type, :string

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :autonum, :string
        attribute :displayorder, :integer
        xml do
          element "standard-paragraph-block"
          map_attribute "type", to: :type

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "autonum", to: :autonum
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
