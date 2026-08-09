# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Elements
      # Kept as the StandardDocument-layer alias of the document-layer
      # Input model (see lib/metanorma/document/elements/input.rb) so
      # existing StandardDocument references keep working.
      Input = Metanorma::Document::Elements::Input
    end
  end
end
