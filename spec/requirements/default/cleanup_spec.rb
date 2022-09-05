require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Requirements::Default do
    it "moves requirement metadata deflist to correct location" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause

      [.requirement,subsequence="A",inherit="/ss/584/2015/level/1 &amp; /ss/584/2015/level/2"]
      ====
      [%metadata]
      model:: ogc
      type:: class
      identifier:: http://www.opengis.net/spec/waterml/2.0/req/xsd-xml-rules[*req/core*]
      subject:: Encoding of logical models
      inherit:: urn:iso:dis:iso:19156:clause:7.2.2
      inherit:: urn:iso:dis:iso:19156:clause:8
      inherit:: http://www.opengis.net/doc/IS/GML/3.2/clause/2.4
      inherit:: O&M Abstract model, OGC 10-004r3, clause D.3.4
      inherit:: http://www.opengis.net/spec/SWE/2.0/req/core/core-concepts-used
      inherit:: <<ref2>>
      inherit:: <<ref3>>
      target:: http://www.example.com
      classification:: priority:P0
      classification:: domain:Hydrology,Groundwater
      classification:: control-class:Technical
      obligation:: recommendation,requirement

      I recommend this
      ====
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
            <sections>
        <clause id='_' inline-header='false' obligation='normative'>
          <title>Clause</title>
          <requirement id='_' subsequence='A' obligation='recommendation,requirement' model='ogc' type='class'>
            <identifier>http://www.opengis.net/spec/waterml/2.0/req/xsd-xml-rules</identifier>
            <subject>Encoding of logical models</subject>
            <inherit>/ss/584/2015/level/1 &amp; /ss/584/2015/level/2</inherit>
            <inherit>urn:iso:dis:iso:19156:clause:7.2.2</inherit>
            <inherit>urn:iso:dis:iso:19156:clause:8</inherit>
            <inherit>http://www.opengis.net/doc/IS/GML/3.2/clause/2.4</inherit>
            <inherit>O&amp;M Abstract model, OGC 10-004r3, clause D.3.4</inherit>
            <inherit>http://www.opengis.net/spec/SWE/2.0/req/core/core-concepts-used</inherit>
            <inherit>
              <xref target='ref2'/>
            </inherit>
            <inherit>
              <xref target='ref3'/>
            </inherit>
            <classification>
                 <tag>priority</tag>
                 <value>P0</value>
               </classification>
               <classification>
                 <tag>domain</tag>
                 <value>Hydrology</value>
               </classification>
               <classification>
                 <tag>domain</tag>
                 <value>Groundwater</value>
               </classification>
               <classification>
                 <tag>control-class</tag>
                 <value>Technical</value>
               </classification>
               <classification>
                 <tag>target</tag>
                 <value><link target='http://www.example.com'/></value>
               </classification>
            <description>
              <p id='_'>I recommend this</p>
            </description>
          </requirement>
        </clause>
      </sections>
            </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "moves inherit macros to correct location" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause

      [.requirement,subsequence="A",inherit="/ss/584/2015/level/1 &amp; /ss/584/2015/level/2"]
      .Title
      ====
      inherit:[A]
      inherit:[B]
      I recommend this
      ====

      [.requirement,subsequence="A",classification="X:Y"]
      .Title
      ====
      inherit:[A]
      I recommend this
      ====

      [.requirement,subsequence="A"]
      .Title
      ====
      inherit:[A]
      I recommend this
      ====

      [.requirement,subsequence="A"]
      .Title
      ====
      inherit:[A]
      ====

      [.requirement,subsequence="A"]
      ====
      inherit:[A]
      ====

    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
        <sections>
          <clause id='_' inline-header='false' obligation='normative'>
            <title>Clause</title>
            <requirement id='_' subsequence='A' model="default">
                         <title>Title</title>
              <inherit>A</inherit>
              <inherit>B</inherit>
              <inherit>/ss/584/2015/level/1 &amp; /ss/584/2015/level/2</inherit>
              <description>
                <p id='_'> I recommend this</p>
              </description>
            </requirement>
            <requirement id='_' subsequence='A' model="default">
              <title>Title</title>
              <inherit>A</inherit>
              <classification>
                <tag>X</tag>
                <value>Y</value>
              </classification>
              <description>
                <p id='_'> I recommend this</p>
              </description>
            </requirement>
            <requirement id='_' subsequence='A' model="default">
              <title>Title</title>
              <inherit>A</inherit>
              <description>
                <p id='_'> I recommend this</p>
              </description>
            </requirement>
            <requirement id='_' subsequence='A' model="default">
              <title>Title</title>
                 <inherit>A</inherit>
              </requirement>
              <requirement id='_' subsequence='A' model="default">
              <inherit>A</inherit>
            </requirement>
          </clause>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end
end

