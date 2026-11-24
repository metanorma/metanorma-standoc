require "spec_helper"

RSpec.describe Metanorma::Standoc::Validate::Schema do
  let(:converter) { Metanorma::Standoc::Converter.new(:standoc, {}) }
  let(:validator) { Metanorma::Standoc::Validate.new(converter) }

  def fixture(id)
    File.read(File.join(__dir__, "fixtures/shared", "#{id}.xml"))
  end

  it "selects the shared profile through the existing validation_flavor interface" do
    expect(validator.shared_schema_errors(fixture("standoc-native"))).to be_empty
    expect(validator.shared_schema_errors(fixture("iec"))).not_to be_empty
    expect(validator.shared_schema_errors(fixture("iec"), flavor: "iec")).to be_empty
    expect(validator.schema_file).to eq "standoc-compile.rng"
  end

  it "reports shared grammar failures through the existing registered STANDOC_7 log" do
    allow(converter.log).to receive(:add).and_call_original
    xml = fixture("standoc").sub("Text", "<unknown-content/>")
    expect(validator.shared_schema_validate(xml)).not_to be_empty
    expect(converter.log).to have_received(:add).with("STANDOC_7", "Document", params: [kind_of(String)]).at_least(:once)
  end

  it "preserves native validation parity for attribute-bearing SVG at the explicit normalization boundary" do
    xml = fixture("standoc-svg-attributes")
    expect(validator.shared_schema_errors(xml)).not_to be_empty
    normalized = validator.formattedstr_strip(Nokogiri::XML(xml).dup)
    expect(validator.shared_schema_errors(validator.to_xml(normalized))).to be_empty
    expect { validator.schema_validate(normalized, File.expand_path("../../lib/metanorma/validate/standoc-compile.rng", __dir__)) }.to output(/Syntax Valid!/).to_stderr
    expect(xml).to include('viewBox="0 0 10 10"', 'width="10"', 'height="10"')
  end

  it "keeps shared selection separate from explicit custom schema paths" do
    allow(validator).to receive(:schema_validate_errors).with("explicit-custom.rng", kind_of(String)).and_return([])
    expect { validator.schema_validate(Nokogiri::XML("<custom/>"), "explicit-custom.rng") }.to output(/Syntax Valid!/).to_stderr
    expect(validator).to have_received(:schema_validate_errors).with("explicit-custom.rng", kind_of(String))
  end
end
