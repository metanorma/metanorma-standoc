# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      # Table of contents, represented as a list of crossreferences, each with textual content.
      class ToC < Metanorma::StandardDocument::Blocks::StandardBlockNoNotes
        attribute :list, Metanorma::StandardDocument::Lists::StandardUnorderedList

        xml do
          element "toc"
          map_element "list", to: :list
        end
      end
    end
  end
end
