require "spec_helper"
require "relaton_iec"
require "fileutils"

RSpec.describe Asciidoctor::Standoc do
  it "applies smartquotes by default" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == "Quotation" A's
    INPUT
       #{BLANK_HDR}
              <sections>
  <clause id="_" inline-header="false" obligation="normative">
  <title>“Quotation” A’s</title>
</clause>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "applies smartquotes when requested" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :smartquotes: true

      == "Quotation" A's
    INPUT
       #{BLANK_HDR}
              <sections>
  <clause id="_" inline-header="false" obligation="normative">
  <title>“Quotation” A’s</title>
</clause>
       </sections>
       </standard-document>
    OUTPUT
  end

    it "does not apply smartquotes when requested not to" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
  end

  it "does not apply smartquotes to sourcecode, tt, pre, pseudocode" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
  end

  it "handles < > &amp; in Asciidoctor correctly" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == {blank}

      <&amp;>
    INPUT
       #{BLANK_HDR}
              <sections>
         <clause id="_" inline-header="false" obligation="normative">
<p id="_">&lt;&amp;&gt;</p>
       </clause>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "removes empty text elements" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
         <term id="_"><preferred><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>t</mi><mn>90</mn></msub></math></stem></preferred><admitted><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>t</mi><mn>91</mn></msub></math></stem></admitted>
       <definition><p id="_">Time</p></definition></term>
       </terms>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "moves term domains out of the term definition paragraph" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Tempus

      domain:[relativity] Time

      === Tempus1

      Time2

      domain:[relativity2]
    INPUT
       #{BLANK_HDR}
              <sections>
         <terms id="_" obligation="normative">
         <title>Terms and definitions</title>
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
         <term id="_">
         <preferred>Tempus</preferred>
         <domain>relativity</domain><definition><p id="_"> Time</p></definition>
       </term>
       <term id='_'>
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
  end

  it "permits multiple blocks in term definition paragraph" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
         <term id="_"><preferred><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>t</mi><mn>90</mn></msub></math></stem></preferred><definition><formula id="_"> 
         <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>t</mi><mi>A</mi></msub></math></stem> 
       </formula>
       <p id="_">This paragraph is extraneous</p></definition>
       </term>
       </terms>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "strips any initial boilerplate from terms and definitions" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>

       <term id="_">
       <preferred>Time</preferred>
         <definition><p id="_">This paragraph is extraneous</p></definition>
       </term></terms>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "moves notes inside preceding blocks, if they are not at clause end, and the blocks are not delimited" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
  <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>r</mi><mo>=</mo><mn>1</mn><mi>%</mi><mi>r</mi><mo>=</mo><mn>1</mn><mi>%</mi></math></stem>
<note id="_">
  <p id="_">That formula does not do much</p>
</note></formula>

       <p id="_">Indeed.</p></sections>
       </standard-document>
    OUTPUT
  end

    it "does not move notes inside preceding blocks, if they are marked as keep-separate" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
       #{BLANK_HDR}
    <sections><formula id="_">
  <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>r</mi><mo>=</mo><mn>1</mn><mi>%</mi><mi>r</mi><mo>=</mo><mn>1</mn><mi>%</mi></math></stem></formula>
<note id="_">
  <p id="_">That formula does not do much</p>
