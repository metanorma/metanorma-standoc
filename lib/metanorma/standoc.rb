require "metanorma/document"

module Metanorma
  module Standoc
  end
end

require "metanorma/standoc/document"
require_relative "./converter/processor"

# Backwards-compat alias so external consumers that reference
# Metanorma::StandardDocument keep resolving during the transition.
# Silently replaces any prior Metanorma::StandardDocument constant
# (e.g. an older metanorma-document release shipping its own copy) to
# avoid Ruby's "already initialized constant" warning.
# Scheduled for removal once downstream flavor gems (ietf, jis, oiml,
# itu, ieee, bsi, csa, iec) update their internal references.
module Metanorma
  if defined?(Metanorma::StandardDocument)
    Metanorma.send(:remove_const, :StandardDocument)
  end
  StandardDocument = Metanorma::Standoc::Document
  deprecate_constant :StandardDocument
end
