# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      # A floating section title used in BSI and JIS documents.
      # Differs from FloatingTitle: uses element name "section-title",
      # has id (not derived from StandardBlockNoNotes), and contains TextElement.
      class FloatingSectionTitle < Lutaml::Model::Serializable
        attribute :id, :string
        attribute :depth, :integer
        attribute :text, :string, collection: true

        xml do
          element "section-title"
          map_attribute "id", to: :id
          map_attribute "depth", to: :depth
          map_content to: :text
        end
      end
    end
  end
end
