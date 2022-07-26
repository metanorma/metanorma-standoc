require "spec_helper"

RSpec.describe Metanorma::Standoc do
  it "processes the Metanorma::Standoc inline macros" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      preferred:[term0]
      alt:[term1]
      admitted:[term1a]
      deprecated:[term2]
      domain:[term3]
      inherit:[<<ref1>>]
      autonumber:table[3]
      add:[a <<clause>>] del:[B]
      identifier:[a http://example.com]

      [bibliography]
      == Bibliography
      * [[[ref1,XYZ 123]]] _Title_
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <preface>
          <foreword id='_' obligation='informative'>
          <title>Foreword</title>
          <preferred><expression><name>term0</name></expression></preferred>
          <admitted><expression><name>term1</name></expression></admitted>
          <admitted><expression><name>term1a</name></expression></admitted>
          <deprecates><expression><name>term2</name></expression></deprecates>
          <domain>term3</domain>
          <inherit>
            <eref type='inline' bibitemid='ref1' citeas='XYZ 123'/>
          </inherit>
          <autonumber type='table'>3</autonumber>
          <add>
                      a
                      <xref target='clause'/>
                    </add>
                    <del>B</del>
                    <identifier>a http://example.com</identifier>
        </foreword>
      </preface>
      <sections> </sections>
      <bibliography>
        <references id='_' obligation='informative' normative="false">
          <title>Bibliography</title>
          <bibitem id='ref1'>
            <formattedref format='application/x-isodoc+xml'>
              <em>Title</em>
            </formattedref>
            <docidentifier>XYZ 123</docidentifier>
            <docnumber>123</docnumber>
          </bibitem>
        </references>
      </bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes the Metanorma::Standoc index macros" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      index:also[]
      index:see[A]
      index:also[B,C~x~]
      index:see[D,_E_,F]
      index:also[G,H,I,J]
      index:see[K,L,M,N,O]
      index-range:id2[P]
      index-range:id3[((_P_))]
      index-range:id3[(((Q, R, S)))]

      Text [[id2]]

      Text [[id3]]
    INPUT
    output = <<~OUTPUT
                  #{BLANK_HDR}
        <sections>
          <p id='_'>
            <index-xref also='true'>
              <primary>B</primary>
              <target>
                C
                <sub>x</sub>
              </target>
            </index-xref>
            <index-xref also='false'>
              <primary>D</primary>
              <secondary>
                <em>E</em>
              </secondary>
              <target>F</target>
            </index-xref>
            <index-xref also='true'>
              <primary>G</primary>
              <secondary>H</secondary>
              <tertiary>I</tertiary>
              <target>J</target>
            </index-xref>
             P
      <index to="id2">
        <primary>P</primary>
      </index>
      <em>P</em>
      <index to="id3">
        <primary>
          <em>P</em>
        </primary>
      </index>
      <index to="id3">
        <primary>Q</primary>
        <secondary>R</secondary>
        <tertiary>S</tertiary>
      </index>
          </p>
          <p id='_'>
                   Text
                   <bookmark id='id2'/>
                 </p>
                 <p id='_'>
                   Text
                   <bookmark id='id3'/>
                 </p>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes the Metanorma::Standoc variant macros" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == lang:en[English] lang:fr-Latn[Français]

      this lang:en[English] lang:fr-Latn[Français] section is lang:en[silly]  lang:fr[fou]

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
        <clause id='_' inline-header='false' obligation='normative'>
          <title>
            <variant lang='en'>English</variant>
            <variant lang='fr' script='Latn'>Français</variant>
          </title>
          <p id='_'>
            this
            <variant>
              <variant lang='en'>English</variant>
              <variant lang='fr' script='Latn'>Français</variant>
            </variant>
             section is
            <variant>
              <variant lang='en'>silly</variant>
              <variant lang='fr'>fou</variant>
            </variant>
          </p>
        </clause>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes the macro for editorial notes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      EDITOR: Note1

      [EDITOR]
      ====
      Note2
      ====

      [EDITOR]
      Note3
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <sections>
           <admonition id='_' type='editorial'>
             <p id='_'>Note1</p>
           </admonition>
           <admonition id='_' type='editorial'>
             <p id='_'>Note2</p>
           </admonition>
           <admonition id='_' type='editorial'>
             <p id='_'>Note3</p>
           </admonition>
         </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes the Metanorma::Standoc concept and related macros" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      {{clause1}}
      term:[clause1]
      {{clause1,w\[o\]rd}}
      term:[clause1,w[o&#93;rd]
      {{clause1,w\[o\]rd,term}}
      {{blah}}
      term:[blah]
      {{blah,word}}
      term:[blah,word]
      {{blah,term,word}}
      {{blah,term,word,xref}}
      {{blah,term,word,xref,options="noital,noref,nolinkmention,nolinkref"}}
      {{blah,term,word,xref,options="ital,ref,linkmention,linkref"}}

      related:contrast[blah]

      [[clause1]]
      == Clause
      Terms are defined here
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <preface>
        <foreword id='_' obligation='informative'>
          <title>Foreword</title>
          <p id='_'>
          <concept>
          <strong>
          term
          <tt>clause1</tt>
          not resolved via ID
          <tt>clause1</tt>
        </strong>
          </concept>
          <concept>
          <strong>
          term
          <tt>clause1</tt>
          not resolved via ID
          <tt>clause1</tt>
        </strong>
          </concept>
          <concept>
          <strong>
          term
          <tt>clause1</tt>, display <tt>w[o]rd</tt>
          not resolved via ID
          <tt>clause1</tt>
          </strong>
          </concept>
          <concept>
          <strong>
          term
          <tt>clause1</tt>, display <tt>w[o]rd</tt>
          not resolved via ID
          <tt>clause1</tt>
          </strong>
          </concept>
          <concept>
          <strong>
          term
          <tt>clause1</tt>, display <tt>w[o]rd</tt>
          not resolved via ID
          <tt>clause1</tt>
        </strong>
          </concept>
             <concept>
                <strong>
                  term
                  <tt>blah</tt>
                   not resolved via ID
                  <tt>blah</tt>
                </strong>
              </concept>
              <concept>
                <strong>
                  term
                  <tt>blah</tt>
                   not resolved via ID
                  <tt>blah</tt>
                </strong>
              </concept>
              <concept>
                <strong>
                  term
                  <tt>blah</tt>
                  , display
                  <tt>word</tt>
                   not resolved via ID
                  <tt>blah</tt>
                </strong>
              </concept>
              <concept>
                <strong>
                  term
                  <tt>blah</tt>
                  , display
                  <tt>word</tt>
                   not resolved via ID
                  <tt>blah</tt>
                </strong>
              </concept>
              <concept>
                <strong>
                  term
                  <tt>blah</tt>
                  , display
                  <tt>term</tt>
                   not resolved via ID
                  <tt>blah</tt>
                </strong>
              </concept>
              <concept>
                 <strong>
                   term
                   <tt>blah</tt>
                   , display
                   <tt>term</tt>
                    not resolved via ID
                   <tt>blah</tt>
                 </strong>
               </concept>
               <concept ital='false' ref='false' linkmention='false' linkref='false'>
                 <strong>
                   term
                   <tt>blah</tt>
                   , display
                   <tt>term</tt>
                    not resolved via ID
                   <tt>blah</tt>
                 </strong>
               </concept>
               <concept ital='true' ref='true' linkmention='true' linkref='true'>
                 <strong>
                   term
                   <tt>blah</tt>
                   , display
                   <tt>term</tt>
                    not resolved via ID
                   <tt>blah</tt>
                 </strong>
               </concept>
               </p>
      <related type='contrast'>
        <strong>
          term
          <tt>blah</tt>
           not resolved via ID
          <tt>blah</tt>
        </strong>
      </related>
        </foreword>
      </preface>
      <sections>
        <clause id='clause1' inline-header='false' obligation='normative'>
          <title>Clause</title>
          <p id='_'>Terms are defined here</p>
        </clause>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes the Metanorma::Standoc concept macros for acronyms" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      {{Clause1}}
      {{Clause1,Clause 1}}
      {{Clause 2}}
      {{Clause 2,Clause 1}}
      {{<<Clause2>>,Clause 2}}

      symbol:[Clause1]
      symbol:[Clause1,word]
      symbol:[Clause 2]
      symbol:[Clause 2,word]

      {{<<Clause2>>,word}}
      {{<<Clause2>>,word,term}}
      {{<<Clause2>>,word,term,xref}}
      {{<<Clause2>>,word,term,xref,options="noital,noref,nolinkmention,nolinkref"}}
      {{<<Clause2>>,word,term,xref,options="ital,ref,linkmention,linkref"}}

      == Terms and definitions
      === Clause1
      == Symbols and Abbreviated Terms
      Clause1:: A
      [[Clause2]]Clause 2:: C
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
       <preface>
                 <foreword id='_' obligation='informative'>
                   <title>Foreword</title>
                   <p id='_'>
                                  <concept>
                 <refterm>Clause1</refterm>
                 <renderterm>Clause1</renderterm>
                 <xref target='term-Clause1'/>
               </concept>
               <concept>
                 <refterm>Clause1</refterm>
                 <renderterm>Clause 1</renderterm>
                 <xref target='term-Clause1'/>
               </concept>
               <concept>
                 <refterm>Clause 2</refterm>
                 <renderterm>Clause 2</renderterm>
                 <xref target='Clause2'/>
               </concept>
               <concept>
                 <refterm>Clause 2</refterm>
                 <renderterm>Clause 1</renderterm>
                 <xref target='Clause2'/>
               </concept>
               <concept>
                 <refterm>Clause 2</refterm>
                 <renderterm>Clause 2</renderterm>
                 <xref target='Clause2'/>
               </concept>
               </p><p id="_">
               <concept>
                 <refterm>Clause1</refterm>
                 <renderterm>Clause1</renderterm>
                 <xref target='symbol-Clause1'/>
               </concept>
               <concept>
                 <refterm>Clause1</refterm>
                 <renderterm>word</renderterm>
                 <xref target='symbol-Clause1'/>
               </concept>
               <concept>
                 <refterm>Clause 2</refterm>
                 <renderterm>Clause 2</renderterm>
                 <xref target='Clause2'/>
               </concept>
               <concept>
                 <refterm>Clause 2</refterm>
                 <renderterm>word</renderterm>
                 <xref target='Clause2'/>
               </concept>
               </p><p id="_">
               <concept>
                 <refterm>word</refterm>
                 <renderterm>word</renderterm>
                 <xref target='Clause2'/>
               </concept>
               <concept>
                 <refterm>word</refterm>
                 <renderterm>term</renderterm>
                 <xref target='Clause2'/>
               </concept>
               <concept>
                 <refterm>word</refterm>
                 <renderterm>term</renderterm>
                 <xref target='Clause2'>xref</xref>
               </concept>
                <concept ital='false' ref='false' linkmention='false' linkref='false'>
                  <refterm>word</refterm>
                  <renderterm>term</renderterm>
                  <xref target='Clause2'>xref</xref>
                </concept>
                <concept ital='true' ref='true' linkmention='true' linkref='true'>
                 <refterm>word</refterm>
                 <renderterm>term</renderterm>
                 <xref target='Clause2'>xref</xref>
               </concept>
                   </p>
                 </foreword>
               </preface>
               <sections>
                 <terms id='_' obligation='normative'>
                   <title>Terms and definitions</title>
                   <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
                   <term id='term-Clause1'>
                     <preferred><expression><name>Clause1</name></expression></preferred>
                   </term>
                 </terms>
                 <definitions id='_' obligation='normative'>
                   <title>Symbols and abbreviated terms</title>
                   <dl id='_'>
                     <dt id="symbol-Clause1">Clause1</dt>
                     <dd>
                       <p id='_'>A</p>
                     </dd>
                     <dt id='Clause2'>Clause 2</dt>
                     <dd>
                       <p id='_'>C</p>
                     </dd>
                   </dl>
                 </definitions>
               </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes the concept and related macros with xrefs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      {{<<clause1>>}}
      {{<<clause1>>,w\[o\]rd}}
      {{<<clause1>>,term,w\[o\]rd}}
      {{<<clause1>>,term,w\[o\]rd,Clause #1}}

      related:supersedes[<<clause1>>,term]

      [[clause1]]
      == Clause
      Terms are defined here
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
            <preface>
                   <foreword id='_' obligation='informative'>
             <title>Foreword</title>
             <p id='_'>
               <concept>
                 <xref target='clause1'/>
               </concept>
               <concept>
                 <refterm>w[o]rd</refterm>
                 <renderterm>w[o]rd</renderterm>
                 <xref target='clause1'/>
               </concept>
               <concept>
                 <refterm>term</refterm>
                 <renderterm>w[o]rd</renderterm>
                 <xref target='clause1'/>
               </concept>
               <concept>
                 <refterm>term</refterm>
                 <renderterm>w[o]rd</renderterm>
                 <xref target='clause1'>Clause #1</xref>
               </concept>
             </p>
                   <related type='supersedes'>
        <preferred>
          <expression>
            <name>term</name>
          </expression>
        </preferred>
        <xref target='clause1'/>
      </related>
           </foreword>
      </preface>
      <sections>
        <clause id='clause1' inline-header='false' obligation='normative'>
          <title>Clause</title>
          <p id='_'>Terms are defined here</p>
        </clause>
      </sections>
            </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes the concept and related macros with erefs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      {{<<blah>>}}
      {{<<blah>>,word}}
      {{<<blah>>,term,word}}
      {{<<blah>>,term,word,Clause #1}}
      {{<<blah,clause=3.1>>}}
      {{<<blah,clause=3.1>>,word}}
      {{<<blah,clause=3.1>>,term,word}}
      {{<<blah,clause=3.1,figure=a>>}}
      {{<<blah,clause=3.1,figure=a>>,word}}
      {{<<blah,clause=3.1,figure=a>>,term,word,Clause #1}}

      related:narrower[<<blah,clause=3.1,figure=a>>,term]

      [bibliography]
      == Bibliography
      * [[[blah,blah]]] _Blah_
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <preface>
           <foreword id='_' obligation='informative'>
             <title>Foreword</title>
             <p id='_'>
               <concept>
                 <eref bibitemid='blah'/>
               </concept>
               <concept>
                 <refterm>word</refterm>
                 <renderterm>word</renderterm>
                 <eref bibitemid='blah'/>
               </concept>
               <concept>
                 <refterm>term</refterm>
                 <renderterm>word</renderterm>
                 <eref bibitemid='blah'/>
               </concept>
               <concept>
                 <refterm>term</refterm>
                 <renderterm>word</renderterm>
                 <eref bibitemid='blah'>Clause #1</eref>
               </concept>
               <concept>
                 <eref bibitemid='blah'>
                   <localityStack>
                     <locality type='clause'>
                       <referenceFrom>3.1</referenceFrom>
                     </locality>
                   </localityStack>
                 </eref>
               </concept>
               <concept>
                 <refterm>word</refterm>
                 <renderterm>word</renderterm>
                 <eref bibitemid='blah'>
                   <localityStack>
                     <locality type='clause'>
                       <referenceFrom>3.1</referenceFrom>
                     </locality>
                   </localityStack>
                 </eref>
               </concept>
               <concept>
                 <refterm>term</refterm>
                 <renderterm>word</renderterm>
                 <eref bibitemid='blah'>
                   <localityStack>
                     <locality type='clause'>
                       <referenceFrom>3.1</referenceFrom>
                     </locality>
                   </localityStack>
                 </eref>
               </concept>
               <concept>
                 <eref bibitemid='blah'>
                   <localityStack>
                     <locality type='clause'>
                       <referenceFrom>3.1</referenceFrom>
                     </locality>
                     <locality type='figure'>
                       <referenceFrom>a</referenceFrom>
                     </locality>
                   </localityStack>
                 </eref>
               </concept>
               <concept>
                 <refterm>word</refterm>
                 <renderterm>word</renderterm>
                 <eref bibitemid='blah'>
                   <localityStack>
                     <locality type='clause'>
                       <referenceFrom>3.1</referenceFrom>
                     </locality>
                     <locality type='figure'>
                       <referenceFrom>a</referenceFrom>
                     </locality>
                   </localityStack>
                 </eref>
               </concept>
               <concept>
                 <refterm>term</refterm>
                 <renderterm>word</renderterm>
                 <eref bibitemid='blah'>
                   <localityStack>
                     <locality type='clause'>
                       <referenceFrom>3.1</referenceFrom>
                     </locality>
                     <locality type='figure'>
                       <referenceFrom>a</referenceFrom>
                     </locality>
                   </localityStack>
                   Clause #1
                 </eref>
               </concept>
             </p>
                   <related type='narrower'>
        <preferred>
          <expression>
            <name>term</name>
          </expression>
        </preferred>
        <eref bibitemid='blah'>
          <localityStack>
            <locality type='clause'>
              <referenceFrom>3.1</referenceFrom>
            </locality>
            <locality type='figure'>
              <referenceFrom>a</referenceFrom>
            </locality>
          </localityStack>
        </eref>
      </related>
           </foreword>
         </preface>
         <sections> </sections>
         <bibliography>
           <references id='_' normative='false' obligation='informative'>
             <title>Bibliography</title>
             <bibitem id='blah'>
               <formattedref format='application/x-isodoc+xml'>
                 <em>Blah</em>
               </formattedref>
               <docidentifier>blah</docidentifier>
             </bibitem>
           </references>
         </bibliography>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes the concept and related macros with termbase" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      {{<<IEV:135-13-13>>}}
      {{<<IEV:135-13-13>>,word}}
      {{<<IEV:135-13-13>>,term,word}}
      {{<<IEV:135-13-13>>,term,word,Clause #1}}

      related:see[<<IEV:135-13-13>>,term]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
              <p id='_'>
                   <concept>
                     <termref base='IEV' target='135-13-13'/>
                   </concept>
                   <concept>
                     <refterm>word</refterm>
                     <renderterm>word</renderterm>
                     <termref base='IEV' target='135-13-13'/>
                   </concept>
                   <concept>
                     <refterm>term</refterm>
                     <renderterm>word</renderterm>
                     <termref base='IEV' target='135-13-13'/>
                   </concept>
                   <concept>
                     <refterm>term</refterm>
                     <renderterm>word</renderterm>
                     <termref base='IEV' target='135-13-13'>Clause #1</termref>
                   </concept>
              </p>
          <related type='see'>
            <preferred>
              <expression>
                <name>term</name>
              </expression>
            </preferred>
            <termref base='IEV' target='135-13-13'/>
          </related>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes the concept macros with disambiguation for math symbols" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [[clause1]]

      == Symbols and Abbreviated Terms
      stem:[|~ x ~|]:: A function that returns the smallest integer greater than or equal to stem:[x]; also known as the _ceiling_ function.
      stem:[|__ x __|]:: A function that returns the largest integer less than or equal to stem:[x]; also known as the _floor_ function.
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
            <sections>
        <definitions id='clause1' obligation='normative'>
          <title>Symbols and abbreviated terms</title>
          <dl id='_'>
            <dt id='symbol-__x230a_-x-__x230b_'>
              <stem type='MathML'>
                <math xmlns='http://www.w3.org/1998/Math/MathML'>
                  <mo>&#8970;</mo>
                  <mi>x</mi>
                  <mo>&#8971;</mo>
                </math>
              </stem>
            </dt>
            <dd>
              <p id='_'>
                A function that returns the largest integer less than or equal to
                <stem type='MathML'>
                  <math xmlns='http://www.w3.org/1998/Math/MathML'>
                    <mi>x</mi>
                  </math>
                </stem>
                ; also known as the
                <em>floor</em>
                 function.
              </p>
            </dd>
            <dt id='symbol-__x2308_-x-__x2309_'>
              <stem type='MathML'>
                <math xmlns='http://www.w3.org/1998/Math/MathML'>
                  <mo>&#8968;</mo>
                  <mi>x</mi>
                  <mo>&#8969;</mo>
                </math>
              </stem>
            </dt>
            <dd>
              <p id='_'>
                A function that returns the smallest integer greater than or equal
                to
                <stem type='MathML'>
                  <math xmlns='http://www.w3.org/1998/Math/MathML'>
                    <mi>x</mi>
                  </math>
                </stem>
                ; also known as the
                <em>ceiling</em>
                 function.
              </p>
            </dd>
          </dl>
        </definitions>
      </sections>
            </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes the TODO custom admonition" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      TODO: Note1

      [TODO]
      ====
      Note2
      ====

      [TODO]
      Note3
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
           <sections><review reviewer="(Unknown)" id="_" date="#{Date.today}T00:00:00Z">
        <p id="_">Note1</p>
      </review>
      <review reviewer="(Unknown)" id="_" date="#{Date.today}T00:00:00Z">
        <p id="_">Note2</p>
      </review>
      <review reviewer="(Unknown)" id="_" date="#{Date.today}T00:00:00Z">
        <p id="_">Note3</p>
      </review></sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "generates pseudocode examples, with formatting and initial indentation" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [pseudocode,subsequence="A",number="3",keep-with-next=true,keep-lines-together=true]
      [%unnumbered]
      ====
        *A* +
              [smallcap]#B#

        _C_
      ====
    INPUT
    output = <<~OUTPUT
              #{BLANK_HDR}
              <sections>
        <figure id="_"  subsequence='A' class="pseudocode" unnumbered="true" number="3" keep-with-next="true" keep-lines-together="true">
              <p id="_">  <strong>A</strong><br/>
              <smallcap>B</smallcap></p>
      <p id="_">  <em>C</em></p></figure>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "supplies line breaks in pseudocode" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [pseudocode]
      ====
      A
      B

      D
      E
      ====
    INPUT
    output = <<~OUTPUT
              #{BLANK_HDR}
              <sections>
      <figure id='_' class='pseudocode'>
                   <p id='_'>
                     A
                     <br/>
                     B
                   </p>
                   <p id='_'>
                     D
                     <br/>
                     E
                   </p>
                 </figure>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "skips embedded blocks and other exceptions when supplying line breaks in pseudocode" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [pseudocode]
      ====
      [stem]
      ++++
      bar X' = (1)/(v) sum_(i = 1)^(v) t_(i)
      ++++

      A ::
      B ::: C +
      D
      ====
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
               <sections>
       <figure id='_' class='pseudocode'>
        <formula id='_'>
          <stem type='MathML'>
            <math xmlns='http://www.w3.org/1998/Math/MathML'>
            <mover accent="true">
                            <mrow>
                              <mi>X</mi>
                            </mrow>
                              <mo>¯</mo>
                          </mover>
                          <mo>′</mo>
                          <mo>=</mo>
                          <mfrac>
                            <mrow>
                              <mn>1</mn>
                            </mrow>
                            <mrow>
                              <mi>v</mi>
                            </mrow>
                          </mfrac>
                          <munderover>
                            <mrow>
                              <mo>∑</mo>
                            </mrow>
                            <mrow>
                              <mrow>
                                <mi>i</mi>
                                <mo>=</mo>
                                <mn>1</mn>
                              </mrow>
                            </mrow>
                            <mrow>
                              <mi>v</mi>
                            </mrow>
                          </munderover>
                          <msub>
                            <mrow>
                              <mi>t</mi>
                            </mrow>
                            <mrow>
                              <mi>i</mi>
                            </mrow>
                          </msub>
            </math>
          </stem>
        </formula>
                       <dl id='_'>
        <dt>A </dt>
        <dd>
          <dl id='_'>
            <dt>B </dt>
            <dd>
              <p id='_'>
                C
                <br/>
                 D
              </p>
            </dd>
          </dl>
        </dd>
      </dl>
                  </figure>
       </sections>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes the Ruby markups" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      ruby:楽聖少女[がくせいしょうじょ]
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
           <sections>
             <p id="_">
             <ruby>楽聖少女<rp>(</rp><rt>がくせいしょうじょ</rt><rp>)</rp></ruby>
           </p>
           </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes the footnoteblock macro" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      footnoteblock:[id1]

      [[id1]]
      [NOTE]
      --
      |===
      |a |b

      |c |d
      |===

      * A
      * B
      * C
      --
    INPUT
    output = <<~OUTPUT
                  #{BLANK_HDR}
                  <sections>
                    <p id="_">
                    <fn reference='1'>
        <table id='_'>
          <thead>
            <tr>
              <th valign='top' align='left'>a</th>
              <th valign='top' align='left'>b</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td valign='top' align='left'>c</td>
              <td valign='top' align='left'>d</td>
            </tr>
          </tbody>
        </table>
        <ul id='_'>
          <li>
            <p id='_'>A</p>
          </li>
          <li>
            <p id='_'>B</p>
          </li>
          <li>
            <p id='_'>C</p>
          </li>
        </ul>
      </fn>
                  </p>
                  </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes the footnoteblock macro with failed reference" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      footnoteblock:[id1]

      [[id2]]
      [NOTE]
      --
      |===
      |a |b

      |c |d
      |===

      * A
      * B
      * C
      --
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
       <sections>
          <p id='_'>
            <fn reference='1'>[ERROR]</fn>
          </p>
          <note id='id2'>
            <table id='_'>
              <thead>
                <tr>
                  <th valign='top' align='left'>a</th>
                  <th valign='top' align='left'>b</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td valign='top' align='left'>c</td>
                  <td valign='top' align='left'>d</td>
                </tr>
              </tbody>
            </table>
            <ul id='_'>
              <li>
                <p id='_'>A</p>
              </li>
              <li>
                <p id='_'>B</p>
              </li>
              <li>
                <p id='_'>C</p>
              </li>
            </ul>
          </note>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes input form macros" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [form,id=N0,name=N1,action="/action_page.php",class="checkboxes"]
      --
      label:fname[First name:] +
      input:text[id=fname,name=fname] +
      label:lname[Last name:] +
      input:text[id=lname,name=lname] +
      label:pwd[Password:] +
      input:password[id=pwd,name=pwd] +
      input:radio[id=male,name=gender,value=male]
      label:male[Male] +
      input:radio[id=female,name=gender,value=female]
      label:female[Female] +
      input:radio[id=other,name=gender,value=other]
      label:other[Other] +
      input:checkbox[id=vehicle1,name=vehicle1,value=Bike,checked=true]
      label:vehicle1[I have a bike] +
      input:checkbox[id=vehicle2,name=vehicle2,value=Car]
      label:vehicle2[I have a car] +
      input:checkbox[id=vehicle3,name=vehicle3,value=Boat]
      label:vehicle3[I have a boat] +
      input:date[id=birthday,name=birthday] +
      label:myfile[Select a file:]
      input:file[id=myfile,name=myfile] +
      label:cars[Select a car:] +
      select:[id=cars,name=cars,value=fiat,size=4,disabled=true,multiple=true]
      option:[Volvo,value=volvo,disabled=true]
      option:[Saab,value=saab]
      option:[Fiat,value=fiat]
      option:[Audi,value=audi]
      textarea:[id=t1,name=message,rows=10,cols=30,value="The cat was playing in the garden."]
      input:button[value="Click Me!"]
      input:button[]
      input:submit[value="Submit"]
      --
    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
        <sections>
        <form id='N0' name='N1' action='/action_page.php' class="checkboxes">
        <p id='_'>
          <label for='fname'>First name:</label>
          <br/>
          <input type='text' id='fname' name='fname'/>
          <br/>
          <label for='lname'>Last name:</label>
          <br/>
          <input type='text' id='lname' name='lname'/>
          <br/>
          <label for='pwd'>Password:</label>
          <br/>
          <input type='password' id='pwd' name='pwd'/>
          <br/>
          <input type='radio' id='male' name='gender' value='male'/>
          <label for='male'>Male</label>
          <br/>
          <input type='radio' id='female' name='gender' value='female'/>
          <label for='female'>Female</label>
          <br/>
          <input type='radio' id='other' name='gender' value='other'/>
          <label for='other'>Other</label>
          <br/>
          <input type='checkbox' id='vehicle1' name='vehicle1' value='Bike' checked='true'/>
          <label for='vehicle1'>I have a bike</label>
          <br/>
          <input type='checkbox' id='vehicle2' name='vehicle2' value='Car'/>
          <label for='vehicle2'>I have a car</label>
          <br/>
          <input type='checkbox' id='vehicle3' name='vehicle3' value='Boat'/>
          <label for='vehicle3'>I have a boat</label>
          <br/>
          <input type='date' id='birthday' name='birthday'/>
          <br/>
          <label for='myfile'>Select a file:</label>
          <input type='file' id='myfile' name='myfile'/>
          <br/>
          <label for='cars'>Select a car:</label>
          <br/>
          <select id='cars' name='cars' size='4' disabled='true' multiple='true' value='fiat'>
            <option disabled='true' value='volvo'/>
            <option value='saab'/>
            <option value='fiat'/>
            <option value='audi'/>
          </select>
          <textarea id='t1' name='message' rows='10' cols='30' value='The cat was playing in the garden.'/>
          <input type='button' value='Click Me!'/>
          <input type='button'/>
          <input type='submit' value='Submit'/>
        </p>
      </form>
              </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes ToC form macros" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[clause1]]
      == Clause 1

      [[clause1A]]
      === Clause 1A

      [[clause1Aa]]
      ==== Clause 1Aa

      [[clause1Ab]]
      ==== Clause 1Ab

      [.variant-title,type=toc]
      1Ab Clause

      [[clause1B]]
      === Clause 1B

      [[clause1Ba]]
      ==== Clause 1Ba

      [[clause2]]
      == Clause 2

      And introducing:
      toc:["//clause[@id = 'clause1'\\]/clause/title","//clause[@id = 'clause1'\\]/clause/clause/title:2"]

      toc:["//clause[@id = 'clause1'\\]/clause/title"]
    INPUT
    output = <<~OUTPUT
                  #{BLANK_HDR}
                  <sections>
              <clause id='clause1' inline-header='false' obligation='normative'>
                <title>Clause 1</title>
                <clause id='clause1A' inline-header='false' obligation='normative'>
                  <title>Clause 1A</title>
                  <clause id='clause1Aa' inline-header='false' obligation='normative'>
                    <title>Clause 1Aa</title>
                  </clause>
                  <clause id='clause1Ab' inline-header='false' obligation='normative'>
                    <title>Clause 1Ab</title>
                    <variant-title type='toc'>1Ab Clause</variant-title>
                  </clause>
                </clause>
                <clause id='clause1B' inline-header='false' obligation='normative'>
                  <title>Clause 1B</title>
                  <clause id='clause1Ba' inline-header='false' obligation='normative'>
                    <title>Clause 1Ba</title>
                  </clause>
                </clause>
              </clause>
              <clause id='clause2' inline-header='false' obligation='normative'>
                <title>Clause 2</title>
                <p id='_'>And introducing: </p>
      <toc>
        <ul id='_'>
          <li>
            <xref target='clause1A'>Clause 1A</xref>
          </li>
          <li>
            <ul id='_'>
              <li>
                <xref target='clause1Aa'>Clause 1Aa</xref>
              </li>
              <li>
                <xref target='clause1Ab'>1Ab Clause</xref>
              </li>
            </ul>
          </li>
          <li>
            <xref target='clause1B'>Clause 1B</xref>
          </li>
          <li>
            <ul id='_'>
              <li>
                <xref target='clause1Ba'>Clause 1Ba</xref>
              </li>
            </ul>
          </li>
        </ul>
      </toc>
      <toc>
        <ul id='_'>
          <li>
            <xref target='clause1A'>Clause 1A</xref>
          </li>
          <li>
            <xref target='clause1B'>Clause 1B</xref>
          </li>
        </ul>
      </toc>
              </clause>
            </sections>
                  </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes embed macro" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[clause1]]
      == Clause 1

      embed::spec/assets/xref_error.adoc[]
    INPUT
    output = <<~OUTPUT
      <standard-document xmlns='https://www.metanorma.org/ns/standoc' type='semantic' version='#{Metanorma::Standoc::VERSION}'>
       <bibdata type='standard'>
         <title language='en' format='text/plain'>Document title</title>
         <language>en</language>
         <script>Latn</script>
         <status>
           <stage>published</stage>
         </status>
         <copyright>
           <from>2022</from>
         </copyright>
         <ext>
           <doctype>standard</doctype>
         </ext>
         <relation type='derivedFrom'>
           <bibitem>
             <title language='en' format='text/plain'>X</title>
             <language>en</language>
             <script>Latn</script>
             <status>
               <stage>published</stage>
             </status>
             <copyright>
               <from>2022</from>
             </copyright>
             <ext>
               <doctype>standard</doctype>
             </ext>
           </bibitem>
         </relation>
              </bibdata>
              <sections>
                <clause id='clause1' inline-header='false' obligation='normative'>
                  <title>Clause 1</title>
                </clause>
                <clause id='_' inline-header='false' obligation='normative'>
                  <title>Clause</title>
                  <p id='_'>
                    <xref target='a'>b</xref>
                  </p>
                </clause>
              </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes embed macro with overwriting" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[clause1]]
      == Clause

      embed::spec/assets/xref_error.adoc[]
    INPUT
    output = <<~OUTPUT
      <standard-document xmlns='https://www.metanorma.org/ns/standoc' type='semantic' version='#{Metanorma::Standoc::VERSION}'>
              <bibdata type='standard'>
                  <title language='en' format='text/plain'>Document title</title>
          <language>en</language>
          <script>Latn</script>
          <status>
            <stage>published</stage>
          </status>
          <copyright>
            <from>2022</from>
          </copyright>
          <ext>
            <doctype>standard</doctype>
          </ext>
          <relation type='derivedFrom'>
            <bibitem>
              <title language='en' format='text/plain'>X</title>
              <language>en</language>
              <script>Latn</script>
              <status>
                <stage>published</stage>
              </status>
              <copyright>
                <from>2022</from>
              </copyright>
              <ext>
                <doctype>standard</doctype>
              </ext>
            </bibitem>
          </relation>
              </bibdata>
              <sections>
                <clause id='clause1' inline-header='false' obligation='normative'>
                  <title>Clause</title>
                </clause>
              </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes recursive embed macro with includes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[clause1]]
      == Clause

      embed::spec/assets/a1.adoc[]
    INPUT
    output = <<~OUTPUT
      <standard-document xmlns='https://www.metanorma.org/ns/standoc' type='semantic' version='#{Metanorma::Standoc::VERSION}'>
         <bibdata type='standard'>
           <title language='en' format='text/plain'>Document title</title>
           <language>en</language>
           <script>Latn</script>
           <status>
             <stage>published</stage>
           </status>
           <copyright>
             <from>2022</from>
           </copyright>
           <ext>
             <doctype>standard</doctype>
           </ext>
           <relation type='derivedFrom'>
             <bibitem>
               <title language='en' format='text/plain'>X</title>
               <language>en</language>
               <script>Latn</script>
               <status>
                 <stage>published</stage>
               </status>
               <copyright>
                 <from>2022</from>
               </copyright>
               <ext>
                 <doctype>standard</doctype>
               </ext>
               <relation type='derivedFrom'>
                 <bibitem>
                   <title language='en' format='text/plain'>A2</title>
                   <language>en</language>
                   <script>Latn</script>
                   <status>
                     <stage>published</stage>
                   </status>
                   <copyright>
                     <from>2022</from>
                   </copyright>
                   <ext>
                     <doctype>standard</doctype>
                   </ext>
                   <relation type='derivedFrom'>
                      <bibitem>
                        <title language='en' format='text/plain'>A3</title>
                        <language>en</language>
                        <script>Latn</script>
                        <status>
                          <stage>published</stage>
                        </status>
                        <copyright>
                          <from>2022</from>
                        </copyright>
                        <ext>
                          <doctype>standard</doctype>
                        </ext>
                      </bibitem>
                    </relation>
                    <relation type='derivedFrom'>
                      <bibitem>
                        <title language='en' format='text/plain'>A3a</title>
                        <language>en</language>
                        <script>Latn</script>
                        <status>
                          <stage>published</stage>
                        </status>
                        <copyright>
                          <from>2022</from>
                        </copyright>
                        <ext>
                          <doctype>standard</doctype>
                        </ext>
                      </bibitem>
                    </relation>
                 </bibitem>
               </relation>
             </bibitem>
           </relation>
         </bibdata>
         <sections>
           <clause id='clause1' inline-header='false' obligation='normative'>
             <title>Clause</title>
           </clause>
           <clause id='_' inline-header='false' obligation='normative'>
             <title>Clause 1</title>
             <p id='_'>X</p>
           </clause>
           <clause id='_' inline-header='false' obligation='normative'>
             <title>Clause 2</title>
             <p id='_'>X</p>
           </clause>
           <clause id='_' inline-header='false' obligation='normative'>
             <title>Clause 3</title>
             <p id='_'>X</p>
           </clause>
           <clause id='_' inline-header='false' obligation='normative'>
              <title>Clause 4</title>
              <p id='_'>X</p>
            </clause>
           <clause id='_' inline-header='false' obligation='normative'>
             <title>Clause 3a</title>
             <p id='_'>X</p>
           </clause>
         </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes embed macro with document in a different flavour" do
    require "metanorma-iso"
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[clause1]]
      == Clause 1

      embed::spec/assets/iso.adoc[]
    INPUT
    output = <<~OUTPUT
      <standard-document xmlns='https://www.metanorma.org/ns/standoc' type='semantic' version='#{Metanorma::Standoc::VERSION}'>
       <bibdata type='standard'>
         <title language='en' format='text/plain'>Document title</title>
         <language>en</language>
         <script>Latn</script>
         <status>
           <stage>published</stage>
         </status>
         <copyright>
           <from>2022</from>
         </copyright>
         <ext>
           <doctype>standard</doctype>
         </ext>
                    <relation type='derivedFrom'>
             <bibitem>
               <title language='en' format='text/plain' type='main'>
                 Medical devices — Quality management systems — Requirements for
                 regulatory purposes
               </title>
               <title language='en' format='text/plain' type='title-main'>
                 Medical devices — Quality management systems — Requirements for
                 regulatory purposes
               </title>
               <title language='fr' format='text/plain' type='main'>
                 Dispositifs médicaux — Systèmes de management de la qualité —
                 Exigences à des fins réglementaires
               </title>
               <title language='fr' format='text/plain' type='title-main'>
                 Dispositifs médicaux — Systèmes de management de la qualité —
                 Exigences à des fins réglementaires
               </title>
               <contributor>
                 <role type='author'/>
                 <organization>
                   <name>International Organization for Standardization</name>
                   <abbreviation>ISO</abbreviation>
                 </organization>
               </contributor>
               <contributor>
                 <role type='publisher'/>
                 <organization>
                   <name>International Organization for Standardization</name>
                   <abbreviation>ISO</abbreviation>
                 </organization>
               </contributor>
               <language>en</language>
               <script>Latn</script>
               <status>
                 <stage abbreviation='IS'>60</stage>
                 <substage>60</substage>
               </status>
               <copyright>
                 <from>2022</from>
                 <owner>
                   <organization>
                     <name>International Organization for Standardization</name>
                     <abbreviation>ISO</abbreviation>
                   </organization>
                 </owner>
               </copyright>
               <ext>
                 <doctype>standard</doctype>
                 <editorialgroup>
                   <agency>ISO</agency>
                 </editorialgroup>
                 <approvalgroup>
           <agency>ISO</agency>
         </approvalgroup>
                 <stagename>International standard</stagename>
               </ext>
             </bibitem>
           </relation>
              </bibdata>
              <sections>
                <clause id='clause1' inline-header='false' obligation='normative'>
                  <title>Clause 1</title>
                </clause>
              </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes std-link macro" do
    VCR.use_cassette("std-link", match_requests_on: %i[method uri body]) do
      input = <<~INPUT
        #{ISOBIB_BLANK_HDR}

        [[clause1]]
        == Clause

        std-link:[ISO 131]
        std-link:[iso:std:iso:13485:en,droploc%clause=4,text]
      INPUT
      output = <<~OUTPUT
         #{BLANK_HDR}
                  <sections>
            <clause id='clause1' inline-header='false' obligation='normative'>
              <title>Clause</title>
              <p id='_'>
                <eref type='inline' bibitemid='_' citeas='ISO 131'/>
                <eref type='inline' droploc='true' bibitemid='_' citeas='iso:std:iso:13485:en'>
                  <localityStack>
                    <locality type='clause'>
                      <referenceFrom>4</referenceFrom>
                    </locality>
                  </localityStack>
                  text
                </eref>
              </p>
            </clause>
          </sections>
          <bibliography>
            <references hidden='true' normative='true'>
              <bibitem id='_' type='standard' hidden="true">
                <fetched/>
                <title type='title-intro' format='text/plain' language='en' script='Latn'>Acoustics</title>
                <title type='title-main' format='text/plain' language='en' script='Latn'>Expression of physical and subjective magnitudes of sound or noise in air</title>
                <title type='main' format='text/plain' language='en' script='Latn'>
                  Acoustics — Expression of physical and subjective magnitudes of sound
                  or noise in air
                </title>
                <uri type='src'>https://www.iso.org/standard/3944.html</uri>
                <uri type='rss'>https://www.iso.org/contents/data/standard/00/39/3944.detail.rss</uri>
                <docidentifier type='ISO' primary='true'>ISO 131</docidentifier>
                <docidentifier type='URN'>urn:iso:std:iso:131:stage-95.99:ed-1</docidentifier>
                <docnumber>131</docnumber>
                <contributor>
                  <role type='publisher'/>
                  <organization>
                    <name>International Organization for Standardization</name>
                    <abbreviation>ISO</abbreviation>
                    <uri>www.iso.org</uri>
                  </organization>
                </contributor>
                <edition>1</edition>
                <language>en</language>
                <script>Latn</script>
                <status>
                  <stage>95</stage>
                  <substage>99</substage>
                </status>
                <copyright>
                  <from>1979</from>
                  <owner>
                    <organization>
                      <name>ISO</name>
                    </organization>
                  </owner>
                </copyright>
                <relation type='obsoletes'>
                  <bibitem type='standard'>
                    <formattedref format='text/plain'>ISO/R 357:1963</formattedref>
                    <docidentifier type='ISO' primary='true'>ISO/R 357:1963</docidentifier>
                  </bibitem>
                </relation>
                <relation type='instance'>
                  <bibitem type='standard'>
                    <fetched/>
                    <title type='title-intro' format='text/plain' language='en' script='Latn'>Acoustics</title>
                    <title type='title-main' format='text/plain' language='en' script='Latn'>Expression of physical and subjective magnitudes of sound or noise in air</title>
                    <title type='main' format='text/plain' language='en' script='Latn'>
                      Acoustics — Expression of physical and subjective magnitudes of
                      sound or noise in air
                    </title>
                    <uri type='src'>https://www.iso.org/standard/3944.html</uri>
                    <uri type='rss'>https://www.iso.org/contents/data/standard/00/39/3944.detail.rss</uri>
                    <docidentifier type='ISO' primary='true'>ISO 131:1979</docidentifier>
                    <docidentifier type='URN'>urn:iso:std:iso:131:stage-95.99:ed-1</docidentifier>
                    <docnumber>131</docnumber>
                    <date type='published'>
                      <on>1979-11</on>
                    </date>
                    <contributor>
                      <role type='publisher'/>
                      <organization>
                        <name>International Organization for Standardization</name>
                        <abbreviation>ISO</abbreviation>
                        <uri>www.iso.org</uri>
                      </organization>
                    </contributor>
                    <edition>1</edition>
                    <language>en</language>
                    <script>Latn</script>
                    <status>
                      <stage>95</stage>
                      <substage>99</substage>
                    </status>
                    <copyright>
                      <from>1979</from>
                      <owner>
                        <organization>
                          <name>ISO</name>
                        </organization>
                      </owner>
                    </copyright>
                    <relation type='obsoletes'>
                      <bibitem type='standard'>
                        <formattedref format='text/plain'>ISO/R 357:1963</formattedref>
                        <docidentifier type='ISO' primary='true'>ISO/R 357:1963</docidentifier>
                      </bibitem>
                    </relation>
                    <place>Geneva</place>
                  </bibitem>
                </relation>
                <place>Geneva</place>
              </bibitem>
              <bibitem id='_' hidden="true">
                <formattedref format='application/x-isodoc+xml'/>
                <docidentifier type='ISO'>iso:std:iso:13485:en</docidentifier>
                <docnumber>13485:en</docnumber>
              </bibitem>
            </references>
          </bibliography>
        </standard-document>
      OUTPUT
      expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))
                  .gsub(%r{ bibitemid="_[^"]+"}, ' bibitemid="_"')))
        .to be_equivalent_to xmlpp(output)
    end
  end

  describe "term inline macros" do
    subject(:convert) do
      xmlpp(
        strip_guid(
          Asciidoctor.convert(
            input, *OPTIONS
          ),
        ),
      )
    end
    let(:input) do
      <<~XML
        #{ASCIIDOC_BLANK_HDR}
        == Terms and Definitions

        === name

        == Main

        term:[name,name2] is a term

        {{name,name2}} is a term

        related:equivalent[name]
      XML
    end
    let(:output) do
      <<~XML
        #{BLANK_HDR}
        <sections>
          <terms id='_' obligation='normative'>
            <title>Terms and definitions</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id='term-name'>
              <preferred><expression><name>name</name></expression></preferred>
            </term>
          </terms>
          <clause id='_' inline-header='false' obligation='normative'>
            <title>Main</title>
            <p id='_'>
            <concept>
              <refterm>name</refterm>
              <renderterm>name2</renderterm>
              <xref target='term-name'/>
            </concept>
             is a term
            </p>
            <p id='_'>
            <concept>
              <refterm>name</refterm>
              <renderterm>name2</renderterm>
              <xref target='term-name'/>
            </concept>
             is a term
            </p>
          <related type='equivalent'>
          <preferred>
          <expression>
            <name>name</name>
          </expression>
        </preferred>
          <xref target='term-name'>name</xref>
          </related>
          </clause>
        </sections>
        </standard-document>
      XML
    end

    it "converts macro into the correct xml" do
      expect(convert).to(be_equivalent_to(xmlpp(output)))
    end

    context "default params" do
      let(:input) do
        <<~XML
          #{ASCIIDOC_BLANK_HDR}

          == Terms and Definitions

          === name

          == Main

          term:[name] is a term

          {{name}} is a term
        XML
      end
      let(:output) do
        <<~XML
          #{BLANK_HDR}
          <sections>
            <terms id='_' obligation='normative'>
              <title>Terms and definitions</title>
              <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
              <term id='term-name'>
                <preferred><expression><name>name</name></expression></preferred>
              </term>
            </terms>
            <clause id='_' inline-header='false' obligation='normative'>
              <title>Main</title>
              <p id='_'>
              <concept>
              <refterm>name</refterm>
              <renderterm>name</renderterm>
              <xref target='term-name'/>
              </concept>
              is a term
              </p>
              <p id='_'>
              <concept>
              <refterm>name</refterm>
              <renderterm>name</renderterm>
              <xref target='term-name'/>
              </concept>
              is a term
              </p>
            </clause>
          </sections>
          </standard-document>
        XML
      end

      it "uses `name` as termref name" do
        expect(convert).to(be_equivalent_to(xmlpp(output)))
      end
    end

    context "terms with index terms" do
      let(:input) do
        <<~XML
          #{ASCIIDOC_BLANK_HDR}

          == Terms and Definitions

          === name(((name)))

          == Main

          term:[name] is a term

          {{name}} is a term
        XML
      end
      let(:output) do
        <<~XML
          #{BLANK_HDR}
          <sections>
            <terms id='_' obligation='normative'>
              <title>Terms and definitions</title>
              <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
              <term id='term-name'>
                <preferred><expression><name>name
           <index>
               <primary>name</primary>
             </index>
           </name>
                </expression></preferred>
              </term>
            </terms>
            <clause id='_' inline-header='false' obligation='normative'>
              <title>Main</title>
              <p id='_'>
              <concept>
              <refterm>name</refterm>
              <renderterm>name</renderterm>
              <xref target='term-name'/>
              </concept>
              is a term
              </p>
              <p id='_'>
              <concept>
              <refterm>name</refterm>
              <renderterm>name</renderterm>
              <xref target='term-name'/>
              </concept>
              is a term
              </p>
            </clause>
          </sections>
          </standard-document>
        XML
      end

      it "strips index terms in terms anchors" do
        expect(convert).to(be_equivalent_to(xmlpp(output)))
      end
    end

    context "multiply exising ids in document" do
      let(:input) do
        <<~XML
          #{ASCIIDOC_BLANK_HDR}

          == Terms and Definitions

          === name
          === name2

          [[term-name]]
          == Main

          paragraph

          [[term-name2]]
          == Second

          term:[name] is a term
          term:[name2] is a term
          {{name}} is a term
          {{name2}} is a term
        XML
      end
      let(:output) do
        <<~XML
          #{BLANK_HDR}
          <sections>
            <terms id='_' obligation='normative'>
              <title>Terms and definitions</title>
              <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
              <term id='term-name-1'>
                 <preferred><expression><name>name</name></expression></preferred>
              </term>
              <term id='term-name2-1'>
                <preferred><expression><name>name2</name></expression></preferred>
              </term>
            </terms>
            <clause id='term-name' inline-header='false' obligation='normative'>
              <title>Main</title>
              <p id='_'>paragraph</p>
            </clause>
            <clause id='term-name2' inline-header='false' obligation='normative'>
              <title>Second</title>
              <p id='_'>
               <concept>
                 <refterm>name</refterm>
                 <renderterm>name</renderterm>
                 <xref target='term-name-1'/>
               </concept>
                is a term
               <concept>
                 <refterm>name2</refterm>
                 <renderterm>name2</renderterm>
                 <xref target='term-name2-1'/>
               </concept>
                is a term
               <concept>
                 <refterm>name</refterm>
                 <renderterm>name</renderterm>
                 <xref target='term-name-1'/>
               </concept>
                is a term
               <concept>
                 <refterm>name2</refterm>
                 <renderterm>name2</renderterm>
                 <xref target='term-name2-1'/>
               </concept>
                is a term
              </p>
            </clause>
          </sections>
          </standard-document>
        XML
      end

      it "generates unique ids which do not match existing ids" do
        expect(convert).to(be_equivalent_to(xmlpp(output)))
      end
    end

    context "when missing actual ref" do
      let(:input) do
        <<~XML
          #{ASCIIDOC_BLANK_HDR}

          == Terms and Definitions

          === name identity

          [[name-check]]
          === name check

          paragraph

          term:[name check] is a term

          term:[name identity] is a term

          Moreover, term:[missing] is a term


          {{name check}} is a term

          {{name identity}} is a term

          Moreover, {{missing}} is a term

          related:equivalent[missing]
        XML
      end
      let(:output) do
        <<~XML
               #{BLANK_HDR}
                      <sections>
                <terms id='_' obligation='normative'>
                  <title>Terms and definitions</title>
                  <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
                  <term id='term-name-identity'>
                    <preferred><expression><name>name identity</name></expression></preferred>
                  </term>
                  <term id='name-check'>
                    <preferred><expression><name>name check</name></expression></preferred>
          <related type='equivalent'>
            <strong>
              term
              <tt>missing</tt>
               not resolved via ID
              <tt>missing</tt>
            </strong>
          </related>
                    <definition><verbal-definition>
                      <p id='_'>paragraph</p>
                      <p id='_'>
                        <concept>
                          <refterm>name check</refterm>
                          <renderterm>name check</renderterm>
                          <xref target='name-check'/>
                        </concept>
                         is a term
                      </p>
                      <p id='_'>
                        <concept>
                          <refterm>name identity</refterm>
                          <renderterm>name identity</renderterm>
                          <xref target='term-name-identity'/>
                        </concept>
                         is a term
                      </p>
                      <p id='_'>
                        Moreover,
                        <concept>
                          <strong>
                            term
                            <tt>missing</tt>
                             not resolved via ID
                            <tt>missing</tt>
                          </strong>
                        </concept>
                         is a term
                      </p>
                      <p id='_'>
                        <concept>
                          <refterm>name check</refterm>
                          <renderterm>name check</renderterm>
                          <xref target='name-check'/>
                        </concept>
                         is a term
                      </p>
                      <p id='_'>
                        <concept>
                          <refterm>name identity</refterm>
                          <renderterm>name identity</renderterm>
                          <xref target='term-name-identity'/>
                        </concept>
                         is a term
                      </p>
                      <p id='_'>
                        Moreover,
                        <concept>
                          <strong>
                            term
                            <tt>missing</tt>
                             not resolved via ID
                            <tt>missing</tt>
                          </strong>
                        </concept>
                         is a term
                      </p>
                    </verbal-definition></definition>
                  </term>
                </terms>
              </sections>
            </standard-document>
        XML
      end

      it "generates unique ids which do not match existing ids" do
        expect(convert).to(be_equivalent_to(xmlpp(output)))
      end
    end
  end

  describe "lutaml_figure macro" do
    let(:example_file) { fixtures_path("test.xmi") }
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        [lutaml_uml_datamodel_description,#{example_file}]
        --
        --

        This is lutaml_figure::[package="Wrapper root package", name="Fig B1 Full model"] figure
      TEXT
    end
    let(:output) do
      '<xref target="figure-EAID_0E029ABF_C35A_49e3_9EEA_FFD4F32780A8">'
    end

    it "correctly renders input" do
      expect(strip_src(xml_string_conent(metanorma_process(input))))
        .to(include(output))
    end
  end

  describe "lutaml_uml_datamodel_description macro" do
    subject(:convert) do
      xmlpp(
        strip_guid(
          Asciidoctor.convert(
            input, *OPTIONS
          ),
        ),
      )
    end

    let(:example_file) { fixtures_path("test.xmi") }
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        [lutaml_uml_datamodel_description,#{example_file}]
        --
        [.diagram_include_block, base_path="requirements/"]
        .....
        Diagram text
        .....

        [.include_block, package="Another", base_path="spec/fixtures/"]
        .....
        my text
        .....

        [.include_block, base_path="spec/fixtures/"]
        .....
        my text
        .....

        [.before]
        .....
        mine text
        .....

        [.before, package="Another"]
        .....
        text before Another package
        .....

        [.after, package="Another"]
        .....
        text after Another package
        .....

        [.after, package="CityGML"]
        .....
        text after CityGML package
        .....

        [.after]
        .....
        footer text
        .....
        --
      TEXT
    end
    let(:output) do
      <<~TEXT
        #{BLANK_HDR}
        #{File.read(fixtures_path('datamodel_description_sections_tree.xml'))}
        </standard-document>
      TEXT
    end

    it "correctly renders input" do
      expect(convert)
        .to(be_equivalent_to(xmlpp(output)))
    end
  end
end
