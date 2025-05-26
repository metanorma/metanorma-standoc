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
           <svgmap id="_" unnumbered='true' number='8' subsequence='A' keep-with-next='true' keep-lines-together='true'>
             <target href='http://www.example.com'>
               <xref target='ref1'><display-text>Computer</display-text></xref>
             </target>
           </svgmap>
           <figure id="_" anchor="ref1">
             <name>SVG title</name>
             <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id="Layer_1_000000001" x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
        <style/>
        <image/>
        <a xlink:href='#ref1'>
        <rect x='123.28' y='273.93' width='88.05' height='41.84'/>
        </a>
        <a xlink:href='mn://basic_attribute_schema'>
          <rect x='324.69' y='450.52' width='132.62' height='40.75'/>
        </a>
        <a xlink:href='mn://support_resource_schema'>
          <rect x='324.69' y='528.36' width='148.16' height='40.75'/>
        </a>
      </svg>
                 </figure>
                 <svgmap id="_">
                   <figure id="_" anchor="ref2" unnumbered='true' number='8' subsequence='A' keep-with-next='true' keep-lines-together='true'>
        <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id="Layer_1_000000002" x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
          <style/>
          <image/>
          <a xlink:href='#ref1'>
            <rect x='123.28' y='273.93' width='88.05' height='41.84'/>
          </a>
          <a xlink:href='http://www.example.com'>
            <rect x='324.69' y='450.52' width='132.62' height='40.75'/>
          </a>
          <a xlink:href='mn://support_resource_schema'>
            <rect x='324.69' y='528.36' width='148.16' height='40.75'/>
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
                       <display-text>Coffee</display-text>
                     </eref>
                   </target>
                 </svgmap>
      </sections>
      <bibliography>
        <references hidden='true' normative='false'>
          <bibitem id="_" anchor="express_action_schema" type='internal'>
            <docidentifier type='repository'>express/action_schema</docidentifier>
          </bibitem>
        </references>
      </bibliography>
             </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS)))
      .gsub(%r{<image[^>]+?/>}m, "<image/>")
      .gsub(%r{<image.*?</image>}m, "<image/>")
      .gsub(%r{<style.*?</style>}m, "<style/>")
      .gsub(%r{ class="st0[^"]*"}m, ""))
      .to be_equivalent_to Xml::C14n.format(output)
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
        <sourcecode id='_'><body>&lt;tag/&gt;</body></sourcecode>
        <sourcecode id="_" anchor="A"><body>
          var
          <strong>x</strong>
           :
          <xref target='A'><display-text>recursive</display-text></xref>
           &lt;tag/&gt;
        </body></sourcecode>
      </sections>
             </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
        <sourcecode id="_" anchor="A"><body>
          var
          <strong>x</strong>
           :
          <xref target='A'><display-text>recursive</display-text></xref>
        </body></sourcecode>
      </sections>
             </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "moves notes inside preceding blocks, if the blocks are not delimited" do
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
                     <sections>
          <formula id="_">
            <stem type="MathML" block="true">
              <math xmlns="http://www.w3.org/1998/Math/MathML">
                <mstyle displaystyle="true">
                  <mi>r</mi>
                  <mo>=</mo>
                  <mn>1</mn>
                  <mi>%</mi>
                  <mi>r</mi>
                  <mo>=</mo>
                  <mn>1</mn>
                  <mi>%</mi>
                </mstyle>
              </math>
              <asciimath>r = 1 %
      r = 1 %</asciimath>
            </stem>
            <note id="_">
              <p id="_">That formula does not do much</p>
            </note>
          </formula>
          <p id="_">Indeed.</p>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
                     <sections>
          <formula id="_">
            <stem type="MathML" block="true">
              <math xmlns="http://www.w3.org/1998/Math/MathML">
                <mstyle displaystyle="true">
                  <mi>r</mi>
                  <mo>=</mo>
                  <mn>1</mn>
                  <mi>%</mi>
                  <mi>r</mi>
                  <mo>=</mo>
                  <mn>1</mn>
                  <mi>%</mi>
                </mstyle>
              </math>
              <asciimath>r = 1 %
      r = 1 %</asciimath>
            </stem>
          </formula>
          <note id="_">
            <p id="_">That formula does not do much</p>
          </note>
          <p id="_">Indeed.</p>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
               <tr id="_">
                 <th id="_" valign='top' align='left'>A</th>
                 <th id="_" valign='top' align='left'>B</th>
               </tr>
             </thead>
             <tbody>
               <tr id="_">
                 <td id="_" valign='top' align='left'>C</td>
                 <td id="_" valign='top' align='left'>D</td>
               </tr>
             </tbody>
           </table>
           <note id='_'>
             <p id='_'>That formula does not do much</p>
           </note>
           <table id='_'>
             <thead>
               <tr id="_">
                 <th id="_" valign='top' align='left'>A</th>
                 <th id="_" valign='top' align='left'>B</th>
               </tr>
             </thead>
             <tbody>
               <tr id="_">
                 <td id="_" valign='top' align='left'>C</td>
                 <td id="_" valign='top' align='left'>D</td>
               </tr>
             </tbody>
             <note id='_'>
               <p id='_'>That formula does not do much</p>
             </note>
           </table>
           <p id='_'>Indeed.</p>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
             <sections><sourcecode id="_" lang="ruby"><body>[1...x].each do |y|
        puts y
      end</body></sourcecode>
      <note id="_">
        <p id="_">That loop does not do much</p>
      </note></sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
              <tr id="_">
                <td id="_" valign='top' align='left'>a</td>
                <td id="_" valign='top' align='left'>b</td>
                <td id="_" valign='top' align='left'>c</td>
              </tr>
            </tbody>
            <dl id='_' key='true'>
              <dt>a</dt>
              <dd id="_">
                <p id='_'>b</p>
              </dd>
            </dl>
          </table>
          <table id='_'>
            <tbody>
              <tr id="_">
                <td id="_" valign='top' align='left'>a</td>
                <td id="_" valign='top' align='left'>b</td>
                <td id="_" valign='top' align='left'>c</td>
              </tr>
            </tbody>
            <dl id='_' key='true'>
              <dt>a</dt>
              <dd id="_">
                <p id='_'>b</p>
              </dd>
            </dl>
          </table>
          <table id='_'>
            <tbody>
              <tr id="_">
                <td id="_" valign='top' align='left'>a</td>
                <td id="_" valign='top' align='left'>b</td>
                <td id="_" valign='top' align='left'>c</td>
              </tr>
            </tbody>
          </table>
          <dl id='_'>
            <dt>a</dt>
            <dd id="_">
              <p id='_'>b</p>
            </dd>
          </dl>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
            <table id="_"><thead><tr id="_">
            <th id="_" valign="top" align="left">a</th>
            <th id="_" valign="top" align="left">b</th>
            <th id="_" valign="top" align="left">c</th>
          </tr><tr id="_">
            <th id="_" valign="top" align="left">a</th>
            <th id="_" valign="top" align="left">b</th>
            <th id="_" valign="top" align="left">c</th>
          </tr><tr id="_">
            <th id="_" valign="top" align="left">a</th>
            <th id="_" valign="top" align="left">b</th>
            <th id="_" valign="top" align="left">c</th>
          </tr></thead>
        <tbody>
          <tr id="_">
            <td id="_" valign="top" align="left">a</td>
            <td id="_" valign="top" align="left">b</td>
            <td id="_" valign="top" align="left">c</td>
          </tr>
        </tbody>
      </table>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
          <tr id="_">
            <th id="_" valign="top" align="left">a</th>
            <th id="_" valign="top" align="left">b</th>
            <th id="_" valign="top" align="left">c</th>
          </tr>
        <tr id="_">
            <th id="_" valign="top" align="left">a</th>
            <th id="_" valign="top" align="left">b</th>
            <th id="_" valign="top" align="left">c</th>
          </tr><tr id="_">
            <th id="_" valign="top" align="left">a</th>
            <th id="_" valign="top" align="left">b</th>
            <th id="_" valign="top" align="left">c</th>
          </tr></thead>
        <tbody>


          <tr id="_">
            <td id="_" valign="top" align="left">a</td>
            <td id="_" valign="top" align="left">b</td>
            <td id="_" valign="top" align="left">c</td>
          </tr>
        </tbody>
      </table>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
          <tr id="_">
            <td id="_" valign="top" align="left">a</td>
            <td id="_" valign="top" align="left">b</td>
            <td id="_" valign="top" align="left">c</td>
          </tr>
        </tbody>
      <note id="_">
        <p id="_">Note 1</p>
      </note><note id="_">
        <p id="_">Note 2</p>
      </note></table>

      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
           <formula id="_">
             <stem type="MathML" block="true">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mstyle displaystyle="true">
                   <mi>F</mi>
                   <mi>o</mi>
                   <mstyle mathvariant="normal">
                     <munder>
                       <mi>a</mi>
                       <mo>̲</mo>
                     </munder>
                   </mstyle>
                 </mstyle>
               </math>
               <asciimath>Formula</asciimath>
             </stem>
             <dl id="_" key="true">
               <dt>a</dt>
               <dd id="_">
                 <p id="_">b</p>
               </dd>
             </dl>
           </formula>
           <formula id="_">
             <stem type="MathML" block="true">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mstyle displaystyle="true">
                   <mi>F</mi>
                   <mi>o</mi>
                   <mstyle mathvariant="normal">
                     <munder>
                       <mi>a</mi>
                       <mo>̲</mo>
                     </munder>
                   </mstyle>
                 </mstyle>
               </math>
               <asciimath>Formula</asciimath>
             </stem>
             <dl id="_" key="true">
               <dt>a</dt>
               <dd id="_">
                 <p id="_">b</p>
               </dd>
             </dl>
           </formula>
           <formula id="_">
             <stem type="MathML" block="true">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mstyle displaystyle="true">
                   <mi>F</mi>
                   <mi>o</mi>
                   <mstyle mathvariant="normal">
                     <munder>
                       <mi>a</mi>
                       <mo>̲</mo>
                     </munder>
                   </mstyle>
                 </mstyle>
               </math>
               <asciimath>Formula</asciimath>
             </stem>
           </formula>
           <dl id="_">
             <dt>a</dt>
             <dd id="_">
               <p id="_">b</p>
             </dd>
           </dl>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
             </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
              <dd id="_">
                <p id='_'>b</p>
              </dd>
            </dl>
          </figure>
          <figure id='_'>
            <image src='spec/examples/rice_images/rice_image1.png' id='_' mimetype='image/png' height='auto' width='auto'/>
            <dl id='_' key='true'>
              <dt>a</dt>
              <dd id="_">
                <p id='_'>b</p>
              </dd>
            </dl>
          </figure>
          <figure id='_'>
            <image src='spec/examples/rice_images/rice_image1.png' id='_' mimetype='image/png' height='auto' width='auto'/>
          </figure>
          <dl id='_'>
            <dt>a</dt>
            <dd id="_">
              <p id='_'>b</p>
            </dd>
          </dl>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
        <figure id="_" anchor="figureC-2"><name>Stages of gelatinization</name><figure id="_">
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
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
          <introduction id="_" obligation='informative'>
            <title>Introduction</title>
            <p id='_'>Introduction</p>
          </introduction>
        </preface>
        <sections>
          <admonition id='_' type='important'>
            <p id='_'>Notice which is very important</p>
          </admonition>
          <clause id="_" inline-header='false' obligation='normative' type="scope">
            <title>Scope</title>
            <p id='_'>Scope statement</p>
          </clause>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
      </metanorma>
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
      </metanorma>
    OUTPUT
    expect(Xml::C14n.format(Metanorma::Standoc::Converter.new(nil, *OPTIONS)
      .cleanup(Nokogiri::XML(input)).to_xml))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "deduplicates identifiers in embedded SVGs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR.sub(/:data-uri-image: false/, ':data-uri-image: true')}

      [height=100,width=100]
      image::spec/fixtures/action_schemaexpg1.svg[]

      image::spec/examples/rice_images/rice_image1.png[]

      image::spec/fixtures/action_schemaexpg1.svg[]
    INPUT

    output = <<~OUTPUT
        #{BLANK_HDR}
              <sections>
          <figure id="_" width="100">
            <image src="spec/fixtures/action_schemaexpg1.svg" mimetype="image/svg+xml" id="_" height="100" width="100">
              <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" id="Layer_1" x="0px" y="0px" viewBox="0 0 595.28 841.89" style="enable-background:new 0 0 595.28 841.89;" xml:space="preserve">
                <style/>
                <image/>
                <a xlink:href="mn://action_schema">
                  <rect x="123.28" y="273.93" width="88.05" height="41.84"/>
                </a>
                <a xlink:href="mn://basic_attribute_schema">
                  <rect x="324.69" y="450.52" width="132.62" height="40.75"/>
                </a>
                <a xlink:href="mn://support_resource_schema">
                  <rect x="324.69" y="528.36" width="148.16" height="40.75"/>
                </a>
              </svg>
            </image>
          </figure>
          <figure id="_">
            <image src="data:image/png" mimetype="image/png" id="_" height="auto" width="auto"/>
          </figure>
          <figure id="_">
            <image src="spec/fixtures/action_schemaexpg1.svg" mimetype="image/svg+xml" id="_" height="auto" width="auto">
              <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" id="Layer_1_inject_1" x="0px" y="0px" viewBox="0 0 595.28 841.89" style="enable-background:new 0 0 595.28 841.89;" xml:space="preserve">
                <style/>
                <image/>
                <a xlink:href="mn://action_schema">
                  <rect x="123.28" y="273.93" width="88.05" height="41.84"/>
                </a>
                <a xlink:href="mn://basic_attribute_schema">
                  <rect x="324.69" y="450.52" width="132.62" height="40.75"/>
                </a>
                <a xlink:href="mn://support_resource_schema">
                  <rect x="324.69" y="528.36" width="148.16" height="40.75"/>
                </a>
              </svg>
            </image>
          </figure>
        </sections>
      </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.xpath("//*[local-name() = 'svg']/*[local-name() = 'image']").each do |x|
      x.replace("<image/>")
    end
    expect(strip_guid(Xml::C14n.format(xml.to_xml)
      .gsub(%r{<style.*?</style>}m, "<style/>")
      .gsub(%r{data:image/png[^"']*}m, "data:image/png")
      .gsub(%r{ class="st0[^"]*"}m, "")))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "deduplicates SVG classes" do
    input = <<~INPUT
      #{BLANK_HDR}
        <sections>
        <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 256 256">
        <style>.B{fill:none}.C{stroke:#000}.D{stroke-linejoin:round}.E{stroke-miterlimit:10}.F{stroke-width:5}.G{stroke-linecap:round}.H{stroke-width:3.9}.I{fill:#fff}.J{stroke-dasharray:30.0001, 30.0001}.K{stroke-width:15}</style>
        <g transform="matrix(.133333 0 0 -.133333 -96.525 872.7067)">
         <path d="M2142.88 4842.01h580.793v425.191H2142.88z" clip-path="url(#A0)" class="B C D E F"/>
        </g>
       </svg>
       <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 256 256">
       <style>.B{stroke-linejoin:round}.C{stroke-miterlimit:10}.D{fill:none}.E{stroke:#000}.F{stroke-width:5}.G{stroke-width:3.9}.H{stroke-linecap:round}.I{fill:#fff}.J{stroke-width:15}.K{stroke-dasharray:30.0001, 30.0001}</style>
        <g transform="matrix(.133333 0 0 -.133333 -96.525 872.7067)">
         <path d="M2142.88 4842.01h580.793v425.191H2142.88z" clip-path="url(#A0)" class="B C D E F"/>
        </g>
       </svg>
        </sections>
      </metanorma>
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0 256 256">
             <style>.B_inject_0 {fill:none}.C_inject_0 {stroke:#000}.D_inject_0 {stroke-linejoin:round}.E_inject_0 {stroke-miterlimit:10}.F_inject_0 {stroke-width:5}.G_inject_0 {stroke-linecap:round}.H_inject_0 {stroke-width:3.9}.I_inject_0 {fill:#fff}.J_inject_0 {stroke-dasharray:30.0001, 30.0001}.K_inject_0 {stroke-width:15}</style>
             <g transform="matrix(.133333 0 0 -.133333 -96.525 872.7067)">
               <path d="M2142.88 4842.01h580.793v425.191H2142.88z" clip-path="url(#A0)" class="B_inject_0 C_inject_0 D_inject_0 E_inject_0 F_inject_0"/>
             </g>
           </svg>
           <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0 256 256">
             <style>.B_inject_1 {stroke-linejoin:round}.C_inject_1 {stroke-miterlimit:10}.D_inject_1 {fill:none}.E_inject_1 {stroke:#000}.F_inject_1 {stroke-width:5}.G_inject_1 {stroke-width:3.9}.H_inject_1 {stroke-linecap:round}.I_inject_1 {fill:#fff}.J_inject_1 {stroke-width:15}.K_inject_1 {stroke-dasharray:30.0001, 30.0001}</style>
             <g transform="matrix(.133333 0 0 -.133333 -96.525 872.7067)">
               <path d="M2142.88 4842.01h580.793v425.191H2142.88z" clip-path="url(#A0)" class="B_inject_1 C_inject_1 D_inject_1 E_inject_1 F_inject_1"/>
             </g>
           </svg>
         </sections>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(Metanorma::Standoc::Converter.new(nil, *OPTIONS)
      .cleanup(Nokogiri::XML(input)).to_xml))
      .to be_equivalent_to Xml::C14n.format(output)
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
          <clause id="_" inline-header='false' obligation='normative'>
            <title>Clause 1</title>
            <p id='_'>
              Paragraph
              <index>
                <primary>index</primary>
              </index>
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
            </p>
          </clause>
          <clause id="_" inline-header='false' obligation='normative'>
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
      </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.xpath("//*[local-name() = 'image']").each do |x|
      x.replace("<image/>")
    end
    expect(strip_guid(Xml::C14n.format(xml.to_xml)
      .gsub(%r{<style.*?</style>}m, "<style/>")))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "makes blocks unnumbered" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR.sub(':nodoc:', ":block-unnumbered: sourcecode , literal\n:nodoc:")}

      == Clause 1

      ....
      A
      ....

      [source]
      ----
      A
      ----

      ====
      A
      ====

      [source]
      ----
      B
      ----

      [[block]]
      [source]
      ----
      C
      ----

      [[_block]]
      [source]
      ----
      D
      ----

      [appendix]
      == Appendix

      ....
      A
      ....

      [source]
      ----
      A
      ----
    INPUT

    output = <<~OUTPUT
      #{BLANK_HDR}
           <sections>
             <clause id="_" inline-header="false" obligation="normative">
               <title>Clause 1</title>
               <figure id="_">
                 <pre id="_">A</pre>
               </figure>
               <sourcecode id="_" unnumbered="true"><body>A</body></sourcecode>
               <example id="_">
                 <p id="_">A</p>
               </example>
               <sourcecode id="_" unnumbered="true"><body>B</body></sourcecode>
               <sourcecode id="_" anchor="block" unnumbered="false"><body>C</body></sourcecode>
               <sourcecode id="_" anchor="_block" unnumbered="true"><body>D</body></sourcecode>
             </clause>
           </sections>
           <annex id="_" inline-header="false" obligation="normative">
             <title>Appendix</title>
             <figure id="_">
               <pre id="_">A</pre>
             </figure>
             <sourcecode id="_" unnumbered="true"><body>A</body></sourcecode>
           </annex>
         </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "removes empty paragraphs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      * {blank}
      a::: b
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
          <ul id="_">
             <li>
               <dl id="_">
                 <dt>a</dt>
                 <dd id="_">
                   <p id="_">b</p>
                 </dd>
               </dl>
             </li>
           </ul>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "preserves linebreaks in non-preformatted blocks" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Scope

      .Fragment of a collection description document with a links array and with one item of the array pointing to a list of map tilesets.
      =================
      *Hello
      _And_
      This*

      读写汉字
      _学_
      中文

      [source,json]
      ----
      {
          "links": [
          ...
          {
            "href": "https://data.example.com/collections/buildings/map/tiles",
            "rel": "https://www.opengis.net/def/rel/ogc/1.0/tilesets-map",
            "type": "application/json"
          }
        ]
      }
      ----

      We do not preserve line breaks in Maths though (stem:[x])
      =================
    INPUT
    output = <<~OUTPUT
      <metanorma xmlns="https://www.metanorma.org/ns/standoc" type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
       <bibdata type="standard">
       <title language="en" format="text/plain">Document title</title>
       <language>en</language><script>Latn</script><status><stage>published</stage></status><copyright><from>2025</from></copyright><ext><doctype>standard</doctype><flavor>standoc</flavor></ext></bibdata><metanorma-extension><presentation-metadata><name>TOC Heading Levels</name><value>2</value></presentation-metadata><presentation-metadata><name>HTML TOC Heading Levels</name><value>2</value></presentation-metadata><presentation-metadata><name>DOC TOC Heading Levels</name><value>2</value></presentation-metadata><presentation-metadata><name>PDF TOC Heading Levels</name><value>2</value></presentation-metadata></metanorma-extension>
       <sections><clause id="_" type="scope" inline-header="false" obligation="normative">
       <title>Scope</title>
       <example id="_">
       <name>Fragment of a collection description document with a links array and with one item of the array pointing to a list of map tilesets.</name>
       <p id="_"><strong>Hello <em>And</em> This</strong></p>

       <p id="_">读写汉字<em>学</em>中文</p>

       <sourcecode id="_" lang="json"><body>{
           "links": [
           ...
           {
             "href": "https://data.example.com/collections/buildings/map/tiles",
             "rel": "https://www.opengis.net/def/rel/ogc/1.0/tilesets-map",
             "type": "application/json"
           }
         ]
       }</body></sourcecode>

       <p id="_">We do not preserve line breaks in Maths though (<stem block="false" type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML">
         <mstyle displaystyle="false">
           <mi>x</mi>
         </mstyle>
       </math><asciimath>x</asciimath></stem>)</p>

       </example>
       </clause>
       </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_equivalent_to (output)
  end

  it "moves identifier of empty source-id:[] macro to its parent node" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Scope

      Hello source-id:ABC[text] source-id:DEF[]
    INPUT
    output = <<~OUTPUT
      <sections><clause id="_" type="scope" inline-header="false" obligation="normative">
      <title>Scope</title>
      <p id="_" source="DEF">Hello <span id="_" source="ABC">text</span> </p>
      </clause>
      </sections>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml = xml.at("//xmlns:sections")
    expect(strip_guid(xml.to_xml))
      .to be_equivalent_to (output)
  end

  it "preserves asciidoctor source linebreaks in blocks as space, but not in CJK, and not incorrectly inserting space or stripping space before inline markup" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Scope

      日本規格協会
      （*JSA*）から，

      日本規格協会（*JSA*）から，

      日本規格協会 *JSA* から，

      日本規格協会
      （*JSA*）から，

      日本規格協会
      *JSA*）から，

      日本規格協会
      *日*）から，

      ABC (*JSA*)

      ABC *JSA*

      ABC
      (*JSA*)

      ABC
      *JSA*)

    INPUT
    output = <<~OUTPUT
      <sections><clause id="_" type="scope" inline-header="false" obligation="normative">
      <title>Scope</title>
       <p id="_">日本規格協会（<strong>JSA</strong>）から，</p>
     
       <p id="_">日本規格協会（<strong>JSA</strong>）から，</p>
     
       <p id="_">日本規格協会 <strong>JSA</strong> から，</p>
     
       <p id="_">日本規格協会（<strong>JSA</strong>）から，</p>
     
       <p id="_">日本規格協会 <strong>JSA</strong>）から，</p>
     
       <p id="_">日本規格協会<strong>日</strong>）から，</p>
     
       <p id="_">ABC (<strong>JSA</strong>)</p>
     
       <p id="_">ABC <strong>JSA</strong></p>
     
       <p id="_">ABC (<strong>JSA</strong>)</p>
     
       <p id="_">ABC <strong>JSA</strong>)</p>
      </clause>
      </sections>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml = xml.at("//xmlns:sections")
    expect(strip_guid(xml.to_xml))
      .to be_equivalent_to (output)
  end
end
