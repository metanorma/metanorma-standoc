require "spec_helper"

RSpec.describe Metanorma::Standoc::Document::Sections::BibliographySection do
  it "preserves normative and informative references in their authored order" do
    xml = '<bibliography xmlns="https://www.metanorma.org/ns/standoc"><references id="norm" normative="true"/><references id="bib" normative="false"/></bibliography>'
    model = described_class.from_xml(xml)
    expect(model.element_order.map(&:name)).to eq(%w(references references))
    expect(model.references.map(&:id)).to eq(%w(norm bib))
    expect(described_class.from_xml(model.to_xml).references.map(&:id)).to eq(%w(norm bib))
  end

  it "retains interleaved clause and reference nodes through serialization" do
    xml = '<bibliography xmlns="https://www.metanorma.org/ns/standoc"><references id="r1"/><clause id="c1"/><references id="r2"/></bibliography>'
    model = described_class.from_xml(xml)
    expect(model.element_order.map(&:name)).to eq(%w(references clause references))
    output = Nokogiri::XML(model.to_xml).root.element_children
    expect(output.map(&:name)).to eq(%w(references clause references))
    expect(output.map { |node| node["id"] }).to eq(%w(r1 c1 r2))
  end
end
