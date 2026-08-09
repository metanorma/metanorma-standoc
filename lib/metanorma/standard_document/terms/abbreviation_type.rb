# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # Type of abbreviation, according to how it is formed.
      class AbbreviationType < Lutaml::Model::Serializable
        attribute :value, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        def self.values
          %w[truncation acronym initialism]
        end

        xml do
          element "abbreviation-type"
          map_content to: :value

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
