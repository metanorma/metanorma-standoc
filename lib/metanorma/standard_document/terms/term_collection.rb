# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # A collection of terms, constituting the main body of a Terms Section.
      class TermCollection < Lutaml::Model::Serializable
        attribute :term, Metanorma::StandardDocument::Terms::Term,
                  collection: true

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "terms"
          map_element "term", to: :term

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
