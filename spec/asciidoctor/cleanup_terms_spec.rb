require "spec_helper"
require "relaton_iec"
require "fileutils"

RSpec.describe Asciidoctor::Standoc do
  it "processes term and designation metadata and term sources" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === First Designation

      [%metadata]
      language:: fr
      script:: Latn
      type:: prefix
      isInternational:: true
      abbreviation-type:: acronym
      pronunciation:: fəɹst
      domain:: Hydraulics
      subject:: pipes
      field-of-application:: Field
      usage-info:: This is usage.

      [.source]
      <<ISO2191,section=1>>

      alt:[Third Designation]

      [%metadata]
      language:: he
      script:: Hebr
      type:: suffix
      domain:: Hydraulics1
      subject: pipes1
      usage-info:: This is usage 1.
      absent:: true

      deprecated:[Fourth Designation]

      [%metadata]
      language:: jp
      script:: Japn
      type:: full
      field-of-application:: Field
      grammar::
      gender::: masculine, feminine
      isPreposition::: false
      isNoun::: true
      grammar-value::: irregular declension
      geographic-area:: AUS

      related:see[<<second>>,Fifth Designation]

      [%metadata]
      type:: abbreviation
      grammar::
      gender::: neuter
      isVerb::: true
      geographic-area:: GRC

      [.source]
      <<ISO2191,section=2>>

      Definition

      [.source]
      <<ISO2191,section=3>>

      [[second]]
      === Second Term

      [%metadata]
      usage-info::
      +
      --
      Usage Info 1.

      Usage Info 2.
      --

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
          <terms id='_' obligation='normative'>
            <title>Terms and definitions</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id='term-first-designation'>
              <preferred language='fr' script='Latn' type='prefix' isInternational="true">
                <expression>
                  <name>First Designation</name>
            <abbreviation-type>acronym</abbreviation-type>
            <pronunciation>f&#601;&#633;st</pronunciation>
                </expression>
                <field-of-application>Field</field-of-application>
                <usage-info>This is usage.</usage-info>
                        <termsource status='identical' type='authoritative'>
          <origin bibitemid='ISO2191' type='inline' citeas=''>
            <localityStack>
              <locality type='section'>
                <referenceFrom>1</referenceFrom>
              </locality>
            </localityStack>
          </origin>
        </termsource>
              </preferred>
              <admitted language='he' script='Hebr' type='suffix' absent="true">
                <expression>
                  <name>Third Designation</name>
                </expression>
                <usage-info>This is usage 1.</usage-info>
              </admitted>
              <deprecates language='jp' script='Japn' type='full' geographic-area="AUS">
                <expression>
                  <name>Fourth Designation</name>
            <grammar>
              <gender>masculine</gender>
              <gender>feminine</gender>
              <isPreposition>false</isPreposition>
              <isNoun>true</isNoun>
              <grammar-value>irregular declension</grammar-value>
            </grammar>
                </expression>
                <field-of-application>Field</field-of-application>
              </deprecates>
                      <related type='abbreviation'>
          <preferred geographic-area="GRC">
            <expression>
              <name>Fifth Designation</name>
              <grammar>
                <gender>neuter</gender>
              </grammar>
            </expression>
                                  <termsource status='identical' type='authoritative'>
              <origin bibitemid='ISO2191' type='inline' citeas=''>
                <localityStack>
                  <locality type='section'>
                    <referenceFrom>2</referenceFrom>
                  </locality>
                </localityStack>
              </origin>
            </termsource>
          </preferred>
          <xref target='second'/>
        </related>
              <domain>Hydraulics</domain>
              <subject>pipes</subject>
              <definition><verbal-definition>
                <p id='_'>Definition</p>
              </verbal-definition></definition>
          <termsource status='identical' type='authoritative'>
          <origin bibitemid='ISO2191' type='inline' citeas=''>
            <localityStack>
              <locality type='section'>
                <referenceFrom>3</referenceFrom>
              </locality>
            </localityStack>
          </origin>
        </termsource>
            </term>
        <term id='second'>
        <preferred>
          <expression>
            <name>Second Term</name>
          </expression>
        <usage-info>
          <p id='_'>Usage Info 1.</p>
          <p id='_'>Usage Info 2.</p>
        </usage-info>
        </preferred>
      </term>
          </terms>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "permits multiple preferred terms, and treats them as synonyms in concepts" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === First Designation

      preferred:[Second Designation]

      alt:[Third Designation]

      alt:[Fourth Designation]

      deprecated:[Fourth Designation]

      deprecated:[Fifth Designation]

      related:see[Sixth Designation]

      related:contrast[Seventh Designation]

      Definition

      == Clause

      {{First Designation}}

      {{Second Designation}}
    INPUT
    output = <<~OUTPUT
         #{BLANK_HDR}
                <sections>
                   <terms id='_' obligation='normative'>
        <title>Terms and definitions</title>
        <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
        <term id='term-first-designation'>
          <preferred>
            <expression>
              <name>First Designation</name>
            </expression>
          </preferred>
          <preferred>
            <expression>
              <name>Second Designation</name>
            </expression>
          </preferred>
          <admitted>
            <expression>
              <name>Third Designation</name>
            </expression>
          </admitted>
          <admitted>
            <expression>
              <name>Fourth Designation</name>
            </expression>
          </admitted>
          <deprecates>
            <expression>
              <name>Fourth Designation</name>
            </expression>
          </deprecates>
          <deprecates>
            <expression>
              <name>Fifth Designation</name>
            </expression>
          </deprecates>
        <related type='see'>
          <strong>
            term
            <tt>Sixth Designation</tt>
             not resolved via ID
            <tt>sixth-designation</tt>
          </strong>
        </related>
        <related type='contrast'>
          <strong>
            term
            <tt>Seventh Designation</tt>
             not resolved via ID
            <tt>seventh-designation</tt>
          </strong>
        </related>
          <definition><verbal-definition>
            <p id='_'>Definition</p>
          </verbal-definition></definition>
        </term>
      </terms>
      <clause id='_' inline-header='false' obligation='normative'>
        <title>Clause</title>
        <p id='_'>
          <concept>
            <refterm>First Designation</refterm>
            <renderterm>First Designation</renderterm>
            <xref target='term-first-designation'/>
          </concept>
        </p>
        <p id='_'>
          <concept>
            <refterm>Second Designation</refterm>
            <renderterm>Second Designation</renderterm>
            <xref target='term-first-designation'/>
          </concept>
        </p>
      </clause>
         </sections>
         </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes letter-symbol designations" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === First Designation

      [%metadata]
      letter-symbol:: true

      preferred:[Second Designation]

      [%metadata]
      letter-symbol:: false

      alt:[Third Designation]

      [%metadata]
      letter-symbol:: true

      deprecated:[stem:[t_90]]

      related:see[<<second>>,Fifth Designation]

      [%metadata]
      letter-symbol:: true

      Definition
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
          <terms id='_' obligation='normative'>
            <title>Terms and definitions</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id='term-first-designation'>
              <preferred>
                <letter-symbol>
                  <name>First Designation</name>
                </letter-symbol>
              </preferred>
              <preferred>
                <expression>
                  <name>Second Designation</name>
                </expression>
              </preferred>
              <admitted>
                <letter-symbol>
                  <name>Third Designation</name>
                </letter-symbol>
              </admitted>
              <deprecates>
                <letter-symbol>
                <name>
              <stem type='MathML'>
                <math xmlns='http://www.w3.org/1998/Math/MathML'>
                  <msub>
                    <mrow>
                      <mi>t</mi>
                    </mrow>
                    <mrow>
                      <mn>90</mn>
                    </mrow>
                  </msub>
                </math>
              </stem>
            </name>
                </letter-symbol>
              </deprecates>
              <related type='see'>
                <preferred>
                  <letter-symbol>
                    <name>Fifth Designation</name>
                  </letter-symbol>
                </preferred>
                <xref target='second'/>
              </related>
              <definition><verbal-definition>
                <p id='_'>Definition</p>
              </verbal-definition></definition>
            </term>
          </terms>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes empty designations" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      [[second]]
      === {blank}

      [%metadata]
      isInternational:: true

      preferred:[]

      alt:[]

      deprecated:[]

      related:see[<<second>>,]

      Definition
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
          <terms id='_' obligation='normative'>
            <title>Terms and definitions</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id='second'>
              <preferred isInternational='true'>
                <expression>
                  <name/>
                </expression>
              </preferred>
              <preferred>
                <expression>
                  <name/>
                </expression>
              </preferred>
              <admitted>
                <expression>
                  <name/>
                </expression>
              </admitted>
              <deprecates>
                <expression>
                  <name> </name>
                </expression>
              </deprecates>
              <related type='see'>
                <xref target='second'/>
              </related>
              <definition><verbal-definition>
                <p id='_'>Definition</p>
              </verbal-definition></definition>
            </term>
          </terms>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes graphical-symbol designations" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      [[second]]
      === {blank}

      .Caption
      ....
      <LITERAL>
      FIGURATIVE
      ....

      [%metadata]
      isInternational:: true

      preferred:[]

      .Caption
      ....
      <LITERAL>
      FIGURATIVE
      ....

      alt:[]

      .Caption
      ....
      <LITERAL>
      FIGURATIVE
      ....

      deprecated:[]

      .Caption
      ....
      <LITERAL>
      FIGURATIVE
      ....

      related:see[<<second>>,]

      .Caption
      ....
      <LITERAL>
      FIGURATIVE
      ....

      Definition
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
          <terms id='_' obligation='normative'>
            <title>Terms and definitions</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
             <term id='second'>
               <preferred isInternational='true'>
                 <graphical-symbol>
                   <figure id='_'>
                     <pre id='_'>&lt;LITERAL&gt; FIGURATIVE</pre>
                   </figure>
                 </graphical-symbol>
               </preferred>
               <preferred>
                 <graphical-symbol>
                   <figure id='_'>
                     <pre id='_'>&lt;LITERAL&gt; FIGURATIVE</pre>
                   </figure>
                 </graphical-symbol>
               </preferred>
               <admitted>
                 <graphical-symbol>
                   <figure id='_'>
                     <pre id='_'>&lt;LITERAL&gt; FIGURATIVE</pre>
                   </figure>
                 </graphical-symbol>
               </admitted>
               <deprecates>
                 <graphical-symbol>
                   <figure id='_'>
                     <pre id='_'>&lt;LITERAL&gt; FIGURATIVE</pre>
                   </figure>
                 </graphical-symbol>
               </deprecates>
               <related type='see'>
                 <xref target='second'/>
               </related>
               <definition>
                 <verbal-definition><p id='_'>Definition</p></verbal-definition>
                 <non-verbal-representation>
                 <figure id='_'>
                   <name>Caption</name>
                   <pre id='_'>&lt;LITERAL&gt; FIGURATIVE</pre>
                 </figure>
                 </non-verbal-representation>
               </definition>
             </term>
          </terms>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "sorts designations" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === First Designation

      [%metadata]
      language:: fr
      script:: Latn
      type:: prefix
      isInternational:: true
      abbreviation-type:: acronym
      pronunciation:: fəɹst
      domain:: Hydraulics
      subject:: pipes
      usage-info:: This is usage.

      related:see[Fifth Designation]

      [%metadata]
      grammar::
      gender::: neuter
      isVerb::: true

      deprecated:[Fourth Designation]

      [%metadata]
      language:: jp
      script:: Japn
      type:: full
      grammar::
      gender::: masculine, feminine
      isPreposition::: false
      isNoun::: true
      grammar-value::: irregular declension

      alt:[Third Designation]

      [%metadata]
      language:: he
      script:: Hebr
      type:: suffix
      domain:: Hydraulics1
      subject: pipes1
      usage-info:: This is usage 1.

      preferred:[Second Designation]

      [%metadata]
      type:: abbreviation

      Definition

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
          <terms id='_' obligation='normative'>
            <title>Terms and definitions</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id='term-first-designation'>
              <preferred language='fr' script='Latn' type='prefix' isInternational="true">
                <expression>
                  <name>First Designation</name>
                  <abbreviation-type>acronym</abbreviation-type>
                  <pronunciation>f&#601;&#633;st</pronunciation>
                </expression>
                <usage-info>This is usage.</usage-info>
              </preferred>
              <preferred type='abbreviation'>
                <expression>
                  <name>Second Designation</name>
                </expression>
              </preferred>
              <admitted language='he' script='Hebr' type='suffix'>
                <expression>
                  <name>Third Designation</name>
                </expression>
                <usage-info>This is usage 1.</usage-info>
              </admitted>
              <deprecates language='jp' script='Japn' type='full'>
                <expression>
                  <name>Fourth Designation</name>
                  <grammar>
                    <gender>masculine</gender>
                    <gender>feminine</gender>
                    <isPreposition>false</isPreposition>
                    <isNoun>true</isNoun>
                    <grammar-value>irregular declension</grammar-value>
                  </grammar>
                </expression>
              </deprecates>
              <related type='see'>
                <strong>
                  term
                  <tt>Fifth Designation</tt>
                   not resolved via ID
                  <tt>fifth-designation</tt>
                </strong>
              </related>
              <domain>Hydraulics</domain>
              <subject>pipes</subject>
              <definition><verbal-definition>
                <p id='_'>Definition</p>
              </verbal-definition></definition>
            </term>
          </terms>
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
               <term id="term-t90"><preferred><letter-symbol><name><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub>
               <mrow>
        <mi>t</mi>
      </mrow>
      <mrow>
        <mn>90</mn>
      </mrow>
      </msub></math></stem></name></letter-symbol></preferred>
      <admitted><letter-symbol><name><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub>
      <mrow>
        <mi>t</mi>
      </mrow>
      <mrow>
        <mn>91</mn>
      </mrow>
      </msub></math></stem></name></letter-symbol></admitted>
             <definition><verbal-definition><p id="_">Time</p></verbal-definition></definition></term>
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
               <preferred><expression><name>Tempus</name></expression></preferred>
               <domain>relativity</domain><definition><verbal-definition><p id="_"> Time</p></verbal-definition></definition>
             </term>
             <term id='term-tempus1'>
        <preferred><expression><name>Tempus1</name></expression></preferred>
        <domain>relativity2</domain>
        <definition><verbal-definition>
          <p id='_'>Time2</p>
          <p id='_'> </p>
        </verbal-definition></definition>
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

      * This is a list

      []
      . This too is a list

      []
      This is:: another list


      This is a concluding paragraph
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
               <terms id="_" obligation="normative">
               <title>Terms and definitions</title>
               <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
               <term id="term-t90"><preferred><letter-symbol><name><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub>
                <mrow>
         <mi>t</mi>
       </mrow>
       <mrow>
         <mn>90</mn>
       </mrow>
      </msub></math></stem></name></letter-symbol></preferred>
      <definition>
      <verbal-definition>
      <p id="_">This paragraph is extraneous</p>
                  <ul id='_'>
              <li>
                <p id='_'>This is a list</p>
              </li>
            </ul>
            <ol id='_' type='arabic'>
              <li>
                <p id='_'>This too is a list</p>
              </li>
            </ol>
            <dl id='_'>
              <dt>This is</dt>
              <dd>
                <p id='_'>another list</p>
              </dd>
            </dl>
            <p id='_'>This is a concluding paragraph</p>
      </verbal-definition>
      <non-verbal-representation><formula id="_">
               <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub>
               <mrow>
        <mi>t</mi>
      </mrow>
      <mrow>
        <mi>A</mi>
      </mrow>
      </msub></math></stem>
             </formula></non-verbal-representation>
            </definition>
             </term>
             </terms>
             </sections>
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

      Definition

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
        <term id="term-term"><preferred><expression><name>Term</name></expression></preferred>
        <definition><verbal-definition><p id='_'>Definition</p></verbal-definition></definition>
      <termnote id="_">
        <p id="_">Note</p>
      </termnote><termnote id="_">
        <p id="_">Note 2</p>
      </termnote><termexample id="_">
        <p id="_">Example 1</p>
      </termexample><termexample id="_">
        <p id="_">Example 2</p>
      </termexample><termsource status="identical" type="authoritative">
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

  it "supports non-verbal definitions" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Terms and definitions

      === Term

      [.definition]
      --

      Definition

      [.source]
      <<ISO2191,section=1>>

      |===
      | A | B

      | C | D
      |===
      --

      [.source]
      <<ISO2191,section=2>>

      === Term 2

      [.definition]
      --

      ....
      Literal
      ....

      [stem]
      ++++
      x = y
      ++++

      [.source]
      <<ISO2191,section=3>>
      --

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
          <sections>
            <terms id='_' obligation='normative'>
              <title>Terms and definitions</title>
              <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
              <term id='term-term'>
                <preferred>
                  <expression>
                    <name>Term</name>
                  </expression>
                </preferred>
                <definition>
                  <verbal-definition>
                    <p id='_'>Definition</p>
                    <termsource status='identical' type='authoritative'>
                      <origin bibitemid='ISO2191' type='inline' citeas=''>
                        <localityStack>
                          <locality type='section'>
                            <referenceFrom>1</referenceFrom>
                          </locality>
                        </localityStack>
                      </origin>
                    </termsource>
                  </verbal-definition>
                  <non-verbal-representation>
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
                  </non-verbal-representation>
                </definition>
                <termsource status='identical' type='authoritative'>
                  <origin bibitemid='ISO2191' type='inline' citeas=''>
                    <localityStack>
                      <locality type='section'>
                        <referenceFrom>2</referenceFrom>
                      </locality>
                    </localityStack>
                  </origin>
                </termsource>
              </term>
              <term id='term-term-2'>
                <preferred>
                  <expression>
                    <name>Term 2</name>
                  </expression>
                </preferred>
                <definition>
                  <non-verbal-representation>
                    <figure id='_'>
                      <pre id='_'>Literal</pre>
                    </figure>
                    <formula id='_'>
                      <stem type='MathML'>
                        <math xmlns='http://www.w3.org/1998/Math/MathML'>
                          <mi>x</mi>
                          <mo>=</mo>
                          <mi>y</mi>
                        </math>
                      </stem>
                    </formula>
                    <termsource status='identical' type='authoritative'>
                      <origin bibitemid='ISO2191' type='inline' citeas=''>
                        <localityStack>
                          <locality type='section'>
                            <referenceFrom>3</referenceFrom>
                          </locality>
                        </localityStack>
                      </origin>
                    </termsource>
                  </non-verbal-representation>
                </definition>
              </term>
            </terms>
          </sections>
        </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

end
