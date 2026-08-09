# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      # A designation realised as a graphical symbol
      class GraphicalSymbolDesignation < Lutaml::Model::Serializable
        attribute :figure, Metanorma::Document::Components::AncillaryBlocks::FigureBlock
        attribute :is_international, :boolean

        attribute :semx_id, :string
        attribute :original_id, :string

        xml do
          element "graphical-symbol"
          map_element "figure", to: :figure
          map_attribute "isInternational", to: :is_international

          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
        end
      end
    end
  end
end
