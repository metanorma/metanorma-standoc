require "spec_helper"

OPTIONS_SECTIONED = [{ backend: :standoc, header_footer: true,
                       agree_to_terms: true,
                       attributes: { "sectioned-semantic" => "" } }].freeze

SECTIONED_INPUT = <<~INPUT.freeze
  = Document title
  Author
  :docfile: test.adoc
  :novalid:
  :no-pdf:

  == Scope

  This standard covers *bold*, _italic_, footnote:[a note] and <<term1>>.

  [NOTE]
  --
  An admonition note
  --

  [[term1]]
  == Terms and Definitions

  === term1

  stem:[x = y^2] is a formula.

  [source,ruby]
  ----
  def f; end
  ----

  * one
  * two

  .Table caption
  |===
  |A |B
  |1 |2
  |===

  [appendix]
  == Annex

  Appendix text (((indexed term))).

  [bibliography]
  == Bibliography

  * [[[ref1]]] _Some reference_
INPUT

RSpec.describe Metanorma::Standoc do
  subject(:sectioned) do
    Asciidoctor.convert(SECTIONED_INPUT, *OPTIONS_SECTIONED)
  end

  let(:classic) { Asciidoctor.convert(SECTIONED_INPUT, *OPTIONS) }
  let(:converter) { Metanorma::Standoc::Converter.new(nil, nil) }

  before { FileUtils.rm_f "test.doc" }

  it "engages the sectioned path when the attribute is set" do
    doc = Asciidoctor.load(SECTIONED_INPUT, *OPTIONS_SECTIONED)
    expect(converter.sectioned_semantic?(doc)).to be true
  end

  it "keeps the classic path without the attribute" do
    doc = Asciidoctor.load(SECTIONED_INPUT, *OPTIONS)
    expect(converter.sectioned_semantic?(doc)).to be false
  end

  it "produces the same document as the classic pipeline" do
    expect(strip_guid(sectioned)).to be_xml_equivalent_to(strip_guid(classic))
  end

  it "keeps the same top-level sections" do
    sectioned_names = Nokogiri::XML(sectioned).xpath("//sections/*").map(&:name)
    classic_names = Nokogiri::XML(classic).xpath("//sections/*").map(&:name)
    expect(sectioned_names).to eq classic_names
  end

  it "keeps the same <sections> text content" do
    sectioned_text = Nokogiri::XML(sectioned).xpath("//sections").text
    classic_text = Nokogiri::XML(classic).xpath("//sections").text
    expect(sectioned_text).to eq classic_text
  end
end
