# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      # The bibliographic description of a _StandardDocument_.
      class StandardBibData < Metanorma::Document::Components::BibData::BibData
        attribute :type, :string
        attribute :ext, Metanorma::StandardDocument::Metadata::StandardBibDataExtensionType

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "bibdata"
          map_attribute "type", to: :type
          map_element "ext", to: :ext

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
