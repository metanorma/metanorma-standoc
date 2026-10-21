# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe "relations by description" do
  # A relation attribute carrying free text is not a citable identifier:
  # conversion must fall back to a plain bibitem and complete, whatever
  # error the relaton/pubid generation in the bundle raises for it
  # (strict routing, identifier parse failure, or nothing at all).
  it "falls back to a plain bibitem for unresolvable relation text" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :no-pdf:
      :part-of: BARTELS, R. H., BEATTY, J. C. and BARSKY, B. A.
    INPUT

    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))

    relation = xml.at("//xmlns:relation")
    expect(relation).not_to be_nil
    expect(relation.at(".//xmlns:bibitem")).not_to be_nil
  end
end