</note>

       <p id="_">Indeed.</p></sections>
       </standard-document>
    OUTPUT
  end

  it "does not move notes inside preceding blocks, if they are at clause end" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [source,ruby]
      [1...x].each do |y|
        puts y
      end

      NOTE: That loop does not do much
    INPUT
       #{BLANK_HDR}
              <sections><sourcecode id="_" lang="ruby">[1...x].each do |y|
         puts y
       end</sourcecode>
       <note id="_">
         <p id="_">That loop does not do much</p>
       </note></sections>
       </standard-document>
    OUTPUT
  end

  it "converts xrefs to references into erefs" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      <<iso216>>

      [bibliography]
      == Normative References
      * [[[iso216,ISO 216:2001]]], _Reference_
    INPUT
      #{BLANK_HDR}
        <preface><foreword id="_" obligation="informative">
        <title>Foreword</title>
        <p id="_">
        <eref type="inline" bibitemid="iso216" citeas="ISO 216:2001"/>
      </p>
      </foreword></preface><sections>
      </sections><bibliography><references id="_" obligation="informative" normative="true">
        <title>Normative References</title>
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
  end

  it "extracts localities from erefs" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      <<iso216,whole,clause=3,example=9-11,locality:prelude="33 a",locality:entirety:the reference,xyz>>
      <<iso216,whole,clause=3,example=9-11,locality:prelude=33,locality:entirety="the reference";whole,clause=3,example=9-11,locality:prelude=33,locality:entirety:the reference,xyz>>

      [bibliography]
      == Normative References
      * [[[iso216,ISO 216]]], _Reference_
    INPUT
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

        </p>
      </foreword></preface><sections>
      </sections><bibliography><references id="_" obligation="informative" normative="true">
        <title>Normative References</title>
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
  end


  it "strips type from xrefs" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      <<iso216>>

      [bibliography]
      == Clause
      * [[[iso216,ISO 216]]], _Reference_
    INPUT
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
  end

  it "processes localities in term sources" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
         <term id="_">
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
  end

  it "removes initial extraneous material from Normative References" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      This is extraneous information

      * [[[iso216,ISO 216]]], _Reference_

      This is also extraneous information
    INPUT
      #{BLANK_HDR}
      <sections></sections>
      <bibliography><references id="_" obligation="informative" normative="true"><title>Normative References</title>
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
       <p id='_'>This is also extraneous information</p>
      </references>
      </bibliography>
      </standard-document>
    OUTPUT
  end

    it "sorts references with their notes in Bibliography" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Bibliography

      This is extraneous information

      * [[[iso216,ISO 216]]], _Reference_

      NOTE: ABC

      NOTE: DEF

      This is further extraneous information

      NOTE: GHI

      * [[[iso216,ISO 215]]], _Reference_

      NOTE: JKL

      This is also extraneous information
    INPUT
      #{BLANK_HDR}
      <sections> </sections>
         <bibliography>
           <references id='_' obligation='informative' normative="false">
             <title>Bibliography</title>
             <p id='_'>This is extraneous information</p>
             <bibitem id='iso216' type='standard'>
               <title format='text/plain'>Reference</title>
               <docidentifier>ISO 216</docidentifier>
               <docnumber>216</docnumber>
               <contributor>
                 <role type='publisher'/>
                 <organization>
                   <name>ISO</name>
                 </organization>
               </contributor>
             </bibitem>
             <note id='_'>
               <p id='_'>ABC</p>
             </note>
             <note id='_'>
               <p id='_'>DEF</p>
             </note>
             <bibitem id='iso216' type='standard'>
               <title format='text/plain'>Reference</title>
               <docidentifier>ISO 215</docidentifier>
               <docnumber>215</docnumber>
               <contributor>
                 <role type='publisher'/>
                 <organization>
                   <name>ISO</name>
                 </organization>
               </contributor>
             </bibitem>
             <note id='_'>
               <p id='_'>JKL</p>
             </note>
             <p id='_'>
               This is further extraneous information
               <note id='_'>
                 <p id='_'>GHI</p>
               </note>
             </p>
             <p id='_'>This is also extraneous information</p>
           </references>
         </bibliography>
       </standard-document>
    OUTPUT
