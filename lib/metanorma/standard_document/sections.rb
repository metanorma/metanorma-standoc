# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      autoload :Abstract, "#{__dir__}/sections/abstract"
      autoload :Acknowledgements, "#{__dir__}/sections/acknowledgements"
      autoload :AnnexSection, "#{__dir__}/sections/annex_section"
      autoload :BibliographySection, "#{__dir__}/sections/bibliography_section"
      autoload :Colophon, "#{__dir__}/sections/colophon"
      autoload :BoilerplateType, "#{__dir__}/sections/boilerplate_type"
      autoload :ClauseHierarchicalSection,
               "#{__dir__}/sections/clause_hierarchical_section"
      autoload :ClauseSection, "#{__dir__}/sections/clause_section"
      autoload :ContentSection, "#{__dir__}/sections/standard_content_section"
      autoload :DefinitionSection, "#{__dir__}/sections/definition_section"
      autoload :FloatingSectionTitle,
               "#{__dir__}/sections/floating_section_title"
      autoload :FloatingTitle, "#{__dir__}/sections/floating_title"
      autoload :Foreword, "#{__dir__}/sections/foreword"
      autoload :Introduction, "#{__dir__}/sections/introduction"
      autoload :MiscContainer, "#{__dir__}/sections/misc_container"
      autoload :NormativeType, "#{__dir__}/sections/normative_type"
      autoload :Preface, "#{__dir__}/sections/preface"
      autoload :Sections, "#{__dir__}/sections/sections"
      autoload :StandardHierarchicalSection,
               "#{__dir__}/sections/standard_hierarchical_section"
      autoload :StandardReferencesSection,
               "#{__dir__}/sections/standard_references_section"
      autoload :StandardSection, "#{__dir__}/sections/standard_section"
      autoload :TermsSection, "#{__dir__}/sections/terms_section"
    end
  end
end
