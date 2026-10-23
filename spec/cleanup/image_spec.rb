require "spec_helper"

RSpec.describe Metanorma::Standoc::Image do
  let(:harness) { Class.new { include Metanorma::Standoc::Image }.new }
  let(:xmlns) do
    'xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"'
  end
  let(:svg_body) do
    <<~SVG
      <style>.k { fill: url(#g) } .m { stroke: red }</style>
      <defs>
        <linearGradient id="g"/>
        <clipPath id="cp"><rect/></clipPath>
        <filter id="uniq1"/>
      </defs>
      <circle class="k m" fill="url(#g)" clip-path="url(#cp)" filter="url(#uniq1)"/>
      <use xlink:href="#g"/>
      <use href="#cp"/>
      <use xlink:href="#uniq1"/>
      <a href="http://example.com/#g"/>
    SVG
  end
  let(:host) do
    <<~XML
      <root xmlns:xlink="http://www.w3.org/1999/xlink">
        <p id="g">host text</p>
        <svg #{xmlns} id="s1">#{svg_body}</svg>
        <svg #{xmlns} id="mid"><defs><rect id="solo"/></defs><use href="#solo"/></svg>
        <svg #{xmlns} id="s3">#{svg_body.gsub("uniq1", "uniq3")}</svg>
        <p id="tail">tail text</p>
      </root>
    XML
  end
  let(:expected) do
    <<~XML
      <root xmlns:xlink="http://www.w3.org/1999/xlink">
        <p id="g">host text</p>
        <svg #{xmlns} id="s1">
          <style>.k_inject_0 { fill: url(#g_inject_0) } .m_inject_0 { stroke: red }</style>
          <defs>
            <linearGradient id="g_inject_0"/>
            <clipPath id="cp_inject_0"><rect/></clipPath>
            <filter id="uniq1"/>
          </defs>
          <circle class="k_inject_0 m_inject_0" fill="url(#g_inject_0)" clip-path="url(#cp_inject_0)" filter="url(#uniq1)"/>
          <use xlink:href="#g_inject_0"/>
          <use href="#cp_inject_0"/>
          <use xlink:href="#uniq1"/>
          <a href="http://example.com/#g"/>
        </svg>
        <svg #{xmlns} id="mid"><defs><rect id="solo"/></defs><use href="#solo"/></svg>
        <svg #{xmlns} id="s3">
          <style>.k_inject_1 { fill: url(#g_inject_2) } .m_inject_1 { stroke: red }</style>
          <defs>
            <linearGradient id="g_inject_2"/>
            <clipPath id="cp_inject_2"><rect/></clipPath>
            <filter id="uniq3"/>
          </defs>
          <circle class="k_inject_1 m_inject_1" fill="url(#g_inject_2)" clip-path="url(#cp_inject_2)" filter="url(#uniq3)"/>
          <use xlink:href="#g_inject_2"/>
          <use href="#cp_inject_2"/>
          <use xlink:href="#uniq3"/>
          <a href="http://example.com/#g"/>
        </svg>
        <p id="tail">tail text</p>
      </root>
    XML
  end

  {
    "Nokogiri" => ->(xml) { Nokogiri::XML(xml) },
    "Moxml" => ->(xml) { Moxml.new(:leptris).parse(xml) },
  }.each do |family, parser|
    context "with a #{family} document" do
      let(:doc) { parser.call(host) }

      it "disambiguates ids and references in place, preserving the host" do
        harness.svg_cleanup(doc)
        expect(doc.root.to_xml).to be_xml_equivalent_to expected
      end

      it "mutates the original document object" do
        before = doc.root
        harness.svg_cleanup(doc)
        expect(doc.root).to equal before
        expect(doc.xpath("//m:svg[@id='s3']//m:linearGradient/@id",
                         "m" => "http://www.w3.org/2000/svg").first.text)
          .to eq "g_inject_2"
        expect(doc.xpath("//p").map { |p| p["id"] }).to eq %w(g tail)
      end

      it "leaves documents without SVGs, or SVGs without ids, untouched" do
        xml = "<root><p id='a'>x</p><svg xmlns='http://www.w3.org/2000/svg'>" \
              "<circle/></svg></root>"
        d = parser.call(xml)
        harness.svg_cleanup(d)
        expect(d.root.to_xml).to be_xml_equivalent_to xml
      end
    end
  end

  context "with a repeated SVG root id in a Nokogiri document" do
    let(:xml) do
      <<~XML
        <root>
          <svg #{xmlns} id="Layer_1"><g id="a"/></svg>
          <svg #{xmlns} id="Layer_1"><g id="b"/></svg>
          <svg #{xmlns} id="Layer_1_inject_1"><g id="c"/></svg>
        </root>
      XML
    end

    it "keeps the first root id and suffixes later ones by position" do
      doc = Nokogiri::XML(xml)
      harness.svg_cleanup(doc)
      expect(doc.xpath("//m:svg/@id", "m" => "http://www.w3.org/2000/svg")
        .map(&:text)).to eq %w(Layer_1 Layer_1_inject_1 Layer_1_inject_1)
    end
  end
end
