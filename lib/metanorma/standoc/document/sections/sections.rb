# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    module Sections
      # Container for the main body sections of a document.
      # Corresponds to isodoc.rnc:
      #   sections = element sections {
      #     ( clause | terms | term-clause | definitions | floating-title )+
      #   }
      class Sections < Lutaml::Model::Serializable
        attribute :clause, ClauseSection, collection: true
        attribute :terms,
                  Metanorma::Standoc::Document::Sections::TermsSection,
                  collection: true
        attribute :definitions,
                  Metanorma::Standoc::Document::Sections::DefinitionSection,
                  collection: true
        attribute :floating_title,
                  Metanorma::Standoc::Document::Sections::FloatingTitle,
                  collection: true
        attribute :references,
                  Metanorma::Standoc::Document::Sections::StandardReferencesSection,
                  collection: true

        # Presentation-specific attributes
        attribute :semx_id, :string
        attribute :displayorder, :integer

        # Loose paragraphs directly under <sections> (e.g. the ITU
        # zzSTDTitle1 title paragraph at the start of sections).
        attribute :p,
                  Metanorma::Document::Components::Paragraphs::ParagraphBlock,
                  collection: true

        xml do
          element "sections"
          ordered

          Metanorma::Standoc::Document::SectionXmlMapping.apply_sections_elements(self)
          map_element "p", to: :p
          Metanorma::Standoc::Document::SectionXmlMapping.apply_sections_attributes(self)
        end
      end
    end
  end
end
