# frozen_string_literal: true

module Metanorma
  module Standoc
    module Document
      module Terms
        # Presentation-layer rendering of a term definition: the
        # formatted definition block emitted alongside the semantic
        # `definition` verbal expression. Carries the block children
        # (`p`, `termnote`, `dl`, `ol`, `ul`) so no front-matter term
        # content is lost.
        class FmtDefinition < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :p, Metanorma::Document::Components::Paragraphs::ParagraphBlock,
                    collection: true
          attribute :termnote, Metanorma::Standoc::Document::Terms::TermNote,
                    collection: true
          attribute :dl, Metanorma::Document::Components::Lists::DefinitionList
          attribute :ol, Metanorma::Document::Components::Lists::OrderedList,
                    collection: true
          attribute :ul, Metanorma::Document::Components::Lists::UnorderedList,
                    collection: true

          xml do
            element "fmt-definition"
            map_attribute "id", to: :id
            map_element "p", to: :p
            map_element "termnote", to: :termnote
            map_element "dl", to: :dl
            map_element "ol", to: :ol
            map_element "ul", to: :ul
          end
        end
      end
    end
  end
end
