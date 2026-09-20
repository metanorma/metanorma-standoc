# frozen_string_literal: true

require_relative "../../spec_helper"

# standoc#1249 second half: the term-grammar family mapped to the
# grammar shape (Grammar = element grammar with child elements).
RSpec.describe "term grammar vocabulary" do
  describe Metanorma::Standoc::Document::Terms::GrammarInfo do
    it "parses the grammar shape: child elements, not attributes" do
      grammar = described_class.from_xml(
        "<grammar><gender>masculine</gender><number>singular</number>" \
        "<isNoun>true</isNoun><isPreposition>false</isPreposition>" \
        "<grammar-value>uncountable</grammar-value></grammar>",
      )

      expect(grammar.gender.first.value).to eq("masculine")
      expect(grammar.number.first.value).to eq("singular")
      expect(grammar.is_noun).to be(true)
      expect(grammar.is_preposition).to be(false)
      expect(grammar.is_verb).to be_nil
      expect(grammar.grammar_value).to eq(["uncountable"])
    end

    it "round-trips under the grammar root" do
      xml = "<grammar><gender>neuter</gender><isAdjective>true</isAdjective></grammar>"
      expect(described_class.from_xml(xml).to_xml)
        .to be_xml_equivalent_to(xml)
    end
  end

  describe Metanorma::Standoc::Document::Terms::Designation do
    it "parses the designation vocabulary: symbol forms and application fields" do
      designation = described_class.from_xml(
        "<designation><letter-symbol><name>X</name></letter-symbol>" \
        "<field-of-application>chemistry</field-of-application>" \
        "<usage-info>informal</usage-info></designation>",
      )

      expect(designation.letter_symbol).not_to be_nil
      expect(designation.field_of_application.value).to eq(["chemistry"])
      expect(designation.usage_info.value).to eq(["informal"])
    end

    it "parses grammar inside an expression designation" do
      designation = described_class.from_xml(
        "<designation><expression><name>Term</name>" \
        "<grammar><isNoun>true</isNoun></grammar></expression></designation>",
      )

      expect(designation.expression.grammar.is_noun).to be(true)
    end
  end

  describe Metanorma::Standoc::Document::Terms::FmtRelated do
    it "parses the rendered related-term notice" do
      fmt = described_class.from_xml(
        "<fmt-related><semx element=\"related\" source=\"_r1\">" \
        "<p>CONTRAST: other</p></semx></fmt-related>",
      )

      expect(fmt.semx.first.element_attr).to eq("related")
    end

    it "is marked as rendered display" do
      expect(described_class.ancestors)
        .to include(Metanorma::Document::Components::Inline::RenderedDisplay)
    end
  end
end
