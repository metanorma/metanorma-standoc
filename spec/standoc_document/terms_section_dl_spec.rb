# frozen_string_literal: true

require_relative "../spec_helper"

# metanorma-ietf#376: a bare <dl> directly inside a terms section was
# unreachable at parse - TermsSection mapped paragraphs and term
# entries but no definition list
RSpec.describe "definition list mapping on terms sections" do
  it "parses a terms-section <dl> into definition_lists" do
    xml = <<~XML
      <terms id="_terms1" obligation="normative">
        <title>Terms and Definitions</title>
        <p>intro</p>
        <dl id="_dl1">
          <dt>Time-Stamping Unit</dt>
          <dd>As defined in RFC 3628.</dd>
          <dt>Merkle Tree</dt>
          <dd>As defined in RFC 6962.</dd>
        </dl>
      </terms>
    XML

    terms = Metanorma::Standoc::Document::Sections::TermsSection.from_xml(xml)

    expect(terms.definition_lists.length).to eq(1)
    expect(terms.definition_lists.first.dt.size).to eq(2)
  end
end
