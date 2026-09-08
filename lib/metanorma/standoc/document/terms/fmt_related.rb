# frozen_string_literal: true

module Metanorma
  module Standoc
    module Document
      module Terms
        # Presentation-layer rendering of a related-term cross
        # reference: the formatted "CONTRAST:/SEE:" notice wrapping the
        # rendered designation.
        class FmtRelated < Lutaml::Model::Serializable
          include Metanorma::Document::Components::Inline::RenderedDisplay

          attribute :text, :string, collection: true
          attribute :semx,
                    Metanorma::Document::Components::Inline::SemxElement,
                    collection: true

          xml do
            element "fmt-related"
            mixed_content
            map_content to: :text
            map_element "semx", to: :semx
          end
        end
      end
    end
  end
end
