require "spec_helper"
require "iecbib"
require "fileutils"

RSpec.describe Asciidoctor::Standoc do
  it "applies smartquotes by default" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      == "Quotation"
    INPUT
       #{BLANK_HDR}
              <sections>
  <clause id="_" inline-header="false" obligation="normative">
  <title>“Quotation”</title>
</clause>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "applies smartquotes when requested" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :smartquotes: true

      == "Quotation"
    INPUT
       #{BLANK_HDR}
              <sections>
  <clause id="_" inline-header="false" obligation="normative">
  <title>“Quotation”</title>
</clause>
       </sections>
       </standard-document>
    OUTPUT
  end

    it "does not apply smartquotes when requested not to" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :smartquotes: false

      == "Quotation"
    INPUT
       #{BLANK_HDR}
              <sections>
  <clause id="_" inline-header="false" obligation="normative">
  <title>"Quotation"</title>
</clause>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "does not apply smartquotes to sourcecode, tt, pre" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :smartquotes: true

      == "Quotation"

      "Quotation"

      `"quote"`

      [source]
      ----
      "quote"
      ----

    INPUT
       #{BLANK_HDR}
              <sections>
                <clause id="_" inline-header="false" obligation="normative"><title>“Quotation”</title><p id="_">“Quotation”</p>
<p id="_">
  <tt>"quote"</tt>
</p>
<sourcecode id="_">"quote"</sourcecode></clause>
       </sections>
       </standard-document>
    OUTPUT
  end


  it "removes empty text elements" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      == {blank}
    INPUT
       #{BLANK_HDR}
              <sections>
         <clause id="_" inline-header="false" obligation="normative">

       </clause>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "processes stem-only terms as admitted" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === stem:[t_90]

      stem:[t_91]

      Time
    INPUT
       #{BLANK_HDR}
              <sections>
         <terms id="_" obligation="normative">
         <title>Terms and definitions</title>
         <term id="_"><preferred><stem type="AsciiMath">t_90</stem></preferred><admitted><stem type="AsciiMath">t_91</stem></admitted>
       <definition><p id="_">Time</p></definition></term>
       </terms>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "moves term domains out of the term definition paragraph" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Tempus

      domain:[relativity] Time
    INPUT
       #{BLANK_HDR}
              <sections>
         <terms id="_" obligation="normative">
         <title>Terms and definitions</title>
         <term id="_">
         <preferred>Tempus</preferred>
         <domain>relativity</domain><definition><p id="_"> Time</p></definition>
       </term>
       </terms>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "permits multiple blocks in term definition paragraph" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
       #{BLANK_HDR}
              <sections>
         <terms id="_" obligation="normative">
         <title>Terms and definitions</title>
         <term id="_"><preferred><stem type="AsciiMath">t_90</stem></preferred><definition><formula id="_">
         <stem type="AsciiMath">t_A</stem>
       </formula><p id="_">This paragraph is extraneous</p></definition>
       </term>
       </terms>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "strips any initial boilerplate from terms and definitions" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      I am boilerplate

      * So am I

      === Time

      This paragraph is extraneous
    INPUT
       #{BLANK_HDR}
              <sections>
         <terms id="_" obligation="normative"><title>Terms and definitions</title>

       <term id="_">
       <preferred>Time</preferred>
         <definition><p id="_">This paragraph is extraneous</p></definition>
       </term></terms>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "moves notes inside preceding blocks, if they are not at clause end, and the blocks are not delimited" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [stem]
      ++++
      r = 1 %
      r = 1 %
      ++++

      NOTE: That formula does not do much

      Indeed.
    INPUT
       #{BLANK_HDR}
    <sections><formula id="_">
  <stem type="AsciiMath">r = 1 %
r = 1 %</stem>
<note id="_">
  <p id="_">That formula does not do much</p>
