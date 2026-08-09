# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      # Abstract of the document.
      class Abstract < Metanorma::StandardDocument::Sections::ContentSection
        attribute :original_id, :string
        xml do
          element "abstract"

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
