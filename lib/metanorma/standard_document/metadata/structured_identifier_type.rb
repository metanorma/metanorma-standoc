# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      # Representation of the identifier for a _StandardDocument_, giving its individual semantic
      # components.
      class StructuredIdentifierType < Lutaml::Model::Serializable
        attribute :type, :string
        attribute :agency, :string, collection: true
        attribute :class, :string
        attribute :docnumber, :string
        attribute :partnumber, :string
        attribute :edition, :string
        attribute :version, :string
        attribute :supplementtype, :string
        attribute :supplementnumber, :string
        attribute :year, :string
        attribute :language, :string
        attribute :part, :string
        attribute :appendix, :string

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "structuredidentifier"
          map_attribute "type", to: :type
          map_element "agency", to: :agency
          map_attribute "class", to: :class
          map_attribute "docnumber", to: :docnumber
          map_attribute "partnumber", to: :partnumber
          map_attribute "edition", to: :edition
          map_attribute "version", to: :version
          map_attribute "supplementtype", to: :supplementtype
          map_attribute "supplementnumber", to: :supplementnumber
          map_element "year", to: :year
          map_attribute "language", to: :language
          map_element "part", to: :part
          map_element "appendix", to: :appendix

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
