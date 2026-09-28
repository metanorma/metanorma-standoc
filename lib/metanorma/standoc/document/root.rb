# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    class Root < Metanorma::Document::Root
      include Metanorma::Standoc::Document::RootAttributes

      attribute :bibdata,
                Metanorma::Document::Components::BibData::BibliographicItem
      attribute :preface,
                Metanorma::Standoc::Document::Sections::Preface
      attribute :sections,
                Metanorma::Standoc::Document::Sections::Sections
      attribute :annex,
                Metanorma::Standoc::Document::Sections::AnnexSection,
                collection: true

      # The concrete root mapping for standoc-flavor documents. Flavor
      # roots re-declare their own xml blocks; this one makes bare
      # standoc documents parseable instead of type-only.
      xml do
        element "metanorma"
        namespace Metanorma::Standoc::Document::Namespace
        Metanorma::Standoc::Document::RootXmlMapping.apply(self)
      end
    end
  end
end
