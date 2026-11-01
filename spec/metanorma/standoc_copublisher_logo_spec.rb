require "spec_helper"
require "relaton"
require "base64"
require "fileutils"
require "tmpdir"

# The example matrix varies publisher, abbreviation, and extra document
# attributes per context; memoized helpers express that variation directly.
# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe Metanorma::Standoc do
  let(:publisher) { "Acme Corporation" }
  let(:abbr) { "ACME" }
  let(:extra_attrs) { ":sdo-logos:" }
  let(:input) do
    <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :data-uri-image: false
      :publisher: #{publisher}
      :publisher_abbr: #{abbr}
      #{extra_attrs}
    INPUT
  end
  let(:xml) { convert_document }

  before do
    Relaton::Sdo.configure do |c|
      c.url = "file://#{File.join(fixture_dir, 'index.yaml')}"
      c.storage_dir = Dir.mktmpdir("relaton-sdo-spec-cache")
      c.ttl = 24 * 60 * 60
    end
    Relaton::Sdo::Store.instance.reset!
    File.write(File.join(fixture_dir, "index.yaml"), index_yaml)
  end

  after do
    FileUtils.remove_entry(fixture_dir)
    FileUtils.remove_entry(Relaton::Sdo.configuration.storage_dir, true)
  end

  def convert_document
    @convert_document ||= begin
      doc = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
      doc.remove_namespaces!
      doc
    end
  end

  def index_yaml
    @index_yaml ||= <<~YAML
      ---
      organizations:
        ACME:
          name:
          - content: Acme Corporation
          logo:
          - style: default
            format: png
            size: 64x32
            url: file://#{File.join(fixture_dir, 'acme.png')}
        LOGOLESS:
          name:
          - content: Logoless Standards Body
          logo: []
        TWOVARIANT:
          name:
          - content: Two-variant Standards Body
          logo:
          - style: mono
            format: svg
            url: file://#{File.join(fixture_dir, 'missing.svg')}
          - style: default
            format: png
            url: file://#{File.join(fixture_dir, 'two.png')}
        BROKEN:
          name:
          - content: Broken Logo Standards Body
          logo:
          - style: default
            format: png
            url: file://#{File.join(fixture_dir, 'nonexistent.png')}
    YAML
  end

  def publisher_logo_image
    convert_document
      .at("//contributor[role/@type = 'publisher']//organization/logo/image")
  end

  def fixture_dir
    @fixture_dir ||= begin
      dir = Dir.mktmpdir("relaton-sdo-fixtures")
      FileUtils.cp("spec/assets/correct.png", File.join(dir, "acme.png"))
      FileUtils.cp("spec/assets/correct.png", File.join(dir, "two.png"))
      dir
    end
  end

  def png_data_uri
    encoded = Base64.strict_encode64(File.binread(File.join(fixture_dir,
                                                            "acme.png")))
    "data:image/png;base64,#{encoded}"
  end

  it "fetches the logo from the store when the document provides none" do
    expect(publisher_logo_image["src"]).to eq(png_data_uri)
  end

  it "declares the mimetype of the fetched logo" do
    expect(publisher_logo_image["mimetype"]).to eq("image/png")
  end

  context "when the store offers several variants" do
    let(:publisher) { "Two-variant Standards Body" }
    let(:abbr) { "TWOVARIANT" }

    it "prefers the PNG variant" do
      expect(publisher_logo_image["src"]).to eq(png_data_uri)
    end
  end

  context "when the document attributes provide a logo" do
    let(:extra_attrs) do
      ":sdo-logos:\n" \
        ":publisher_logo: spec/assets/correct.png"
    end

    it "keeps the document attribute logo" do
      expect(publisher_logo_image["src"]).to eq("spec/assets/correct.png")
    end
  end

  context "when `:sdo-logos:` is not enabled" do
    let(:extra_attrs) { "" }

    it "leaves the logo out" do
      expect(xml.at("//contributor[role/@type = 'publisher']" \
                    "//organization/logo")).to be_nil
    end
  end

  context "when the organization is unknown to the store" do
    let(:abbr) { "MONS" }

    it "leaves the logo out" do
      expect(xml.at("//contributor[role/@type = 'publisher']" \
                    "//organization/logo")).to be_nil
    end
  end

  describe "copublisher detection" do
    let(:converter) { Metanorma::Standoc::Converter.new(nil, nil) }

    it "treats every publisher as a copublisher when there is no default" do
      expect(converter.own_publisher?({ name: "Acme Corporation" }, "ACME"))
        .to be(false)
    end
  end

  context "when the store entry has no logos" do
    let(:publisher) { "Logoless Standards Body" }
    let(:abbr) { "LOGOLESS" }

    it "leaves the logo out" do
      expect(xml.at("//contributor[role/@type = 'publisher']" \
                    "//organization/logo")).to be_nil
    end
  end

  context "when the logo cannot be fetched" do
    let(:publisher) { "Broken Logo Standards Body" }
    let(:abbr) { "BROKEN" }

    it "logs a warning" do
      expect { convert_document }.to output(
        %r{Could not fetch the authoritative logo for organization BROKEN},
      ).to_stderr
    end

    it "leaves the logo out and still compiles" do
      expect(xml.at("//contributor[role/@type = 'publisher']" \
                    "//organization/logo")).to be_nil
    end
  end
end

# rubocop:enable RSpec/MultipleMemoizedHelpers
