require "spec_helper"
require "open3"

RSpec.describe Metanorma::Standoc do
  it "processes recommendation" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [.recommendation,identifier="/ogc/recommendation/wfs/2",subject="user;developer, implementer",inherit="/ss/584/2015/level/1; /ss/584/2015/level/2",options="unnumbered",type=verification,model=ogc,tag=X,multilingual-rendering=common]
      ====
      I recommend this
      ====
    INPUT
    output = <<~"OUTPUT"
      #{BLANK_HDR}
       <sections>
         <recommendation id="_" unnumbered="true" type="verification" model="ogc" tag='X' multilingual-rendering='common'>
         <identifier>/ogc/recommendation/wfs/2</identifier>
       <subject>user</subject>
       <subject>developer, implementer</subject>
       <inherit>/ss/584/2015/level/1</inherit>
       <inherit>/ss/584/2015/level/2</inherit>
         <description><p id="_">I recommend this</p>
       </description>
       </recommendation>
              </sections>
              </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:misc-container")&.remove
    expect(xmlpp(strip_guid(xml.to_xml)))
      .to be_equivalent_to xmlpp(output)
  end

  it "applies default requirement model" do
    mock_default_recommendation_model("ogc")
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}

      [[A]]
      [.permission]
      ====
      I permit this


      [[B]]
      [.permission]
      =====
      I also permit this

      . List
      . List
      =====
      ====
    INPUT

    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(xml.at("//xmlns:permission[@id = 'A']/@model").text).to eq("ogc")
    expect(xml.at("//xmlns:permission/xmlns:permission/@model").text)
      .to eq("ogc")
  end

  it "overrides default requirement model" do
    mock_default_recommendation_model("ogc")
    input = <<~"INPUT"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :data-uri-image: false
      :requirements-model: default

      [[A]]
      [.permission]
      ====
      I permit this

      [[B]]
      [.permission]
      =====
      I also permit this

      . List
      . List
      =====
      ====
    INPUT

    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(xml.at("//xmlns:permission[@id = 'A']/@model").text).to eq("default")
    expect(xml.at("//xmlns:permission/xmlns:permission/@model").text)
      .to eq("default")
  end

  it "inherits requirement model from parent" do
    mock_default_recommendation_model("ogc")
    input = <<~"INPUT"

      #{ASCIIDOC_BLANK_HDR}
      [[A]]
      [.permission,model=ogc]
      ====
      I permit this

      [[B]]
      [.permission,model=default]
      =====
      I also permit this

      . List
      . List
      =====
      ====
    INPUT

    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(xml.at("//xmlns:permission[@id = 'A']/@model").text).to eq("ogc")
    expect(xml.at("//xmlns:permission/xmlns:permission/@model").text)
      .to eq("ogc")
  end

  private

  def mock_default_recommendation_model(model)
    allow_any_instance_of(::Metanorma::Standoc::Blocks)
      .to receive(:default_requirement_model).and_return(
        model,
      )
  end
end
