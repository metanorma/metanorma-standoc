require "spec_helper"
require_relative "../../lib/metanorma/validate/universal_schema"

RSpec.describe Metanorma::Standoc::Validate::UniversalSchema do
  let(:shared) { described_class }
  let(:namespace) { "urn:shared-test" }

  def source(special, flavor_pattern: "<text/>")
    <<~RNG
      <grammar xmlns="http://relaxng.org/ns/structure/1.0" ns="#{namespace}"
               datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes">
        <start><ref name="root"/></start>
        <define name="root"><element name="metanorma"><ref name="attributes"/><ref name="body"/></element></define>
        <define name="attributes">
          <attribute name="flavor">#{flavor_pattern}</attribute>
          <attribute name="type"><choice><value>semantic</value><value>presentation</value></choice></attribute>
          <attribute name="version"><data type="positiveInteger"/></attribute>
        </define>
        <define name="body"><element name="section"><zeroOrMore><choice>
          <element name="#{special}"><empty/></element>
          <element name="fmt-name"><text/></element>
          <element name="li"><text/></element>
          <element name="embedded"><ref name="root"/></element>
          <element name="extension"><zeroOrMore><ref name="foreign"/></zeroOrMore></element>
        </choice></zeroOrMore></element></define>
        <define name="foreign"><element><anyName/>
          <zeroOrMore><attribute><anyName/></attribute></zeroOrMore>
          <zeroOrMore><choice><text/><ref name="foreign"/></choice></zeroOrMore>
        </element></define>
      </grammar>
    RNG
  end

  let(:result) do
    profiles = [shared::Profile.new(id: "a", xml: source("a-only")),
                shared::Profile.new(id: "b", xml: source("b-only"))]
    shared::Producer.new(profiles: profiles, metadata_parents: %w(fmt-name li)).produce
  end
  let(:grammar) { Nokogiri::XML::RelaxNG(result.xml) }

  def xml(flavor, content, type: "semantic", version: "1")
    "<metanorma xmlns='#{namespace}' flavor='#{flavor}' type='#{type}' version='#{version}'><section>#{content}</section></metanorma>"
  end

  def valid?(input)
    grammar.validate(Nokogiri::XML(input)).empty?
  end

  it "accepts each source language only behind its exact flavor discriminator" do
    expect(valid?(xml("a", "<a-only/>"))).to be true
    expect(valid?(xml("b", "<b-only/>"))).to be true
    expect(valid?(xml("a", "<b-only/>"))).to be false
    expect(valid?(xml("b", "<a-only/>"))).to be false
    expect(valid?(xml("unknown", "<a-only/>"))).to be false
    expect(valid?(xml("a ", "<a-only/>"))).to be false
  end

  it "retains original datatype and unknown-structure rejection" do
    expect(valid?(xml("a", "<a-only/>", version: "zero"))).to be false
    expect(valid?(xml("a", "<unknown/>"))).to be false
    expect(valid?(xml("a", "<a-only/><unexpected/>"))).to be false
  end

  it "does not accidentally clamp reused root attributes on nested documents" do
    nested = "<embedded>#{xml('b', '<a-only/>')}</embedded>"
    expect(valid?(xml("a", nested))).to be true
  end

  it "allows the exact metadata child only in presentation on declared parents" do
    label = "<fmt-name>Figure 1<fmt-ladl-label-data local='1' global='Figure 1' value='1' direction='left' global-direction='left' labeller='figure'/></fmt-name>"
    expect(valid?(xml("a", label, type: "presentation"))).to be true
    expect(valid?(xml("a", label))).to be false
    expect(valid?(xml("a", "<fmt-ladl-label-data/>", type: "presentation"))).to be false
    expect(valid?(xml("a", "<extension><fmt-ladl-label-data/></extension>", type: "presentation"))).to be false
  end

  it "rejects duplicate metadata, unexpected attributes, text and child elements" do
    ["<fmt-ladl-label-data/><fmt-ladl-label-data/>",
     "<fmt-ladl-label-data private='x'/>",
     "<fmt-ladl-label-data>text</fmt-ladl-label-data>",
     "<fmt-ladl-label-data><child/></fmt-ladl-label-data>"].each do |payload|
      expect(valid?(xml("a", "<fmt-name>Figure 1#{payload}</fmt-name>", type: "presentation"))).to be false
    end
  end

  it "rejects private ISO facts through an otherwise valid foreign-extension wildcard" do
    facts = "<extension><v:sequence xmlns:v='#{shared::PRIVATE_FACTS_NS}'><v:item/></v:sequence></extension>"
    expect(Nokogiri::XML::RelaxNG(source("a-only")).validate(Nokogiri::XML(xml("a", facts)))).to be_empty
    expect(valid?(xml("a", facts))).to be false
    expect(valid?(xml("a", facts, type: "presentation"))).to be false
    expect(valid?(xml("a", "<extension><other xmlns='urn:vendor'>text</other></extension>"))).to be true
  end

  it "validates a selected configuration, not merely any globally valid branch" do
    validator = shared::Validator.new(xml: result.xml, manifest: result.manifest)
    expect(validator.validate(xml("a", "<a-only/>"), flavor: "a")).to be_empty
    expect(validator.validate(xml("b", "<b-only/>"), flavor: "a")).not_to be_empty
    expect { validator.validate(xml("a", "<a-only/>"), flavor: "missing") }
      .to raise_error(shared::Error, /unknown configured flavor/)
  end

  it "binds the profile manifest to the actual one-file grammar" do
    bad = result.manifest.merge("rng_sha256" => "0" * 64)
    expect { shared::Validator.new(xml: result.xml, manifest: bad) }
      .to raise_error(shared::Error, /integrity mismatch/)
    expect(Nokogiri::XML(result.xml).xpath("//r:include | //r:externalRef", "r" => shared::NS)).to be_empty
  end

  it "fails rather than widening a source that excludes the configured flavor" do
    profile = shared::Profile.new(id: "a", xml: source("a-only", flavor_pattern: "<value>different</value>"))
    expect { shared::Producer.new(profiles: [profile], metadata_parents: []).produce }
      .to raise_error(shared::Error, /source excludes root flavor/)
  end

  it "rejects sources without mandatory root discriminators" do
    incomplete = source("a-only").sub('<attribute name="flavor"><text/></attribute>', "")
    profile = shared::Profile.new(id: "a", xml: incomplete)
    expect { shared::Producer.new(profiles: [profile], metadata_parents: []).produce }
      .to raise_error(shared::Error, /does not require flavor/)
  end
