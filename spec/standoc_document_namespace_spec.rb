# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Metanorma::Standoc::Document namespace" do
  describe "canonical namespace" do
    it "exposes Metanorma::Standoc::Document as a Module" do
      expect(Metanorma::Standoc::Document).to be_a(Module)
    end

    it "exposes Root with the canonical name" do
      expect(Metanorma::Standoc::Document::Root.name)
        .to eq("Metanorma::Standoc::Document::Root")
    end

    it "Root extends Metanorma::Document::Root" do
      expect(Metanorma::Standoc::Document::Root.superclass)
        .to eq(Metanorma::Document::Root)
    end
  end

  describe "submodules are reachable under the new namespace" do
    [
      %w[Blocks],
      %w[Sections],
      %w[Sections Preface],
      %w[Sections ClauseSection],
      %w[Sections StandardReferencesSection],
      %w[Terms Term],
      %w[Metadata StandardBibData],
      %w[Lists StandardDefinitionList],
      %w[Elements],
      %w[Refs],
    ].each do |path|
      it "Metanorma::Standoc::Document::#{path.join("::")}" do
        constant = path.reduce(Metanorma::Standoc::Document) do |ns, name|
          ns.const_get(name)
        end
        expect(constant).to be_a(Module)
        expect(constant.name)
          .to start_with("Metanorma::Standoc::Document")
      end
    end
  end

  describe "backwards-compat alias" do
    it "Metanorma::StandardDocument aliases to the new namespace" do
      expect(Metanorma::StandardDocument).to eq(Metanorma::Standoc::Document)
    end

    it "Metanorma::StandardDocument::Root resolves via the alias" do
      expect(Metanorma::StandardDocument::Root)
        .to eq(Metanorma::Standoc::Document::Root)
    end

    it "the alias preserves class identity (not a duplicate)" do
      expect(Metanorma::StandardDocument::Root.equal?(
               Metanorma::Standoc::Document::Root)).to be(true)
    end
  end

  describe "XML round-trip via the new namespace" do
    it "parses a <foreword> element" do
      xml = "<foreword><p>hello</p></foreword>"
      fw = Metanorma::Standoc::Document::Sections::Foreword.from_xml(xml)
      expect(fw).to be_a(Metanorma::Standoc::Document::Sections::Foreword)
    end

    it "parses a <p> paragraph element" do
      xml = "<p>text</p>"
      p = Metanorma::Document::Components::Paragraphs::ParagraphBlock.from_xml(xml)
      expect(p).to be_a(Metanorma::Document::Components::Paragraphs::ParagraphBlock)
    end
  end
end
