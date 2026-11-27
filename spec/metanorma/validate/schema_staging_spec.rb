# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Metanorma::Standoc::Validate do
  # The packed toolchain's memfs cannot be reproduced locally, but the
  # mechanism it exercises is exact: compiling a schema that uses
  # <include href> from a bare string fails with "no base URI", and the
  # staged closure must reproduce the include geometry so the compile
  # matches parse_file's output (metanorma-standoc#1416).
  let(:validator_class) do
    Class.new do
      include Metanorma::Standoc::Validate::Schema

      def schema_file
        "a.rng"
      end
    end
  end

  subject(:validator) { validator_class.new }

  let(:schema_dir) { Dir.mktmpdir }

  let(:doc_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <thing/>
    XML
  end

  let(:bad_doc_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <wrong/>
    XML
  end

  before do
    File.write(File.join(schema_dir, "a.rng"), <<~RNG)
      <?xml version="1.0" encoding="UTF-8"?>
      <grammar xmlns="http://relaxng.org/ns/structure/1.0"
               datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes">
        <include href="b.rng"/>
      </grammar>
    RNG
    File.write(File.join(schema_dir, "b.rng"), <<~RNG)
      <?xml version="1.0" encoding="UTF-8"?>
      <grammar xmlns="http://relaxng.org/ns/structure/1.0"
               datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes">
        <define name="thing">
          <element name="thing"><empty/></element>
        </define>
        <start>
          <ref name="thing"/>
        </start>
      </grammar>
    RNG
  end

  it "bare string compilation of an including schema has no base URI" do
    expect do
      Leptris::XML::RelaxNG.parse(
        File.read(File.join(schema_dir, "a.rng")),
      )
    end.to raise_error(Leptris::XML::Error, /no base URI/)
  end

  it "compiles the including schema through the staged closure" do
    doc = Leptris::XML.parse(doc_xml, readonly: true)
    errors = validator.schema_validate_errors(
      File.join(schema_dir, "a.rng"), write_doc(doc_xml)
    )
    expect(errors).to be_empty
  end

  it "reports the errors the file-compiled schema reports" do
    errors = validator.schema_validate_errors(
      File.join(schema_dir, "a.rng"), write_doc(bad_doc_xml)
    )
    expect(errors).not_to be_empty
    expect(errors.first[:message]).to include("wrong")
  end

  after do
    FileUtils.remove_entry(schema_dir)
  end

  def write_doc(xml)
    path = File.join(schema_dir, "doc.xml")
    File.write(path, xml)
    path
  end
end
