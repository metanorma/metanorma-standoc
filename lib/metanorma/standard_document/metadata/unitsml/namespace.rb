# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Metadata
      module Unitsml
        # UnitsML vocabulary namespace. Fixtures use the default-namespace
        # form (<UnitsML xmlns="..."> with unprefixed children), so no
        # prefix_default is declared.
        class Namespace < Lutaml::Xml::Namespace
          uri "https://schema.unitsml.org/unitsml/1.0"
          element_form_default :qualified
        end
      end
    end
  end
end
