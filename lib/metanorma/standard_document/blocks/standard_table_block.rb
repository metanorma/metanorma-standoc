# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      class StandardTableBlock < Metanorma::Document::Components::Tables::TableBlock
        attribute :width, :string
        attribute :plain, :string
        attribute :style, :string
        attribute :number, :string
        attribute :colgroup, Metanorma::StandardDocument::Blocks::TableCol,
                  collection: true

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :autonum, :string
        attribute :fmt_name, :string
        attribute :fmt_xref_label, :string
        attribute :displayorder, :integer

        xml do
          element "standard-table-block"
          map_attribute "width", to: :width
          map_attribute "plain", to: :plain
          map_attribute "style", to: :style
          map_attribute "number", to: :number
          map_element "colgroup", to: :colgroup

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
