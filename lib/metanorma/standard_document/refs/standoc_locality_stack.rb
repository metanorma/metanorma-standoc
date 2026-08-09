# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Refs
      # Description of location in a reference, which can be combined with other locations in a single
      # citation.
      class StandocLocalityStack < Metanorma::Document::Relaton::LocalityStack
        attribute :connective, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "standoc-locality-stack"
          map_attribute "connective", to: :connective

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
