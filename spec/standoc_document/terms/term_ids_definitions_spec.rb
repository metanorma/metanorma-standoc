# frozen_string_literal: true

require "spec_helper"
require "metanorma/document"

RSpec.describe "term definition ids and terms-section definitions" do
  it "round-trips id on definition" do
    xml = '<definition id="_d1"><p>Text.</p></definition>'
    obj = Metanorma::Standoc::Document::Terms::TermDefinition.from_xml(xml)
    expect(obj.id).to eq("_d1")
    expect(obj.to_xml).to include('id="_d1"')
  end

  it "round-trips id on verbal-definition" do
    xml = '<verbal-definition id="_v1"><p>Text.</p></verbal-definition>'
    obj = Metanorma::Standoc::Document::Terms::VerbalExpression.from_xml(xml)
    expect(obj.id).to eq("_v1")
    expect(obj.to_xml).to include('id="_v1"')
  end

  it "round-trips definitions under terms" do
    xml = '<terms id="_t"><definitions id="_df">' \
          "<dl><dt>a</dt><dd><p>b</p></dd></dl></definitions></terms>"
    obj = Metanorma::Standoc::Document::Sections::TermsSection.from_xml(xml)
    expect(obj.definitions.size).to eq(1)
    expect(obj.definitions.first.id).to eq("_df")
    expect(obj.to_xml).to include("<definitions", 'id="_df"')
  end
end
