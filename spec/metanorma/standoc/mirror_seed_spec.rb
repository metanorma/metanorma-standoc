# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Standoc::MirrorSeed do
  describe "section handlers" do
    it "registers every SECTION_HANDLERS entry" do
      registry = Metanorma::Mirror.build_default_registry
      described_class::SECTION_HANDLERS.each_key do |klass|
        expect(registry).to be_registered(klass), klass.name
      end
    end
  end

  describe "structural handlers" do
    it "registers every STRUCTURAL_HANDLERS entry" do
      registry = Metanorma::Mirror.build_default_registry
      described_class::STRUCTURAL_HANDLERS.each_key do |klass|
        expect(registry).to be_registered(klass), klass.name
      end
    end
  end

  it "registers the standoc positional id categories" do
    sections = Metanorma::Standoc::Document::Sections
    categories = Metanorma::Mirror::IdStrategy::Positional.categories
    expect(categories[sections::ClauseSection]).to be(:section)
  end

  it "maps annex sections to the annex category" do
    sections = Metanorma::Standoc::Document::Sections
    categories = Metanorma::Mirror::IdStrategy::Positional.categories
    expect(categories[sections::AnnexSection]).to be(:annex)
  end

  it "keeps the section table non-empty" do
    expect(described_class::SECTION_HANDLERS).not_to be_empty
  end

  it "keeps the structural table non-empty" do
    expect(described_class::STRUCTURAL_HANDLERS).not_to be_empty
  end
end
