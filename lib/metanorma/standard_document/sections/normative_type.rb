# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      # The force of a clause of text in a _StandardDocument_.
      class NormativeType < Lutaml::Model::Serializable
        attribute :value, :string

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :displayorder, :integer

        def self.values
          %w[normative informative]
        end

        xml do
          element "normative-type"
          map_content to: :value

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
