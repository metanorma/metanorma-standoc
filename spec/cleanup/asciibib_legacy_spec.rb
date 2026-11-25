# frozen_string_literal: true

require_relative "../spec_helper"

# metanorma-standoc#1412: the authored id:: is the citation target,
# but the legacy Relaton hash parser strips non-word characters from
# it (ANSI.X9.95 -> ANSIX995), leaving cross-references dangling.
# metanorma-standoc#1413: the legacy AsciiBib contact keys
# (contact.street/city/country) were dropped silently, the uri
# serialized in a position the schema rejects, and a role-less
# contributor degraded to an invalid contributor element.
RSpec.describe "AsciiBib legacy contact and id handling" do
  subject(:xml) do
    Asciidoctor.convert(input, backend: :standoc, header_footer: true).to_s
  end

  let(:input) do
    <<~ADOC
      = Test Doc
      Author
      :nodoc:
      :no-isobib:

      The integrity of the process gave rise to <<ANSI.X9.95>>.

      [bibliography]
      == Informative References

      [%bibitem]
      === {blank}
      id:: ANSI.X9.95
      docid::
      docid.id:: ANSI X9.95:2005
      title::
      title.type:: main
      title.content:: Trusted Time Stamp Management And Security

      [%bibitem]
      === {blank}
      docid::
      docid.id:: ETSI GS
      title::
      title.type:: main
      title.content:: ETSI Title
      contributor::
      contributor.organization.name:: European Telecommunications Standards Institute
      contributor.organization.contact::
      contributor.organization.contact.street:: 650 Route des Lucioles
      contributor.organization.contact.city:: Sophia Antipolis Cedex
      contributor.organization.contact.country:: France
      contributor.organization.contact.uri:: https://www.etsi.org
    ADOC
  end

  it "keeps the authored id as the bibitem anchor" do
    expect(xml).to include('anchor="ANSI.X9.95"')
    expect(xml).not_to include("ANSIX995")
  end

  it "carries the legacy contact keys into a nested address" do
    expect(xml).to include("<street>650 Route des Lucioles</street>")
    expect(xml).to include("<city>Sophia Antipolis Cedex</city>")
    expect(xml).to include("<country>France</country>")
  end

  it "wraps address and uri in a contact element" do
    expect(xml).to include("<contact>")
    expect(xml).not_to match(%r{<organization>[^<]*<(address|uri)>})
  end

  it "defaults a role-less contributor to author" do
    expect(xml).to include('<role type="author"/>')
  end
end
