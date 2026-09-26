# frozen_string_literal: true

module Metanorma
  module Standoc
    module Document
      module Terms
        # The <semx> wrapper inside <fmt-definition>: presentation XML
        # wraps the definition block content in it, so the block's
        # children (p, termnote, dl, ol, ul) live one level down.
        class FmtDefinitionSemx < Lutaml::Model::Serializable
          attribute :element, :string
          attribute :source, :string
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
            element "semx"
            map_attribute "element", to: :element
            map_attribute "source", to: :source
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
