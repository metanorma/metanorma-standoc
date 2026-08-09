# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      # A group associated with the production of the standards document, typically within
      # a standards definition organization.
      class EditorialGroupType < Lutaml::Model::Serializable
        attribute :technicalcommittee,
                  Metanorma::StandardDocument::Metadata::TechnicalCommitteeType, collection: true

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "editorialgroup"
          map_element "technical-committee", to: :technicalcommittee

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
