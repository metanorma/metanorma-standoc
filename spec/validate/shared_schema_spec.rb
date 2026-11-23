require "spec_helper"
require_relative "../../lib/metanorma/validate/universal_schema"

RSpec.describe "the shipped shared grammar" do
  shared = Metanorma::Standoc::Validate::UniversalSchema
  schema_directory = File.expand_path("../../lib/metanorma/validate/schemas", __dir__)
  fixture_directory = File.expand_path("fixtures/shared", __dir__)
  manifest = JSON.parse(File.read(File.join(schema_directory, "shared-profiles.json")))

  before(:context) do
    @validator = shared::Validator.new(xml: File.read(File.join(schema_directory, "shared.rng")), manifest: manifest)
  end

  def document(id)
    File.read(File.join(__dir__, "fixtures/shared", "#{id}.xml"))
  end

  manifest.fetch("profiles").each do |profile|
    it "validates the #{profile.fetch('id')} source fixture and rejects selection of every other flavor" do
      id = profile.fetch("id")
      xml = File.read(File.join(fixture_directory, "#{id}.xml"))
      expect(@validator.validate(xml, flavor: id, representation: "semantic")).to be_empty
      (manifest.fetch("profiles").map { |entry| entry.fetch("id") } - [id]).each do |other|
        expect(@validator.validate(xml, flavor: other, representation: "semantic")).not_to be_empty
      end
      malformed = xml.sub("</p>", "<not-a-standard-element/></p>")
      expect(@validator.validate(malformed, flavor: id, representation: "semantic")).not_to be_empty
    end
  end

  it "accepts actual Asciidoctor Standoc semantic output" do
    expect(@validator.validate(document("standoc-native"), flavor: "standoc")).to be_empty
  end

  it "retains different flavor body requirements after changing the root flavor" do
    doc = Nokogiri::XML(document("standoc"))
    doc.xpath("//*[local-name()='clause']").last.remove
    expect(@validator.validate(doc, flavor: "standoc")).to be_empty
    doc.root["flavor"] = "iec"
    expect(@validator.validate(doc, flavor: "iec")).not_to be_empty
  end

  it "supports embedded MathML and actual SVG namespaces with preserved source constraints" do
    %w(math svg).each do |feature|
      expect(@validator.validate(document("iec-#{feature}"), flavor: "iec")).to be_empty
    end
    invalid_math = document("iec-math").sub("<mi>x</mi>", "<unknown-math-element/>")
    expect(@validator.validate(invalid_math, flavor: "iec")).not_to be_empty
  end

  it "allows only the declared presentation payload shape, once, on declared parents" do
    xml = document("iec").sub('type="semantic"', 'type="presentation"')
    payload = '<fmt-ladl-label-data local="1" global="1" value="1" direction="forward" global-direction="forward" labeller="section"/>'
    valid = xml.sub("Text", "Text#{payload}")
    expect(@validator.validate(valid, flavor: "iec", representation: "presentation")).to be_empty
    expect(@validator.validate(valid, flavor: "iec", representation: "semantic")).not_to be_empty
    expect(@validator.validate(valid.sub('type="presentation"', 'type="semantic"'), flavor: "iec")).not_to be_empty
    expect(@validator.validate(xml.sub("Text", "#{payload}#{payload}"), flavor: "iec")).not_to be_empty
    expect(@validator.validate(valid.sub('local="1"', 'extra="1"'), flavor: "iec")).not_to be_empty
    expect(@validator.validate(xml.sub("<sections>", "<sections>#{payload}"), flavor: "iec")).not_to be_empty
  end

  it "uses explicit representation configuration for VSD without adding an authored type" do
    xml = document("vsd").sub("Text", 'Text<fmt-ladl-label-data value="1"/>')
    expect(@validator.validate(xml, flavor: "vsd", representation: "presentation")).to be_empty
    expect(@validator.validate(xml, flavor: "vsd", representation: "semantic")).not_to be_empty
    expect(@validator.validate(xml, flavor: "vsd")).not_to be_empty
  end

  it "rejects private validation facts even inside otherwise open SVG extension content" do
    xml = document("iec-svg").sub('<s:title>Plot</s:title>', '<f:fact xmlns:f="urn:metanorma:iso:validation-projection:1">Fact</f:fact>')
    expect(@validator.validate(xml, flavor: "iec")).not_to be_empty
  end

  it "accepts a real native Document model admonition serialized into its UN document context" do
    paragraph = Metanorma::Document::Components::Paragraphs::ParagraphBlock.new(id: "mp1", text: ["Warning"])
    model = Metanorma::Document::Components::MultiParagraph::AdmonitionBlock.new(id: "ma1", type: "important", unnumbered: true, paragraphs: [paragraph])
    fragment = model.to_xml
    expect(fragment).to include('unnumbered="true"')
    xml = document("un").sub('<p id="p1">Text</p>', fragment)
    expect(@validator.validate(xml, flavor: "un")).to be_empty
  end

  it "preserves the repaired UN admonition type and boolean restrictions" do
    xml = document("un").sub('<p id="p1">Text</p>', '<admonition id="a1" type="important" unnumbered="true"><p id="ap1">Warning</p></admonition>')
    expect(@validator.validate(xml, flavor: "un")).to be_empty
    expect(@validator.validate(xml.sub('unnumbered="true"', 'unnumbered="perhaps"'), flavor: "un")).not_to be_empty
    expect(@validator.validate(xml.sub(' type="important"', ''), flavor: "un")).not_to be_empty
    expect(@validator.validate(xml.sub('type="important"', 'type="invented"'), flavor: "un")).not_to be_empty
  end
