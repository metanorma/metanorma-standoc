# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      class Colophon < Lutaml::Model::Serializable
        attribute :clause, ClauseSection, collection: true

        xml do
          element "colophon"
          map_element "clause", to: :clause
        end
      end
    end
  end
end
