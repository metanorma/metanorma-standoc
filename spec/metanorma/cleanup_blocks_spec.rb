require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Standoc do
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
        <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>r</mi><mo>=</mo><mn>1</mn><mo>%</mo><mi>r</mi><mo>=</mo><mn>1</mn><mo>%</mo></math></stem>
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
        <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>r</mi><mo>=</mo><mn>1</mn><mo>%</mo><mi>r</mi><mo>=</mo><mn>1</mn><mo>%</mo></math></stem></formula>
      <note id="_">
        <p id="_">That formula does not do much</p>
      </note>
             <p id="_">Indeed.</p></sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "does not move notes inside preceding tables, if they are marked as keep-separate" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      |===
      |A |B

      |C |D
      |===

      [NOTE,keep-separate=true]
      ====
      That formula does not do much
      ====

      |===
      |A |B

      |C |D
      |===

      [NOTE]
      ====
      That formula does not do much
      ====

      Indeed.
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
                 <table id='_'>
             <thead>
               <tr>
                 <th valign='top' align='left'>A</th>
                 <th valign='top' align='left'>B</th>
               </tr>
             </thead>
             <tbody>
               <tr>
                 <td valign='top' align='left'>C</td>
                 <td valign='top' align='left'>D</td>
               </tr>
             </tbody>
           </table>
           <note id='_'>
             <p id='_'>That formula does not do much</p>
           </note>
           <table id='_'>
             <thead>
               <tr>
                 <th valign='top' align='left'>A</th>
                 <th valign='top' align='left'>B</th>
               </tr>
             </thead>
             <tbody>
               <tr>
                 <td valign='top' align='left'>C</td>
                 <td valign='top' align='left'>D</td>
               </tr>
             </tbody>
             <note id='_'>
               <p id='_'>That formula does not do much</p>
             </note>
           </table>
           <p id='_'>Indeed.</p>
      </sections>
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

  it "moves metadata deflist to correct location" do
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
      target:: ABC
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
            <identifier>
              <link target='http://www.opengis.net/spec/waterml/2.0/req/xsd-xml-rules'>
                <strong>req/core</strong>
              </link>
            </identifier>
            <subject>Encoding of logical models</subject>
            <inherit>/ss/584/2015/level/1 &amp; /ss/584/2015/level/2</inherit>
            <inherit>urn:iso:dis:iso:19156:clause:7.2.2</inherit>
            <inherit>urn:iso:dis:iso:19156:clause:8</inherit>
            <inherit>
              <link target='http://www.opengis.net/doc/IS/GML/3.2/clause/2.4'/>
            </inherit>
            <inherit>O&amp;M Abstract model, OGC 10-004r3, clause D.3.4</inherit>
            <inherit>
              <link target='http://www.opengis.net/spec/SWE/2.0/req/core/core-concepts-used'/>
            </inherit>
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
                 <value>ABC</value>
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
            <requirement id='_' subsequence='A'>
              <title>Title</title>
              <inherit>A</inherit>
              <inherit>B</inherit>
              <inherit>/ss/584/2015/level/1 &amp; /ss/584/2015/level/2</inherit>
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
              </requirement>
              <requirement id='_' subsequence='A'>
              <inherit>A</inherit>
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

      [IMPORTANT,coverpage=true]
      ====
      Notice which is also very important
      ====

    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
        <preface>
          <note id='_'>
            <p id='_'>Note which is very important</p>
          </note>
          <admonition id='_' type='important' coverpage='true'>
            <p id='_'>Notice which is also very important</p>
          </admonition>
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

  it "updates anchor reference along with anchor to match content" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[samplecode]]
      .Sample Code
      ====

      [source,ruby]
      --
      puts "Hello, world."
      %w{a b c}.each do |x| <1>
        puts x
      end
      --
      <1> This is an annotation
      ====
    INPUT
    output = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    callout_id = output.at("//xmlns:callout/@target").text
    annotation_id = output.at("//xmlns:annotation/@id").text
    expect(callout_id).to eq(annotation_id)
  end
  it "deduplicates identifiers in inline SVGs" do
    input = <<~INPUT
      #{BLANK_HDR}
        <sections>
        <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 256 256">
         <defs>
           <linearGradient id="gradient1">
             <stop class="stop1" offset="0%" xlink:href="#gradient1"/>
             <stop class="stop2" offset="100%"/>
             <style>url(#gradient1)</style>
           </linearGradient>
         </defs>
         <circle fill="url(#gradient1)" cx="128" cy="128" r="100" />
       </svg>
               <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 256 256">
         <defs>
           <linearGradient id="gradient2">
             <stop class="stop1" offset="0%" xlink:href="#gradient2"/>
             <stop class="stop2" offset="100%"/>
             <style>url(#gradient2)</style>
           </linearGradient>
         </defs>
         <circle fill="url(#gradient2)" cx="128" cy="128" r="100" />
       </svg>
             <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 256 256">
         <defs>
           <linearGradient id="gradient1">
             <stop class="stop1" offset="0%" xlink:href="#gradient1"/>
             <stop class="stop2" offset="100%"/>
             <style>url(#gradient1)</style>
           </linearGradient>
         </defs>
         <circle fill="url(#gradient1)" cx="128" cy="128" r="100" />
       </svg>
             </sections>
      </standard-document>
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                 <sections>
                   <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0 256 256">
         <defs>
           <linearGradient id="gradient1_inject_0">
             <stop class="stop1" offset="0%" xlink:href="#gradient1_inject_0"/>
             <stop class="stop2" offset="100%"/>
             <style>url(#gradient1_inject_0)</style>
           </linearGradient>
         </defs>
         <circle fill="url(#gradient1_inject_0)" cx="128" cy="128" r="100"/>
       </svg>
               <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0 256 256">
         <defs>
           <linearGradient id="gradient2">
             <stop class="stop1" offset="0%" xlink:href="#gradient2"/>
             <stop class="stop2" offset="100%"/>
             <style>url(#gradient2)</style>
           </linearGradient>
         </defs>
         <circle fill="url(#gradient2)" cx="128" cy="128" r="100"/>
       </svg>
             <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0 256 256">
         <defs>
           <linearGradient id="gradient1_inject_2">
             <stop class="stop1" offset="0%" xlink:href="#gradient1_inject_2"/>
             <stop class="stop2" offset="100%"/>
             <style>url(#gradient1_inject_2)</style>
           </linearGradient>
         </defs>
         <circle fill="url(#gradient1_inject_2)" cx="128" cy="128" r="100"/>
       </svg>
             </sections>
      </standard-document>
    OUTPUT
    expect(Metanorma::Standoc::Converter.new(nil, *OPTIONS)
      .cleanup(Nokogiri::XML(input)).to_xml)
      .to be_equivalent_to xmlpp(output)
  end

  it "deduplicates identifiers in embedded SVGs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR.sub(/:data-uri-image: false/, ':data-uri-image: true')}

      image::spec/fixtures/action_schemaexpg1.svg[]

      image::spec/examples/rice_images/rice_image1.png[]

      image::spec/fixtures/action_schemaexpg1.svg[]
    INPUT

    output = <<~OUTPUT
       #{BLANK_HDR}
                <sections>
          <figure id='_'>
            <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
              <style/>
              <image/>
              <a xlink:href='mn://action_schema'>
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
          <figure id='_'>
              <image/>
          </figure>
          <figure id='_'>
            <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1_inject_1' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
              <style/>
              <image/>
              <a xlink:href='mn://action_schema'>
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
        </sections>
      </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.xpath("//*[local-name() = 'image']").each do |x|
      x.replace("<image/>")
    end
    expect(xmlpp(strip_guid(xml.to_xml)
      .gsub(%r{<style.*?</style>}m, "<style/>")))
      .to be_equivalent_to xmlpp(output)
  end

  it "removes paras with indexterms" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause 1

      Paragraph

      (((index)))

      [NOTE]
      --

      (((index)))

      Note
      --

      [NOTE]
      --

      (((index)))

      --

      == Clause 2

      Paragraph

      ((index))

    INPUT

    output = <<~OUTPUT
       #{BLANK_HDR}
               <sections>
           <clause id='_' inline-header='false' obligation='normative'>
             <title>Clause 1</title>
             <p id='_'>
               Paragraph
               <index>
                 <primary>index</primary>
               </index>
             </p>
             <note id='_'>
               <p id='_'>
                 <index>
                   <primary>index</primary>
                 </index>
                 Note
               </p>
             </note>
             <note id='_'>
               <p id='_'>
                 <index>
                   <primary>index</primary>
                 </index>
               </p>
             </note>
           </clause>
           <clause id='_' inline-header='false' obligation='normative'>
              <title>Clause 2</title>
              <p id='_'>Paragraph</p>
              <p id='_'>
                index
                <index>
                  <primary>index</primary>
                </index>
              </p>
            </clause>
         </sections>
       </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.xpath("//*[local-name() = 'image']").each do |x|
      x.replace("<image/>")
    end
    expect(xmlpp(strip_guid(xml.to_xml)
      .gsub(%r{<style.*?</style>}m, "<style/>")))
      .to be_equivalent_to xmlpp(output)
  end

end
