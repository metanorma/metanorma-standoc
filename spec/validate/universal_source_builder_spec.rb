require "spec_helper"
require "tmpdir"
require_relative "../../lib/metanorma/validate/universal_schema"

RSpec.describe Metanorma::Standoc::Validate::UniversalSchema::SourceBuilder do
  let(:shared) { Metanorma::Standoc::Validate::UniversalSchema }

  it "explicitly repairs the UN extension while retaining the base required type" do
    Dir.mktmpdir("shared-un-source") do |directory|
      File.write(File.join(directory, "isodoc.rng"), <<~RNG)
        <grammar xmlns="http://relaxng.org/ns/structure/1.0" ns="urn:un"
                 datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes">
          <start><element name="un-standard"><element name="admonition"><ref name="AdmonitionAttributes"/><element name="p"><text/></element></element></element></start>
          <define name="AdmonitionAttributes"><attribute name="type"><value>important</value></attribute><optional><attribute name="class"/></optional></define>
        </grammar>
      RNG
      File.write(File.join(directory, "un.rng"), <<~RNG)
        <grammar xmlns="http://relaxng.org/ns/structure/1.0" ns="urn:un"
                 datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes">
          <include href="isodoc.rng"><define name="AdmonitionAttr" combine="interleave"><optional><attribute name="unnumbered"><data type="boolean"/></attribute></optional></define></include>
        </grammar>
      RNG
      expect { Metanorma::Standoc::Validate::Schema::Compiler.new(root: directory).compile("un.rng") }
        .to raise_error(Metanorma::Standoc::Validate::Schema::Compiler::Error, /missing define:AdmonitionAttr/)
      result = described_class.new(metadata_parents: []).build(sources: [
        { id: "un", root: directory, entry: "un.rng", repository: "fixture/un", revision: "pinned-source",
          flavor_attribute: false, representation_attribute: false, migration: "un-admonition-attributes-1" },
      ])
      validator = shared::Validator.new(xml: result.xml, manifest: result.manifest)
      xml = '<un-standard xmlns="urn:un"><admonition type="important" class="warning" unnumbered="true"><p>Warning</p></admonition></un-standard>'
      expect(validator.validate(xml, flavor: "un", representation: "semantic")).to be_empty
      expect(validator.validate(xml.sub(' type="important"', ''), flavor: "un", representation: "semantic")).not_to be_empty
      expect(validator.validate(xml.sub('unnumbered="true"', 'unnumbered="perhaps"'), flavor: "un", representation: "semantic")).not_to be_empty
      expect(result.manifest).not_to have_key("source_migrations")
      expect(result.manifest.fetch("profiles").first.keys).not_to include("provenance", "source_sha256")
    end
  end

  it "preserves significant literal whitespace and namespaces during annotation stripping" do
    Dir.mktmpdir("shared-literal-source") do |directory|
      File.write(File.join(directory, "source.rng"), <<~RNG)
        <grammar xmlns="http://relaxng.org/ns/structure/1.0" ns="urn:literal" datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes">
          <start><element name="literal"><attribute name="value"><value type="string">  exact  </value></attribute><empty/></element></start>
        </grammar>
      RNG
      result = described_class.new(metadata_parents: []).build(sources: [
        { id: "literal", root: directory, entry: "source.rng", repository: "fixture/literal", revision: "pinned-source",
          flavor_attribute: false, representation_attribute: false },
      ])
      validator = shared::Validator.new(xml: result.xml, manifest: result.manifest)
      expect(validator.validate('<literal xmlns="urn:literal" value="  exact  "/>', flavor: "literal", representation: "semantic")).to be_empty
      expect(validator.validate('<literal xmlns="urn:literal" value="exact"/>', flavor: "literal", representation: "semantic")).not_to be_empty
    end
  end
end
