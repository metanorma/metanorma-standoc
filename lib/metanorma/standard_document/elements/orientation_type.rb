# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Elements
      # Orientation of pages in a section of text in paged media.
      class OrientationType < Lutaml::Model::Serializable
        attribute :value, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "orientation-type"
          map_content to: :value

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end

        def self.values
          %w[portrait landscape]
        end
      end
    end
  end
end
