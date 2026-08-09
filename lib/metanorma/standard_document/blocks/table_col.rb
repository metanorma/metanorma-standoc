# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      class TableCol < Lutaml::Model::Serializable
        attribute :width, :string

        xml do
          element "table-col"
          map_attribute "width", to: :width
        end
      end
    end
  end
end
