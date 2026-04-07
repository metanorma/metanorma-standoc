require "spec_helper"
require "metanorma/cleanup/merge_bibitems"
require "relaton/bib"

RSpec.describe Metanorma::Standoc::Cleanup::MergeBibitems do
  let(:bibitem_xml) do
    <<~XML
      <bibitem id="TEST-001" type="standard">
        <title type="main" language="en">Test Standard Title</title>
        <docidentifier type="TEST">TEST-001</docidentifier>
        <date type="published"><on>2023-01-01</on></date>
        <contributor>
          <role type="publisher"/>
          <organization><name>Test Organization</name></organization>
        </contributor>
        <place><formattedPlace>Geneva</formattedPlace></place>
      </bibitem>
    XML
  end

  let(:bibdata_xml) do
    <<~XML
      <bibdata type="standard">
        <title type="main" language="en">Collection Document Title</title>
        <docidentifier type="TEST">TEST-001</docidentifier>
        <date type="published"><on>2023-06-15</on></date>
        <contributor>
          <role type="author"/>
          <organization><name>Author Org</name></organization>
        </contributor>
        <place><formattedPlace>New York</formattedPlace></place>
        <ext><flavor>test</flavor></ext>
      </bibdata>
    XML
  end

  let(:bibdata_xml2) do
    <<~XML
      <bibdata type="standard">
        <title type="main" language="en">Override Title</title>
        <docidentifier type="TEST">TEST-002</docidentifier>
        <contributor>
          <role type="publisher"/>
          <organization><name>Publisher Org</name></organization>
        </contributor>
      </bibdata>
    XML
  end

  describe "#load_bibitem" do
    subject(:instance) { described_class.new(bibitem_xml, bibitem_xml) }

    context "when XML root is <bibitem>" do
      it "parses correctly without error" do
        result = instance.send(:load_bibitem, bibitem_xml)
        expect(result).to be_a(Hash)
        expect(result[:docidentifier]).not_to be_nil
      end
    end

    context "when XML root is <bibdata>" do
      it "parses correctly without error" do
        result = instance.send(:load_bibitem, bibdata_xml)
        expect(result).to be_a(Hash)
        expect(result[:docidentifier]).not_to be_nil
      end

      it "preserves ext content from bibdata" do
        result = instance.send(:load_bibitem, bibdata_xml)
        expect(result).to be_a(Hash)
        # ext should be present when parsed from bibdata
        expect(result[:ext]).not_to be_nil
      end
    end
  end

  describe "#merge" do
    context "when both inputs are <bibitem> XML" do
      let(:new_bibitem_xml) do
        <<~XML
          <bibitem id="TEST-001" type="standard">
            <title type="main" language="en">Updated Title</title>
            <docidentifier type="TEST">TEST-001</docidentifier>
            <date type="published"><on>2024-01-01</on></date>
            <place><formattedPlace>London</formattedPlace></place>
          </bibitem>
        XML
      end

      it "merges without error" do
        result = described_class.new(bibitem_xml, new_bibitem_xml).merge
        expect(result).to be_a(described_class)
      end

      it "overwrites place from new" do
        m = described_class.new(bibitem_xml, new_bibitem_xml).merge
        noko = m.to_noko
        expect(noko.at("./place/formattedPlace")&.text).to eq("London")
      end
    end

    context "when both inputs are <bibdata> XML" do
      it "merges without error" do
        result = described_class.new(bibdata_xml, bibdata_xml2).merge
        expect(result).to be_a(described_class)
      end

      it "overwrites docidentifier from new bibdata" do
        m = described_class.new(bibdata_xml, bibdata_xml2).merge
        noko = m.to_noko
        expect(noko.at("./docidentifier")&.text).to include("TEST-002")
      end
    end

    context "when old is <bibdata> and new is <bibdata> (collection prefatory_content use case)" do
      it "produces valid XML output via to_noko" do
        m = described_class.new(bibdata_xml, bibdata_xml2).merge
        noko = m.to_noko
        expect(noko).not_to be_nil
        expect(noko.name).to eq("bibdata")
      end
    end
  end

  describe "#to_noko" do
    context "when initialized with bibdata XML" do
      it "returns a bibdata root node (preserving bibdata context)" do
        m = described_class.new(bibdata_xml, bibdata_xml2).merge
        noko = m.to_noko
        expect(noko.name).to eq("bibdata")
      end
    end

    context "when initialized with bibitem XML" do
      it "returns an XML node" do
        m = described_class.new(bibitem_xml, bibitem_xml).merge
        noko = m.to_noko
        expect(noko).not_to be_nil
      end
    end
  end
end
