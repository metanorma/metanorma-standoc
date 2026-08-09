# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      # The type of change described in AmendBlock.
      class ChangeType < Lutaml::Model::Serializable
        attribute :value, :string

        xml do
          element "change-type"
          map_content to: :value
        end

        def self.values
          %w[add modify delete]
        end
      end
    end
  end
end
