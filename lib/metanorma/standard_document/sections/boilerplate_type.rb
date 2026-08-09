# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      # Content addressing legal and licensing concerns around the document,
      # outside of the main flow of document content.
      class BoilerplateType < Lutaml::Model::Serializable
        attribute :copyright, Metanorma::Document::Components::Sections::HierarchicalSection
        attribute :license, Metanorma::Document::Components::Sections::HierarchicalSection
        attribute :legal, Metanorma::Document::Components::Sections::HierarchicalSection
        attribute :feedback, Metanorma::Document::Components::Sections::HierarchicalSection

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :displayorder, :integer

        xml do
          element "boilerplate"
          map_element "copyright", to: :copyright
          map_element "license", to: :license
          map_element "legal", to: :legal
          map_element "feedback", to: :feedback

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
