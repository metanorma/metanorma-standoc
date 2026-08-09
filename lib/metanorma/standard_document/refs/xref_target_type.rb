# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Refs
      # Listing of multiple cross-reference targets to be combined under the one element
      class XrefTargetType < Lutaml::Model::Serializable
        attribute :target, Metanorma::Document::Components::IdElements::IdElement
        attribute :connective, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "xref-target-type"
          map_element "target", to: :target
          map_attribute "connective", to: :connective

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
