# frozen_string_literal: true

module Metanorma
  module Standoc
    # Registers the standoc section model's knowledge into the
    # metanorma-mirror gem: section and structural handlers plus the
    # standoc part of the positional id categories
    # (metanorma-document seeds the Components knowledge).
    class MirrorSeed
      POSITIONAL_CATEGORIES = {
        Document::Sections::ClauseSection => :section,
        Document::Sections::ContentSection => :section,
        Document::Sections::TermsSection => :section,
        Document::Sections::DefinitionSection => :section,
        Document::Sections::AnnexSection => :annex,
      }.freeze

      SECTION_HANDLERS = {
        Document::Sections::ClauseSection => :clause,
        Document::Sections::AnnexSection => :annex,
        Document::Sections::ContentSection => :content_section,
        Document::Sections::TermsSection => :terms,
        Document::Sections::DefinitionSection => :definitions,
        Document::Sections::StandardReferencesSection => :references,
        Document::Sections::FloatingTitle => :floating_title,
      }.freeze

      STRUCTURAL_HANDLERS = {
        Document::Sections::Preface => :preface,
        # IsoPreface and UnPreface deliberately do not inherit
        # StandardDocument::Preface (grammar-strict classes compose from
        # mixins), so they need explicit registrations — the registry
        # resolves handlers through class ancestry.
        Document::Sections::Sections => :sections,
        Document::Sections::BibliographySection => :bibliography,
      }.freeze

      class << self
        def register
          register_handlers
          register_positional_categories
        end

        private

        def register_handlers
          Mirror.register_default do |registry|
            sections(registry)
            structural(registry)
          end
        end

        def sections(registry)
          SECTION_HANDLERS.each do |klass, name|
            registry.register(klass, Mirror::Handlers::Section,
                              method_name: name)
          end
        end

        def structural(registry)
          STRUCTURAL_HANDLERS.each do |klass, name|
            registry.register(klass, Mirror::Handlers::Structural,
                              method_name: name)
          end
        end

        def register_positional_categories
          POSITIONAL_CATEGORIES.each do |klass, category|
            Mirror::IdStrategy::Positional.register_category(klass, category)
          end
        end
      end
    end
  end
end
