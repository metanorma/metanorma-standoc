# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Terms
      autoload :AbbreviationType, "#{__dir__}/terms/abbreviation_type"
      autoload :Concept, "#{__dir__}/terms/concept"
      autoload :DefinitionCollection, "#{__dir__}/terms/definition_collection"
      autoload :Designation, "#{__dir__}/terms/designation"
      autoload :ExpressionDesignation, "#{__dir__}/terms/expression_designation"
      autoload :ExpressionType, "#{__dir__}/terms/expression_type"
      autoload :GrammarGender, "#{__dir__}/terms/grammar_gender"
      autoload :GrammarInfo, "#{__dir__}/terms/grammar_info"
      autoload :GraphicalSymbolDesignation,
               "#{__dir__}/terms/graphical_symbol_designation"
      autoload :LetterSymbolDesignation,
               "#{__dir__}/terms/letter_symbol_designation"
      autoload :NonVerbalRepresentation,
               "#{__dir__}/terms/non_verbal_representation"
      autoload :RelatedTerm, "#{__dir__}/terms/related_term"
      autoload :RelatedTermType, "#{__dir__}/terms/related_term_type"
      autoload :Term, "#{__dir__}/terms/term"
      autoload :TermCollection, "#{__dir__}/terms/term_collection"
      autoload :TermDefinition, "#{__dir__}/terms/term_definition"
      autoload :TermExpression, "#{__dir__}/terms/term_expression"
      autoload :TermNameElement, "#{__dir__}/terms/term_name_element"
      autoload :TermSource, "#{__dir__}/terms/term_source"
      autoload :TermSourceStatus, "#{__dir__}/terms/term_source_status"
      autoload :TermSourceType, "#{__dir__}/terms/term_source_type"
      autoload :VerbalExpression, "#{__dir__}/terms/verbal_expression"
    end
  end
end
