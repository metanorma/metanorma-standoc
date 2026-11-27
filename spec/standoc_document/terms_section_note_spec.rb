# frozen_string_literal: true

require_relative "../spec_helper"

# metanorma-ietf#380: a note directly inside a terms section was
# unreachable at parse - TermsSection mapped paragraphs, lists and
# term entries but no note
RSpec.describe "note mapping on terms sections" do
  it "parses a terms-section note into notes" do
    xml = <<~XML
      <terms id="_terms1" obligation="normative">
        <title>Terms and Definitions</title>
        <note id="_note1"><p>Term usage note.</p></note>
      </terms>
    XML

    terms = Metanorma::Standoc::Document::Sections::TermsSection.from_xml(xml)

    expect(terms.notes.length).to eq(1)
  end
end
