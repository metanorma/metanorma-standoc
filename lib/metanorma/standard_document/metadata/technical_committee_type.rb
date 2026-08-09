# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      # Technical committee associated with the production of a standards document.
      class TechnicalCommitteeType < Lutaml::Model::Serializable
        attribute :number, :integer
        attribute :type, :string
        attribute :text, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "technical-committee"
          map_attribute "number", to: :number
          map_attribute "type", to: :type
          map_attribute "text", to: :text

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