end

RSpec.describe "canonical ISO shared schema" do
  before(:context) do
    base = File.expand_path("../../lib/metanorma/validate/schemas", __dir__)
    @validator = Metanorma::Standoc::Validate::UniversalSchema::Validator.new(xml: File.read(File.join(base, "shared.rng")), manifest: File.read(File.join(base, "shared-profiles.json")))
  end

  def iso_xml
    File.read(File.join(__dir__, "fixtures/shared/iso.xml"))
  end

  it "accepts actual native ISO structure without manufacturing converter metadata" do
    expect(@validator.validate(iso_xml, flavor: "iso", representation: "semantic")).to be_empty
  end

  it "rejects actual incomplete native bibliography metadata" do
    incomplete = File.read(File.join(__dir__, "fixtures/shared/iso-incomplete.xml"))
    expect(@validator.validate(incomplete, flavor: "iso")).not_to be_empty
  end

  it "keeps old Standoc converter metadata requirements intact" do
    expect(@validator.validate(iso_xml.sub('flavor="iso"', 'flavor="standoc"'), flavor: "standoc")).not_to be_empty
  end

  it "keeps exact root identity and authored content constraints" do
    expect(@validator.validate(iso_xml.sub('flavor="iso"', 'flavor="iec"'), flavor: "iso")).not_to be_empty
    expect(@validator.validate(iso_xml.sub('<strong>', '<unknown>').sub('</strong>', '</unknown>'), flavor: "iso")).not_to be_empty
    expect(@validator.validate(iso_xml.sub('<metanorma ', '<iso-standard ').sub('</metanorma>', '</iso-standard>'), flavor: "iso")).not_to be_empty
  end

  it "accepts boolean visibility and current-language metadata with strict datatypes" do
    hidden = iso_xml.sub('id="scope"', 'id="scope" hidden="true"')
    expect(@validator.validate(hidden, flavor: "iso")).to be_empty
    expect(@validator.validate(hidden.sub('hidden="true"', 'hidden="false"'), flavor: "iso")).to be_empty
    expect(@validator.validate(hidden.sub('hidden="true"', 'hidden="perhaps"'), flavor: "iso")).not_to be_empty
    expect(@validator.validate(iso_xml.sub('current="true"', 'current="perhaps"'), flavor: "iso")).not_to be_empty
  end
  it "accepts actual native ISO presentation without changing the semantic branch" do
    xml = File.read(File.join(__dir__, "fixtures/shared/iso-presentation.xml"))
    expect(@validator.validate(xml, flavor: "iso", representation: "presentation")).to be_empty
    expect(@validator.validate(xml, flavor: "iso", representation: "semantic")).not_to be_empty
    expect(@validator.validate(xml.sub('type="presentation"', 'type="semantic"'), flavor: "iso")).not_to be_empty
    expect(@validator.validate(xml.sub('flavor="iso"', 'flavor="standoc"'), flavor: "standoc")).not_to be_empty
  end

  it "keeps native ISO presentation vocabulary closed and typed" do
    xml = File.read(File.join(__dir__, "fixtures/shared/iso-presentation.xml"))
    expect(@validator.validate(xml.sub('displayorder="1"', 'displayorder="first"'), flavor: "iso")).not_to be_empty
    expect(@validator.validate(xml.sub('<fmt-title>', '<fmt-title unexpected="true">'), flavor: "iso")).not_to be_empty
    expect(@validator.validate(xml.sub('<span>Scope</span>', '<unknown>Scope</unknown>'), flavor: "iso")).not_to be_empty
    expect(@validator.validate(xml.sub('</fmt-title>', '</fmt-title><fmt-title/>'), flavor: "iso")).not_to be_empty
    expect(@validator.validate(xml.sub('<fmt-xref target=', '<fmt-xref unknown="value" target='), flavor: "iso")).not_to be_empty
  end

end