end

RSpec.describe 'legacy universal schema configuration' do
  let(:shared) { Metanorma::Standoc::Validate::UniversalSchema }

  def legacy_source(name, namespace)
    %(<grammar xmlns="http://relaxng.org/ns/structure/1.0" ns="#{namespace}"><start><element name="#{name}"><element name="p"><text/></element></element></start></grammar>)
  end

  it 'uses exact legacy root QName without introducing authored attributes' do
    profiles = %w(a b).map do |id|
      shared::Profile.new(id: id, xml: legacy_source("#{id}-standard", "urn:#{id}"), flavor_attribute: false, representation_attribute: false)
    end
    result = shared::Producer.new(profiles: profiles, metadata_parents: ['p']).produce
    validator = shared::Validator.new(xml: result.xml, manifest: result.manifest)
    xml = '<a-standard xmlns="urn:a"><p>Text</p></a-standard>'
    expect(validator.validate(xml, flavor: 'a', representation: 'semantic')).to be_empty
    expect(validator.validate(xml, flavor: 'b', representation: 'semantic')).not_to be_empty
    expect(validator.validate(xml, flavor: 'a')).not_to be_empty
    metadata = xml.sub('Text', 'Text<fmt-ladl-label-data value="1"/>')
    expect(validator.validate(metadata, flavor: 'a', representation: 'presentation')).to be_empty
    expect(validator.validate(metadata, flavor: 'a', representation: 'semantic')).not_to be_empty
  end

  it 'rejects ambiguous legacy profile discrimination' do
    profiles = %w(a b).map do |id|
      shared::Profile.new(id: id, xml: legacy_source('same', 'urn:same'), flavor_attribute: false, representation_attribute: false)
    end
    expect { shared::Producer.new(profiles: profiles, metadata_parents: []).produce }.to raise_error(shared::Error, /overlapping/)
  end
end

RSpec.describe "shared profile guard collisions" do
  it "rejects a duplicate discriminator even when a different flavor occurs between them" do
    shared = Metanorma::Standoc::Validate::UniversalSchema
    source = '<grammar xmlns="http://relaxng.org/ns/structure/1.0" ns="urn:overlap"><start><element name="metanorma"><attribute name="flavor"/><attribute name="type"/></element></start></grammar>'
    profiles = [['a', 'a'], ['b', 'b'], ['c', 'a']].map do |id, flavor|
      shared::Profile.new(id: id, flavor: flavor, xml: source)
    end
    expect { shared::Producer.new(profiles: profiles, metadata_parents: []).produce }.to raise_error(shared::Error, /overlapping/)
  end
end
