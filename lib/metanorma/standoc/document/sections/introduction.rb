# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Sections
      # Introduction of document.
      class Introduction < Metanorma::Standoc::Document::Sections::ContentSection
        attribute :original_id, :string
        xml do
          element "introduction"

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "autonum", to: :autonum
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
