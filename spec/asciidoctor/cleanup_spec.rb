require "spec_helper"
require "relaton_iec"
require "fileutils"

RSpec.describe Asciidoctor::Standoc do
  it "processes svgmap" do
    FileUtils.cp "spec/fixtures/action_schemaexpg1.svg",
                 "action_schemaexpg1.svg"
    FileUtils.cp "spec/fixtures/action_schemaexpg1.svg",
                 "action_schemaexpg2.svg"
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [svgmap%unnumbered,number=8,subsequence=A,keep-with-next=true,keep-lines-together=true]
      ====
      * <<ref1,Computer>>; http://www.example.com
      ====

      [[ref1]]
      .SVG title
      [.svgmap]
      ====
      image::action_schemaexpg1.svg[]

      * <<ref1,Computer>>; mn://action_schema
      * http://www.example.com[Phone]; http://www.example.com
      ====

      [[ref2]]
      [svgmap%unnumbered,number=8,subsequence=A,keep-with-next=true,keep-lines-together=true]
      ====
      [alt=Workmap]
      image::action_schemaexpg2.svg[]

      * <<ref1,Computer>>; mn://action_schema
      * http://www.example.com[Phone]; mn://basic_attribute_schema
      * <<express:action_schema:action_schema.basic,Coffee>>; mn://support_resource_schema
      ====
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections>
              <svgmap unnumbered='true' number='8' subsequence='A' keep-with-next='true' keep-lines-together='true'>
                   <target href='http://www.example.com'>
                     <xref target='ref1'>Computer</xref>
                   </target>
                 </svgmap>
                 <figure id='ref1'>
                 <name>SVG title</name>
                 <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1_000000001' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
        <style/>
        <image/>
        <a xlink:href='#ref1'>
          <rect x='123.28' y='273.93' class='st0' width='88.05' height='41.84'/>
        </a>
        <a xlink:href='mn://basic_attribute_schema'>
          <rect x='324.69' y='450.52' class='st0' width='132.62' height='40.75'/>
        </a>
        <a xlink:href='mn://support_resource_schema'>
          <rect x='324.69' y='528.36' class='st0' width='148.16' height='40.75'/>
        </a>
      </svg>
                 </figure>
                 <svgmap>
                   <figure id='ref2' unnumbered='true' number='8' subsequence='A' keep-with-next='true' keep-lines-together='true'>
        <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1_000000002' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
          <style/>
          <image/>
          <a xlink:href='#ref1'>
            <rect x='123.28' y='273.93' class='st0' width='88.05' height='41.84'/>
          </a>
          <a xlink:href='http://www.example.com'>
            <rect x='324.69' y='450.52' class='st0' width='132.62' height='40.75'/>
          </a>
          <a xlink:href='mn://support_resource_schema'>
            <rect x='324.69' y='528.36' class='st0' width='148.16' height='40.75'/>
          </a>
        </svg>
                   </figure>
                   <target href='mn://support_resource_schema'>
                     <eref bibitemid='express_action_schema' citeas=''>
                       <localityStack>
                         <locality type='anchor'>
                           <referenceFrom>action_schema.basic</referenceFrom>
                         </locality>
                       </localityStack>
                       Coffee
                     </eref>
                   </target>
                 </svgmap>
      </sections>
      <bibliography>
        <references hidden='true' normative='false'>
          <bibitem id='express_action_schema' type='internal'>
            <docidentifier type='repository'>express/action_schema</docidentifier>
          </bibitem>
        </references>
      </bibliography>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .gsub(%r{<image.*?</image>}m, "<image/>")
      .gsub(%r{<style.*?</style>}m, "<style/>"))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes markup in sourcecode" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [source]
      ----
      <tag/>
      ----

      [[A]]
      [source]
      ----
      var {{{*x*}}} : {{{<<A,recursive>>}}} <tag/>
      ----


    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections>
        <sourcecode id='_'>&lt;tag/&gt;</sourcecode>
        <sourcecode id='A'>
          var
          <strong>x</strong>
           :
          <xref target='A'>recursive</xref>
           &lt;tag/&gt;
        </sourcecode>
      </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes markup in sourcecode with custom delimiters" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :sourcecode-markup-start: [[[
      :sourcecode-markup-end: ]]]

      [[A]]
      [source]
      ----
      var [[[*x*]]] : [[[<<A,recursive>>]]]
      ----


    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections>
        <sourcecode id='A'>
          var
          <strong>x</strong>
           :
          <xref target='A'>recursive</xref>
        </sourcecode>
      </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "applies smartquotes by default" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == "Quotation" A's

      '24:00:00'.
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
        <clause id="_" inline-header="false" obligation="normative">
        <title>“Quotation” A’s</title>
        <p id='_'>‘24:00:00’.</p>
      </clause>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "applies smartquotes when requested" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :smartquotes: true

      == "Quotation" A's
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
        <clause id="_" inline-header="false" obligation="normative">
        <title>“Quotation” A’s</title>
      </clause>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "does not apply smartquotes when requested not to" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :smartquotes: false

      == "Quotation" A's

      `"quote" A's`
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
        <clause id="_" inline-header="false" obligation="normative">
        <title>"Quotation" A's</title>
      <p id="_">
        <tt>"quote" A's</tt>
      </p>
      </clause>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "does not apply smartquotes to sourcecode, tt, pre, pseudocode" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :smartquotes: true

      == "Quotation" A's

      "Quotation" A's

      `"quote" A's`

      [source]
      ----
      "quote" A's
      ----

      [pseudocode]
      ====
      "quote" A's
      ====

    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
                      <clause id="_" inline-header="false" obligation="normative"><title>“Quotation” A’s</title><p id="_">“Quotation” A’s</p>
      <p id="_">
        <tt>"quote" A’s</tt>
      </p>
      <sourcecode id="_">"quote" A's</sourcecode>
      <figure id='_' class='pseudocode'>
        <p id='_'>"quote" A's</p>
      </figure>
      </clause>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "handles < > &amp; in Asciidoctor correctly" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == {blank}

      <&amp;>
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
               <clause id="_" inline-header="false" obligation="normative">
      <p id="_">&lt;&amp;&gt;</p>
             </clause>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "ignores tags when applying smartquotes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      "((ppt))",

      "((ppm))", "((ppt))"
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections>
                        <p id='_'>
           &#8220;ppt&#8221;,
           <index>
             <primary>ppt</primary>
           </index>
         </p>
         <p id='_'>
           &#8220;ppm&#8221;,
           <index>
             <primary>ppm</primary>
           </index>
            &#8220;ppt&#8221;
           <index>
             <primary>ppt</primary>
           </index>
         </p>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "removes empty text elements" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == {blank}
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections>
        <clause id="_" inline-header="false" obligation="normative">

      </clause>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes stem-only terms as admitted" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === stem:[t_90]

      stem:[t_91]

      Time
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
               <terms id="_" obligation="normative">
               <title>Terms and definitions</title>
               <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
               <term id="term-t90"><preferred><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub>
               <mrow>
        <mi>t</mi>
      </mrow>
      <mrow>
        <mn>90</mn>
      </mrow>
      </msub></math></stem></preferred><admitted><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub>
      <mrow>
        <mi>t</mi>
      </mrow>
      <mrow>
        <mn>91</mn>
      </mrow>
      </msub></math></stem></admitted>
             <definition><p id="_">Time</p></definition></term>
             </terms>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "moves term domains out of the term definition paragraph" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Tempus

      domain:[relativity] Time

      === Tempus1

      Time2

      domain:[relativity2]
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
               <terms id="_" obligation="normative">
               <title>Terms and definitions</title>
               <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
               <term id="term-tempus">
               <preferred>Tempus</preferred>
               <domain>relativity</domain><definition><p id="_"> Time</p></definition>
             </term>
             <term id='term-tempus1'>
        <preferred>Tempus1</preferred>
        <domain>relativity2</domain>
        <definition>
          <p id='_'>Time2</p>
          <p id='_'> </p>
        </definition>
      </term>
             </terms>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "permits multiple blocks in term definition paragraph" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :stem:

      == Terms and Definitions

      === stem:[t_90]

      [stem]
      ++++
      t_A
      ++++

      This paragraph is extraneous
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
               <terms id="_" obligation="normative">
               <title>Terms and definitions</title>
               <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
               <term id="term-t90"><preferred><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub>
                <mrow>
         <mi>t</mi>
       </mrow>
       <mrow>
         <mn>90</mn>
       </mrow>
      </msub></math></stem></preferred><definition><formula id="_">
               <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub>
               <mrow>
        <mi>t</mi>
      </mrow>
      <mrow>
        <mi>A</mi>
      </mrow>
      </msub></math></stem>
             </formula>
             <p id="_">This paragraph is extraneous</p></definition>
             </term>
             </terms>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "moves notes inside preceding blocks, if they are not at clause end, and the blocks are not delimited" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [stem]
      ++++
      r = 1 %
      r = 1 %
      ++++

      NOTE: That formula does not do much

      Indeed.
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
          <sections><formula id="_">
        <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>r</mi><mo>=</mo><mn>1</mn><mi>%</mi><mi>r</mi><mo>=</mo><mn>1</mn><mi>%</mi></math></stem>
      <note id="_">
        <p id="_">That formula does not do much</p>
      </note></formula>
             <p id="_">Indeed.</p></sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "does not move notes inside preceding blocks, if they are marked as keep-separate" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [stem]
      ++++
      r = 1 %
      r = 1 %
      ++++

      [NOTE,keep-separate=true]
      ====
      That formula does not do much
      ====

      Indeed.
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
          <sections><formula id="_">
        <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>r</mi><mo>=</mo><mn>1</mn><mi>%</mi><mi>r</mi><mo>=</mo><mn>1</mn><mi>%</mi></math></stem></formula>
      <note id="_">
        <p id="_">That formula does not do much</p>
      </note>
             <p id="_">Indeed.</p></sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "does not move notes inside preceding blocks, if they are at clause end" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [source,ruby]
      [1...x].each do |y|
        puts y
      end

      NOTE: That loop does not do much
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections><sourcecode id="_" lang="ruby">[1...x].each do |y|
        puts y
      end</sourcecode>
      <note id="_">
        <p id="_">That loop does not do much</p>
      </note></sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "converts xrefs to references into erefs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      <<iso216>>
      <<iso216,droploc%capital%>>

      [bibliography]
      == Normative References
      * [[[iso216,ISO 216:2001]]], _Reference_
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <preface><foreword id="_" obligation="informative">
        <title>Foreword</title>
        <p id="_">
        <eref type="inline" bibitemid="iso216" citeas="ISO 216:2001"/>
        <eref type='inline' case='capital' droploc='true' bibitemid='iso216' citeas='ISO 216:2001'/>
      </p>
      </foreword></preface><sections>
      </sections><bibliography><references id="_" obligation="informative" normative="true">
        <title>Normative references</title>
        #{NORM_REF_BOILERPLATE}
        <bibitem id="iso216" type="standard">
         <title format="text/plain">Reference</title>
         <docidentifier>ISO 216:2001</docidentifier>
         <docnumber>216</docnumber>
         <date type="published">
           <on>2001</on>
         </date>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>ISO</name>
           </organization>
         </contributor>
       </bibitem>
      </references>
      </bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "extracts localities from erefs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      <<iso216,whole,clause=3,example=9-11,locality:prelude="33 a",locality:entirety:the reference,xyz>>
      <<iso216,whole,clause=3,example=9-11,locality:prelude=33,locality:entirety="the reference";whole,clause=3,example=9-11,locality:prelude=33,locality:entirety:the reference,xyz>>
      <<iso216,_whole_>>
      <<iso216,a _whole_ flagon>>
      <<iso216,whole,clause=3,a _whole_ flagon>>
      <<iso216,droploc%capital%whole,clause=3,a _whole_ flagon>>

      [bibliography]
      == Normative References
      * [[[iso216,ISO 216]]], _Reference_
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
            <preface><foreword id="_" obligation="informative">
              <title>Foreword</title>
              <p id="_">
              <eref type="inline" bibitemid="iso216" citeas="ISO 216">
              <localityStack>
              <locality type="whole"/><locality type="clause"><referenceFrom>3</referenceFrom></locality><locality type="example"><referenceFrom>9</referenceFrom><referenceTo>11</referenceTo></locality><locality type="locality:prelude"><referenceFrom>33 a</referenceFrom></locality><locality type="locality:entirety"/>
              </localityStack>
              the reference,xyz</eref>
       <eref type='inline' bibitemid='iso216' citeas='ISO 216'>
         <localityStack>
           <locality type='whole'/>
           <locality type='clause'>
             <referenceFrom>3</referenceFrom>
           </locality>
           <locality type='example'>
             <referenceFrom>9</referenceFrom>
             <referenceTo>11</referenceTo>
           </locality>
           <locality type='locality:prelude'>
             <referenceFrom>33</referenceFrom>
           </locality>
           <locality type='locality:entirety'>
           <referenceFrom>the reference</referenceFrom>
           </locality>
         </localityStack>
         <localityStack>
           <locality type='whole'/>
           <locality type='clause'>
             <referenceFrom>3</referenceFrom>
           </locality>
           <locality type='example'>
             <referenceFrom>9</referenceFrom>
             <referenceTo>11</referenceTo>
           </locality>
           <locality type='locality:prelude'>
             <referenceFrom>33</referenceFrom>
           </locality>
           <locality type='locality:entirety'/>
         </localityStack>
         the reference,xyz
       </eref>
      <eref type='inline' bibitemid='iso216' citeas='ISO 216'>
        <em>whole</em>
      </eref>
      <eref type='inline' bibitemid='iso216' citeas='ISO 216'>
        a
        <em>whole</em>
         flagon
      </eref>
      <eref type='inline' bibitemid='iso216' citeas='ISO 216'>
        <localityStack>
          <locality type='whole'/>
          <locality type='clause'>
            <referenceFrom>3</referenceFrom>
          </locality>
        </localityStack>
        a
        <em>whole</em>
         flagon
      </eref>
      <eref type='inline' case='capital' droploc='true' bibitemid='iso216' citeas='ISO 216'>
        <localityStack>
          <locality type='whole'/>
          <locality type='clause'>
            <referenceFrom>3</referenceFrom>
          </locality>
        </localityStack>
        a
        <em>whole</em>
         flagon
      </eref>
              </p>
            </foreword></preface><sections>
            </sections><bibliography><references id="_" obligation="informative" normative="true">
              <title>Normative references</title>
              #{NORM_REF_BOILERPLATE}
              <bibitem id="iso216" type="standard">
               <title format="text/plain">Reference</title>
               <docidentifier>ISO 216</docidentifier>
               <docnumber>216</docnumber>
               <contributor>
                 <role type="publisher"/>
                 <organization>
                   <name>ISO</name>
                 </organization>
               </contributor>
             </bibitem>
            </references>
            </bibliography>
            </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "strips type from xrefs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      <<iso216>>

      [bibliography]
      == Clause
      * [[[iso216,ISO 216]]], _Reference_
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
             <preface>
             <foreword id="_" obligation="informative">
               <title>Foreword</title>
               <p id="_">
               <eref type="inline" bibitemid="iso216" citeas="ISO 216"/>
             </p>
             </foreword></preface><sections>
             </sections><bibliography><references id="_" obligation="informative" normative="false">
        <title>Bibliography</title>
        <bibitem id="iso216" type="standard">
        <title format="text/plain">Reference</title>
        <docidentifier>ISO 216</docidentifier>
               <docnumber>216</docnumber>
        <contributor>
          <role type="publisher"/>
          <organization>
            <name>ISO</name>
          </organization>
        </contributor>
      </bibitem>
      </references></bibliography>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes localities in term sources" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      [.source]
      <<ISO2191,section=1>>
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
      <sections>
        <terms id="_" obligation="normative">
        <title>Terms and definitions</title>
        <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
        <term id="term-term1">
        <preferred>Term1</preferred>
        <termsource status="identical">
        <origin bibitemid="ISO2191" type="inline" citeas="">
        <localityStack>
       <locality type="section"><referenceFrom>1</referenceFrom></locality>
       </localityStack>
       </origin>
      </termsource>
      </term>
      </terms>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "inserts IDs into paragraphs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      Paragraph
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
        <p id="_">Paragraph</p>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "inserts IDs into notes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [example]
      ====
      NOTE: This note has no ID
      ====
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
        <example id="_">
        <note id="_">
        <p id="_">This note has no ID</p>
      </note>
      </example>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "moves table key inside table" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      |===
      |a |b |c
      |===

      Key

      a:: b

      |===
      |a |b |c
      |===

      [%key]
      a:: b

      |===
      |a |b |c
      |===

      a:: b
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
          <table id='_'>
            <tbody>
              <tr>
                <td valign='top' align='left'>a</td>
                <td valign='top' align='left'>b</td>
                <td valign='top' align='left'>c</td>
              </tr>
            </tbody>
            <dl id='_' key='true'>
              <dt>a</dt>
              <dd>
                <p id='_'>b</p>
              </dd>
            </dl>
          </table>
          <table id='_'>
            <tbody>
              <tr>
                <td valign='top' align='left'>a</td>
                <td valign='top' align='left'>b</td>
                <td valign='top' align='left'>c</td>
              </tr>
            </tbody>
            <dl id='_' key='true'>
              <dt>a</dt>
              <dd>
                <p id='_'>b</p>
              </dd>
            </dl>
          </table>
          <table id='_'>
            <tbody>
              <tr>
                <td valign='top' align='left'>a</td>
                <td valign='top' align='left'>b</td>
                <td valign='top' align='left'>c</td>
              </tr>
            </tbody>
          </table>
          <dl id='_'>
            <dt>a</dt>
            <dd>
              <p id='_'>b</p>
            </dd>
          </dl>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes headerrows attribute for table without header rows" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [headerrows=3]
      |===
      |a |b |c
      |a |b |c
      |a |b |c
      |a |b |c
      |===
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
            <table id="_"><thead><tr>
            <th valign="top" align="left">a</th>
            <th valign="top" align="left">b</th>
            <th valign="top" align="left">c</th>
          </tr><tr>
            <th valign="top" align="left">a</th>
            <th valign="top" align="left">b</th>
            <th valign="top" align="left">c</th>
          </tr><tr>
            <th valign="top" align="left">a</th>
            <th valign="top" align="left">b</th>
            <th valign="top" align="left">c</th>
          </tr></thead>
        <tbody>
          <tr>
            <td valign="top" align="left">a</td>
            <td valign="top" align="left">b</td>
            <td valign="top" align="left">c</td>
          </tr>
        </tbody>
      </table>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes headerrows attribute for table with header rows" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [headerrows=3]
      |===
      |a |b |c

      |a |b |c
      |a |b |c
      |a |b |c
      |===
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
        <table id="_">
        <thead>
          <tr>
            <th valign="top" align="left">a</th>
            <th valign="top" align="left">b</th>
            <th valign="top" align="left">c</th>
          </tr>
        <tr>
            <th valign="top" align="left">a</th>
            <th valign="top" align="left">b</th>
            <th valign="top" align="left">c</th>
          </tr><tr>
            <th valign="top" align="left">a</th>
            <th valign="top" align="left">b</th>
            <th valign="top" align="left">c</th>
          </tr></thead>
        <tbody>


          <tr>
            <td valign="top" align="left">a</td>
            <td valign="top" align="left">b</td>
            <td valign="top" align="left">c</td>
          </tr>
        </tbody>
      </table>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "moves table notes inside table" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      |===
      |a |b |c
      |===

      NOTE: Note 1

      NOTE: Note 2
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections><table id="_">
        <tbody>
          <tr>
            <td valign="top" align="left">a</td>
            <td valign="top" align="left">b</td>
            <td valign="top" align="left">c</td>
          </tr>
        </tbody>
      <note id="_">
        <p id="_">Note 1</p>
      </note><note id="_">
        <p id="_">Note 2</p>
      </note></table>

      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "moves formula key inside formula" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [stem]
      ++++
      Formula
      ++++

      Where,

      a:: b

      [stem]
      ++++
      Formula
      ++++

      [%key]
      a:: b

      [stem]
      ++++
      Formula
      ++++

      a:: b
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
          <formula id='_'>
            <stem type='MathML'>
              <math xmlns='http://www.w3.org/1998/Math/MathML'>
                <mi>F</mi>
                <mi>or</mi>
                <mi>μ</mi>
                <mi>l</mi>
                <mi>a</mi>
              </math>
            </stem>
            <dl id='_' key='true'>
              <dt>a</dt>
              <dd>
                <p id='_'>b</p>
              </dd>
            </dl>
          </formula>
          <formula id='_'>
            <stem type='MathML'>
              <math xmlns='http://www.w3.org/1998/Math/MathML'>
                <mi>F</mi>
                <mi>or</mi>
                <mi>μ</mi>
                <mi>l</mi>
                <mi>a</mi>
              </math>
            </stem>
            <dl id='_' key='true'>
              <dt>a</dt>
              <dd>
                <p id='_'>b</p>
              </dd>
            </dl>
          </formula>
          <formula id='_'>
            <stem type='MathML'>
              <math xmlns='http://www.w3.org/1998/Math/MathML'>
                <mi>F</mi>
                <mi>or</mi>
                <mi>μ</mi>
                <mi>l</mi>
                <mi>a</mi>
              </math>
            </stem>
          </formula>
          <dl id='_'>
            <dt>a</dt>
            <dd>
              <p id='_'>b</p>
            </dd>
          </dl>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "moves footnotes inside figures" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      .Figuretitle.footnote:[xyz]
      image::spec/examples/rice_images/rice_image1.png[]

      footnote:[This is a footnote to a figure]

      footnote:[This is another footnote to a figure]

      A footnote:[This is a third footnote]
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections><figure id="_">
             <name>
        Figuretitle.
        <fn reference='1'>
          <p id='_'>xyz</p>
        </fn>
      </name>
               <image src="spec/examples/rice_images/rice_image1.png" id="_" mimetype="image/png" height="auto" width="auto"/>
             <fn reference="a">
               <p id="_">This is a footnote to a figure</p>
             </fn><fn reference="b">
               <p id="_">This is another footnote to a figure</p>
             </fn></figure>
             <p id='_'>
        A
        <fn reference='2'>
          <p id='_'>This is a third footnote</p>
        </fn>
      </p>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "moves figure key inside figure" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      image::spec/examples/rice_images/rice_image1.png[]

      key:

      a:: b

      image::spec/examples/rice_images/rice_image1.png[]

      [%key]
      a:: b

      image::spec/examples/rice_images/rice_image1.png[]

      a:: b
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
          <figure id='_'>
            <image src='spec/examples/rice_images/rice_image1.png' id='_' mimetype='image/png' height='auto' width='auto'/>
            <dl id='_' key='true'>
              <dt>a</dt>
              <dd>
                <p id='_'>b</p>
              </dd>
            </dl>
          </figure>
          <figure id='_'>
            <image src='spec/examples/rice_images/rice_image1.png' id='_' mimetype='image/png' height='auto' width='auto'/>
            <dl id='_' key='true'>
              <dt>a</dt>
              <dd>
                <p id='_'>b</p>
              </dd>
            </dl>
          </figure>
          <figure id='_'>
            <image src='spec/examples/rice_images/rice_image1.png' id='_' mimetype='image/png' height='auto' width='auto'/>
          </figure>
          <dl id='_'>
            <dt>a</dt>
            <dd>
              <p id='_'>b</p>
            </dd>
          </dl>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes subfigures" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [[figureC-2]]
      .Stages of gelatinization
      ====
      .Initial stages: No grains are fully gelatinized (ungelatinized starch granules are visible inside the kernels)
      image::spec/examples/rice_images/rice_image3_1.png[]

      .Intermediate stages: Some fully gelatinized kernels are visible
      image::spec/examples/rice_images/rice_image3_2.png[]

      .Final stages: All kernels are fully gelatinized
      image::spec/examples/rice_images/rice_image3_3.png[]
      ====
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections>
        <figure id="figureC-2"><name>Stages of gelatinization</name><figure id="_">
        <name>Initial stages: No grains are fully gelatinized (ungelatinized starch granules are visible inside the kernels)</name>
        <image src="spec/examples/rice_images/rice_image3_1.png" id="_" mimetype="image/png" height="auto" width="auto"/>
      </figure>
      <figure id="_">
        <name>Intermediate stages: Some fully gelatinized kernels are visible</name>
        <image src="spec/examples/rice_images/rice_image3_2.png" id="_" mimetype="image/png" height="auto" width="auto"/>
      </figure>
      <figure id="_">
        <name>Final stages: All kernels are fully gelatinized</name>
        <image src="spec/examples/rice_images/rice_image3_3.png" id="_" mimetype="image/png" height="auto" width="auto"/>
      </figure></figure>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "numbers bibliographic notes and footnotes sequentially" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      footnote:[Footnote]

      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:--]]] footnote:[The standard is in press] _Standard_

      == Clause
      footnote:[Footnote2]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <preface><foreword id="_" obligation="informative">
        <title>Foreword</title>
        <p id="_"><fn reference="1">
        <p id="_">Footnote</p>
      </fn>
      </p>
      </foreword></preface><sections>

      <clause id="_" inline-header="false" obligation="normative">
        <title>Clause</title>
        <p id="_"><fn reference="2">
        <p id="_">Footnote2</p>
      </fn>
      </p>
      </clause></sections><bibliography><references id="_" obligation="informative" normative="true">
        <title>Normative references</title>
        #{NORM_REF_BOILERPLATE}
        <bibitem id="iso123" type="standard">
         <title format="text/plain">Standard</title>
         <docidentifier>ISO 123:—</docidentifier>
         <docnumber>123</docnumber>
         <date type="published">
           <on>–</on>
         </date>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>ISO</name>
           </organization>
         </contributor>
         <note format="text/plain" type="Unpublished-Status">The standard is in press</note>
       </bibitem>
      </references>
      </bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "rearranges term note, term example, term source" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Terms and definitions

      === Term

      [.source]
      <<ISO2191,section=1>>

      NOTE: Note

      [example]
      Example 1

      NOTE: Note 2

      [example]
      Example 2
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
      <terms id="_" obligation="normative">
        <title>Terms and definitions</title>
        <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
        <term id="term-term"><preferred>Term</preferred>



      <termnote id="_">
        <p id="_">Note</p>
      </termnote><termnote id="_">
        <p id="_">Note 2</p>
      </termnote><termexample id="_">
        <p id="_">Example 1</p>
      </termexample><termexample id="_">
        <p id="_">Example 2</p>
      </termexample><termsource status="identical">
        <origin bibitemid="ISO2191" type="inline" citeas="">
        <localityStack>
       <locality type="section"><referenceFrom>1</referenceFrom></locality>
        </localityStack>
       </origin>
      </termsource></term>
      </terms>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "separates IEV citations by top-level clause" do
    FileUtils.rm_rf File.expand_path("~/.relaton-bib.pstore1")
    FileUtils.mv File.expand_path("~/.relaton/cache"),
                 File.expand_path("~/.relaton-bib.pstore1"), force: true
    FileUtils.rm_rf File.expand_path("~/.iev.pstore1")
    FileUtils.mv File.expand_path("~/.iev.pstore"),
                 File.expand_path("~/.iev.pstore1"), force: true
    FileUtils.rm_rf "relaton/cache"
    FileUtils.rm_rf "test.iev.pstore"
    # mock_iecbib_get_iec60050_102_01
    # mock_iecbib_get_iec60050_103_01
    # mock_iev
    VCR.use_cassette "separates_iev_citations_by_top_level_clause" do
      input = <<~INPUT
        #{CACHED_ISOBIB_BLANK_HDR}

        [bibliography]
        == Normative References
        * [[[iev,IEV]]], _iev_

        == Terms and definitions
        === Automation1

        [.source]
        <<iev,clause="103-01-02">>

        === Automation2

        [.source]
        <<iev,clause="102-01-02">>

        === Automation3

        [.source]
        <<iev,clause="103-01-02">>
      INPUT
      output = <<~OUTPUT
          #{BLANK_HDR}
          <sections>
        <terms id="_" obligation="normative"><title>Terms and definitions</title>
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
         <term id="term-automation1">
          <preferred>Automation1</preferred>
          <termsource status="identical">
          <origin bibitemid="IEC60050-103" type="inline" citeas="IEC 60050-103:2009">
          <localityStack>
        <locality type="clause"><referenceFrom>103-01-02</referenceFrom></locality>
          </localityStack>
        </origin>
        </termsource>
        </term>
        <term id="term-automation2">
          <preferred>Automation2</preferred>
          <termsource status="identical">
          <origin bibitemid="IEC60050-102" type="inline" citeas="IEC 60050-102:2007">
          <localityStack>
        <locality type="clause"><referenceFrom>102-01-02</referenceFrom></locality>
          </localityStack>
        </origin>
        </termsource>
        </term>
        <term id="term-automation3">
          <preferred>Automation3</preferred>
          <termsource status="identical">
          <origin bibitemid="IEC60050-103" type="inline" citeas="IEC 60050-103:2009">
          <localityStack>
        <locality type="clause"><referenceFrom>103-01-02</referenceFrom></locality>
          </localityStack>
        </origin>
        </termsource>
        </term></terms></sections><bibliography><references id="_" obligation="informative" normative="true">
          <title>Normative references</title>
        #{NORM_REF_BOILERPLATE}
          <bibitem type="standard" id="IEC60050-102">
          <fetched>#{Date.today}</fetched>
          <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
          <title type="title-part" format="text/plain" language="en" script="Latn">Part 102: Mathematics — General concepts and linear algebra</title>
          <title type='main' format='text/plain' language='en' script='Latn'>International Electrotechnical Vocabulary (IEV) — Part 102: Mathematics — General concepts and linear algebra</title>
          <uri type="src">https://webstore.iec.ch/publication/160</uri>
          <uri type="obp">/preview/info_iec60050-102%7Bed1.0%7Db.pdf</uri>
          <docidentifier type="IEC">IEC 60050-102:2007</docidentifier>
          <docidentifier type='URN'>urn:iec:std:iec:60050-102:2007:::en</docidentifier>
          <date type="published">
            <on>2007-08-27</on>
          </date>
          <contributor>
            <role type="publisher"/>
            <organization>
              <name>International Electrotechnical Commission</name>
              <abbreviation>IEC</abbreviation>
              <uri>www.iec.ch</uri>
            </organization>
          </contributor>
          <edition>1.0</edition>
          <language>en</language>
          <script>Latn</script>
          <abstract format="text/plain" language="en" script="Latn">This part of IEC 60050 gives the general mathematical terminology used in the fields of electricity, electronics and telecommunications, together with basic concepts in linear algebra. It maintains a clear distinction between mathematical concepts and physical concepts, even if some terms are used in both cases. Another part will deal with functions.&#13; It has the status of a horizontal standard in accordance with IEC Guide 108.</abstract>
          <status>
            <stage>60</stage>
            <substage>60</substage>
          </status>
          <copyright>
            <from>2007</from>
            <owner>
              <organization>
              <name>International Electrotechnical Commission</name>
              <abbreviation>IEC</abbreviation>
              <uri>www.iec.ch</uri>
              </organization>
            </owner>
          </copyright>
          <place>Geneva</place>
        </bibitem><bibitem type="standard" id="IEC60050-103">
          <fetched>#{Date.today}</fetched>
          <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
          <title type="title-part" format="text/plain" language="en" script="Latn">Part 103: Mathematics — Functions</title>
          <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) — Part 103: Mathematics — Functions</title>
          <uri type="src">https://webstore.iec.ch/publication/161</uri>
          <uri type="obp">/preview/info_iec60050-103%7Bed1.0%7Db.pdf</uri>
          <docidentifier type="IEC">IEC 60050-103:2009</docidentifier>
          <docidentifier type='URN'>urn:iec:std:iec:60050-103:2009:::en</docidentifier>
          <date type="published">
            <on>2009-12-14</on>
          </date>
          <contributor>
            <role type="publisher"/>
            <organization>
            <name>International Electrotechnical Commission</name>
        <abbreviation>IEC</abbreviation>
        <uri>www.iec.ch</uri>
            </organization>
          </contributor>
          <edition>1.0</edition>
          <language>en</language>
          <script>Latn</script>
          <abstract format="text/plain" language="en" script="Latn">IEC 60050-103:2009 gives the terminology relative to functions of one or more variables. Together with IEC 60050-102, it covers the mathematical terminology used in the fields of electricity, electronics and telecommunications. It maintains a clear distinction between mathematical concepts and physical concepts, even if some terms are used in both cases. Mathematical symbols are generally in accordance with IEC 60027-1 and ISO 80000-2. This standard cancels and replaces Sections 101-13, 101-14 and 101-15 of International Standard IEC 60050-101:1998. It has the status of a horizontal standard in accordance with IEC Guide 108.</abstract>
          <status>
            <stage>60</stage>
            <substage>60</substage>
          </status>
          <copyright>
            <from>2009</from>
            <owner>
              <organization>
              <name>International Electrotechnical Commission</name>
        <abbreviation>IEC</abbreviation>
        <uri>www.iec.ch</uri>
              </organization>
            </owner>
          </copyright>
          <place>Geneva</place>
        </bibitem>
        </references></bibliography>
        </standard-document>
      OUTPUT
      expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
        .to be_equivalent_to xmlpp(output)
    end
    FileUtils.rm_rf File.expand_path("~/.iev.pstore")
    FileUtils.mv File.expand_path("~/.iev.pstore1"),
                 File.expand_path("~/.iev.pstore"), force: true
    FileUtils.rm_rf File.expand_path("~/.relaton/cache")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"),
                 File.expand_path("~/.relaton/cache"), force: true
  end

  it "counts footnotes with link-only content as separate footnotes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      footnote:[http://www.example.com]

      footnote:[http://www.example.com]

      footnote:[http://www.example1.com]
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections><p id="_"><fn reference="1">
        <p id="_">
          <link target="http://www.example.com"/>
        </p>
      </fn>
      </p>
      <p id="_"><fn reference="1">
        <p id="_">
          <link target="http://www.example.com"/>
        </p>
      </fn>
      </p>
      <p id="_"><fn reference="2">
        <p id="_">
          <link target="http://www.example1.com"/>
        </p>
      </fn>
      </p></sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "retains AsciiMath on request" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :mn-keep-asciimath:

      stem:[1/r]
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections>
        <p id="_">
        <stem type="AsciiMath">1/r</stem>
      </p>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "converts AsciiMath to MathML by default" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:

      stem:[1/r]
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections>
               <p id="_">
               <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mfrac>
      <mrow>
        <mn>1</mn>
      </mrow>
      <mrow>
        <mi>r</mi>
      </mrow>
      </mfrac></math></stem>
             </p>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "cleans up text MathML" do
    input = <<~INPUT
      #{BLANK_HDR}
      <sections>
      <stem type="MathML">&lt;math xmlns="http://www.w3.org/1998/Math/MathML"&gt;&lt;mfrac&gt;&lt;mn&gt;1&lt;/mn&gt;&lt;mi&gt;r&lt;/mi&gt;&lt;/mfrac&gt;&lt;/math&gt;</stem>
      </sections>
      </standard-document>
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
      <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mfrac><mn>1</mn><mi>r</mi></mfrac></math></stem>
      </sections>
      </standard-document>
    OUTPUT
    expect(Asciidoctor::Standoc::Converter.new(nil, *OPTIONS)
      .cleanup(Nokogiri::XML(input)).to_xml)
      .to be_equivalent_to xmlpp(output)
  end

  it "removes nested bibitem IDs" do
    input = <<~INPUT
      #{BLANK_HDR}
      <bibliography>
        <references normative="true"><title>Normative</title>
        <bibitem id="A">
          <relation type="includes">
            <bibitem id="B"/>
          </relation>
        </bibitem>
      </bibliography>
      </standard-document>
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <bibliography>
        <references normative="true"><title>Normative</title>
        <bibitem id="A">
          <relation type="includes">
            <bibitem id="B"/>
          </relation>
        </bibitem>
      </references>
      </bibliography>
      </standard-document>
    OUTPUT
    expect(Asciidoctor::Standoc::Converter.new(nil, *OPTIONS)
      .cleanup(Nokogiri::XML(input)).to_xml)
      .to be_equivalent_to xmlpp(output)
  end

  it "renumbers numeric references in Bibliography sequentially" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause
      <<iso123>>
      <<iso124>>

      [bibliography]
      == Bibliography

      * [[[iso124,ISO 124]]] _Standard 124_
      * [[[iso123,1]]] _Standard 123_
    INPUT
    output = <<~OUTPUT
          #{BLANK_HDR}
      <sections><clause id="_" inline-header="false" obligation="normative">
        <title>Clause</title>
        <p id="_"><eref type="inline" bibitemid="iso123" citeas="[2]"/>
      <eref type="inline" bibitemid="iso124" citeas="ISO 124"/></p>
      </clause>
      </sections><bibliography><references id="_" obligation="informative" normative="false">
        <title>Bibliography</title>
        <bibitem id="iso124" type="standard">
        <title format="text/plain">Standard 124</title>
        <docidentifier>ISO 124</docidentifier>
        <docnumber>124</docnumber>
        <contributor>
          <role type="publisher"/>
          <organization>
            <name>ISO</name>
          </organization>
        </contributor>
      </bibitem>
        <bibitem id="iso123">
        <formattedref format="application/x-isodoc+xml">
          <em>Standard 123</em>
        </formattedref>
        <docidentifier type="metanorma">[2]</docidentifier>
      </bibitem>
      </references></bibliography>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "renumbers numeric references in Bibliography subclauses sequentially" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause
      <<iso123>>
      <<iso124>>
      <<iso125>>
      <<iso126>>

      [bibliography]
      == Bibliography

      [bibliography]
      === Clause 1
      * [[[iso124,ISO 124]]] _Standard 124_
      * [[[iso123,1]]] _Standard 123_

      [bibliography]
      === {blank}
      * [[[iso125,ISO 125]]] _Standard 124_
      * [[[iso126,1]]] _Standard 123_

      [bibliography]
      == Bibliography Redux

      [bibliography]
      === Clause 1
      * [[[iso127,ISO 124]]] _Standard 124_
      * [[[iso128,1]]] _Standard 123_

    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
        <sections><clause id="_" inline-header="false" obligation="normative">
             <title>Clause</title>
             <p id="_"><eref type="inline" bibitemid="iso123" citeas="[2]"/>
           <eref type="inline" bibitemid="iso124" citeas="ISO 124"/>
           <eref type="inline" bibitemid="iso125" citeas="ISO 125"/>
           <eref type="inline" bibitemid="iso126" citeas="[4]"/></p>
           </clause>
           </sections><bibliography><clause id="_" obligation="informative"><title>Bibliography</title><references id="_" obligation="informative" normative="false">
             <title>Clause 1</title>
             <bibitem id="iso124" type="standard">
             <title format="text/plain">Standard 124</title>
             <docidentifier>ISO 124</docidentifier>
             <docnumber>124</docnumber>
             <contributor>
               <role type="publisher"/>
               <organization>
                 <name>ISO</name>
               </organization>
             </contributor>
           </bibitem>
             <bibitem id="iso123">
             <formattedref format="application/x-isodoc+xml">
               <em>Standard 123</em>
             </formattedref>
             <docidentifier type="metanorma">[2]</docidentifier>
           </bibitem>
           </references>
           <references id="_" obligation="informative" normative="false">
             <bibitem id="iso125" type="standard">
             <title format="text/plain">Standard 124</title>
             <docidentifier>ISO 125</docidentifier>
             <docnumber>125</docnumber>
             <contributor>
               <role type="publisher"/>
               <organization>
                 <name>ISO</name>
               </organization>
             </contributor>
           </bibitem>
             <bibitem id="iso126">
             <formattedref format="application/x-isodoc+xml">
               <em>Standard 123</em>
             </formattedref>
             <docidentifier type="metanorma">[4]</docidentifier>
           </bibitem>
        </references>
      </clause>
      <clause id='_' obligation='informative'>
        <title>Bibliography Redux</title>
        <references id='_' normative='false' obligation='informative'>
          <title>Clause 1</title>
          <bibitem id='iso127' type='standard'>
            <title format='text/plain'>Standard 124</title>
            <docidentifier>ISO 124</docidentifier>
            <docnumber>124</docnumber>
            <contributor>
              <role type='publisher'/>
              <organization>
                <name>ISO</name>
              </organization>
            </contributor>
          </bibitem>
          <bibitem id='iso128'>
            <formattedref format='application/x-isodoc+xml'>
              <em>Standard 123</em>
            </formattedref>
            <docidentifier type='metanorma'>[6]</docidentifier>
          </bibitem>
           </references></clause></bibliography>
           </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "removes bibdata bibitem IDs" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :translated-from: IEC 60050-102

      [bibliography]
      == Normative References

    INPUT
    output = <<~OUTPUT
          <?xml version='1.0' encoding='UTF-8'?>
      <standard-document xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}">
        <bibdata type='standard'>
          <title language='en' format='text/plain'>Document title</title>
          <language>en</language>
          <script>Latn</script>
          <status>
            <stage>published</stage>
          </status>
          <copyright>
            <from>#{Date.today.year}</from>
          </copyright>
          <relation type='translatedFrom'>
            <bibitem>
              <title>--</title>
              <docidentifier>IEC 60050-102</docidentifier>
            </bibitem>
          </relation>
          <ext>
            <doctype>article</doctype>
          </ext>
        </bibdata>
        <sections> </sections>
        <bibliography>
          <references id='_' obligation='informative' normative="true">
            <title>Normative references</title>
            <p id="_">There are no normative references in this document.</p>
          </references>
        </bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "imports boilerplate file" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :docstage: 10
      :boilerplate-authority: spec/assets/boilerplate.xml

      == Clause 1

    INPUT
    output = <<~OUTPUT
          <standard-document xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}">
        <bibdata type='standard'>
          <title language='en' format='text/plain'>Document title</title>
          <language>en</language>
          <script>Latn</script>
          <status>
            <stage>10</stage>
          </status>
          <copyright>
            <from>#{Date.today.year}</from>
          </copyright>
          <ext>
            <doctype>article</doctype>
          </ext>
        </bibdata>
        <boilerplate>
          <text>10</text>
        </boilerplate>
        <sections>
          <clause id='_' inline-header='false' obligation='normative'>
            <title>Clause 1</title>
          </clause>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "sorts symbols lists #1" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[L]]
      == Symbols and abbreviated terms

      α:: Definition 1
      Xa:: Definition 2
      x_1_:: Definition 3
      x_m_:: Definition 4
      x:: Definition 5
      stem:[n]:: Definition 6
      m:: Definition 7
    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
        <sections>
          <definitions id='L' obligation="normative">
            <title>Symbols and abbreviated terms</title>
            <dl id='_'>
            <dt id="symbol-m">m</dt>
      <dd>
        <p id='_'>Definition 7</p>
      </dd>
      <dt id="symbol-_-n-">
        <stem type='MathML'>
          <math xmlns='http://www.w3.org/1998/Math/MathML'>
            <mi>n</mi>
          </math>
        </stem>
      </dt>
      <dd>
        <p id='_'>Definition 6</p>
      </dd>
              <dt id="symbol-x">x</dt>
              <dd>
                <p id='_'>Definition 5</p>
              </dd>
              <dt  id='symbol-x_m_'>x_m_</dt>
              <dd>
                <p id='_'>Definition 4</p>
              </dd>
              <dt id='symbol-x_1_'>x_1_</dt>
              <dd>
                <p id='_'>Definition 3</p>
              </dd>
              <dt id='symbol-xa'>Xa</dt>
              <dd>
                <p id='_'>Definition 2</p>
              </dd>
              <dt  id='symbol-&#945;'>α</dt>
              <dd>
                <p id='_'>Definition 1</p>
              </dd>
            </dl>
          </definitions>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "sorts symbols lists #2" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[L]]
      == Symbols and abbreviated terms

      stem:[alpha]:: Definition 1
      xa:: Definition 2
      stem:[x_1]:: Definition 3
      stem:[x_m]:: Definition 4
      x:: Definition 5
    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
        <sections>
          <definitions id='L' obligation="normative">
            <title>Symbols and abbreviated terms</title>
            <dl id='_'>
              <dt  id='symbol-x'>x</dt>
              <dd>
                <p id='_'>Definition 5</p>
              </dd>
              <dt  id='symbol-_-xm-'><stem type='MathML'>
              <math xmlns='http://www.w3.org/1998/Math/MathML'>
        <msub>
          <mrow>
        <mi>x</mi>
      </mrow>
      <mrow>
        <mi>m</mi>
      </mrow>
        </msub>
      </math>
              </stem></dt>
              <dd>
                <p id='_'>Definition 4</p>
              </dd>
              <dt  id='symbol-_-x1-'><stem type='MathML'>
               <math xmlns='http://www.w3.org/1998/Math/MathML'>
         <msub>
           <mrow>
        <mi>x</mi>
      </mrow>
      <mrow>
        <mn>1</mn>
      </mrow>
         </msub>
       </math>
              </stem></dt>
              <dd>
                <p id='_'>Definition 3</p>
              </dd>
              <dt  id='symbol-xa'>xa</dt>
              <dd>
                <p id='_'>Definition 2</p>
              </dd>
              <dt  id='symbol-_-&#945;-'>
              <stem type='MathML'>
        <math xmlns='http://www.w3.org/1998/Math/MathML'>
          <mi>α</mi>
        </math>
      </stem>
              </dt>
              <dd>
                <p id='_'>Definition 1</p>
              </dd>
            </dl>
          </definitions>
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


    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
        <sections>
          <clause id='_' inline-header='false' obligation='normative'>
            <title>Clause</title>
            <requirement id='_' subsequence='A'>
              <title>Title</title>
              <inherit>/ss/584/2015/level/1 &amp; /ss/584/2015/level/2</inherit>
              <inherit>A</inherit>
              <inherit>B</inherit>
              <description>
                <p id='_'> I recommend this</p>
              </description>
            </requirement>
            <requirement id='_' subsequence='A'>
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
            <requirement id='_' subsequence='A'>
              <title>Title</title>
              <inherit>A</inherit>
              <description>
                <p id='_'> I recommend this</p>
              </description>
            </requirement>
            <requirement id='_' subsequence='A'>
              <title>Title</title>
              <inherit>A</inherit>
              <description>
                <p id='_'> </p>
              </description>
            </requirement>
          </clause>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "moves %beforeclause admonitions to right position" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      .Foreword
      Foreword

      [NOTE,beforeclauses=true]
      ====
      Note which is very important
      ====

      == Introduction
      Introduction

      == Scope
      Scope statement

      [IMPORTANT,beforeclauses=true]
      ====
      Notice which is very important
      ====
    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
        <preface>
          <note id='_'>
            <p id='_'>Note which is very important</p>
          </note>
          <foreword id='_' obligation='informative'>
            <title>Foreword</title>
            <p id='_'>Foreword</p>
          </foreword>
          <introduction id='_' obligation='informative'>
            <title>Introduction</title>
            <p id='_'>Introduction</p>
          </introduction>
        </preface>
        <sections>
          <admonition id='_' type='important'>
            <p id='_'>Notice which is very important</p>
          </admonition>
          <clause id='_' inline-header='false' obligation='normative' type="scope">
            <title>Scope</title>
            <p id='_'>Scope statement</p>
          </clause>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "fixes illegal anchors" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[a:b]]
      == A
      <</:ab>>
      <<:>>
      <<1>>
      <<1:>>
      <<1#b>>
      <<:a#b:>>
      <</%ab>>
      <<1!>>
    INPUT
    output = <<~OUTPUT
      <standard-document xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}">
        <bibdata type='standard'>
          <title language='en' format='text/plain'>Document title</title>
          <language>en</language>
          <script>Latn</script>
          <status>
            <stage>published</stage>
          </status>
          <copyright>
            <from>#{Time.now.year}</from>
          </copyright>
          <ext>
            <doctype>article</doctype>
          </ext>
        </bibdata>
        <sections>
        <clause id='a_b' inline-header='false' obligation='normative'>
                   <title>A</title>
                   <eref bibitemid='__ab' citeas=''/>
                   <xref target='_'/>
                   <xref target='_1'/>
                   <xref target='_1_'/>
                   <xref target='1#b'/>
                   <xref target='_a#b_'/>
                   <xref target='_%ab'/>
                   <xref target='_1_'/>
                 </clause>
        </sections>
        <bibliography>
        <references hidden='true' normative='false'>
          <bibitem id='__ab' type='internal'>
            <docidentifier type='repository'>//ab</docidentifier>
          </bibitem>
        </references>
      </bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(Asciidoctor.convert(input, *OPTIONS)
      .gsub(/<p id="_[^"]+">/, "").gsub("</p>", "")))
      .to be_equivalent_to(output)
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{normalised identifier in <clause id="a_b" inline-header="false" obligation="normative"/> from a:b})
      .to_stderr
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{normalised identifier in <eref bibitemid="__ab" citeas=""/> from /_ab})
      .to_stderr
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{normalised identifier in <xref target="_"/> from :})
      .to_stderr
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{normalised identifier in <xref target="_1"/> from 1})
      .to_stderr
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{normalised identifier in <xref target="_1_"/> from 1:})
      .to_stderr
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{normalised identifier in <xref target="_a#b_"/> from :a#b:})
      .to_stderr
  end

  it "moves title footnotes to bibdata" do
    input = <<~INPUT
      = Document title footnote:[ABC] footnote:[DEF]
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:

    INPUT
    output = <<~OUTPUT
      <standard-document xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}">
               <bibdata type='standard'>
                 <title language='en' format='text/plain'>Document title</title>
                 <note type='title-footnote'>
                   <p>ABC</p>
                 </note>
                 <note type='title-footnote'>
                   <p>DEF</p>
                 </note>
                 <language>en</language>
                 <script>Latn</script>
                 <status>
                   <stage>published</stage>
                 </status>
                 <copyright>
                   <from>#{Time.now.year}</from>
                 </copyright>
                 <ext>
                   <doctype>article</doctype>
                 </ext>
               </bibdata>
               <sections> </sections>
               </standard-document>
    OUTPUT
    expect(xmlpp(Asciidoctor.convert(input, *OPTIONS)))
      .to be_equivalent_to xmlpp(output)
  end

  it "converts UnitsML to MathML" do
    input = <<~INPUT
      = Document title
      Author
      :stem:

      [stem]
      ++++
      <math xmlns='http://www.w3.org/1998/Math/MathML'>
        <mrow>
        <mn>7</mn>
        <mtext>unitsml(m*kg^-2)</mtext>
        <mo>+</mo>
        <mn>8</mn>
        <mtext>unitsml(m*kg^-2)</mtext>
        </mrow>
      </math>
      ++++
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <misc-container>
           <UnitsML xmlns='https://schema.unitsml.org/unitsml/1.0'>
             <UnitSet>
               <Unit xml:id='U_m.kg-2' dimensionURL='#D_LM-2'>
                 <UnitSystem name='SI' type='SI_derived' xml:lang='en-US'/>
                 <UnitName xml:lang='en'>m*kg^-2</UnitName>
                 <UnitSymbol type='HTML'>
                   m&#160;kg
                   <sup>&#8722;2</sup>
                 </UnitSymbol>
                 <UnitSymbol type='MathML'>
                   <math xmlns='http://www.w3.org/1998/Math/MathML'>
                     <mrow>
                       <mi mathvariant='normal'>m</mi>
                       <mo rspace='thickmathspace'>&#8290;</mo>
                       <msup>
                         <mrow>
                           <mi mathvariant='normal'>kg</mi>
                         </mrow>
                         <mrow>
                           <mo>&#8722;</mo>
                           <mn>2</mn>
                         </mrow>
                       </msup>
                     </mrow>
                   </math>
                 </UnitSymbol>
                 <RootUnits>
                   <EnumeratedRootUnit unit='meter'/>
                   <EnumeratedRootUnit unit='gram' prefix='k' powerNumerator='-2'/>
                 </RootUnits>
               </Unit>
             </UnitSet>
             <DimensionSet>
               <Dimension xml:id='D_LM-2'>
                 <Length symbol='L' powerNumerator='1'/>
                 <Mass symbol='M' powerNumerator='-2'/>
               </Dimension>
             </DimensionSet>
             <PrefixSet>
               <Prefix prefixBase='10' prefixPower='3' xml:id='NISTp10_3'>
                 <PrefixName xml:lang='en'>kilo</PrefixName>
                 <PrefixSymbol type='ASCII'>k</PrefixSymbol>
                 <PrefixSymbol type='unicode'>k</PrefixSymbol>
                 <PrefixSymbol type='LaTeX'>k</PrefixSymbol>
                 <PrefixSymbol type='HTML'>k</PrefixSymbol>
               </Prefix>
             </PrefixSet>
           </UnitsML>
         </misc-container>
         <sections>
           <formula id='_'>
             <stem type='MathML'>
               <math xmlns='http://www.w3.org/1998/Math/MathML'>
                 <mrow>
                   <mn>7</mn>
                   <mo rspace='thickmathspace'>&#8290;</mo>
                   <mrow xref='U_m.kg-2'>
                     <mi mathvariant='normal'>m</mi>
                     <mo rspace='thickmathspace'>&#8290;</mo>
                     <msup>
                       <mrow>
                         <mi mathvariant='normal'>kg</mi>
                       </mrow>
                       <mrow>
                         <mo>&#8722;</mo>
                         <mn>2</mn>
                       </mrow>
                     </msup>
                   </mrow>
                   <mo>+</mo>
                   <mn>8</mn>
                   <mo rspace='thickmathspace'>&#8290;</mo>
                   <mrow xref='U_m.kg-2'>
                     <mi mathvariant='normal'>m</mi>
                     <mo rspace='thickmathspace'>&#8290;</mo>
                     <msup>
                       <mrow>
                         <mi mathvariant='normal'>kg</mi>
                       </mrow>
                       <mrow>
                         <mo>&#8722;</mo>
                         <mn>2</mn>
                       </mrow>
                     </msup>
                   </mrow>
                 </mrow>
               </math>
             </stem>
           </formula>
         </sections>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "customises italicisation of MathML" do
    input = <<~INPUT
      = Document title
      Author
      :stem:

      [stem]
      ++++
      <math xmlns='http://www.w3.org/1998/Math/MathML'>
        <mi>A</mi>
        <mo>+</mo>
        <mi>a</mi>
        <mo>+</mo>
        <mi>Α</mi>
        <mo>+</mo>
        <mi>α</mi>
        <mo>+</mo>
        <mi>AB</mi>
        <mstyle mathvariant="italic">
        <mrow>
        <mi>Α</mi>
        </mrow>
        </mstyle>
      </math>
      ++++
    INPUT

    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(<<~"OUTPUT")
        #{BLANK_HDR}
          <sections>
            <formula id='_'>
              <stem type='MathML'>
                <math xmlns='http://www.w3.org/1998/Math/MathML'>
                  <mi>A</mi>
                  <mo>+</mo>
                  <mi>a</mi>
                  <mo>+</mo>
                  <mi>Α</mi>
                  <mo>+</mo>
                  <mi>α</mi>
                  <mo>+</mo>
                  <mi>AB</mi>
                  <mstyle mathvariant='italic'>
          <mrow>
            <mi>Α</mi>
          </mrow>
        </mstyle>
                </math>
              </stem>
            </formula>
          </sections>
        </standard-document>
      OUTPUT
    mock_mathml_italicise({ uppergreek: false, upperroman: true,
                            lowergreek: true, lowerroman: true })
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(<<~"OUTPUT")
        #{BLANK_HDR}
          <sections>
            <formula id='_'>
              <stem type='MathML'>
                <math xmlns='http://www.w3.org/1998/Math/MathML'>
                  <mi>A</mi>
                  <mo>+</mo>
                  <mi>a</mi>
                  <mo>+</mo>
                  <mi mathvariant="normal">Α</mi>
                  <mo>+</mo>
                  <mi>α</mi>
                  <mo>+</mo>
                  <mi>AB</mi>
                  <mstyle mathvariant='italic'>
          <mrow>
            <mi>Α</mi>
          </mrow>
        </mstyle>
                </math>
              </stem>
            </formula>
          </sections>
        </standard-document>
      OUTPUT
    mock_mathml_italicise({ uppergreek: true, upperroman: false,
                            lowergreek: true, lowerroman: true })
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(<<~"OUTPUT")
        #{BLANK_HDR}
          <sections>
            <formula id='_'>
              <stem type='MathML'>
                <math xmlns='http://www.w3.org/1998/Math/MathML'>
                  <mi mathvariant="normal">A</mi>
                  <mo>+</mo>
                  <mi>a</mi>
                  <mo>+</mo>
                  <mi>Α</mi>
                  <mo>+</mo>
                  <mi>α</mi>
                  <mo>+</mo>
                  <mi>AB</mi>
                  <mstyle mathvariant='italic'>
          <mrow>
            <mi>Α</mi>
          </mrow>
        </mstyle>
                </math>
              </stem>
            </formula>
          </sections>
        </standard-document>
      OUTPUT
    mock_mathml_italicise({ uppergreek: true, upperroman: true,
                            lowergreek: false, lowerroman: true })
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(<<~"OUTPUT")
        #{BLANK_HDR}
          <sections>
            <formula id='_'>
              <stem type='MathML'>
                <math xmlns='http://www.w3.org/1998/Math/MathML'>
                  <mi>A</mi>
                  <mo>+</mo>
                  <mi>a</mi>
                  <mo>+</mo>
                  <mi>Α</mi>
                  <mo>+</mo>
                  <mi mathvariant="normal">α</mi>
                  <mo>+</mo>
                  <mi>AB</mi>
                  <mstyle mathvariant='italic'>
          <mrow>
            <mi>Α</mi>
          </mrow>
        </mstyle>
                </math>
              </stem>
            </formula>
          </sections>
        </standard-document>
      OUTPUT
    mock_mathml_italicise({ uppergreek: true, upperroman: true,
                            lowergreek: true, lowerroman: false })
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(<<~"OUTPUT")
        #{BLANK_HDR}
          <sections>
            <formula id='_'>
              <stem type='MathML'>
                <math xmlns='http://www.w3.org/1998/Math/MathML'>
                  <mi>A</mi>
                  <mo>+</mo>
                  <mi mathvariant="normal">a</mi>
                  <mo>+</mo>
                  <mi>Α</mi>
                  <mo>+</mo>
                  <mi>α</mi>
                  <mo>+</mo>
                  <mi>AB</mi>
                  <mstyle mathvariant='italic'>
          <mrow>
            <mi>Α</mi>
          </mrow>
        </mstyle>
                </math>
              </stem>
            </formula>
          </sections>
        </standard-document>
      OUTPUT
    mock_mathml_italicise({ uppergreek: true, upperroman: true,
                            lowergreek: true, lowerroman: true })
  end

  it "process express_ref macro with existing bibliography" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Clause

      <<uml:A:A.B.C,C>>
      <<uml:A>>
      <<express-schema:action:action.AA,AA>>
      <<express-schema:action:action.AB>>

      [[action]]
      [type="express-schema"]
      == Action

      [[action.AA]]
      === AA

      [bibliography]
      == Bibliography
      * [[[D,E]]] F
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
       <sections>
           <clause id='_' inline-header='false' obligation='normative'>
             <title>Clause</title>
             <p id='_'>
               <eref bibitemid='uml_A' citeas="">
               <localityStack>
                 <locality type='anchor'><referenceFrom>A.B.C</referenceFrom></locality>
               </localityStack>
                 C
               </eref>
               <eref bibitemid='uml_A' citeas=""/>
               <xref target='action.AA'>AA</xref>
               <xref target='action'>** Missing target action.AB</xref>
             </p>
           </clause>
           <clause id='action' type='express-schema' inline-header='false' obligation='normative'>
             <title>Action</title>
             <clause id='action.AA' inline-header='false' obligation='normative'>
             <title>AA</title>
              </clause>
           </clause>
         </sections>
         <bibliography>
           <references id='_' normative='false' obligation='informative'>
             <title>Bibliography</title>
             <bibitem id='D'>
               <formattedref format='application/x-isodoc+xml'>F</formattedref>
               <docidentifier>E</docidentifier>
             </bibitem>
           </references>
           <references hidden='true' normative='false'>
             <bibitem id='uml_A' type='internal'>
               <docidentifier type='repository'>uml/A</docidentifier>
             </bibitem>
           </references>
         </bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "process express_ref macro with no existing bibliography" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [[B]]
      [type="express-schema"]
      == Clause

      [[B1]]
      NOTE: X

      <<express-schema:A:A.B.C,C>>
      <<express-schema:A>>
      <<express-schema:B>>
      <<express-schema:B1>>
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections>
             <clause id='B' type='express-schema' inline-header='false' obligation='normative'>
                   <title>Clause</title>
                   <note id='B1'>
                     <p id='_'>X</p>
                   </note>
                   <p id='_'>
                     <eref bibitemid='express-schema_A' citeas=''>
                       <localityStack>
                         <locality type='anchor'>
                           <referenceFrom>A.B.C</referenceFrom>
                         </locality>
                       </localityStack>
                       C
                     </eref>
                     <eref bibitemid='express-schema_A' citeas=''/>
                     <xref target='B'/>
                     <xref target='B1'/>
                   </p>
                 </clause>
               </sections>
               <bibliography>
                 <references hidden='true' normative='false'>
                   <bibitem id='express-schema_A' type='internal'>
                     <docidentifier type='repository'>express-schema/A</docidentifier>
                   </bibitem>
                 </references>
               </bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  private

  def mock_mathml_italicise(string)
    allow_any_instance_of(::Asciidoctor::Standoc::Cleanup)
      .to receive(:mathml_mi_italics).and_return(string)
  end

  def mock_iecbib_get_iec60050_103_01
    expect(Iecbib::IecBibliography).to receive(:get)
      .with("IEC 60050-103", nil, { keep_year: true }) do
      IsoBibItem::XMLParser.from_xml(<<~"OUTPUT")
        <bibitem type="standard" id="IEC60050-103">
           <title format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary</title>
           <docidentifier>IEC 60050-103:2009</docidentifier>
           <date type="published">
             <on>2009</on>
           </date>
           <contributor>
             <role type="publisher"/>
             <organization>
               <name>International Electrotechnical Commission</name>
               <abbreviation>IEC</abbreviation>
               <uri>www.iec.ch</uri>
             </organization>
           </contributor>
           <language>en</language>
           <language>fr</language>
           <script>Latn</script>
           <status>
             <stage>60</stage>
           </status>
           <copyright>
             <from>2018</from>
             <owner>
               <organization>
                 <name>International Electrotechnical Commission</name>
                 <abbreviation>IEC</abbreviation>
                 <uri>www.iec.ch</uri>
               </organization>
             </owner>
           </copyright>
         </bibitem>
      OUTPUT
    end
  end

  def mock_iecbib_get_iec60050_102_01
    expect(Iecbib::IecBibliography).to receive(:get)
      .with("IEC 60050-102", nil, { keep_year: true }) do
      IsoBibItem::XMLParser.from_xml(<<~"OUTPUT")
        <bibitem type="standard" id="IEC60050-102">
           <title format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary</title>
           <docidentifier>IEC 60050-102:2007</docidentifier>
           <date type="published">
             <on>2007</on>
           </date>
           <contributor>
             <role type="publisher"/>
             <organization>
               <name>International Electrotechnical Commission</name>
               <abbreviation>IEC</abbreviation>
               <uri>www.iec.ch</uri>
             </organization>
           </contributor>
           <language>en</language>
           <language>fr</language>
           <script>Latn</script>
           <status>
             <stage>60</stage>
           </status>
           <copyright>
             <from>2018</from>
             <owner>
               <organization>
                 <name>International Electrotechnical Commission</name>
                 <abbreviation>IEC</abbreviation>
                 <uri>www.iec.ch</uri>
               </organization>
             </owner>
           </copyright>
         </bibitem>
      OUTPUT
    end
  end

  def mock_iev
    expect(Iecbib::IecBibliography).to receive(:get).with("IEV", nil, {}) do
      IsoBibItem::XMLParser.from_xml(<<~"OUTPUT")
        <bibitem type="standard" id="IEC60050:2001">
           <title format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary</title>
           <docidentifier>IEC 60050:2011</docidentifier>
           <date type="published">
             <on>2007</on>
           </date>
           <contributor>
             <role type="publisher"/>
             <organization>
               <name>International Electrotechnical Commission</name>
               <abbreviation>IEC</abbreviation>
               <uri>www.iec.ch</uri>
             </organization>
           </contributor>
           <language>en</language>
           <language>fr</language>
           <script>Latn</script>
           <status>
             <stage>60</stage>
           </status>
           <copyright>
             <from>2018</from>
             <owner>
               <organization>
                 <name>International Electrotechnical Commission</name>
                 <abbreviation>IEC</abbreviation>
                 <uri>www.iec.ch</uri>
               </organization>
             </owner>
           </copyright>
         </bibitem>
      OUTPUT
    end.at_least :once
  end
end
