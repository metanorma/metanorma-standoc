# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # Term related to the current term.
      class RelatedTerm < Lutaml::Model::Serializable
        attribute :type, :string
        attribute :preferred, Metanorma::StandardDocument::Terms::Designation
        attribute :xref, Metanorma::Document::Components::Inline::XrefElement
        attribute :eref, Metanorma::Document::Components::Inline::ErefElement
        attribute :termref, Metanorma::StandardDocument::Refs::ReferenceToTermbase

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "related"
          map_attribute "type", to: :type
          map_element "preferred", to: :preferred
          map_element "xref", to: :xref
          map_element "eref", to: :eref
          map_element "termref", to: :termref

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
