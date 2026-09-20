# frozen_string_literal: true

require_relative "../spec_helper"

# standoc#1249 (first half): the image-map blocks and the column break
# parse as clause children — the Components models wired through
# BlockAttributes/BlockXmlMapping.
RSpec.describe "section image-map blocks" do
  describe Metanorma::Standoc::Document::Sections::ClauseSection do
    it "parses svgmap with its link targets" do
      xml = <<~XML
        <clause id="_c1">
          <title>Schemas</title>
          <svgmap id="_s1">
            <figure id="_f1"><image src="architecture.svg"/></figure>
            <target href="B"><xref target="clause-2"/></target>
          </svgmap>
        </clause>
      XML

      clause = described_class.from_xml(xml)
      expect(clause.svgmaps.length).to eq(1)
      svgmap = clause.svgmaps.first
      expect(svgmap.id).to eq("_s1")
      expect(svgmap.figure.first.id).to eq("_f1")
      expect(svgmap.target.first.href).to eq("B")
      expect(svgmap.target.first.xref.target).to eq("clause-2")
    end

    it "parses imagemap areas" do
      xml = <<~XML
        <clause id="_c1">
          <title>Areas</title>
          <imagemap id="_m1">
            <figure id="_f1"><image src="map.png"/></figure>
            <area type="rect"><link target="https://example.com"/>
              <coords x="0" y="0"/><coords x="10" y="10"/></area>
          </imagemap>
        </clause>
      XML

      clause = described_class.from_xml(xml)
      expect(clause.imagemaps.length).to eq(1)
      area = clause.imagemaps.first.area.first
      expect(area.area_type).to eq("rect")
      expect(area.link.target).to eq("https://example.com")
      expect(area.coords.map { |c| [c.x, c.y] }).to eq([[0.0, 0.0], [10.0, 10.0]])
    end

    it "parses columnbreak as a block child" do
      xml = <<~XML
        <clause id="_c1"><title>Multilingual</title>
          <p id="_p1">First column.</p>
          <columnbreak/>
          <p id="_p2">Second column.</p>
        </clause>
      XML

      clause = described_class.from_xml(xml)
      expect(clause.paragraphs.length).to eq(2)
      expect(clause.columnbreaks.length).to eq(1)
    end

    it "round-trips the blocks through serialization" do
      xml = <<~XML
        <clause id="_c1"><title>Schemas</title>
          <svgmap id="_s1"><figure id="_f1"><image src="a.svg"/></figure></svgmap>
        </clause>
      XML

      expect(described_class.from_xml(xml).to_xml)
        .to be_xml_equivalent_to(xml)
    end
  end
end
