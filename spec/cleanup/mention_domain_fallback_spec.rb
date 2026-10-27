require "spec_helper"

RSpec.describe Metanorma::Standoc do
  subject(:xml) do
    x = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS)).tap(&:remove_namespaces!)
    File.write("/tmp/mention_spec_dump.xml", x.to_xml) if ENV["MENTION_DUMP"]
    x
  end

  let(:input) do
    <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === alpha

      domain:[Domain One]

      An {{beta}} reference and an {{eps}} reference.

      === beta

      domain:[Domain Two]

      A {{gamma}} reference and an {{alpha}} reference.

      === gamma

      domain:[Domain Two]

      Gamma definition.

      === delta

      domain:[Domain Three]

      A {{eps}} reference.

      === eps

      domain:[Domain One]

      Eps definition.

      === eps

      domain:[Domain Two]

      Another eps definition.
    INPUT
  end

  it "resolves a mention whose designation is unique across domains" do
    ref = xml.at("//concept[refterm[contains(., 'beta')]]/xref")
    expect(ref).not_to be_nil
    expect(ref["target"]).to eq("term-_Domain-Two_-beta")
  end

  it "resolves an ambiguous mention within the referring term's own domain" do
    ref = xml.at("//concept[refterm[contains(., 'eps')]]/xref")
    expect(ref).not_to be_nil
    expect(ref["target"]).to eq("term-_Domain-One_-eps")
  end

  it "resolves a cross-domain mention whose designation is unique" do
    ref = xml.at("//concept[refterm[contains(., 'alpha')]]/xref")
    expect(ref).not_to be_nil
    expect(ref["target"]).to eq("term-_Domain-One_-alpha")
  end

  it "resolves a mention to the referring term's own domain candidate" do
    ref = xml.at("//concept[refterm[contains(., 'gamma')]]/xref")
    expect(ref).not_to be_nil
    expect(ref["target"]).to eq("term-_Domain-Two_-gamma")
  end

  it "does not resolve a mention ambiguous across foreign domains" do
    ref = xml.at("//term[.//domain = 'Domain Three']//concept")
    expect(ref.at("errormsg")).not_to be_nil
  end
end
