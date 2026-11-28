require "spec_helper"

# Byte-parity guard for the semantic endgame string assembly
# (metanorma-standoc#1264): the textcleanup join, its rstrip and
# footnote-collapsing passes, and the insert_xml_cr whole-document
# substitutions that follow, before the result is handed to the
# cleanup parse. The goldens under spec/fixtures were generated from
# unmodified main; these specs fail if any endgame transform shifts
# a single byte.
#
# strip_guid normalises what is deliberately non-deterministic per
# compile (random UUIDs, the schema-version stamp); the compile-time
# version and copyright-year stamps are normalised the same way the
# BLANK_HDR spec constants interpolate them.
RSpec.describe Metanorma::Standoc do
  let(:normalize_stamps) do
    lambda do |xml|
      xml.sub(%r{ version="[^"]+"},
              %( version="#{Metanorma::Standoc::VERSION}"))
        .sub(%r{<from>[^<]+</from>}, "<from>#{Time.now.year}</from>")
    end
  end

  it "reproduces the endgame assembly byte-for-byte (smartquotes)" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :no-pdf:
      :no-isobib:
      :data-uri-image: false

      == Smart quote handling

      He said "apply the 'best' practice..." to the 3x tests, and left--for good.
      Text footnote:[A footnote right here] and more text that follows it.

      The line
      break continuation
      here.

      .Sourcename
      [source,ruby]
      ----
      puts "hi"
      ----

      |===
      |A |B
      |1 |2
      |===

      NOTE: A "noted" passage with 'quotes' and an ellipsis... here.
    INPUT
    expected = normalize_stamps.call(
      File.read(fixtures_path("semantic_endgame_smartquotes.xml")),
    )
    got = normalize_stamps.call(
      strip_guid(Asciidoctor.convert(input, *OPTIONS)),
    )
    expect(got).to eq expected
  end

  it "reproduces the endgame assembly byte-for-byte (straight quotes)" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :no-pdf:
      :no-isobib:
      :smartquotes: false
      :data-uri-image: false

      == Straight quote handling

      The don’t test keeps its apostrophe straight here.
      Text footnote:[Another footnote] and more text that follows it.

      The line
      break continuation
      here.
    INPUT
    expected = normalize_stamps.call(
      File.read(fixtures_path("semantic_endgame_straightquotes.xml")),
    )
    got = normalize_stamps.call(
      strip_guid(Asciidoctor.convert(input, *OPTIONS)),
    )
    expect(got).to eq expected
  end
end