end

  it "inserts IDs into paragraphs" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
             <th align="left">a</th>
             <th align="left">b</th>
             <th align="left">c</th>
           </tr><tr>
             <th align="left">a</th>
             <th align="left">b</th>
             <th align="left">c</th>
           </tr><tr>
             <th align="left">a</th>
             <th align="left">b</th>
             <th align="left">c</th>
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
             <th align="left">a</th>
             <th align="left">b</th>
             <th align="left">c</th>
           </tr><tr>
             <th align="left">a</th>
             <th align="left">b</th>
             <th align="left">c</th>
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
       </standard-document>
    OUTPUT
  end

  it "moves formula key inside formula" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
         <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>F</mi><mi>or</mi><mi>μ</mi><mi>l</mi><mi>a</mi></math></stem> 
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      .Figuretitle.footnote:[xyz]
      image::spec/examples/rice_images/rice_image1.png[]

      footnote:[This is a footnote to a figure]

      footnote:[This is another footnote to a figure]

      A footnote:[This is a third footnote]
    INPUT
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
  end

  it "moves figure key inside figure" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      image::spec/examples/rice_images/rice_image1.png[]

      key:

      a:: b
    INPUT
       #{BLANK_HDR}
       <sections><figure id="_">
         <image src="spec/examples/rice_images/rice_image1.png" id="_" mimetype="image/png" height="auto" width="auto"/>
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
  end

  it "numbers bibliographic notes and footnotes sequentially" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      footnote:[Footnote]

      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:--]]] footnote:[The standard is in press] _Standard_

      == Clause
      footnote:[Footnote2]
    INPUT
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
        <title>Normative References</title>
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
         <note format="text/plain" type="ISO DATE">The standard is in press</note>
       </bibitem>
      </references>
      </bibliography>
      </standard-document>
    OUTPUT
  end

  it "defaults section obligations" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
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
  end

  it "extends clause levels past 5" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
        <terms id="_" obligation="normative"><title>Terms and definitions</title>
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
         <term id="_">
          <preferred>Automation1</preferred>
          <termsource status="identical">
          <origin bibitemid="IEC60050-103" type="inline" citeas="IEC 60050-103:2009">
          <localityStack>
        <locality type="clause"><referenceFrom>103-01-02</referenceFrom></locality>
          </localityStack>
        </origin>
        </termsource>
        </term>
        <term id="_">
          <preferred>Automation2</preferred>
          <termsource status="identical">
          <origin bibitemid="IEC60050-102" type="inline" citeas="IEC 60050-102:2007">
          <localityStack>
        <locality type="clause"><referenceFrom>102-01-02</referenceFrom></locality>
          </localityStack>
        </origin>
        </termsource>
        </term>
        <term id="_">
          <preferred>Automation3</preferred>
          <termsource status="identical">
          <origin bibitemid="IEC60050-103" type="inline" citeas="IEC 60050-103:2009">
          <localityStack>
        <locality type="clause"><referenceFrom>103-01-02</referenceFrom></locality>
          </localityStack>
        </origin>
        </termsource>
        </term></terms></sections><bibliography><references id="_" obligation="informative" normative="true">
          <title>Normative References</title>
        #{NORM_REF_BOILERPLATE}
          <bibitem type="standard" id="IEC60050-102">
          <fetched>#{Date.today}</fetched>
          <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
          <title type="title-part" format="text/plain" language="en" script="Latn">Part 102: Mathematics — General concepts and linear algebra</title>
          <title type='main' format='text/plain' language='en' script='Latn'>International Electrotechnical Vocabulary (IEV) — Part 102: Mathematics — General concepts and linear algebra</title>
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
    end
    FileUtils.rm_rf File.expand_path("~/.iev.pstore")
    FileUtils.mv File.expand_path("~/.iev.pstore1"), File.expand_path("~/.iev.pstore"), force: true
    FileUtils.rm_rf File.expand_path("~/.relaton/cache")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"), File.expand_path("~/.relaton/cache"), force: true
  end

   it "counts footnotes with link-only content as separate footnotes" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      
      footnote:[http://www.example.com]

      footnote:[http://www.example.com]

      footnote:[http://www.example1.com]
    INPUT
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
  end

      it "retains AsciiMath on request" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :mn-keep-asciimath:

      stem:[1/r]
    INPUT
       #{BLANK_HDR}
       <sections>
  <p id="_">
  <stem type="AsciiMath">1/r</stem>
</p>
</sections>
</standard-document>

    OUTPUT
  end

  it "converts AsciiMath to MathML by default" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:

      stem:[1/r]
    INPUT
       #{BLANK_HDR}
       <sections>
         <p id="_">
         <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mfrac><mn>1</mn><mi>r</mi></mfrac></math></stem>
       </p>
       </sections>
       </standard-document>
    OUTPUT
  end

    it "cleans up text MathML" do
      expect(Asciidoctor::Standoc::Converter.new(nil, backend: :standoc, header_footer: true).cleanup(Nokogiri::XML(<<~"INPUT")).to_xml).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{BLANK_HDR}
      <sections>
      <stem type="MathML">&lt;math xmlns="http://www.w3.org/1998/Math/MathML"&gt;&lt;mfrac&gt;&lt;mn&gt;1&lt;/mn&gt;&lt;mi&gt;r&lt;/mi&gt;&lt;/mfrac&gt;&lt;/math&gt;</stem>
      </sections>
      </standard-document>
    INPUT
       #{BLANK_HDR}
       <sections>
       <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mfrac><mn>1</mn><mi>r</mi></mfrac></math></stem>
</sections>


       </standard-document>
    OUTPUT
  end

        it "renumbers numeric references in Bibliography sequentially" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      == Clause
      <<iso123>>
      <<iso124>>

      [bibliography]
      == Bibliography

      * [[[iso124,ISO 124]]] _Standard 124_
      * [[[iso123,1]]] _Standard 123_
    INPUT
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
        end

                it "renumbers numeric references in Bibliography subclauses sequentially" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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

    INPUT
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
       </references></clause></bibliography>
       </standard-document>
OUTPUT
        end

 it "inserts boilerplate before empty Normative References" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      [bibliography]
      == Normative References

      INPUT
      #{BLANK_HDR}
      <sections>

</sections><bibliography><references id="_" obligation="informative" normative="true">
  <title>Normative References</title><p id="_">There are no normative references in this document.</p>
</references></bibliography>
</standard-document>
      OUTPUT
      end

 it "inserts boilerplate before non-empty Normative References" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      [bibliography]
      == Normative References
      * [[[a,b]]] A

      INPUT
    #{BLANK_HDR}
    <sections>

       </sections><bibliography><references id="_" obligation="informative" normative="true">
         <title>Normative References</title><p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
         <bibitem id="a">
         <formattedref format="application/x-isodoc+xml">A</formattedref>
         <docidentifier>b</docidentifier>
       </bibitem>
       </references></bibliography>
       </standard-document>

      OUTPUT
      end

it "inserts boilerplate before empty Normative References in French" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
    = Document title
    Author
    :docfile: test.adoc
    :nodoc:
    :novalid:
    :no-isobib:
    :language: fr

    [bibliography]
    == Normative References

    INPUT
    #{BLANK_HDR.sub(/<language>en/, "<language>fr")}
    <sections>

</sections><bibliography><references id="_" obligation="informative" normative="true">
  <title>Normative References</title><p id="_">Le présent document ne contient aucune référence normative.</p>
</references></bibliography>
</standard-document>
      OUTPUT
      end

it "removes bibdata bibitem IDs" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
    <?xml version='1.0' encoding='UTF-8'?>
<standard-document xmlns='https://www.metanorma.org/ns/standoc'>
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
      <title>Normative References</title>
      <p id="_">There are no normative references in this document.</p>
    </references>
  </bibliography>
</standard-document>
OUTPUT
end

it "imports boilerplate file" do
  expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
    <standard-document xmlns='https://www.metanorma.org/ns/standoc'>
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
end

it "sorts symbols lists" do
  expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
  #{ASCIIDOC_BLANK_HDR}
  
  [[L]]
  == Symbols and abbreviated terms

  α:: Definition 1
  xa:: Definition 2
  x_1_:: Definition 3
  x_m_:: Definition 4
  x:: Definition 5
  INPUT
  #{BLANK_HDR}
  <sections>
    <definitions id='L' obligation="normative">
      <title>Symbols and abbreviated terms</title>
      <dl id='_'>
        <dt>x</dt>
        <dd>
          <p id='_'>Definition 5</p>
        </dd>
        <dt>x_m_</dt>
        <dd>
          <p id='_'>Definition 4</p>
        </dd>
        <dt>x_1_</dt>
        <dd>
          <p id='_'>Definition 3</p>
        </dd>
        <dt>xa</dt>
        <dd>
          <p id='_'>Definition 2</p>
        </dd>
        <dt>α</dt>
        <dd>
          <p id='_'>Definition 1</p>
        </dd>
      </dl>
    </definitions>
  </sections>
</standard-document>
  OUTPUT
end

it "sorts symbols lists" do
  expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
  #{ASCIIDOC_BLANK_HDR}
  
  [[L]]
  == Symbols and abbreviated terms

  stem:[alpha]:: Definition 1
  xa:: Definition 2
  stem:[x_1]:: Definition 3
  stem:[x_m]:: Definition 4
  x:: Definition 5
  INPUT
  #{BLANK_HDR}
  <sections>
    <definitions id='L' obligation="normative">
      <title>Symbols and abbreviated terms</title>
      <dl id='_'>
        <dt>x</dt>
        <dd>
          <p id='_'>Definition 5</p>
        </dd>
        <dt><stem type='MathML'>
        <math xmlns='http://www.w3.org/1998/Math/MathML'>
  <msub>
    <mi>x</mi>
    <mi>m</mi>
  </msub>
</math>
        </stem></dt>
        <dd>
          <p id='_'>Definition 4</p>
        </dd>
        <dt><stem type='MathML'>
         <math xmlns='http://www.w3.org/1998/Math/MathML'>
   <msub>
     <mi>x</mi>
     <mn>1</mn>
   </msub>
 </math>
        </stem></dt>
        <dd>
          <p id='_'>Definition 3</p>
        </dd>
        <dt>xa</dt>
        <dd>
          <p id='_'>Definition 2</p>
        </dd>
        <dt>
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
end

it "moves inherit macros to correct location" do
  expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
end

it "moves %beforeclause admonitions to right position" do
  expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
  #{BLANK_HDR}
  <preface>
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
    <note id='_'>
      <p id='_'>Note which is very important</p>
    </note>
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
end


  private

    def mock_iecbib_get_iec60050_103_01
      expect(Iecbib::IecBibliography).to receive(:get).with("IEC 60050-103", nil, {keep_year: true}) do
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
      expect(Iecbib::IecBibliography).to receive(:get).with("IEC 60050-102", nil, {keep_year: true}) do
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
