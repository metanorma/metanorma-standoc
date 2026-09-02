# frozen_string_literal: true

require "spec_helper"
require "metanorma/document"

RSpec.describe Metanorma::Standoc::Document::Sections::Sections do
  it "maps introduction inside the sections container" do
    xml = <<~XML
      <sections>
        <introduction id="_intro" obligation="normative">
          <title>Introduction</title>
          <p>Body introduction paragraph.</p>
        </introduction>
        <clause id="_c1"><title>Scope</title><p>Scope paragraph.</p></clause>
      </sections>
    XML

    sections = described_class.from_xml(xml)

    expect(sections.introduction)
      .to be_a(Metanorma::Standoc::Document::Sections::Introduction)
    expect(sections.introduction.id).to eq("_intro")
    expect(sections.introduction.title.text).to eq(["Introduction"])
    expect(sections.clause.size).to eq(1)
  end
end
