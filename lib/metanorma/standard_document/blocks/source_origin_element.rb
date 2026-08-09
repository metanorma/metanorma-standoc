# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      class SourceOriginElement < Lutaml::Model::Serializable
        attribute :bibitemid, :string
        attribute :type, :string
        attribute :citeas, :string
        attribute :locality_stack, Metanorma::Document::Relaton::LocalityStack,
                  collection: true

        xml do
          element "origin"
          map_attribute "bibitemid", to: :bibitemid
          map_attribute "type", to: :type
          map_attribute "citeas", to: :citeas
          map_element "localityStack", to: :locality_stack
        end
      end
    end
  end
end
