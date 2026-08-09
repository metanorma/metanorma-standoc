# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # The type of the managed term in the present context.
      class TermSourceType < Lutaml::Model::Serializable
        attribute :value, :string

        def self.values
          %w[authoritative lineage]
        end

        xml do
          element "term-source-type"
          map_content to: :value
        end
      end
    end
  end
end
