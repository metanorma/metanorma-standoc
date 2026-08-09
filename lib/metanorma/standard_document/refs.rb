# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Refs
      autoload :ReferenceToTerm, "#{__dir__}/refs/reference_to_term"
      autoload :ReferenceToTermbase, "#{__dir__}/refs/reference_to_termbase"
      autoload :StandocLocalityStack, "#{__dir__}/refs/standoc_locality_stack"
      autoload :StandocReferenceToCitationElement,
               "#{__dir__}/refs/standoc_reference_to_citation_element"
      autoload :StandocReferenceToIdElement,
               "#{__dir__}/refs/standoc_reference_to_id_element"
      autoload :XrefCaseType, "#{__dir__}/refs/xref_case_type"
      autoload :XrefConnectiveType, "#{__dir__}/refs/xref_connective_type"
      autoload :XrefTargetType, "#{__dir__}/refs/xref_target_type"
    end
  end
end
