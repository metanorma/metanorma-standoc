require "spec_helper"
require "tmpdir"
require_relative "../../lib/metanorma/validate/schema_compiler"

RSpec.describe Metanorma::Standoc::Validate::Schema::Compiler do
  let(:rng_ns) { "http://relaxng.org/ns/structure/1.0" }

  def with_schemas(files)
    Dir.mktmpdir("metanorma-rng-compiler") do |directory|
      files.each { |name, text| File.write(File.join(directory, name), text) }
      yield Pathname.new(directory)
    end
  end

  def grammar(content, attrs = "")
    "<grammar xmlns='#{rng_ns}' #{attrs}>#{content}</grammar>"
  end

  def accepts?(schema, xml)
    schema.validate(Nokogiri::XML(xml)).empty?
  end

  it "preserves include overrides, datatype restrictions and namespace context" do
    files = {
      "base.rng" => grammar("<start><ref name='root'/></start>" \
        "<define name='root'><element name='doc'><ref name='body'/></element></define>" \
        "<define name='body'><text/></define>"),
      "entry.rng" => grammar("<include href='base.rng'><define name='body'>" \
        "<attribute name='number'><data type='positiveInteger'/></attribute>" \
        "</define></include>", "ns='urn:sample' datatypeLibrary='http://www.w3.org/2001/XMLSchema-datatypes'")
    }
    with_schemas(files) do |directory|
      result = described_class.new(root: directory).compile("entry.rng")
      flat = Nokogiri::XML::RelaxNG(result.xml)
      original = File.open(directory.join("entry.rng")) do |input|
        Nokogiri::XML::RelaxNG(input)
      end
      ["<doc xmlns='urn:sample' number='2'/>",
       "<doc xmlns='urn:sample' number='zero'/>",
       "<doc xmlns='urn:sample' unknown='2'/>",
       "<doc number='2'/>", "<doc xmlns='urn:sample'/>"]
        .each { |xml| expect(accepts?(flat, xml)).to eq(accepts?(original, xml)), xml }
      expect(accepts?(flat, "<doc xmlns='urn:sample' number='2'/>")).to be true
      expect(result.sources.keys.sort).to eq %w(base.rng entry.rng)
      expect(result.sources.values).to all(match(/\A[0-9a-f]{64}\z/))
      expect(Nokogiri::XML(result.xml).xpath("//r:include", "r" => rng_ns)).to be_empty
    end
  end

  it "preserves external grammar scope and namespaced children" do
    files = {
      "external.rng" => grammar("<start><ref name='item'/></start>" \
        "<define name='item'><element name='inner'><empty/></element></define>", "ns='urn:inner'"),
      "entry.rng" => grammar("<start><ref name='item'/></start>" \
        "<define name='item'><element name='outer'><externalRef href='external.rng'/></element></define>", "ns='urn:outer'")
    }
    with_schemas(files) do |directory|
      result = described_class.new(root: directory).compile("entry.rng")
      schema = Nokogiri::XML::RelaxNG(result.xml)
      expect(accepts?(schema, "<outer xmlns='urn:outer'><inner xmlns='urn:inner'/></outer>")).to be true
      expect(accepts?(schema, "<outer xmlns='urn:outer'><inner/></outer>")).to be false
      expect(result.xml).not_to include("externalRef")
    end
  end

  it "retains combine semantics across nested includes and div components" do
    files = {
      "base.rng" => grammar("<start><ref name='doc'/></start>" \
        "<div><define name='doc'><element name='doc'><ref name='attrs'/></element></define>" \
        "<define name='attrs'><attribute name='a'/></define></div>"),
      "middle.rng" => grammar("<include href='base.rng'/>" \
        "<define name='attrs' combine='interleave'><attribute name='b'/></define>"),
      "entry.rng" => grammar("<include href='middle.rng'/>")
    }
    with_schemas(files) do |directory|
      result = described_class.new(root: directory).compile("entry.rng")
      schema = Nokogiri::XML::RelaxNG(result.xml)
      expect(accepts?(schema, "<doc a='1' b='2'/>")).to be true
      expect(accepts?(schema, "<doc a='1'/>")).to be false
      expect(accepts?(schema, "<doc a='1' b='2' c='3'/>")).to be false
    end
  end

  it "rejects an override of a nonexistent definition" do
    with_schemas("base.rng" => grammar("<start><element name='doc'><empty/></element></start>"),
                 "entry.rng" => grammar("<include href='base.rng'><define name='absent'><text/></define></include>")) do |directory|
      expect { described_class.new(root: directory).compile("entry.rng") }
        .to raise_error(described_class::Error, /overrides missing/)
    end
  end

  it "rejects cycles, remote references and references outside the allowed source root" do
    with_schemas("a.rng" => grammar("<include href='b.rng'/>"),
                 "b.rng" => grammar("<include href='a.rng'/>"),
                 "remote.rng" => grammar("<include href='https://example.invalid/schema.rng'/>")) do |directory|
      compiler = described_class.new(root: directory)
      expect { compiler.compile("a.rng") }.to raise_error(described_class::Error, /cyclic/)
      expect { compiler.compile("remote.rng") }.to raise_error(described_class::Error, /only local/)
      expect { compiler.compile("../missing.rng") }.to raise_error(described_class::Error)
    end
  end

  it "rejects existing references and symlinks outside its permitted source root" do
    Dir.mktmpdir("metanorma-rng-boundary") do |directory|
      root = Pathname.new(directory).join("schemas")
      root.mkdir
      outside = Pathname.new(directory).join("outside.rng")
      outside.write(grammar("<start><element name='doc'><empty/></element></start>"))
      root.join("entry.rng").write(grammar("<include href='../outside.rng'/>"))
      File.symlink(outside, root.join("link.rng"))
      compiler = described_class.new(root: root)
      expect { compiler.compile("entry.rng") }.to raise_error(described_class::Error, /escapes root/)
      expect { compiler.compile("link.rng") }.to raise_error(described_class::Error, /escapes root/)
    end
  end

  it "compiles the real standoc dependency graph into one strict standalone grammar" do
    directory = File.expand_path("../../lib/metanorma/validate", __dir__)
    result = described_class.new(root: directory).compile("standoc-compile.rng")
    xml = Nokogiri::XML(result.xml)
    expect(xml.xpath("//r:include | //r:externalRef", "r" => rng_ns)).to be_empty
    expect(result.sources.size).to eq 12
    original = Nokogiri::XML::RelaxNG(File.open(File.join(directory, "standoc-compile.rng")))
    flat = Nokogiri::XML::RelaxNG(result.xml)
    Dir.mktmpdir("metanorma-unified-sample") do |tmp|
      source = <<~ADOC
        = Document title
        Author
        :docfile: sample.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :docnumber: 1000
        :copyright-year: 2026
        :publisher: Ribose

        == Clause
        Para
      ADOC
      semantic = Dir.chdir(tmp) { Asciidoctor.convert(source, backend: :standoc, header_footer: true) }
      valid = Nokogiri::XML(semantic)
      expect(original.validate(valid)).to be_empty
      expect(flat.validate(valid)).to be_empty
      invalid = valid.dup
      invalid.root.add_child("<unexpected xmlns='https://www.metanorma.org/ns/standoc'/>")
      expect(original.validate(invalid)).not_to be_empty
      expect(flat.validate(invalid)).not_to be_empty
    end
  end
end
