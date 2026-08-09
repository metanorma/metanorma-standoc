# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Lists
      autoload :StandardDefinition, "#{__dir__}/lists/standard_definition"
      autoload :StandardDefinitionList,
               "#{__dir__}/lists/standard_definition_list"
      autoload :StandardDefinitionTerm,
               "#{__dir__}/lists/standard_definition_term"
      autoload :StandardUnorderedList,
               "#{__dir__}/lists/standard_unordered_list"
      autoload :UnorderedCheckableListItem,
               "#{__dir__}/lists/unordered_checkable_list_item"
    end
  end
end
