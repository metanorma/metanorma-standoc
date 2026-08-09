# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Sections
      # Container for preface sections.
      # Corresponds to isodoc.rnc:
      #   preface = element preface {
      #     ( content | abstract | foreword | introduction |
      #       acknowledgements | executivesummary )+
      #   }
      class Preface < Lutaml::Model::Serializable
        attribute :abstract, ContentSection
        attribute :foreword, ContentSection
        attribute :introduction, ContentSection
        attribute :acknowledgements, ContentSection
        attribute :executivesummary, ContentSection
        attribute :content, ContentSection, collection: true

        # Presentation-specific attributes
        attribute :semx_id, :string
        attribute :displayorder, :integer

        xml do
          element "preface"
          ordered

          Metanorma::StandardDocument::SectionXmlMapping.apply_preface_elements(self)
          map_element "clause", to: :content

          Metanorma::StandardDocument::SectionXmlMapping.apply_preface_attributes(self)
        end
      end
    end
  end
end
