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

  it "renders the copyright year through the bibdata object path" do
    FileUtils.rm_f "test.html"
    processor.output(<<~XML, "test.xml", "test.html", :html)
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
    document = Nokogiri::HTML(File.read("test.html"))
    expect(document.at_css(".docyear")&.text).to include("2026")
  end
end
