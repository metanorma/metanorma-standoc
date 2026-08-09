# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      class BlockSourceElement < Lutaml::Model::Serializable
        attribute :status, :string
        attribute :type, :string
        attribute :origin, SourceOriginElement
        attribute :modification, Metanorma::Document::Components::Paragraphs::ParagraphBlock

        xml do
          element "source"
          map_attribute "status", to: :status
          map_attribute "type", to: :type
          map_element "origin", to: :origin
          map_element "modification", to: :modification
        end
      end
    end
  end
end
