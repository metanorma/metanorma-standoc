# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # The status of a term as it is used in this document, relative to its definition in the original
      # document.
      class TermSourceStatus < Lutaml::Model::Serializable
        attribute :value, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        def self.values
          %w[identical modified restyled context-added generalisation
             specialisation unspecified]
        end

        xml do
          element "term-source-status"
          map_content to: :value

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
