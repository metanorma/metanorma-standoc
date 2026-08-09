# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    # Type of standards document representation.
    class StandardDocumentType < Lutaml::Model::Serializable
      attribute :value, :string, values: %w[semantic presentation]

      xml do
        element "standard-document-type"
        map_content to: :value
      end
    end
  end
end
