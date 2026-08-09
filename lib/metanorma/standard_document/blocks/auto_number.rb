# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      # Specification of how blocks of a given class should be autonumbered
      # within an AmendBlock newContent element.
      class AutoNumber < Lutaml::Model::Serializable
        attribute :type, :string
        attribute :value, :string

        xml do
          element "autonumber"
          map_attribute "type", to: :type
          map_content to: :value
        end
      end
    end
  end
end
