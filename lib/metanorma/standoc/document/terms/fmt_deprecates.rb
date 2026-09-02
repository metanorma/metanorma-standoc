# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # Presentation-layer rendering of a deprecated designation:
      # the formatted deprecation notice emitted alongside the semantic
      # `deprecates` designation.
      class FmtDeprecates < Lutaml::Model::Serializable
        attribute :p, Metanorma::Document::Components::Paragraphs::ParagraphBlock,
                  collection: true

        xml do
          element "fmt-deprecates"
          map_element "p", to: :p
        end
      end
    end
  end
end
