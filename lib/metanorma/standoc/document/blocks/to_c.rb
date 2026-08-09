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
        end
      end
    end
  end
end
