# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      class StandardQuoteBlock < Metanorma::Document::Components::MultiParagraph::QuoteBlock
        attribute :type, :string

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :autonum, :string
        attribute :fmt_name, :string
        attribute :fmt_xref_label, :string
        attribute :displayorder, :integer
        xml do
          element "standard-quote-block"
          map_attribute "type", to: :type

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "autonum", to: :autonum
          map_element "fmt-name", to: :fmt_name
          map_element "fmt-xref-label", to: :fmt_xref_label
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
