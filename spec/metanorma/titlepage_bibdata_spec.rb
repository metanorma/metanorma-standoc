# frozen_string_literal: true

require "spec_helper"
require "metanorma-core"
require "fileutils"

# The standoc default title page renders through the flat metadata
# context: the isodoc titlepage Liquid context does not carry the
# bibdata object (verified: {{ bibdata.copyright.from }} renders empty
# where {{ docyear }} renders the year - the object paths work on the
# cover/boilerplate contexts, not this one). So the title page keeps
# the flat keys, including the verbatim-copy docyear
# (= bibdata/copyright/from); the bibdata.* migration of
# metanorma-standoc#1434 is a two-step change - first teach the
# titlepage context to carry bibdata (isodoc), then swap the
# verbatim-copy fields. This spec pins the current contract.
RSpec.describe "default HTML title page" do
  registry = Metanorma::Registry.instance
  registry.register(Metanorma::Standoc::Processor)
  processor = registry.find_processor(:standoc)

  it "renders the copyright year" do
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
