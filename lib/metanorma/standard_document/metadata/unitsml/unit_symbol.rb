# frozen_string_literal: true

require "mml"
require "mml/v3"

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        # Unit symbol. type="HTML" symbols can carry inline markup
        # (e.g. "nmol mol <sup>−1</sup>"), type="MathMl" symbols carry a
        # MathML <math> child, so this is a mixed-content model.
        class UnitSymbol < Lutaml::Model::Serializable
          attribute :type, :string
          attribute :text, :string, collection: true
          attribute :sup, Metanorma::Document::Components::Inline::SupElement,
                    collection: true
          attribute :sub, Metanorma::Document::Components::Inline::SubElement,
                    collection: true
          attribute :math, "Mml::V3::Math", collection: true

          xml do
            element "UnitSymbol"
            namespace Unitsml::Namespace
            mixed_content
            map_attribute "type", to: :type
            map_content to: :text
            map_element "sup", to: :sup
            map_element "sub", to: :sub
            map_element "math", to: :math
          end
        end
      end
    end
  end
end
