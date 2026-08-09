# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      # Wrapper for the <bibliography> element that contains
      # one or more <references> sections (normative and/or informative).
      class BibliographySection < Lutaml::Model::Serializable
        attribute :references, StandardReferencesSection, collection: true
        attribute :clause, ClauseSection, collection: true

        xml do
          element "bibliography"
          map_element "references", to: :references
          map_element "clause", to: :clause
        end
      end
    end
  end
end
