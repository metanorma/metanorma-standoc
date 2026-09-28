# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Blocks
      # Table of contents, represented as a list of crossreferences, each with textual content.
      class ToC < Metanorma::Standoc::Document::Blocks::StandardBlockNoNotes
        attribute :list, Metanorma::Standoc::Document::Lists::StandardUnorderedList

        xml do
          element "toc"
          map_element "list", to: :list
          # Authored TOCs wrap the entries in a bare <ul>
          map_element "ul", to: :list
        end
      end
    end
  end
end
