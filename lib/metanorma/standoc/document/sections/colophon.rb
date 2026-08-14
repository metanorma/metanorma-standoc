# frozen_string_literal: true

module Metanorma
  module Standoc::Document
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
