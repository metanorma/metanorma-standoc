# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # Formally defined concept used in a _StandardDocument_, aligned to a definition.
      # That concept may be defined as a term within the current document, or it may
      # be defined externally.
      class Concept < Lutaml::Model::Serializable
        attribute :ital, :boolean
        attribute :ref, :boolean
        attribute :linkmention, :boolean
        attribute :linkref, :boolean
        attribute :refterm, :string, collection: true
        attribute :renderterm, :string
        attribute :xref, Metanorma::Document::Components::ReferenceElements::ReferenceToIdElement
        attribute :eref, Metanorma::Document::Components::ReferenceElements::ReferenceToCitationElement
        attribute :termref, Metanorma::StandardDocument::Refs::ReferenceToTermbase

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "concept"
          mixed_content
          map_attribute "ital", to: :ital
          map_attribute "ref", to: :ref
          map_attribute "linkmention", to: :linkmention
          map_attribute "linkref", to: :linkref
          map_content to: :refterm
          map_element "renderterm", to: :renderterm
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
