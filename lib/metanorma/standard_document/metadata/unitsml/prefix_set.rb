# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        class PrefixSet < Lutaml::Model::Serializable
          attribute :prefix, Prefix, collection: true

          xml do
            element "PrefixSet"
            namespace Unitsml::Namespace
            map_element "Prefix", to: :prefix
          end
        end
      end
    end
  end
end
