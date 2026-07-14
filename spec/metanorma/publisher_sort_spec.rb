require "spec_helper"

# Shared, configurable publisher bibliography-sort helpers (metanorma-oiml#12).
# The base standoc sort is a no-op; these helpers are exercised by every
# flavour's sort_biblio and are unit-tested here in isolation.
RSpec.describe Metanorma::Standoc::Ref do
  # Minimal host object mixing in the helpers, with a converter stub supplying
  # #skip_docid (the DOI/ISSN/ISBN exclusion xpath fragment).
  let(:host) do
    conv = Struct.new(:skip_docid).new(
      "@type = 'DOI' or @type = 'doi'",
    )
    Class.new do
      include Metanorma::Standoc::Ref
      attr_accessor :publisher_sort_config
      def initialize(conv) = (@conv = conv)
    end.new(conv)
  end

  DEFAULT = [
    { abbrev: "ISO", name: "International Organization for Standardization",
      rank: 1 },
    { abbrev: "IEC", name: "International Electrotechnical Commission",
      rank: 2 },
  ].freeze

  # Build a <bibitem> with the given publisher orgs (each {abbrev:, name:}) and
  # an optional typed docidentifier.
  def bibitem(*publishers, docid: nil)
    pubs = publishers.map do |p|
      abbr = p[:abbrev] ? "<abbreviation>#{p[:abbrev]}</abbreviation>" : ""
      name = p[:name] ? "<name>#{p[:name]}</name>" : ""
      "<contributor><role type='publisher'/>" \
        "<organization>#{abbr}#{name}</organization></contributor>"
    end.join
    d = docid ? "<docidentifier type='#{docid}'>x</docidentifier>" : ""
    Nokogiri::XML("<bibitem>#{pubs}#{d}</bibitem>").root
  end

  def rank(bib, table = DEFAULT)
    host.publisher_sort_rank(bib, table)
  end

  it "ranks by the default table, then standards, then everything else" do
    expect(rank(bibitem({ abbrev: "ISO" }))).to eq 1
    expect(rank(bibitem({ abbrev: "IEC" }))).to eq 2
    expect(rank(bibitem({ abbrev: "XYZ" }, docid: "XYZ"))).to eq 3
    expect(rank(bibitem({ abbrev: "XYZ" }))).to eq 4
  end

  it "matches abbreviations case-insensitively and by name" do
    # abbrev arrives lowercased from AsciiDoc attribute keys
    host.publisher_sort_config =
      [{ abbrev: "oiml",
         name: "International Organization of Legal Metrology", rank: 1 }]
    expect(rank(bibitem({ abbrev: "OIML" }))).to eq 1
    expect(rank(bibitem(
                  { name: "International Organization of Legal Metrology" },
                ))).to eq 1
  end

  it "lets @publisher_sort_config override the flavour default table" do
    host.publisher_sort_config = [
      { abbrev: "OIML", name: "x", rank: 1 },
      { abbrev: "ISO", name: "y", rank: 2 },
      { abbrev: "IEC", name: "z", rank: 3 },
    ]
    expect(rank(bibitem({ abbrev: "OIML" }))).to eq 1
    expect(rank(bibitem({ abbrev: "ISO" }))).to eq 2
    expect(rank(bibitem({ abbrev: "IEC" }))).to eq 3
  end

  # The secondary key must be deterministic for multiple co-publishers, so the
  # historical JIS ordering (JIS+IEC before JIS+ISO, JIS+IEC+ISO alongside
  # JIS+IEC) is preserved: pick the smallest co-publisher token.
  it "picks the smallest co-publisher token as the secondary key" do
    table = [
      { abbrev: "JIS", name: "j", rank: 1 },
      { abbrev: "ISO", name: "International Organization for Standardization",
        rank: 2 },
      { abbrev: "IEC", name: "International Electrotechnical Commission",
        rank: 3 },
    ]
    second = lambda do |*pubs|
      host.publisher_sort_second(bibitem(*pubs), table)
    end
    expect(second.call({ abbrev: "JIS" }, { abbrev: "IEC" })).to eq "IEC"
    expect(second.call({ abbrev: "JIS" }, { abbrev: "ISO" })).to eq "ISO"
    expect(second.call({ abbrev: "JIS" }, { abbrev: "IEC" },
                       { abbrev: "ISO" })).to eq "IEC"
  end
end
