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

# metanorma-standoc#1412 follow-up: the authored id:: wins over the
# clause's derived heading anchor — AsciiBib includes pull foreign
# drafts' bibitems in, and their heading ids must not shadow the ids
# the citations name
RSpec.describe "authored id precedence over the clause anchor" do
  class AsciiBibHarness
    include Metanorma::Standoc::Asciibib
    include Metanorma::Standoc::Utils

    Entry = Struct.new(:code, :params)
    class LogSpy
      attr_reader :entries

      def initialize = @entries = []

      def add(code, _node, params: []) = @entries << Entry.new(code, params)
    end

    attr_reader :log, :refids

    def initialize
      @log = LogSpy.new
      @refids = []
    end
  end

  it "keeps the authored id when the clause carries a derived anchor" do
    clause_xml = <<~XML
      <clause id="_uuid1" anchor="draftmphtest205" bibitem="true">
        <title>draft-mph-test2-05</title>
        <dl>
          <dt>id</dt><dd><p>draft-mph-test2-05</p></dd>
          <dt>title</dt><dd><p>Draft B Title</p></dd>
        </dl>
      </clause>
    XML
    clause = Nokogiri::XML(clause_xml).root

    harness = AsciiBibHarness.new
    bib = harness.dl_bib_extract(clause)
    harness.validate_ref_dl(bib, clause)
    converted = Nokogiri::XML(
      Relaton::Bib::ItemData.new(
        **Relaton::Bib::HashParserV1.hash_to_bib(bib),
      ).to_xml,
    )
    harness.ref_dl_cleanup_id(converted.root, clause, bib["id"])

    expect(converted.root["anchor"]).to eq("draft-mph-test2-05")
  end
end
