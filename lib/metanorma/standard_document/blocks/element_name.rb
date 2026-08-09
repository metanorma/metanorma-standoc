# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      # The classes of block subject to autonumbering within an `AmendBlock` `newContent` element.
      class ElementName < Lutaml::Model::Serializable
        attribute :value, :string

        xml do
          element "element-name"
          map_content to: :value
        end

        def self.values
          %w[requirement recommendation permission table figure admonition formula
             sourcecode example note]
        end
      end
    end
  end
end