</note></formula>

       <p id="_">Indeed.</p></sections>
       </standard-document>
    OUTPUT
  end

  it "does not move notes inside preceding blocks, if they are at clause end" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [source,ruby]
      [1...x].each do |y|
        puts y
      end

      NOTE: That loop does not do much
    INPUT
       #{BLANK_HDR}
              <sections><sourcecode id="_">[1...x].each do |y|
         puts y
       end</sourcecode>
       <note id="_">
         <p id="_">That loop does not do much</p>
       </note></sections>
       </standard-document>
    OUTPUT
  end

  it "converts xrefs to references into erefs" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      <<iso216>>

      [bibliography]
      == Normative References
      * [[[iso216,ISO 216:2001]]], _Reference_
    INPUT
      #{BLANK_HDR}
        <preface><foreword obligation="informative">
        <title>Foreword</title>
        <p id="_">
        <eref type="inline" bibitemid="iso216" citeas="ISO 216:2001"/>
      </p>
      </foreword></preface><sections>
      </sections><bibliography><references id="_" obligation="informative">
        <title>Normative References</title>
        <bibitem id="iso216" type="standard">
         <title format="text/plain">Reference</title>
         <docidentifier>ISO 216:2001</docidentifier>
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
      </bibliography
      </standard-document>
    OUTPUT
  end

  it "extracts localities from erefs" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      <<iso216,whole,clause=3,example=9-11,locality:prelude=33,locality:entirety:the reference>>

      [bibliography]
      == Normative References
      * [[[iso216,ISO 216]]], _Reference_
    INPUT
      #{BLANK_HDR}
      <preface><foreword obligation="informative">
        <title>Foreword</title>
        <p id="_">
        <eref type="inline" bibitemid="iso216" citeas="ISO 216"><locality type="whole"/><locality type="clause"><referenceFrom>3</referenceFrom></locality><locality type="example"><referenceFrom>9</referenceFrom><referenceTo>11</referenceTo></locality><locality type="locality:prelude"><referenceFrom>33</referenceFrom></locality><locality type="locality:entirety"/>the reference</eref>
        </p>
      </foreword></preface><sections>
      </sections><bibliography><references id="_" obligation="informative">
        <title>Normative References</title>
        <bibitem id="iso216" type="standard">
         <title format="text/plain">Reference</title>
         <docidentifier>ISO 216</docidentifier>
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
  end


  it "strips type from xrefs" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      <<iso216>>

      [bibliography]
      == Clause
      * [[[iso216,ISO 216]]], _Reference_
    INPUT
       #{BLANK_HDR}
       <preface>
       <foreword obligation="informative">
         <title>Foreword</title>
         <p id="_">
         <eref type="inline" bibitemid="iso216" citeas="ISO 216"/>
       </p>
       </foreword></preface><sections>
       </sections><bibliography><references id="_" obligation="informative">
  <title>Bibliography</title>
  <bibitem id="iso216" type="standard">
  <title format="text/plain">Reference</title>
  <docidentifier>ISO 216</docidentifier>
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
  end

  it "processes localities in term sources" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      [.source]
      <<ISO2191,section=1>>
      INPUT
              #{BLANK_HDR}
       <sections>
         <terms id="_" obligation="normative">
         <title>Terms and definitions</title>
         <term id="_">
         <preferred>Term1</preferred>
         <termsource status="identical">
         <origin bibitemid="ISO2191" type="inline" citeas=""><locality type="section"><referenceFrom>1</referenceFrom></locality></origin>
       </termsource>
       </term>
       </terms>
       </sections>
       </standard-document>
      OUTPUT
  end

  it "removes extraneous material from Normative References" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      This is extraneous information

      * [[[iso216,ISO 216]]], _Reference_
    INPUT
      #{BLANK_HDR}
      <sections></sections>
      <bibliography><references id="_" obligation="informative"><title>Normative References</title>
             <bibitem id="iso216" type="standard">
         <title format="text/plain">Reference</title>
         <docidentifier>ISO 216</docidentifier>
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
  end

  it "inserts IDs into paragraphs" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      Paragraph
    INPUT
       #{BLANK_HDR}
       <sections>
         <p id="_">Paragraph</p>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "inserts IDs into notes" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [example]
      ====
      NOTE: This note has no ID
      ====
    INPUT
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
  end

  it "moves table key inside table" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      |===
      |a |b |c
      |===

      Key

      a:: b
    INPUT
       #{BLANK_HDR}
       <sections><table id="_">
         <tbody>
           <tr>
             <td align="left">a</td>
             <td align="left">b</td>
             <td align="left">c</td>
           </tr>
         </tbody>
       <dl id="_">
         <dt>a</dt>
         <dd>
           <p id="_">b</p>
         </dd>
       </dl></table>

       </sections>
       </standard-document>
    OUTPUT
  end

  it "processes headerrows attribute for table without header rows" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [headerrows=3]
      |===
      |a |b |c
      |a |b |c
      |a |b |c
      |a |b |c
      |===
    INPUT
       #{BLANK_HDR}
       <sections>
             <table id="_"><thead><tr>
             <td align="left">a</td>
             <td align="left">b</td>
             <td align="left">c</td>
           </tr><tr>
             <td align="left">a</td>
             <td align="left">b</td>
             <td align="left">c</td>
           </tr><tr>
             <td align="left">a</td>
             <td align="left">b</td>
             <td align="left">c</td>
           </tr></thead>
         <tbody>
           <tr>
             <td align="left">a</td>
             <td align="left">b</td>
             <td align="left">c</td>
           </tr>
         </tbody>
       </table>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "processes headerrows attribute for table with header rows" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [headerrows=3]
      |===
      |a |b |c

      |a |b |c
      |a |b |c
      |a |b |c
      |===
    INPUT
       #{BLANK_HDR}
       <sections>
         <table id="_">
         <thead>
           <tr>
             <th align="left">a</th>
             <th align="left">b</th>
             <th align="left">c</th>
           </tr>
         <tr>
             <td align="left">a</td>
             <td align="left">b</td>
             <td align="left">c</td>
           </tr><tr>
             <td align="left">a</td>
             <td align="left">b</td>
             <td align="left">c</td>
           </tr></thead>
         <tbody>


           <tr>
             <td align="left">a</td>
             <td align="left">b</td>
             <td align="left">c</td>
           </tr>
         </tbody>
       </table>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "moves table notes inside table" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      |===
      |a |b |c
      |===

      NOTE: Note 1

      NOTE: Note 2
    INPUT
       #{BLANK_HDR}
              <sections><table id="_">
         <tbody>
           <tr>
             <td align="left">a</td>
             <td align="left">b</td>
             <td align="left">c</td>
           </tr>
         </tbody>
       <note id="_">
         <p id="_">Note 1</p>
       </note><note id="_">
         <p id="_">Note 2</p>
       </note></table>

       </sections>
    OUTPUT
  end

  it "moves formula key inside formula" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [stem]
      ++++
      Formula
      ++++

      Where,

      a:: b
    INPUT
       #{BLANK_HDR}
       <sections><formula id="_">
         <stem type="AsciiMath">Formula</stem>
       <dl id="_">
         <dt>a</dt>
         <dd>
           <p id="_">b</p>
         </dd>
       </dl></formula>

       </sections>
       </standard-document>
    OUTPUT
  end

  it "moves footnotes inside figures" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      image::spec/examples/rice_images/rice_image1.png[]

      footnote:[This is a footnote to a figure]

      footnote:[This is another footnote to a figure]
    INPUT
       #{BLANK_HDR}
       <sections><figure id="_">
         <image src="spec/examples/rice_images/rice_image1.png" id="_" imagetype="PNG" height="auto" width="auto"/>
       <fn reference="a">
         <p id="_">This is a footnote to a figure</p>
       </fn><fn reference="b">
         <p id="_">This is another footnote to a figure</p>
       </fn></figure>

       </sections>

       </standard-document>
    OUTPUT
  end

  it "moves figure key inside figure" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      image::spec/examples/rice_images/rice_image1.png[]

      key:

      a:: b
    INPUT
       #{BLANK_HDR}
       <sections><figure id="_">
         <image src="spec/examples/rice_images/rice_image1.png" id="_" imagetype="PNG" height="auto" width="auto"/>
       <dl id="_">
         <dt>a</dt>
         <dd>
           <p id="_">b</p>
         </dd>
       </dl></figure>

       </sections>

       </standard-document>
    OUTPUT
  end

  it "processes subfigures" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
       #{BLANK_HDR}
              <sections>
         <figure id="figureC-2"><figure id="_">
         <name>Initial stages: No grains are fully gelatinized (ungelatinized starch granules are visible inside the kernels)</name>
         <image src="spec/examples/rice_images/rice_image3_1.png" id="_" imagetype="PNG" height="auto" width="auto"/>
       </figure>
       <figure id="_">
         <name>Intermediate stages: Some fully gelatinized kernels are visible</name>
         <image src="spec/examples/rice_images/rice_image3_2.png" id="_" imagetype="PNG" height="auto" width="auto"/>
       </figure>
       <figure id="_">
         <name>Final stages: All kernels are fully gelatinized</name>
         <image src="spec/examples/rice_images/rice_image3_3.png" id="_" imagetype="PNG" height="auto" width="auto"/>
       </figure></figure>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "numbers bibliographic notes and footnotes sequentially" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      footnote:[Footnote]

      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:--]]] footnote:[The standard is in press] _Standard_

      == Clause
      footnote:[Footnote2]
    INPUT
      #{BLANK_HDR}
      <preface><foreword obligation="informative">
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
      </clause></sections><bibliography><references id="_" obligation="informative">
        <title>Normative References</title>
        <bibitem id="iso123" type="standard">
         <title format="text/plain">Standard</title>
         <docidentifier>ISO 123:—</docidentifier>
         <date type="published">
           <on>--</on>
         </date>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>ISO</name>
           </organization>
         </contributor>
         <note format="text/plain">ISO DATE: The standard is in press</note>
       </bibitem>
      </references>
      </bibliography>
      </standard-document>
    OUTPUT
  end

  it "defaults section obligations" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}

      == Clause
      Text

      [appendix]
      == Clause

      Text
    INPUT
       #{BLANK_HDR}
       <sections><clause id="_" inline-header="false" obligation="normative">
         <title>Clause</title>
         <p id="_">Text</p>
       </clause>
       </sections><annex id="_" inline-header="false" obligation="normative">
         <title>Clause</title>
         <p id="_">Text</p>
       </annex>
       </standard-document>
    OUTPUT
  end

    it "rearranges term note, term example, term source" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
       #{BLANK_HDR}
       <sections>
       <terms id="_" obligation="normative">
         <title>Terms and definitions</title>
         <term id="_"><preferred>Term</preferred>



       <termnote id="_">
         <p id="_">Note</p>
       </termnote><termnote id="_">
         <p id="_">Note 2</p>
       </termnote><termexample id="_">
         <p id="_">Example 1</p>
       </termexample><termexample id="_">
         <p id="_">Example 2</p>
       </termexample><termsource status="identical">
         <origin bibitemid="ISO2191" type="inline" citeas=""><locality type="section"><referenceFrom>1</referenceFrom></locality></origin>
       </termsource></term>
       </terms>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "extends clause levels past 5" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
    #{ASCIIDOC_BLANK_HDR}

    == Clause1

    === Clause2

    ==== Clause3

    ===== Clause4

    ====== Clause 5

    [level=6]
    ====== Clause 6

    [level=7]
    ====== Clause 7A

    [level=7]
    ====== Clause 7B

    [level=6]
    ====== Clause 6B

    ====== Clause 5B

    INPUT
    #{BLANK_HDR}
    <sections>
  <clause id="_" inline-header="false" obligation="normative">
  <title>Clause1</title>
  <clause id="_" inline-header="false" obligation="normative">
  <title>Clause2</title>
  <clause id="_" inline-header="false" obligation="normative">
  <title>Clause3</title>
  <clause id="_" inline-header="false" obligation="normative"><title>Clause4</title><clause id="_" inline-header="false" obligation="normative">
  <title>Clause 5</title>
