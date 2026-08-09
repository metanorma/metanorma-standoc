# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Refs
      # Connective linking the current cross-reference target to its predecessor.
      class XrefConnectiveType < Lutaml::Model::Serializable
        attribute :value, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        def self.values
          %w[and or from to]
        end

        xml do
          element "xref-connective-type"
          map_content to: :value

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
