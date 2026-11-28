# frozen_string_literal: true

require "spec_helper"
require "metanorma-core"
require "fileutils"

# The standoc default title page reads the bibdata through Liquid
# object paths (isodoc#784, carried in the titlepage context since
# isodoc 3.7.0): docyear is a verbatim copy of
# bibdata/copyright/from, read through `.first` because `copyright`
# is an array and Liquid cannot dot-index arrays
# (metanorma-standoc#1434). The flat keys that isodoc derives
# (docnumber is the first docidentifier's full text; stage and doctype
# run through status_print) stay flat, and the flat keys remain
# available for existing user templates.
RSpec.describe "default HTML title page" do
  registry = Metanorma::Registry.instance
  registry.register(Metanorma::Standoc::Processor)
  processor = registry.find_processor(:standoc)

  let(:input) do
    <<~XML
      <metanorma xmlns="https://www.metanorma.org/ns/standoc" type="semantic">
        <bibdata type="standard">
          <title language="en" type="main">Document title</title>
          <docidentifier>ISO 17301</docidentifier>
          <docnumber>17301</docnumber>
          <copyright>
            <from>2026</from>
            <owner><organization><name>ISO</name></organization></owner>
          </copyright>
        </bibdata>
        <sections/>
      </metanorma>
    XML
  end

  def docyear(processor, input)
    FileUtils.rm_f "test.html"
    processor.output(input, "test.xml", "test.html", :html)
    Nokogiri::HTML(File.read("test.html")).at_css(".docyear")&.text
  end

  it "renders the copyright year through the bibdata object path" do
    expect(docyear(processor, input)).to include("2026")
  end

  # isodoc sets meta[:bibdata] to nil when Relaton cannot parse the
  # bibdata; the year then falls back to the flat docyear key
  it "falls back to the flat docyear key when meta[:bibdata] is nil" do
    allow_any_instance_of(IsoDoc::Metadata)
      .to receive(:bibdata_hash).and_return(nil)
    expect(docyear(processor, input)).to include("2026")
  end
end
