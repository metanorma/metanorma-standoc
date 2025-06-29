require "spec_helper"
require "open3"

RSpec.describe Metanorma::Standoc do
  it "processes format-specific pass blocks" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [format="rfc,html"]
      ++++
      <abc>X &gt; Y</abc>
      ++++
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
      <sections>
      <passthrough formats='rfc,html'>&lt;abc&gt;X &amp;gt; Y&lt;/abc&gt;</passthrough>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes Metanorma XML pass blocks" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      ++++
      <abc>X &gt;
      ++++

      ++++
      Y</abc>
      ++++
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
      <sections>
      <abc>X &gt; Y</abc>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes open blocks" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      --
      x

      y

      z
      --
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
      <sections><p id="_">x</p>
      <p id="_">y</p>
      <p id="_">z</p></sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes form blocks" do
    mock_uuid_increment
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [form,id=N0,name=N1,action="/action_page.php",class="checkboxes"]
      --
      label:fname[First name:] +
      input:text[id=fname,name=fname]
      --

      [form,id=N1,name=N1,action="/action_page.php",class="checkboxes"]
      ====
      label:fname[First name:] +
      input:text[id=fname,name=fname]
      ====

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
          <sections>
             <form id="_1" anchor="N0" class="checkboxes" name="N1" action="/action_page.php">
                <p id="_2">
                   <label for="fname">First name:</label>
                   <br/>
                   <input type="text" anchor="fname" name="fname" id="_3"/>
                </p>
             </form>
             <form id="_4" anchor="N1" class="checkboxes" name="N1" action="/action_page.php">
                <p id="_5">
                   <label for="fname">First name:</label>
                   <br/>
                   <input type="text" anchor="fname" name="fname" id="_6"/>
                </p>
             </form>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes stem blocks" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[ABC]]
      [stem%inequality,number=3,keep-with-next=true,keep-lines-together=true,tag=X,columns=1,multilingual-rendering=common]
      ++++
      r = 1 %
      r = 1 %
      ++++

      [stem%unnumbered]
      ++++
      <mml:math><mml:msub xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"> <mml:mrow> <mml:mrow> <mml:mi mathvariant="bold-italic">F</mml:mi> </mml:mrow> </mml:mrow> <mml:mrow> <mml:mrow> <mml:mi mathvariant="bold-italic">&#x0391;</mml:mi> </mml:mrow> </mml:mrow> </mml:msub> </mml:math>
      ++++

      [latexmath,subsequence=A]
      ++++
      M =
      \\begin{bmatrix}
      -\\sin λ_0 & \\cos λ_0 & 0 \\\\
      -\\sin φ_0 \\cos λ_0 & -\\sin φ_0 \\sin λ_0 & \\cos φ_0 \\\\
      \\cos φ_0 \\cos λ_0 & \\cos φ_0 \\sin λ_0 & \\sin φ_0
      \\end{bmatrix}
      ++++

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                <sections>
             <formula id="_" anchor="ABC" tag="X" columns="1" multilingual-rendering="common" number="3" keep-with-next="true" keep-lines-together="true" inequality="true">
                <stem block="true" type="MathML">
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
             <formula id="_" unnumbered="true">
                <stem block="true" type="MathML">
                   <mml:math xmlns="">
                      <mml:msub xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math">
                         <mml:mrow>
                            <mml:mrow>
                               <mml:mi xmlns="https://www.metanorma.org/ns/standoc" mathvariant="bold-italic">F</mml:mi>
                            </mml:mrow>
                         </mml:mrow>
                         <mml:mrow>
                            <mml:mrow>
                               <mml:mi xmlns="https://www.metanorma.org/ns/standoc" mathvariant="bold-italic">Α</mml:mi>
                            </mml:mrow>
                         </mml:mrow>
                      </mml:msub>
                   </mml:math>
                </stem>
             </formula>
             <formula id="_" subsequence="A">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mi>M</mi>
                         <mo>=</mo>
                         <mrow>
                            <mo>[</mo>
                            <mtable>
                               <mtr>
                                  <mtd>
                                     <mrow>
                                        <mo>−</mo>
                                        <msub>
                                           <mrow>
                                              <mo rspace="thickmathspace"/>
                                              <mrow>
                                                 <mi>sin</mi>
                                                 <mi>λ</mi>
                                              </mrow>
                                           </mrow>
                                           <mn>0</mn>
                                        </msub>
                                     </mrow>
                                  </mtd>
                                  <mtd>
                                     <msub>
                                        <mrow>
                                           <mo rspace="thickmathspace"/>
                                           <mrow>
                                              <mi>cos</mi>
                                              <mi>λ</mi>
                                           </mrow>
                                        </mrow>
                                        <mn>0</mn>
                                     </msub>
                                  </mtd>
                                  <mtd>
                                     <mn>0</mn>
                                  </mtd>
                               </mtr>
                               <mtr>
                                  <mtd>
                                     <mrow>
                                        <mo>−</mo>
                                        <msub>
                                           <mrow>
                                              <mo rspace="thickmathspace"/>
                                              <mrow>
                                                 <mi>sin</mi>
                                                 <mi>φ</mi>
                                              </mrow>
                                           </mrow>
                                           <mn>0</mn>
                                        </msub>
                                     </mrow>
                                     <msub>
                                        <mrow>
                                           <mo rspace="thickmathspace"/>
                                           <mrow>
                                              <mi>cos</mi>
                                              <mi>λ</mi>
                                           </mrow>
                                        </mrow>
                                        <mn>0</mn>
                                     </msub>
                                  </mtd>
                                  <mtd>
                                     <mrow>
                                        <mo>−</mo>
                                        <msub>
                                           <mrow>
                                              <mo rspace="thickmathspace"/>
                                              <mrow>
                                                 <mi>sin</mi>
                                                 <mi>φ</mi>
                                              </mrow>
                                           </mrow>
                                           <mn>0</mn>
                                        </msub>
                                     </mrow>
                                     <msub>
                                        <mrow>
                                           <mo rspace="thickmathspace"/>
                                           <mrow>
                                              <mi>sin</mi>
                                              <mi>λ</mi>
                                           </mrow>
                                        </mrow>
                                        <mn>0</mn>
                                     </msub>
                                  </mtd>
                                  <mtd>
                                     <msub>
                                        <mrow>
                                           <mo rspace="thickmathspace"/>
                                           <mrow>
                                              <mi>cos</mi>
                                              <mi>φ</mi>
                                           </mrow>
                                        </mrow>
                                        <mn>0</mn>
                                     </msub>
                                  </mtd>
                               </mtr>
                               <mtr>
                                  <mtd>
                                     <msub>
                                        <mrow>
                                           <mo rspace="thickmathspace"/>
                                           <mrow>
                                              <mi>cos</mi>
                                              <mi>φ</mi>
                                           </mrow>
                                        </mrow>
                                        <mn>0</mn>
                                     </msub>
                                     <msub>
                                        <mrow>
                                           <mo rspace="thickmathspace"/>
                                           <mrow>
                                              <mi>cos</mi>
                                              <mi>λ</mi>
                                           </mrow>
                                        </mrow>
                                        <mn>0</mn>
                                     </msub>
                                  </mtd>
                                  <mtd>
                                     <msub>
                                        <mrow>
                                           <mo rspace="thickmathspace"/>
                                           <mrow>
                                              <mi>cos</mi>
                                              <mi>φ</mi>
                                           </mrow>
                                        </mrow>
                                        <mn>0</mn>
                                     </msub>
                                     <msub>
                                        <mrow>
                                           <mo rspace="thickmathspace"/>
                                           <mrow>
                                              <mi>sin</mi>
                                              <mi>λ</mi>
                                           </mrow>
                                        </mrow>
                                        <mn>0</mn>
                                     </msub>
                                  </mtd>
                                  <mtd>
                                     <msub>
                                        <mrow>
                                           <mo rspace="thickmathspace"/>
                                           <mrow>
                                              <mi>sin</mi>
                                              <mi>φ</mi>
                                           </mrow>
                                        </mrow>
                                        <mn>0</mn>
                                     </msub>
                                  </mtd>
                               </mtr>
                            </mtable>
                            <mo>]</mo>
                         </mrow>
                      </mstyle>
                   </math>
               <latexmath>M =
       \\begin{bmatrix}
       -\\sin λ_0  \\cos λ_0  0 \\\\
       -\\sin φ_0 \\cos λ_0  -\\sin φ_0 \\sin λ_0  \\cos φ_0 \\\\
       \\cos φ_0 \\cos λ_0  \\cos φ_0 \\sin λ_0  \\sin φ_0
       \\end{bmatrix}</latexmath>
             </stem>
           </formula>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes annotation blocks" do
    mock_uuid_increment
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :draft: 1.2

      ****
      Initial review 1
      ****

      ****
      Initial review 2
      ****

      [[foreword]]
      == Foreword

      _**Foreword**_

      [reviewer=ISO,date=20170101,from=foreword,to=foreword,type="whatever"]
      ****
      A Foreword shall appear in each document. The generic text is shown here. It does not contain requirements, recommendations or permissions.

      For further information on the Foreword, see *ISO/IEC Directives, Part 2, 2016, Clause 12.*
      ****

      ****
      Blank review
      ****

      == Clause title

      ****
      Second Blank review
      ****

      == {blank}

      ****
      Third Blank review
      ****

      == {blank}

      ****
      Fourth Blank review
      ****

      Following paragraph

      == {blank}

      Express the mass fraction of each defect using <<formulaA-1>>:

      [[formulaA-1,A.1]]
      [stem]
      ++++
      w = (m_D) / (m_s)
      ++++

      where

      stem:[w]:: is the mass fraction of grains with a particular defect in the test

      ****
      Fifth Blank review
      ****

      == {blank}

      Express the mass fraction of each defect using <<formulaA-1>>:

      [[formulaA-1,A.1]]
      [stem]
      ++++
      w = (m_D) / (m_s)
      ++++

      where

      w:: is the mass fraction of grains with a particular defect in the test

      ****
      Sixth Blank review
      ****

      == {blank}

      [NOTE]
      .Label
      Text

      ****
      Seventh Blank review
      ****

      == {blank}

      |===
      | A
      |===

      ****
      Eighth Blank review
      ****


      == {blank}

      .Caption
      |===
      | A
      |===

      ****
      Ninth Blank review
      ****
    INPUT
    output = <<~OUTPUT
      <metanorma xmlns="https://www.metanorma.org/ns/standoc"  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
       <bibdata type="standard">
         <title language="en" format="text/plain">Document title</title>


         <version>
           <draft>1.2</draft>
         </version>
         <language>en</language>
         <script>Latn</script>
         <status><stage>published</stage></status>
         <copyright>
           <from>#{Date.today.year}</from>
         </copyright>
         <ext>
         <doctype>standard</doctype>
            <flavor>standoc</flavor>
         </ext>
       </bibdata>
            <preface>
              <foreword id="_1" obligation="informative">
                 <title id="_66">
                    <bookmark id="_68" anchor="_68"/>
                    <bookmark id="_69" anchor="_69"/>
                    Foreword
                 </title>
              </foreword>
           </preface>
           <sections>
              <foreword id="_7" anchor="foreword" obligation="informative">
                 <title id="_67">Foreword</title>
                 <p id="_9">
                    <em>
                       <strong>
                          <bookmark id="_70" anchor="_70"/>
                          Foreword
                       </strong>
                    </em>
                 </p>
              </foreword>
              <clause id="_15" inline-header="false" obligation="normative">
                 <title id="_16">
                    <bookmark id="_71" anchor="_71"/>
                    Clause title
                 </title>
              </clause>
              <clause id="_19" inline-header="false" obligation="normative">
                 <p id="_79">
                    <bookmark id="_72" anchor="_72"/>
                 </p>
              </clause>
              <clause id="_23" inline-header="false" obligation="normative">
                 <p id="_27">
                    <bookmark id="_73" anchor="_73"/>
                    Following paragraph
                 </p>
              </clause>
              <clause id="_28" inline-header="false" obligation="normative">
                 <p id="_30">
                    <bookmark id="_74" anchor="_74"/>
                    Express the mass fraction of each defect using
                    <xref target="formulaA-1"/>
                    :
                 </p>
                 <formula id="_31" anchor="formulaA-1">
                    <stem block="true" type="MathML">
                       <math xmlns="http://www.w3.org/1998/Math/MathML">
                          <mstyle displaystyle="true">
                             <mi>w</mi>
                             <mo>=</mo>
                             <mfrac>
                                <msub>
                                   <mi>m</mi>
                                   <mi>D</mi>
                                </msub>
                                <msub>
                                   <mi>m</mi>
                                   <mi>s</mi>
                                </msub>
                             </mfrac>
                          </mstyle>
                       </math>
                       <asciimath>w = (m_D) / (m_s)</asciimath>
                    </stem>
                    <dl id="_33" key="true">
                       <dt>
                          <stem block="false" type="MathML">
                             <math xmlns="http://www.w3.org/1998/Math/MathML">
                                <mstyle displaystyle="false">
                                   <mi>w</mi>
                                </mstyle>
                             </math>
                             <asciimath>w</asciimath>
                          </stem>
                       </dt>
                       <dd id="_34">
                          <p id="_80">is the mass fraction of grains with a particular defect in the test</p>
                       </dd>
                    </dl>
                 </formula>
              </clause>
              <clause id="_37" inline-header="false" obligation="normative">
                 <p id="_39">
                    Express the mass fraction of each defect using
                    <xref target="formulaA-1"/>
                    :
                 </p>
                 <formula id="_40" anchor="formulaA-1">
                    <stem block="true" type="MathML">
                       <math xmlns="http://www.w3.org/1998/Math/MathML">
                          <mstyle displaystyle="true">
                             <mi>w</mi>
                             <mo>=</mo>
                             <mfrac>
                                <msub>
                                   <mi>m</mi>
                                   <mi>D</mi>
                                </msub>
                                <msub>
                                   <mi>m</mi>
                                   <mi>s</mi>
                                </msub>
                             </mfrac>
                          </mstyle>
                       </math>
                       <asciimath>w = (m_D) / (m_s)</asciimath>
                    </stem>
                    <dl id="_42" key="true">
                       <dt>
                          <bookmark id="_75" anchor="_75"/>
                          w
                       </dt>
                       <dd id="_43">
                          <p id="_81">is the mass fraction of grains with a particular defect in the test</p>
                       </dd>
                    </dl>
                 </formula>
              </clause>
              <clause id="_46" inline-header="false" obligation="normative">
                 <note id="_48">
                    <p id="_82">
                       <bookmark id="_76" anchor="_76"/>
                       Text
                    </p>
                 </note>
              </clause>
              <clause id="_51" inline-header="false" obligation="normative">
                 <table id="_53">
                    <tbody>
                       <tr id="_54">
                          <td id="_55" valign="top" align="left">
                             <bookmark id="_77" anchor="_77"/>
                             A
                          </td>
                       </tr>
                    </tbody>
                 </table>
              </clause>
              <clause id="_58" inline-header="false" obligation="normative">
                 <table id="_60">
                    <name id="_61">Caption</name>
                    <tbody>
                       <tr id="_62">
                          <td id="_63" valign="top" align="left">
                             <bookmark id="_78" anchor="_78"/>
                             A
                          </td>
                       </tr>
                    </tbody>
                 </table>
              </clause>
           </sections>
           <annotation-container>
              <annotation id="_3" reviewer="(Unknown)" date="#{Date.today}T00:00:00Z" type="review" from="_68" to="_68">
                 <p id="_4">Initial review 1</p>
              </annotation>
              <annotation id="_5" reviewer="(Unknown)" date="#{Date.today}T00:00:00Z" type="review" from="_69" to="_69">
                 <p id="_6">Initial review 2</p>
              </annotation>
              <annotation id="_10" reviewer="ISO" date="20170101T00:00:00Z" type="whatever" from="foreword" to="foreword">
                 <p id="_11">A Foreword shall appear in each document. The generic text is shown here. It does not contain requirements, recommendations or permissions.</p>
                 <p id="_12">
                    For further information on the Foreword, see
                    <strong>ISO/IEC Directives, Part 2, 2016, Clause 12.</strong>
                 </p>
              </annotation>
              <annotation id="_13" reviewer="(Unknown)" date="#{Date.today}T00:00:00Z" type="review" from="_70" to="_70">
                 <p id="_14">Blank review</p>
              </annotation>
              <annotation id="_17" reviewer="(Unknown)" date="#{Date.today}T00:00:00Z" type="review" from="_71" to="_71">
                 <p id="_18">Second Blank review</p>
              </annotation>
              <annotation id="_21" reviewer="(Unknown)" date="#{Date.today}T00:00:00Z" type="review" from="_72" to="_72">
                 <p id="_22">Third Blank review</p>
              </annotation>
              <annotation id="_25" reviewer="(Unknown)" date="#{Date.today}T00:00:00Z" type="review" from="_73" to="_73">
                 <p id="_26">Fourth Blank review</p>
              </annotation>
              <annotation id="_35" reviewer="(Unknown)" date="#{Date.today}T00:00:00Z" type="review" from="_74" to="_74">
                 <p id="_36">Fifth Blank review</p>
              </annotation>
              <annotation id="_44" reviewer="(Unknown)" date="#{Date.today}T00:00:00Z" type="review" from="_75" to="_75">
                 <p id="_45">Sixth Blank review</p>
              </annotation>
              <annotation id="_49" reviewer="(Unknown)" date="#{Date.today}T00:00:00Z" type="review" from="_76" to="_76">
                 <p id="_50">Seventh Blank review</p>
              </annotation>
              <annotation id="_56" reviewer="(Unknown)" date="#{Date.today}T00:00:00Z" type="review" from="_77" to="_77">
                 <p id="_57">Eighth Blank review</p>
              </annotation>
              <annotation id="_64" reviewer="(Unknown)" date="#{Date.today}T00:00:00Z" type="review" from="_78" to="_78">
                 <p id="_65">Ninth Blank review</p>
              </annotation>
           </annotation-container>
        </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(Xml::C14n.format(xml.to_xml.gsub(%r{ schema-version="[^"]+"}, "")))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes multiple term definitions" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      [definition]
      ====
      first definition

      [.source]
      <<ISO2191,section=1>>
      ====

      [.definition,type="simple"]
      --
      second definition

      [.source]
      <<ISO2191,section=2>>
      --

      NOTE: This is a note

      [.source]
      <<ISO2191,section=3>>

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <sections>
           <terms id="_" obligation='normative'>
             <title id="_">Terms and definitions</title>
             <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
             <term id="_" anchor="term-Term1">
               <preferred><expression>
               <name>Term1</name></expression></preferred>
               <definition id="_">
                 <verbal-definition id="_">
                 <p id='_'>first definition</p>
                 <source status='identical' type="authoritative">
                   <origin bibitemid='ISO2191' type='inline' citeas=''>
                     <localityStack>
                       <locality type='section'>
                         <referenceFrom>1</referenceFrom>
                       </locality>
                     </localityStack>
                   </origin>
                 </source>
                 </verbal-definition>
               </definition>
               <definition id="_" type="simple">
               <verbal-definition id="_">
                 <p id='_'>second definition</p>
                 <source status='identical' type="authoritative">
                   <origin bibitemid='ISO2191' type='inline' citeas=''>
                     <localityStack>
                       <locality type='section'>
                         <referenceFrom>2</referenceFrom>
                       </locality>
                     </localityStack>
                   </origin>
                 </source>
                 </verbal-definition>
               </definition>
               <termnote id='_'>
                 <p id='_'>This is a note</p>
               </termnote>
               <source status='identical' type="authoritative">
                 <origin bibitemid='ISO2191' type='inline' citeas=''>
                   <localityStack>
                     <locality type='section'>
                       <referenceFrom>3</referenceFrom>
                     </locality>
                   </localityStack>
                 </origin>
               </source>
             </term>
           </terms>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes term notes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      NOTE: This is a note

      WARNING: This is not a note

      [NOTE,keep-separate=true,tag=X,columns=1,multilingual-rendering=common]
      ====
      XYZ
      ====
    INPUT
    output = <<~OUTPUT
                   #{BLANK_HDR}
            <sections>
              <terms id="_" obligation="normative">
              <title id="_">Terms and definitions</title>
              <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
              <term id="_" anchor="term-Term1">
              <preferred><expression><name>Term1</name></expression></preferred>
              <termnote id="_">
              <p id="_">This is a note</p>
            </termnote>
            <admonition id='_' type='warning'>
          <p id='_'>This is not a note</p>
        </admonition>
             <termnote id='_' tag='X' columns='1' multilingual-rendering='common'>
        <p id='_'>XYZ</p>
      </termnote>
            </term>
            </terms>
            </sections>
            </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes term notes outside of terms sections" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Clause

      [NOTE%termnote]
      ====
      XYZ
      ====
    INPUT
    output = <<~OUTPUT
                     #{BLANK_HDR}
              <sections>
                  <clause id="_" inline-header='false' obligation='normative'>
        <title id="_">Clause</title>
        <termnote id='_'>
          <p id='_'>XYZ</p>
        </termnote>
      </clause>
              </sections>
              </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes term notes as plain notes in nonterm clauses" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      NOTE: This is not a termnote

      ====
      This is not a termexample
      ====

      [.nonterm]
      === Term1

      NOTE: This is a note
    INPUT
    output = <<~OUTPUT
                    #{BLANK_HDR}
                    <sections>
        <terms id="_" obligation="normative">
        <title id="_">Terms and Definitions</title>
               <p id="_">No terms and definitions are listed in this document.</p>
               <note id='_'>
        <p id='_'>This is not a termnote</p>
      </note>
        <example id='_'>
        <p id='_'>This is not a termexample</p>
      </example>
        <clause id="_" inline-header="false" obligation="normative">
        <title id="_">Term1</title>
        <note id="_">
        <p id="_">This is a note</p>
      </note>
      </clause>
      </terms>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes term notes as plain notes in definitions subclauses of terms & definitions" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      === Symbols

      NOTE: This is a note
    INPUT
    output = <<~OUTPUT
                    #{BLANK_HDR}
                    <sections>
        <terms id="_" obligation="normative"><title id="_">Terms, definitions and symbols</title>
      <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
      <term id="_" anchor="term-Term1">
        <preferred><expression><name>Term1</name></expression></preferred>
      </term>
      <definitions id="_" obligation="normative" type="symbols">
        <title id="_">Symbols</title>
        <note id="_">
        <p id="_">This is a note</p>
      </note>
      </definitions></terms>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes nested terms" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      [.term]
      === Term1

      definition

      NOTE: Note 1

      ==== Term11
      definition2

      NOTE: Note 2
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                <sections>
           <clause id="_" obligation='normative' type="terms">
             <title id="_">Terms and definitions</title>
             <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
             <terms id="_" obligation='normative'>
               <title id="_">Term1</title>
               <p id='_'>definition</p>
               <note id='_'>
                 <p id='_'>Note 1</p>
               </note>
               <term id="_" anchor="term-Term11">
                 <preferred>
                   <expression>
                     <name>Term11</name>
                   </expression>
                 </preferred>
                 <definition id="_">
                   <verbal-definition id="_">
                     <p id='_'>definition2</p>
                   </verbal-definition>
                 </definition>
                 <termnote id='_'>
                   <p id='_'>Note 2</p>
                 </termnote>
               </term>
             </terms>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes notes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      NOTE: This is a note

      == Clause 1

      [[ABC]]
      NOTE: This is a note

      [NOTE,keep-separate=true,number=7,subsequence=A,beforeclauses=true,keep-with-next=true,keep-lines-together=true,type=classified,tag=X,columns=1,multilingual-rendering=common]
      ====
      XYZ
      ====
    INPUT
    output = <<~OUTPUT
                  #{BLANK_HDR}
                  <preface><foreword id="_" obligation="informative">
             <title id="_">Foreword</title>
             <note id="_">
             <p id="_">This is a note</p>
           </note>
           </foreword></preface><sections>
             <note id='_' number="7" subsequence="A" keep-with-next="true" keep-lines-together="true" type="classified" tag='X' columns='1' multilingual-rendering='common'>
        <p id='_'>XYZ</p>
      </note>
           <clause id="_" inline-header="false" obligation="normative">
             <title id="_">Clause 1</title>
             <note id="_" anchor="ABC">
             <p id="_">This is a note</p>
           </note>
           </clause></sections>

           </metanorma>

    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes literals" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[ABC]]
      [alt=Literal,keep-with-next=true,keep-lines-together=true,tag=X,columns=1,multilingual-rendering=common]
      ....
      <LITERAL>
      FIGURATIVE
      ....
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
       <sections>
           <figure id="_" anchor="ABC" keep-with-next="true" keep-lines-together="true" tag='X' columns='1' multilingual-rendering='common'>
        <pre id="_" tag="X" columns="1" multilingual-rendering="common" alt="Literal">&lt;LITERAL&gt;
        FIGURATIVE
        </pre>
        </figure>
       </sections>
       </metanorma>

    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes simple admonitions with Asciidoc names" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      CAUTION: Only use paddy or parboiled rice for the determination of husked rice yield.
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
       <sections>
         <admonition id="_" type="caution">
         <p id="_">Only use paddy or parboiled rice for the determination of husked rice yield.</p>
       </admonition>
       </sections>
       </metanorma>

    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes complex admonitions with non-Asciidoc names" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[ABC]]
      [CAUTION,type=Safety Precautions,keep-with-next="true",keep-lines-together="true",tag=X,columns=1,multilingual-rendering=common,notag=true]
      .Precautions
      ====
      While werewolves are hardy community members, keep in mind the following dietary concerns:

      . They are allergic to cinnamon.
      . More than two glasses of orange juice in 24 hours makes them howl in harmony with alarms and sirens.
      . Celery makes them sad.
      ====

      [TIP,type=Box]
      ====
      This is a box
      ====
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
         <admonition id="_" anchor="ABC" type="safety precautions" keep-with-next="true" keep-lines-together="true" tag='X' columns='1' multilingual-rendering='common' notag="true" unnumbered="true">
        <name id="_">Precautions</name><p id="_">While werewolves are hardy community members, keep in mind the following dietary concerns:</p>
       <ol id="_" type="arabic">
         <li>
           <p id="_">They are allergic to cinnamon.</p>
         </li>
         <li>
           <p id="_">More than two glasses of orange juice in 24 hours makes them howl in harmony with alarms and sirens.</p>
         </li>
         <li>
           <p id="_">Celery makes them sad.</p>
         </li>
       </ol></admonition>
           <admonition id="_" type="box">
      <p id="_">This is a box</p>
       </admonition>
       </sections>
       </metanorma>

    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes term examples" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      [[ABC]]
      [example,tag=X,columns=1,multilingual-rendering=common]
      This is an example
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
            <sections>
        <terms id="_" obligation="normative">
        <title id="_">Terms and definitions</title>
      <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
        <term id="_" anchor="term-Term1">
        <preferred><expression><name>Term1</name></expression></preferred>
      <termexample id="_" anchor="ABC" tag='X' columns='1' multilingual-rendering='common'>
        <p id="_">This is an example</p>
      </termexample></term>
      </terms>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes term examples outside of terms sections" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Clause

      [%termexample]
      ====
      XYZ
      ====
    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
              <sections>
                  <clause id="_" inline-header='false' obligation='normative'>
        <title id="_">Clause</title>
        <termexample id='_'>
          <p id='_'>XYZ</p>
        </termexample>
      </clause>
              </sections>
              </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes term examples as plain examples in nonterm clauses" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      [.nonterm]
      === Term1

      [example]
      This is an example
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
      <sections>
        <terms id="_" obligation="normative">
        <title id="_">Terms and Definitions</title>
      <p id="_">No terms and definitions are listed in this document.</p>
        <clause id="_" inline-header="false" obligation="normative">
        <title id="_">Term1</title>
        <example id="_">
        <p id="_">This is an example</p>
      </example>
      </clause>
      </terms>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes term examples as plain examples in definitions subclauses of terms & definitions" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      === Symbols

      [example]
      This is an example
    INPUT
    output = <<~OUTPUT
                    #{BLANK_HDR}
      <sections>
        <terms id="_" obligation="normative"><title id="_">Terms, definitions and symbols</title>
      <p id="_">For the purposes of this document, the following terms and definitions apply.</p><term id="_" anchor="term-Term1">
        <preferred><expression><name>Term1</name></expression></preferred>
      </term>
      <definitions id="_" obligation="normative" type="symbols">
        <title id="_">Symbols</title>
        <example id="_">
        <p id="_">This is an example</p>
      </example>
      </definitions></terms>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes examples" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[ABC]]
      [example,subsequence=A,keep-with-next=true,keep-lines-together=next,tag=X,columns=1,multilingual-rendering=common]
      .Title
      ====
      This is an example

      Amen
      ====

      [example%unnumbered]
      ====
      This is another example
      ====

      [example,number=3]
      ====
      This is yet another example
      ====
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
       <sections>
         <example id="_" anchor="ABC" subsequence="A"  keep-with-next='true' keep-lines-together='next' tag='X' columns='1' multilingual-rendering='common'>
         <name id="_">Title</name>
        <p id="_">This is an example</p>
       <p id="_">Amen</p></example>
         <example id="_" unnumbered="true"><p id="_">This is another example</p></example>
         <example id="_" number="3"><p id="_">This is yet another example</p></example>
       </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes preambles" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      This is a preamble

      == Section 1
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <preface><foreword id="_" obligation="informative">
         <title id="_">Foreword</title>
         <p id="_">This is a preamble</p>
       </foreword></preface><sections>
       <clause id="_" inline-header="false" obligation="normative">
         <title id="_">Section 1</title>
       </clause></sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes preambles with titles" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      .Preamble
      This is a preamble

      == Section 1
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <preface><foreword id="_" obligation="informative">
         <title id="_">Foreword</title>
         <p id="_">This is a preamble</p>
       </foreword></preface><sections>
       <clause id="_" inline-header="false" obligation="normative">
         <title id="_">Section 1</title>
       </clause></sections>
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

      [%key]
      A:: B
      ====
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections>
        <figure id="_" anchor="figureC-2"><name id="_">Stages of gelatinization</name><figure id="_">
        <name id="_">Initial stages: No grains are fully gelatinized (ungelatinized starch granules are visible inside the kernels)</name>
        <image id="_" src="spec/examples/rice_images/rice_image3_1.png" mimetype="image/png" height="auto" width="auto"/>
      </figure>
      <figure id="_">
        <name id="_">Intermediate stages: Some fully gelatinized kernels are visible</name>
        <image id="_" src="spec/examples/rice_images/rice_image3_2.png" mimetype="image/png" height="auto" width="auto"/>
      </figure>
      <figure id="_">
        <name id="_">Final stages: All kernels are fully gelatinized</name>
        <image id="_" src="spec/examples/rice_images/rice_image3_3.png" mimetype="image/png" height="auto" width="auto"/>
      </figure>
      <dl id='_' key='true'>
        <dt>A</dt>
        <dd id="_">
          <p id='_'>B</p>
        </dd>
      </dl>
      </figure>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "does not create subfigures if there is only one nested figure" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [[figureC-2]]
      [.figure]
      .Stages of gelatinization
      ====
      image::spec/examples/rice_images/rice_image3_1.png[]
      ====
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections>
        <figure id="_" anchor="figureC-2"><name id="_">Stages of gelatinization</name>
        <image src="spec/examples/rice_images/rice_image3_1.png" id="_" mimetype="image/png" height="auto" width="auto"/>
      </figure>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes figures within examples" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [[figureC-2]]
      .Stages of gelatinization
      ====
      .Initial stages: No grains are fully gelatinized (ungelatinized starch granules are visible inside the kernels)
      image::spec/examples/rice_images/rice_image3_1.png[]

      Text

      .Intermediate stages: Some fully gelatinized kernels are visible
      image::spec/examples/rice_images/rice_image3_2.png[]

      .Final stages: All kernels are fully gelatinized
      image::spec/examples/rice_images/rice_image3_3.png[]
      ====
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections>
        <example id="_" anchor="figureC-2"><name id="_">Stages of gelatinization</name><figure id="_">
        <name id="_">Initial stages: No grains are fully gelatinized (ungelatinized starch granules are visible inside the kernels)</name>
        <image src="spec/examples/rice_images/rice_image3_1.png" id="_" mimetype="image/png" height="auto" width="auto"/>
      </figure>
      <p id="_">Text</p>
      <figure id="_">
        <name id="_">Intermediate stages: Some fully gelatinized kernels are visible</name>
        <image src="spec/examples/rice_images/rice_image3_2.png" id="_" mimetype="image/png" height="auto" width="auto"/>
      </figure>
      <figure id="_">
        <name id="_">Final stages: All kernels are fully gelatinized</name>
        <image src="spec/examples/rice_images/rice_image3_3.png" id="_" mimetype="image/png" height="auto" width="auto"/>
      </figure></example>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes figures marked up as examples" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [[figureC-2]]
      [.figure]
      .Stages of gelatinization
      ====
      .Initial stages: No grains are fully gelatinized (ungelatinized starch granules are visible inside the kernels)
      image::spec/examples/rice_images/rice_image3_1.png[]

      Text

      .Intermediate stages: Some fully gelatinized kernels are visible
      image::spec/examples/rice_images/rice_image3_2.png[]

      .Final stages: All kernels are fully gelatinized
      image::spec/examples/rice_images/rice_image3_3.png[]

      [.source,status=generalisation]
      <<ISO2191,section=1>>, with adjustments

      [.source,status=specialisation]
      <<ISO2191,section=2>>, with adjustments
      ====
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections>
        <figure id="_" anchor="figureC-2"><name id="_">Stages of gelatinization</name><figure id="_">
        <name id="_">Initial stages: No grains are fully gelatinized (ungelatinized starch granules are visible inside the kernels)</name>
        <image src="spec/examples/rice_images/rice_image3_1.png" id="_" mimetype="image/png" height="auto" width="auto"/>
      </figure>
      <p id="_">Text</p>
      <figure id="_">
        <name id="_">Intermediate stages: Some fully gelatinized kernels are visible</name>
        <image src="spec/examples/rice_images/rice_image3_2.png" id="_" mimetype="image/png" height="auto" width="auto"/>
      </figure>
      <figure id="_">
        <name id="_">Final stages: All kernels are fully gelatinized</name>
        <image src="spec/examples/rice_images/rice_image3_3.png" id="_" mimetype="image/png" height="auto" width="auto"/>
      </figure>
      <source status="generalisation">
        <origin bibitemid="ISO2191" type="inline" citeas="">
          <localityStack>
            <locality type="section">
              <referenceFrom>1</referenceFrom>
            </locality>
          </localityStack>
        </origin>
        <modification>
          <p id="_">with adjustments</p>
        </modification>
      </source>
                   <source status="specialisation">
               <origin bibitemid="ISO2191" type="inline" citeas="">
                 <localityStack>
                   <locality type="section">
                     <referenceFrom>2</referenceFrom>
                   </locality>
                 </localityStack>
               </origin>
               <modification>
                 <p id="_">with adjustments</p>
               </modification>
             </source>
        </figure>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "ignores index terms when processing figures marked up as examples" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      ====
      image::spec/examples/rice_images/rice_image3_1.png[]
      ====

      ====
      ((indexterm))

      image::spec/examples/rice_images/rice_image3_3.png[]
      ====

      ====
      (((indexterm2)))

      image::spec/examples/rice_images/rice_image3_2.png[]
      ====
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <figure id='_'>
             <image src='spec/examples/rice_images/rice_image3_1.png' id='_' mimetype='image/png' height='auto' width='auto'/>
           </figure>
           <example id='_'>
             <p id='_'>
               indexterm
               <index>
                 <primary>indexterm</primary>
               </index>
             </p>
             <figure id='_'>
               <image src='spec/examples/rice_images/rice_image3_3.png' id='_' mimetype='image/png' height='auto' width='auto'/>
             </figure>
           </example>
           <figure id='_'>
             <index>
               <primary>indexterm2</primary>
             </index>
             <image src='spec/examples/rice_images/rice_image3_2.png' id='_' mimetype='image/png' height='auto' width='auto'/>
           </figure>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes images" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[ABC]]
      [%unnumbered,number=3,class=plate]
      .Split-it-right sample divider
      image::spec/examples/rice_images/rice_image1.png[alttext]

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
              <sections>
         <figure id="_" anchor="ABC" unnumbered="true" number="3" class="plate">
         <name id="_">Split-it-right sample divider</name>
                  <image src="spec/examples/rice_images/rice_image1.png" id="_" mimetype="image/png" height="auto" width="auto" alt="alttext"/>
       </figure>
       </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes data URI images" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [subsequence=A]
      .Split-it-right sample divider
      image::data:image/*;base64,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[alttext]

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
              <sections>
         <figure id="_" subsequence="A">
         <name id="_">Split-it-right sample divider</name>
           <image src="data:image/png;base64,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" id="_" mimetype="image/png" height="auto" width="auto" alt="alttext"/>
       </figure>
       </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "accepts attributes on images" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [height=4,width=3,alt="IMAGE",filename="riceimg1.png",titleattr="TITLE",tag=X,columns=1,multilingual-rendering=common]
      .Caption
      image::spec/examples/rice_images/rice_image1.png[]

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
       <sections>
         <figure id="_" tag='X' columns='1' multilingual-rendering='common' width="3">
         <name id="_">Caption</name>
         <image id="_" tag="X" columns="1" multilingual-rendering="common" src="spec/examples/rice_images/rice_image1.png" mimetype="image/png" height="4" width="3" filename="riceimg1.png" title="TITLE" alt="IMAGE"/>
       </figure>
       </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "accepts auto, float and percent values for width and height attributes on images" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [height=4.3,width=auto]
      image::spec/examples/rice_images/rice_image1.png[]

      [height=auto,width=9.3%]
      image::spec/examples/rice_images/rice_image1.png[]

      [height=9.3%,width=9%]
      image::spec/examples/rice_images/rice_image1.png[]

      [width=text-width]
      image::spec/examples/rice_images/rice_image1.png[]

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
       <sections>
         <figure id="_" width="auto">
            <image id="_" src="spec/examples/rice_images/rice_image1.png" mimetype="image/png" height="4.3" width="auto"/>
          </figure>
         <figure id="_" width="9.3%">
            <image id="_" src="spec/examples/rice_images/rice_image1.png" mimetype="image/png" height="auto" width="9.3%"/>
          </figure>
         <figure id="_" width="9%">
            <image id="_" src="spec/examples/rice_images/rice_image1.png" mimetype="image/png" height="9.3%" width="9%"/>
          </figure>
          <figure id="_" width="text-width">
              <image id="_" src="spec/examples/rice_images/rice_image1.png" mimetype="image/png" height="auto" width="text-width"/>
          </figure>
       </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes inline images with width and height attributes on images" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      Hello image:spec/examples/rice_images/rice_image1.png[alt, 4, 3], how are you?

      Hello image:spec/examples/rice_images/rice_image1.png[alt, 4.9, 3.4%], how are you?

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
              <sections>
          <p id="_">Hello <image src="spec/examples/rice_images/rice_image1.png" id="_" mimetype="image/png" height="3" width="4" alt="alt"/>, how are you?</p>
          <p id="_">Hello <image src="spec/examples/rice_images/rice_image1.png" mimetype="image/png" id="_" height="3.4%" width="4.9" alt="alt"/>, how are you?</p>
       </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes images as datauri" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :data-uri-image:

      .Split-it-right sample divider
      image::spec/examples/rice_images/rice_image1.png[]
    INPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to include('<image id="_" src="data:image/png;base64')

    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :data-uri-image: true

      .Split-it-right sample divider
      image::spec/examples/rice_images/rice_image1.png[]
    INPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to include('<image id="_" src="data:image/png;base64')

    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :data-uri-image: false

      .Split-it-right sample divider
      image::spec/examples/rice_images/rice_image1.png[]
    INPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .not_to include('<image id="_" src="data:image/png;base64')

    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:

      .Split-it-right sample divider
      image::spec/examples/rice_images/rice_image1.png[]
    INPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to include('<image id="_" src="data:image/png;base64')

    FileUtils.rm_rf "spec/examples/test.xml"
    system "bundle exec asciidoctor -b standoc -r metanorma-standoc spec/examples/test.adoc"
    expect(strip_guid(File.read("spec/examples/test.xml")))
      .to include('<image id="_" src="data:image/png;base64')
  end

  it "accepts attributes on paragraphs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [align=right,keep-with-next=true,keep-lines-together=true,tag=X,columns=1,multilingual-rendering=common]
      This para is right-aligned.
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
         <p align="right" id="_" keep-with-next="true" keep-lines-together="true" tag='X' columns='1' multilingual-rendering='common'>This para is right-aligned.</p>
       </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes blockquotes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[ABC]]
      [quote, ISO, "ISO7301,section 1",align="right",keep-with-next=true,keep-lines-together=true,tag=X,columns=1,multilingual-rendering=common]
      ____
      Block quotation
      ____
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
       <sections>
         <quote id="_" anchor="ABC" align="right" keep-with-next="true" keep-lines-together="true" tag='X' columns='1' multilingual-rendering='common'>
         <source type="inline" bibitemid="ISO7301" citeas="">
         <localityStack>
        <locality type="section"><referenceFrom>1</referenceFrom></locality>
         </localityStack>
        </source>
         <author>ISO</author>
         <p id="_">Block quotation</p>
       </quote>
       </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes source code" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[ABC]]
      .Caption
      [source%unnumbered%linenums,ruby,number=3,filename=sourcecode1.rb,keep-with-next=true,keep-lines-together=true,tag=X,columns=1,multilingual-rendering=common]
      --
      puts "Hello, world."
      %w{a b c}.each do |x|
        puts x
      end
      --

      [source]
      --
      puts "Hello, world."
      %w{a b c}.each do |x|
        puts x
      end
      --

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
       <sections>
         <sourcecode id="_" anchor="ABC" lang="ruby" filename="sourcecode1.rb" unnumbered="true" number="3" keep-with-next="true" keep-lines-together="true" tag='X' columns='1' multilingual-rendering='common' linenums='true'>
        <name id="_">Caption</name><body>puts "Hello, world."
       %w{a b c}.each do |x|
         puts x
       end</body></sourcecode>
         <sourcecode id="_"><body>
        puts "Hello, world."
       %w{a b c}.each do |x|
         puts x
       end</body></sourcecode>
       </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes source code with :source-linenums-option:" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR.sub(/:nodoc:/, ":source-linenums-option: true\n:nodoc:")}

      [[ABC]]
      .Caption
      [source%unnumbered%linenums,ruby,number=3,filename=sourcecode1.rb,keep-with-next=true,keep-lines-together=true,tag=X,columns=1,multilingual-rendering=common]
      --
      puts "Hello, world."
      %w{a b c}.each do |x|
        puts x
      end
      --

      [source]
      --
      puts "Hello, world."
      %w{a b c}.each do |x|
        puts x
      end
      --

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
       <sections>
         <sourcecode id="_" anchor="ABC" lang="ruby" filename="sourcecode1.rb" unnumbered="true" number="3" keep-with-next="true" keep-lines-together="true" tag='X' columns='1' multilingual-rendering='common' linenums='true'>
        <name id="_">Caption</name><body>puts "Hello, world."
       %w{a b c}.each do |x|
         puts x
       end</body></sourcecode>
         <sourcecode id="_" linenums='true'><body>
        puts "Hello, world."
       %w{a b c}.each do |x|
         puts x
       end</body></sourcecode>
       </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes callouts" do
    mock_uuid_increment
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [source,ruby]
      --
      puts "Hello, world." <1>
      %w{a b c}.each do |x|
        puts x <2>
      end
      --
      <1> This is one callout
      <2> This is another callout
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
          <sections>
             <sourcecode id="_1" lang="ruby">
                <body>
                   puts "Hello, world."
                   <callout target="_2">1</callout>
                   %w{a b c}.each do |x| puts x
                   <callout target="_3">2</callout>
                   end
                </body>
                <callout-annotation id="_2" anchor="_2">
                   <p id="_4">This is one callout</p>
                </callout-annotation>
                <callout-annotation id="_3" anchor="_3">
                   <p id="_5">This is another callout</p>
                </callout-annotation>
             </sourcecode>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes unmodified term sources" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      Definition 0

      [.source]
      <<ISO2191,section=1>>

      [.source]
      <<ISO2191,droploc%capital%section=1>>

      === Term2

      Definition

      [.source]
      {{<<IEV:xyz>>}}

      [.source]
      {{<<IEV:xyz>>,t1}}

      [.source]
      {{<<IEV:xyz>>,t1,t2}}
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
             <sections>
               <terms id="_" obligation="normative">
               <title id="_">Terms and definitions</title><p id="_">For the purposes of this document,
             the following terms and definitions apply.</p>
               <term id="_" anchor="term-Term1">
               <preferred><expression><name>Term1</name></expression></preferred>
               <definition id="_"><verbal-definition id="_"><p id='_'>Definition 0</p></verbal-definition></definition>
               <source status="identical" type="authoritative">
               <origin bibitemid="ISO2191" type="inline" citeas="">
               <localityStack>
              <locality type="section"><referenceFrom>1</referenceFrom></locality>
              </localityStack>
              </origin>
             </source>
             <source status="identical" type="authoritative">
               <origin bibitemid="ISO2191" type="inline" citeas="" case='capital' droploc='true'>
               <localityStack>
              <locality type="section"><referenceFrom>1</referenceFrom></locality>
              </localityStack>
              </origin>
             </source>
             </term>
             <term id="_" anchor="term-Term2">
        <preferred><expression><name>Term2</name></expression></preferred>
        <definition id="_">
        <verbal-definition id="_">
          <p id='_'>Definition</p>
          </verbal-definition>
        </definition>
        <source status='identical' type="authoritative">
          <origin citeas=''>
          <display-text>
            <termref base='IEV' target='xyz'/>
            </display-text>
          </origin>
        </source>
        <source status='identical' type="authoritative">
          <origin citeas=''>
          <display-text>
            <termref base='IEV' target='xyz'/>
            </display-text>
          </origin>
        </source>
        <source status='identical' type="authoritative">
          <origin citeas=''>
          <display-text>
            <termref base='IEV' target='xyz'/>
            </display-text>
          </origin>
        </source>
      </term>
             </terms>
             </sections>
             </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes modified term sources" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      Definition 0

      [.source]
      <<ISO2191,section=1>>, with adjustments

      === Term2

      Definition

      [.source]
      {{<<IEV:xyz>>}}, with adjustments
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
                  <sections>
               <terms id="_" obligation="normative">
               <title id="_">Terms and definitions</title>
               <p id="_">For the purposes of this document,
             the following terms and definitions apply.</p>
               <term id="_" anchor="term-Term1">
               <preferred><expression><name>Term1</name></expression></preferred>
               <definition id="_"><verbal-definition id="_"><p id='_'>Definition 0</p></verbal-definition></definition>
               <source status="modified" type="authoritative">
               <origin bibitemid="ISO2191" type="inline" citeas="">
               <localityStack>
              <locality type="section"><referenceFrom>1</referenceFrom></locality>
              </localityStack>
              </origin>
               <modification>
                 <p id="_">with adjustments</p>
               </modification>
             </source>
             </term>
             <term id="_" anchor="term-Term2">
        <preferred><expression><name>Term2</name></expression></preferred>
        <definition id="_"><verbal-definition id="_">
          <p id='_'>Definition</p>
        </verbal-definition></definition>
        <source status='modified' type="authoritative">
          <origin citeas=''>
          <display-text>
            <termref base='IEV' target='xyz'/>
          </display-text>
          </origin>
          <modification>
            <p id='_'>with adjustments</p>
          </modification>
        </source>
      </term>
             </terms>
             </sections>
             </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes term source attributes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      Definition 0

      [.source,status=generalisation]
      <<ISO2191,section=1>>, with adjustments

      === Term2

      Definition

      [.source,type=lineage]
      {{<<IEV:xyz>>}}, with adjustments
    INPUT
    output = <<~OUTPUT
                #{BLANK_HDR}
                  <sections>
        <terms id="_" obligation='normative'>
          <title id="_">Terms and definitions</title>
          <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
          <term id="_" anchor="term-Term1">
            <preferred>
              <expression>
                <name>Term1</name>
              </expression>
            </preferred>
            <definition id="_"><verbal-definition id="_"><p id='_'>Definition 0</p></verbal-definition></definition>
            <source status='generalisation' type='authoritative'>
              <origin bibitemid='ISO2191' type='inline' citeas=''>
                <localityStack>
                  <locality type='section'>
                    <referenceFrom>1</referenceFrom>
                  </locality>
                </localityStack>
              </origin>
              <modification>
                <p id='_'>with adjustments</p>
              </modification>
            </source>
          </term>
          <term id="_" anchor="term-Term2">
            <preferred>
              <expression>
                <name>Term2</name>
              </expression>
            </preferred>
            <definition id="_"><verbal-definition id="_">
              <p id='_'>Definition</p>
            </verbal-definition></definition>
            <source status='modified' type='lineage'>
              <origin citeas=''>
              <display-text>
                <termref base='IEV' target='xyz'/>
                </display-text>
              </origin>
              <modification>
                <p id='_'>with adjustments</p>
              </modification>
            </source>
          </term>
        </terms>
      </sections>
                </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes delete change clauses" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [change="modify",locality="page=27",path="//table[2]",path_end="//table[2]/following-sibling:example[1]",title="Change"]
      ==== Change Clause
      _This table contains information on polygon cells which are not included in ISO 10303-52. Remove table 2 completely and replace with:_
    INPUT
    output = <<~"OUTPUT"
                  #{BLANK_HDR}
                  <sections>
        <clause id="_" inline-header='false' obligation='normative'>
          <title id="_">Change Clause</title>
          <amend id='_' change='modify' path='//table[2]' path_end='//table[2]/following-sibling:example[1]' title='Change'>
            <description>
              <p id='_'>
                <em>
                  This table contains information on polygon cells which are not
                  included in ISO 10303-52. Remove table 2 completely and replace
                  with:
                </em>
              </p>
            </description>
          </amend>
        </clause>
      </sections>
                  </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes modify change clauses" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [change="modify",locality="page=27",path="//table[2]",path_end="//table[2]/following-sibling:example[1]",title="Change"]
      ==== Change Clause

      autonumber:table[2]
      autonumber:note[7]

      _This table contains information on polygon cells which are not included in ISO 10303-52. Remove table 2 completely and replace with:_

      ____
      .Edges of triangle and quadrilateral cells
      |===
      2+^.^h| triangle 2+^.^h| quadrilateral
      ^.^| edge ^.^| vertices ^.^| edge ^.^| vertices
      ^.^| 1 ^.^| 1, 2 ^.^| 1 ^.^| 1, 2
      ^.^| 2 ^.^| 2, 3 ^.^| 2 ^.^| 2, 3
      ^.^| 3 ^.^| 3, 1 ^.^| 3 ^.^| 3, 4
      | | ^.^| 4 ^.^| 4, 1
      |===

      ====
      This is not generalised further.
      ====

      ____

      Any further exceptions can be ignored.
    INPUT

    output = <<~"OUTPUT"
                  #{BLANK_HDR}
           <sections>
        <clause id="_" inline-header='false' obligation='normative'>
          <title id="_">Change Clause</title>
          <amend id='_' change='modify' path='//table[2]' path_end='//table[2]/following-sibling:example[1]' title='Change'>
          <autonumber type='table'>2</autonumber>
                     <autonumber type='note'>7</autonumber>
                     <description>
                       <p id='_'>
                         <em>
                           This table contains information on polygon cells which are not
                           included in ISO 10303-52. Remove table 2 completely and replace
                           with:
                         </em>
                       </p>
                     </description>
            <newcontent id='_'>
              <table id='_'>
                <name id="_">Edges of triangle and quadrilateral cells</name>
                <tbody>
                  <tr id="_">
                    <th id="_" colspan='2' valign='middle' align='center'>triangle</th>
                    <th id="_" colspan='2' valign='middle' align='center'>quadrilateral</th>
                  </tr>
                  <tr id="_">
                    <td id="_" valign='middle' align='center'>edge</td>
                    <td id="_" valign='middle' align='center'>vertices</td>
                    <td id="_" valign='middle' align='center'>edge</td>
                    <td id="_" valign='middle' align='center'>vertices</td>
                  </tr>
                  <tr id="_">
                    <td id="_" valign='middle' align='center'>1</td>
                    <td id="_" valign='middle' align='center'>1, 2</td>
                    <td id="_" valign='middle' align='center'>1</td>
                    <td id="_" valign='middle' align='center'>1, 2</td>
                  </tr>
                  <tr id="_">
                    <td id="_" valign='middle' align='center'>2</td>
                    <td id="_" valign='middle' align='center'>2, 3</td>
                    <td id="_" valign='middle' align='center'>2</td>
                    <td id="_" valign='middle' align='center'>2, 3</td>
                  </tr>
                  <tr id="_">
                    <td id="_" valign='middle' align='center'>3</td>
                    <td id="_" valign='middle' align='center'>3, 1</td>
                    <td id="_" valign='middle' align='center'>3</td>
                    <td id="_" valign='middle' align='center'>3, 4</td>
                  </tr>
                  <tr id="_">
                    <td id="_" valign='top' align='left'/>
                    <td id="_" valign='top' align='left'/>
                    <td id="_" valign='middle' align='center'>4</td>
                    <td id="_" valign='middle' align='center'>4, 1</td>
                  </tr>
                </tbody>
              </table>
              <example id='_'>
                <p id='_'>This is not generalised further.</p>
              </example>
            </newcontent>
            <description>
        <p id='_'>Any further exceptions can be ignored.</p>
      </description>
          </amend>
        </clause>
      </sections>
           </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes hard breaks" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [%hardbreaks]
      One hardbreak
      Two

      Three hardbreaks +
      Four
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
            <sections>
            <p id='_'>
        One hardbreak
        <br/>
         Two
      </p>
      <p id='_'>
        Three hardbreaks
        <br/>
         Four
      </p>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end
end
