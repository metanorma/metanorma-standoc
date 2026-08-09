# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # The grammatical gender of the designation.
      class GrammarGender < Lutaml::Model::Serializable
        attribute :value, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        def self.values
          %w[masculine feminine neuter common]
        end

        xml do
          element "grammar-gender"
          map_content to: :value

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
