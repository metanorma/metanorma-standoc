# frozen_string_literal: true

module Metanorma
  module StandardDocument
    class AnnotationContainer < Lutaml::Model::Serializable
      class Annotation < Lutaml::Model::Serializable
        attribute :id, :string
        attribute :reviewer, :string
        attribute :from, :string
        attribute :to, :string
        attribute :type, :string
        attribute :date, :string
        attribute :semx_id, :string
        attribute :paragraphs,
                  Metanorma::Document::Components::Paragraphs::ParagraphBlock,
                  collection: true

        xml do
          element "annotation"
          map_attribute "id", to: :id
          map_attribute "reviewer", to: :reviewer
          map_attribute "from", to: :from
          map_attribute "to", to: :to
          map_attribute "type", to: :type
          map_attribute "date", to: :date
          map_attribute "semx-id", to: :semx_id
          map_element "p", to: :paragraphs
        end
      end

      attribute :annotations, Annotation, collection: true

      xml do
        element "annotation-container"
        map_element "annotation", to: :annotations
      end
    end
  end
end
