# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # The relation of a term to the current term.
      class RelatedTermType < Lutaml::Model::Serializable
        attribute :value, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        def self.values
          %w[deprecates supersedes narrower broader equivalent compare contrast
             see]
        end

        xml do
          element "related-term-type"
          map_content to: :value

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
