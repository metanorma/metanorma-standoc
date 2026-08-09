require "metanorma/document"

module Metanorma
  module Standoc
  end
end

require "metanorma/standoc/document"
require_relative "./converter/processor"

module Metanorma
  # Backwards-compat alias so external consumers that reference
  # Metanorma::StandardDocument keep resolving during the transition.
  StandardDocument = Metanorma::Standoc::Document
end
