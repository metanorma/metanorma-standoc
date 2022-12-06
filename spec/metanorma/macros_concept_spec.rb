require "spec_helper"

RSpec.describe Metanorma::Standoc do
  it "processes the Metanorma::Standoc concept and related macros" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      {{clause1}}
      {{clause two}}
      {{clause
      two}}
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
      {{blah,term,word,xref,options="noital,nobold,noref,nolinkmention,nolinkref"}}
      {{blah,term,word,xref,options="ital,bold,ref,linkmention,linkref"}}

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
            <tt>clause two</tt>
             not resolved via ID
            <tt>clause-two</tt>
          </strong>
        </concept>
        <concept>
          <strong>
            term
            <tt>clause two</tt>
             not resolved via ID
            <tt>clause-two</tt>
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
               <concept ital='false' bold='false' ref='false' linkmention='false' linkref='false'>
                 <strong>
                   term
                   <tt>blah</tt>
                   , display
                   <tt>term</tt>
                    not resolved via ID
                   <tt>blah</tt>
                 </strong>
               </concept>
               <concept ital='true' bold='true' ref='true' linkmention='true' linkref='true'>
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
            <dt id='symbol-__x230a_-x-__x230b_-___-x-___'>
              <stem type='MathML'>
                <math xmlns='http://www.w3.org/1998/Math/MathML'>
                  <mo>&#8970;</mo>
                  <mi>x</mi>
                  <mo>&#8971;</mo>
                </math>
                <asciimath>|__ x __|</asciimath>
              </stem>
            </dt>
            <dd>
              <p id='_'>
                A function that returns the largest integer less than or equal to
                <stem type='MathML'>
                  <math xmlns='http://www.w3.org/1998/Math/MathML'>
                    <mi>x</mi>
                  </math>
                  <asciimath>x</asciimath>
                </stem>
                ; also known as the
                <em>floor</em>
                 function.
              </p>
            </dd>
            <dt id='symbol-__x2308_-x-__x2309_-__-x-__'>
              <stem type='MathML'>
                <math xmlns='http://www.w3.org/1998/Math/MathML'>
                  <mo>&#8968;</mo>
                  <mi>x</mi>
                  <mo>&#8969;</mo>
                </math>
                <asciimath>|~ x ~|</asciimath>
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
                   <asciimath>x</asciimath>
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

    context "multiply existing ids in document" do
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
end
