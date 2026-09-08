# frozen_string_literal: true

require_relative "../spec_helper"
require "metanorma/document/grammar_vocabulary"

# standoc#1249: the delegated share of the grammar vocabulary. The
# element enumeration lives in metanorma-document's
# GrammarVocabulary (the SSOT this gem depends on); this gate asserts
# every element delegated to the standoc tree is actually mapped
# here. The delegation stops being an honor system — each repo gates
# its share.
RSpec.describe "delegated grammar coverage" do
  it "maps every element delegated to the standoc tree" do
    delegated = Metanorma::Document::GrammarVocabulary::DELEGATED[:standoc]
    mapped = Dir[File.expand_path("../../lib/**/*.rb", __dir__)].flat_map do |f|
      File.read(f, encoding: "utf-8")
          .scan(/(?:map_element|element)\s+"([a-zA-Z0-9_.:-]+)"/)
          .flatten
    end.uniq

    missing = delegated - mapped
    expect(missing).to be_empty,
                       "delegated elements not mapped in this tree: " \
                       "#{missing.join(', ')}"
  end
end
