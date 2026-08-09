# frozen_string_literal: true

module Metanorma
  module StandardDocument
    class Boilerplate < Lutaml::Model::Serializable
      attribute :copyright_statement,
                Metanorma::StandardDocument::Sections::ContentSection,
                collection: true
      attribute :license_statement,
                Metanorma::StandardDocument::Sections::ContentSection,
                collection: true
      attribute :legal_statement,
                Metanorma::StandardDocument::Sections::ContentSection,
                collection: true
      attribute :feedback_statement,
                Metanorma::StandardDocument::Sections::ContentSection,
                collection: true
      attribute :clause,
                Metanorma::StandardDocument::Sections::ContentSection,
                collection: true

      xml do
        element "boilerplate"
        map_element "copyright-statement", to: :copyright_statement
        map_element "license-statement", to: :license_statement
        map_element "legal-statement", to: :legal_statement
        map_element "feedback-statement", to: :feedback_statement
        map_element "clause", to: :clause
      end
    end
  end
end