<clause id="_" inline-header="false" obligation="normative">
  <title>Clause 6</title>
<clause id="_" inline-header="false" obligation="normative">
  <title>Clause 7A</title>
</clause><clause id="_" inline-header="false" obligation="normative">
  <title>Clause 7B</title>
</clause></clause><clause id="_" inline-header="false" obligation="normative">
  <title>Clause 6B</title>
</clause></clause>




<clause id="_" inline-header="false" obligation="normative">
  <title>Clause 5B</title>
</clause></clause>
</clause>
</clause>
</clause>
</sections>
</standard-document>
    OUTPUT
  end

  it "separates IEV citations by top-level clause" do
    FileUtils.rm_rf File.expand_path("~/.relaton-bib.pstore1")
    FileUtils.mv File.expand_path("~/.relaton/cache"), File.expand_path("~/.relaton-bib.pstore1"), force: true
    FileUtils.rm_rf File.expand_path("~/.iev.pstore1")
    FileUtils.mv File.expand_path("~/.iev.pstore"), File.expand_path("~/.iev.pstore1"), force: true
    FileUtils.rm_rf "relaton/cache"
    FileUtils.rm_rf "test.iev.pstore"
    # mock_iecbib_get_iec60050_102_01
    # mock_iecbib_get_iec60050_103_01
    # mock_iev
    VCR.use_cassette "separates_iev_citations_by_top_level_clause" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
          #{BLANK_HDR}

          <sections>
        <terms id="_" obligation="normative"><title>Terms and definitions</title><term id="_">
          <preferred>Automation1</preferred>
          <termsource status="identical">
          <origin bibitemid="IEC60050-103" type="inline" citeas="IEC 60050-103:2009"><locality type="clause"><referenceFrom>103-01-02</referenceFrom></locality></origin>
        </termsource>
        </term>
        <term id="_">
          <preferred>Automation2</preferred>
          <termsource status="identical">
          <origin bibitemid="IEC60050-102" type="inline" citeas="IEC 60050-102:2007"><locality type="clause"><referenceFrom>102-01-02</referenceFrom></locality></origin>
        </termsource>
        </term>
        <term id="_">
          <preferred>Automation3</preferred>
          <termsource status="identical">
          <origin bibitemid="IEC60050-103" type="inline" citeas="IEC 60050-103:2009"><locality type="clause"><referenceFrom>103-01-02</referenceFrom></locality></origin>
        </termsource>
        </term></terms></sections><bibliography><references id="_" obligation="informative">
          <title>Normative References</title>
          <bibitem type="international-standard" id="IEC60050-102">
          <fetched>#{Date.today}</fetched>
          <title format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary — Part 102: Mathematics — General concepts and linear algebra</title>
          <uri type="src">https://webstore.iec.ch/publication/160</uri>
          <uri type="obp">/preview/info_iec60050-102%7Bed1.0%7Db.pdf</uri>
          <docidentifier type="IEC">IEC 60050-102:2007</docidentifier>
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
          <edition>1.0</edition>
          <language>en</language>
          <script>Latn</script>
          <abstract format="plain" language="en" script="Latn">This part of IEC 60050 gives the general mathematical terminology used in the fields of electricity, electronics and telecommunications, together with basic concepts in linear algebra. It maintains a clear distinction between mathematical concepts and physical concepts, even if some terms are used in both cases. Another part will deal with functions. It has the status of a horizontal standard in accordance with IEC Guide 108.</abstract>
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
          <editorialgroup>
            <technical-committee number="1" type="technicalCommittee">TC 1 - Terminology</technical-committee>
          </editorialgroup>
          <ics>
            <code>01.040.07</code>
            <text>Natural and applied sciences (Vocabularies)</text>
          </ics>
          <ics>
            <code>07.020</code>
            <text>Mathematics</text>
          </ics>
        </bibitem><bibitem type="international-standard" id="IEC60050-103">
          <fetched>#{Date.today}</fetched>
          <title format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary — Part 103: Mathematics — Functions </title>
          <uri type="src">https://webstore.iec.ch/publication/161</uri>
          <uri type="obp">/preview/info_iec60050-103%7Bed1.0%7Db.pdf</uri>
          <docidentifier type="IEC">IEC 60050-103:2009</docidentifier>
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
          <edition>1.0</edition>
          <language>en</language>
          <script>Latn</script>
          <abstract format="plain" language="en" script="Latn">IEC 60050-103:2009 gives the terminology relative to functions of one or more variables. Together with IEC 60050-102, it covers the mathematical terminology used in the fields of electricity, electronics and telecommunications. It maintains a clear distinction between mathematical concepts and physical concepts, even if some terms are used in both cases. Mathematical symbols are generally in accordance with IEC 60027-1 and ISO 80000-2. This standard cancels and replaces Sections 101-13, 101-14 and 101-15 of International Standard IEC 60050-101:1998. It has the status of a horizontal standard in accordance with IEC Guide 108.</abstract>
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
          <editorialgroup>
            <technical-committee number="1" type="technicalCommittee">TC 1 - Terminology</technical-committee>
          </editorialgroup>
          <ics>
            <code>01.040.07</code>
            <text>Natural and applied sciences (Vocabularies)</text>
          </ics>
          <ics>
            <code>07.020</code>
            <text>Mathematics</text>
          </ics>
        </bibitem>
        </references></bibliography>
        </standard-document>
  OUTPUT
    end
    FileUtils.rm_rf File.expand_path("~/.iev.pstore")
    FileUtils.mv File.expand_path("~/.iev.pstore1"), File.expand_path("~/.iev.pstore"), force: true
    FileUtils.rm_rf File.expand_path("~/.relaton/cache")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"), File.expand_path("~/.relaton/cache"), force: true
  end

  private

    def mock_iecbib_get_iec60050_103_01
      expect(Iecbib::IecBibliography).to receive(:get).with("IEC 60050-103", nil, {keep_year: true}) do
      IsoBibItem::XMLParser.from_xml(<<~"OUTPUT")
      <bibitem type="international-standard" id="IEC60050-103">
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
      expect(Iecbib::IecBibliography).to receive(:get).with("IEC 60050-102", nil, {keep_year: true}) do
      IsoBibItem::XMLParser.from_xml(<<~"OUTPUT")
      <bibitem type="international-standard" id="IEC60050-102">
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
      <bibitem type="international-standard" id="IEC60050:2001">
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
