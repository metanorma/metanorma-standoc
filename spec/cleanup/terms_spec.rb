require "spec_helper"
require "relaton/iec"
require "fileutils"

RSpec.describe Metanorma::Standoc do
  it "deals with different levels of mixed order terms" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Terms, definitions, symbols and abbreviations

      === Terms and definitions

      [.boilerplate]
      ==== [Supplied boilerplate]
      NOTE: These terms and definitions are taken from a published British Standard.

      For the purposes of this British Standard, the following terms and definitions
      apply.

      ==== competent person

      person, suitably trained and qualified by knowledge and practical experience,
      and provided with the necessary instructions, to enable the required task(s) to
      be carried out correctly

      ==== dampers

      ===== fire damper

      moveable closure within a duct which is operated automatically or manually and
      is designed to prevent the passage of fire

      ===== smoke damper

      moveable closure within a duct which is operated automatically or manually and
      is designed to prevent or allow the passage of smoke

      ==== ductwork

      system of enclosures of any cross-sectional shape for the distribution or
      extraction of air and/or smoke

      === Symbols
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <sections>
           <clause id="_" obligation="normative" type="terms">
             <title id="_">Terms, definitions and symbols</title>
             <p id="_">For the purposes of this document,
           the following terms and definitions apply.</p>
             <terms id="_" obligation="normative">
               <title id="_">Terms and definitions</title>
               <note id="_">
                 <p id="_">These terms and definitions are taken from a published British Standard.</p>
               </note>
               <p id="_">For the purposes of this British Standard, the following terms and definitions
       apply.</p>
               <term id="_" anchor="term-competent-person">
                 <preferred>
                   <expression>
                     <name>competent person</name>
                   </expression>
                 </preferred>
                 <definition id="_">
                   <verbal-definition id="_">
                     <p id="_">person, suitably trained and qualified by knowledge and practical experience,
       and provided with the necessary instructions, to enable the required task(s) to
       be carried out correctly</p>
                   </verbal-definition>
                 </definition>
               </term>
               <terms id="_" obligation="normative">
                 <title id="_">dampers</title>
                 <term id="_" anchor="term-fire-damper">
                   <preferred>
                     <expression>
                       <name>fire damper</name>
                     </expression>
                   </preferred>
                   <definition id="_">
                     <verbal-definition id="_">
                       <p id="_">moveable closure within a duct which is operated automatically or manually and
       is designed to prevent the passage of fire</p>
                     </verbal-definition>
                   </definition>
                 </term>
                 <term id="_" anchor="term-smoke-damper">
                   <preferred>
                     <expression>
                       <name>smoke damper</name>
                     </expression>
                   </preferred>
                   <definition id="_">
                     <verbal-definition id="_">
                       <p id="_">moveable closure within a duct which is operated automatically or manually and
       is designed to prevent or allow the passage of smoke</p>
                     </verbal-definition>
                   </definition>
                 </term>
               </terms>
               <term id="_" anchor="term-ductwork">
                 <preferred>
                   <expression>
                     <name>ductwork</name>
                   </expression>
                 </preferred>
                 <definition id="_">
                   <verbal-definition id="_">
                     <p id="_">system of enclosures of any cross-sectional shape for the distribution or
       extraction of air and/or smoke</p>
                   </verbal-definition>
                 </definition>
               </term>
             </terms>
             <definitions id="_" type="symbols" obligation="normative">
               <title id="_">Symbols</title>
             </definitions>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

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
      number::: singular, plural
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
          <terms id="_" obligation='normative'>
            <title id="_">Terms and definitions</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id="_" anchor="term-First-Designation">
              <preferred>
                <expression language='fr' script='Latn' type='prefix' isInternational="true">
                  <name>First Designation</name>
            <abbreviation-type>acronym</abbreviation-type>
            <pronunciation>f&#601;&#633;st</pronunciation>
                </expression>
                <field-of-application>Field</field-of-application>
                <usage-info>This is usage.</usage-info>
                        <source status='identical' type='authoritative'>
          <origin bibitemid='ISO2191' type='inline' citeas=''>
            <localityStack>
              <locality type='section'>
                <referenceFrom>1</referenceFrom>
              </locality>
            </localityStack>
          </origin>
        </source>
              </preferred>
              <admitted absent="true">
                <expression language='he' script='Hebr' type='suffix'>
                  <name>Third Designation</name>
                </expression>
                <usage-info>This is usage 1.</usage-info>
              </admitted>
              <deprecates geographic-area="AUS">
                <expression language='jp' script='Japn' type='full'>
                  <name>Fourth Designation</name>
            <grammar>
              <gender>masculine</gender>
              <gender>feminine</gender>
              <number>singular</number>
              <number>plural</number>
              <isPreposition>false</isPreposition>
              <isNoun>true</isNoun>
              <grammar-value>irregular declension</grammar-value>
            </grammar>
                </expression>
                <field-of-application>Field</field-of-application>
              </deprecates>
                      <related type='see'>
          <preferred geographic-area="GRC">
            <expression type="abbreviation">
              <name>Fifth Designation</name>
              <grammar>
                <gender>neuter</gender>
              </grammar>
            </expression>
                                  <source status='identical' type='authoritative'>
              <origin bibitemid='ISO2191' type='inline' citeas=''>
                <localityStack>
                  <locality type='section'>
                    <referenceFrom>2</referenceFrom>
                  </locality>
                </localityStack>
              </origin>
            </source>
          </preferred>
          <xref target='second'/>
        </related>
              <domain>Hydraulics</domain>
              <subject>pipes</subject>
              <definition id="_"><verbal-definition id="_">
                <p id='_'>Definition</p>
              </verbal-definition></definition>
          <source status='identical' type='authoritative'>
          <origin bibitemid='ISO2191' type='inline' citeas=''>
            <localityStack>
              <locality type='section'>
                <referenceFrom>3</referenceFrom>
              </locality>
            </localityStack>
          </origin>
        </source>
            </term>
        <term id="_" anchor="second">
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
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
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
      letter-symbol:: letter

      deprecated:[stem:[t_90]]

      related:see[<<second>>,Fifth Designation]

      [%metadata]
      letter-symbol:: equation

      Definition
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
          <terms id="_" obligation='normative'>
            <title id="_">Terms and definitions</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id="_" anchor="term-First-Designation">
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
                <letter-symbol type="letter">
                  <name>Third Designation</name>
                </letter-symbol>
              </admitted>
              <deprecates>
                <letter-symbol>
                <name>
                                      <stem type="MathML" block="false">
                        <math xmlns="http://www.w3.org/1998/Math/MathML">
                          <mstyle displaystyle="false">
                            <msub>
                              <mi>t</mi>
                              <mn>90</mn>
                            </msub>
                          </mstyle>
                        </math>
                        <asciimath>t_90</asciimath>
                      </stem>
            </name>
                </letter-symbol>
              </deprecates>
              <related type='see'>
                <preferred>
                  <letter-symbol type="equation">
                    <name>Fifth Designation</name>
                  </letter-symbol>
                </preferred>
                <xref target='second'/>
              </related>
              <definition id="_"><verbal-definition id="_">
                <p id='_'>Definition</p>
              </verbal-definition></definition>
            </term>
          </terms>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
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

      === Term

      preferred:[]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <terms id="_" obligation="normative">
             <title id="_">Terms and definitions</title>
             <p id="_">For the purposes of this document,
           the following terms and definitions apply.</p>
             <term id="_" anchor="second">
               <preferred>
                 <expression isInternational="true">
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
                   <name/>
                 </expression>
               </deprecates>
               <related type="see">
                 <xref target="second"/>
               </related>
               <definition id="_">
                 <verbal-definition id="_">
                   <p id="_">Definition</p>
                 </verbal-definition>
               </definition>
             </term>
             <term id="_" anchor="term-Term">
               <preferred>
                 <expression>
                   <name>Term</name>
                 </expression>
               </preferred>
               <preferred>
                 <expression>
                   <name/>
                 </expression>
               </preferred>
             </term>
           </terms>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
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
          <terms id="_" obligation='normative'>
            <title id="_">Terms and definitions</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
             <term id="_" anchor="second">
               <preferred>
                 <graphical-symbol isInternational='true'>
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
               <definition id="_">
                 <verbal-definition id="_">
                   <figure id='_'>
                     <name id="_">Caption</name>
                     <pre id='_'>&lt;LITERAL&gt; FIGURATIVE</pre>
                   </figure>
                   <p id='_'>Definition</p>
                 </verbal-definition>
               </definition>
             </term>
          </terms>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

  it "sorts designations" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      [[des1]]
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

      related:see[<<des1>>,Fifth Designation]

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
          <terms id="_" obligation='normative'>
            <title id="_">Terms and definitions</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id="_" anchor="des1">
              <preferred>
                <expression language='fr' script='Latn' type='prefix' isInternational="true">
                  <name>First Designation</name>
                  <abbreviation-type>acronym</abbreviation-type>
                  <pronunciation>f&#601;&#633;st</pronunciation>
                </expression>
                <usage-info>This is usage.</usage-info>
              </preferred>
              <preferred>
                <expression type='abbreviation'>
                  <name>Second Designation</name>
                </expression>
              </preferred>
              <admitted>
                <expression language='he' script='Hebr' type='suffix'>
                  <name>Third Designation</name>
                </expression>
                <usage-info>This is usage 1.</usage-info>
              </admitted>
              <deprecates>
                <expression language='jp' script='Japn' type='full'>
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
              <preferred><expression><name>Fifth Designation</name><grammar><gender>neuter</gender></grammar></expression>
              </preferred><xref target='des1'/>
              </related>
              <domain>Hydraulics</domain>
              <subject>pipes</subject>
              <definition id="_"><verbal-definition id="_">
                <p id='_'>Definition</p>
              </verbal-definition></definition>
            </term>
          </terms>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

  it "differentiates stem-only and mixed terms" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === stem:[t_90]

      Time

      === stem:[t_90]-sensitivity

      Sensitivity

      === sensitivity to stem:[t_90]

      Sensitivity #2
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
                    <sections>
          <terms id="_" obligation="normative">
            <title id="_">Terms and definitions</title>
            <p id="_">For the purposes of this document,
          the following terms and definitions apply.</p>
            <term id="_" anchor="term-t_90">
              <preferred>
                <letter-symbol>
                  <name>
                    <stem type="MathML" block="false">
                      <math xmlns="http://www.w3.org/1998/Math/MathML">
                        <mstyle displaystyle="false">
                          <msub>
                            <mi>t</mi>
                            <mn>90</mn>
                          </msub>
                        </mstyle>
                      </math>
                      <asciimath>t_90</asciimath>
                    </stem>
                  </name>
                </letter-symbol>
              </preferred>
              <definition id="_">
                <verbal-definition id="_">
                  <p id="_">Time</p>
                </verbal-definition>
              </definition>
            </term>
            <term id="_" anchor="term-t_90-sensitivity">
              <preferred>
                <expression>
                  <name><stem type="MathML" block="false">
                  <math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><msub><mi>t</mi><mn>90</mn></msub></mstyle></math><asciimath>t_90</asciimath></stem>-sensitivity</name>
                </expression>
              </preferred>
              <definition id="_">
                <verbal-definition id="_">
                  <p id="_">Sensitivity</p>
                </verbal-definition>
              </definition>
            </term>
            <term id="_" anchor="term-sensitivity-to-t_90">
              <preferred>
                <expression>
                  <name>sensitivity to <stem type="MathML"  block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><msub><mi>t</mi><mn>90</mn></msub></mstyle></math><asciimath>t_90</asciimath></stem></name>
                </expression>
              </preferred>
              <definition id="_">
                <verbal-definition id="_">
                  <p id="_">Sensitivity #2</p>
                </verbal-definition>
              </definition>
            </term>
          </terms>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
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
               <title id="_">Terms and definitions</title>
               <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
               <term id="_" anchor="term-_relativity_-Tempus">
               <preferred><expression><name>Tempus</name></expression></preferred>
               <domain>relativity</domain><definition id="_"><verbal-definition id="_"><p id="_"> Time</p></verbal-definition></definition>
             </term>
             <term id="_" anchor="term-_relativity2_-Tempus1">
        <preferred><expression><name>Tempus1</name></expression></preferred>
        <domain>relativity2</domain>
        <definition id="_"><verbal-definition id="_">
          <p id='_'>Time2</p>
        </verbal-definition></definition>
      </term>
             </terms>
             </sections>
             </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
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

      alt:[stem:[t_A]]

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
               <title id="_">Terms and definitions</title>
               <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
               <term id="_" anchor="term-t_90"><preferred><letter-symbol><name>
                                     <stem type="MathML" block="false">
                        <math xmlns="http://www.w3.org/1998/Math/MathML">
                          <mstyle displaystyle="false">
                            <msub>
                              <mi>t</mi>
                              <mn>90</mn>
                            </msub>
                          </mstyle>
                        </math>
                        <asciimath>t_90</asciimath>
                      </stem>
      </name></letter-symbol></preferred>
             <admitted>
         <letter-symbol>
           <name>
                                 <stem type="MathML"  block="false">
                        <math xmlns="http://www.w3.org/1998/Math/MathML">
                          <mstyle displaystyle="false">
                            <msub>
                              <mi>t</mi>
                              <mi>A</mi>
                            </msub>
                          </mstyle>
                        </math>
                        <asciimath>t_A</asciimath>
                      </stem>
           </name>
         </letter-symbol>
       </admitted>
      <definition id="_">
      <verbal-definition id="_">
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
              <dd id="_">
                <p id='_'>another list</p>
              </dd>
            </dl>
            <p id='_'>This is a concluding paragraph</p>
      </verbal-definition>
            </definition>
             </term>
             </terms>
             </sections>
             </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
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
        <title id="_">Terms and definitions</title>
        <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
        <term id="_" anchor="term-Term"><preferred><expression><name>Term</name></expression></preferred>
        <definition id="_"><verbal-definition id="_"><p id='_'>Definition</p></verbal-definition></definition>
      <termnote id="_">
        <p id="_">Note</p>
      </termnote><termnote id="_">
        <p id="_">Note 2</p>
      </termnote><termexample id="_">
        <p id="_">Example 1</p>
      </termexample><termexample id="_">
        <p id="_">Example 2</p>
      </termexample><source status="identical" type="authoritative">
        <origin bibitemid="ISO2191" type="inline" citeas="">
        <localityStack>
       <locality type="section"><referenceFrom>1</referenceFrom></locality>
        </localityStack>
       </origin>
      </source></term>
      </terms>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
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
      --

      [.definition]
      --
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
            <terms id="_" obligation='normative'>
              <title id="_">Terms and definitions</title>
              <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
              <term id="_" anchor="term-Term">
                <preferred>
                  <expression>
                    <name>Term</name>
                  </expression>
                </preferred>
                <definition id="_">
                  <verbal-definition id="_">
                    <p id='_'>Definition</p>
                    <source status='identical' type='authoritative'>
                      <origin bibitemid='ISO2191' type='inline' citeas=''>
                        <localityStack>
                          <locality type='section'>
                            <referenceFrom>1</referenceFrom>
                          </locality>
                        </localityStack>
                      </origin>
                    </source>
                  </verbal-definition>
                  <non-verbal-representation id="_">
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
                  </non-verbal-representation>
                </definition>
                <source status='identical' type='authoritative'>
                  <origin bibitemid='ISO2191' type='inline' citeas=''>
                    <localityStack>
                      <locality type='section'>
                        <referenceFrom>2</referenceFrom>
                      </locality>
                    </localityStack>
                  </origin>
                </source>
              </term>
              <term id="_" anchor="term-Term-2">
                <preferred>
                  <expression>
                    <name>Term 2</name>
                  </expression>
                </preferred>
                <definition id="_">
                  <non-verbal-representation id="_">
                    <figure id='_'>
                      <pre id='_'>Literal</pre>
                    </figure>
                    <formula id='_'>
                      <stem type='MathML' block="true">
                        <math xmlns='http://www.w3.org/1998/Math/MathML'>
                        <mstyle displaystyle="true">
                          <mi>x</mi>
                          <mo>=</mo>
                          <mi>y</mi>
                          </mstyle>
                        </math>
                        <asciimath>x = y</asciimath>
                      </stem>
                    </formula>
                    <source status='identical' type='authoritative'>
                      <origin bibitemid='ISO2191' type='inline' citeas=''>
                        <localityStack>
                          <locality type='section'>
                            <referenceFrom>3</referenceFrom>
                          </locality>
                        </localityStack>
                      </origin>
                    </source>
                  </non-verbal-representation>
                </definition>
              </term>
            </terms>
          </sections>
        </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

  it "differentiates stem expressions before, after, and within verbal definitions" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Terms and definitions

      === Term

      stem:[lambda]

      [.definition]
      --

      Definition

      stem:[mu]
      --

      [.definition]
      --

      stem:[nu]
      --

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                <sections>
            <terms id="_" obligation="normative">
              <title id="_">Terms and definitions</title>
              <p id="_">For the purposes of this document,
            the following terms and definitions apply.</p>
              <term id="_" anchor="term-Term">
                <preferred>
                  <expression>
                    <name>Term</name>
                  </expression>
                </preferred>
                    <p id="_">
                      <stem type="MathML" block="false">
                        <math xmlns="http://www.w3.org/1998/Math/MathML">
                          <mstyle displaystyle="false">
                            <mi>λ</mi>
                          </mstyle>
                        </math>
                        <asciimath>lambda</asciimath>
                      </stem>
                    </p>
                <definition id="_">
                  <verbal-definition id="_">
                    <p id="_">Definition</p>
                    <p id="_">
                      <stem type="MathML" block="false">
                        <math xmlns="http://www.w3.org/1998/Math/MathML">
                          <mstyle displaystyle="false">
                            <mi>μ</mi>
                          </mstyle>
                        </math>
                        <asciimath>mu</asciimath>
                      </stem>
                    </p>
                  </verbal-definition>
                </definition>
                <definition id="_">
                  <verbal-definition id="_">
                    <p id="_">
                      <stem type="MathML" block="false">
                        <math xmlns="http://www.w3.org/1998/Math/MathML">
                          <mstyle displaystyle="false">
                            <mi>ν</mi>
                          </mstyle>
                        </math>
                        <asciimath>nu</asciimath>
                      </stem>
                    </p>
                  </verbal-definition>
                </definition>
              </term>
            </terms>
          </sections>
        </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

  it "differentiates formulas before, after, and within verbal definitions" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Terms and definitions

      === Term

      [stem]
      ++++
      lambda
      ++++

      [.definition]
      --

      Definition

      [stem]
      ++++
      mu
      ++++
      --

      [.definition]
      --

      [stem]
      ++++
      nu
      ++++
      --

    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
                  <sections>
          <terms id="_" obligation="normative">
            <title id="_">Terms and definitions</title>
            <p id="_">For the purposes of this document,
          the following terms and definitions apply.</p>
            <term id="_" anchor="term-Term">
              <preferred>
                <expression>
                  <name>Term</name>
                </expression>
              </preferred>
                  <formula id="_">
                    <stem type="MathML" block="true">
                      <math xmlns="http://www.w3.org/1998/Math/MathML">
                        <mstyle displaystyle="true">
                          <mi>λ</mi>
                        </mstyle>
                      </math>
                      <asciimath>lambda</asciimath>
                    </stem>
                  </formula>
              <definition id="_">
                <verbal-definition id="_">
                  <p id="_">Definition</p>
                  <formula id="_">
                    <stem type="MathML" block="true">
                      <math xmlns="http://www.w3.org/1998/Math/MathML">
                        <mstyle displaystyle="true">
                          <mi>μ</mi>
                        </mstyle>
                      </math>
                      <asciimath>mu</asciimath>
                    </stem>
                  </formula>
                </verbal-definition>
                <non-verbal-representation id="_">
                  <formula id="_">
                    <stem type="MathML" block="true">
                      <math xmlns="http://www.w3.org/1998/Math/MathML">
                        <mstyle displaystyle="true">
                          <mi>ν</mi>
                        </mstyle>
                      </math>
                      <asciimath>nu</asciimath>
                    </stem>
                  </formula>
                </non-verbal-representation>
              </definition>
            </term>
          </terms>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

  it "automatically indexes terms" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR.sub(":nodoc:\n", ":nodoc:\n:index-terms:\n")}

      == Terms and definitions

      === Term

      [stem]
      ++++
      lambda
      ++++

      admitted:[x]

      === Term2

      preferred:[stem:[mu_0 // 2]]

      == Symbols and Abbreviated Terms

      x^2^:: Definition
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <terms id="_" obligation="normative">
             <title id="_">Terms and definitions</title>
             <p id="_">For the purposes of this document,
           the following terms and definitions apply.</p>
             <term id="_" anchor="term-Term">
               <preferred>
                 <expression>
                   <name>Term<index><primary>Term</primary></index></name>
                 </expression>
               </preferred>
               <admitted>
                 <expression>
                   <name>x</name>
                 </expression>
               </admitted>
               <definition id="_">
                 <non-verbal-representation id="_">
                   <formula id="_">
                     <stem type="MathML" block="true">
                       <math xmlns="http://www.w3.org/1998/Math/MathML">
                         <mstyle displaystyle="true">
                           <mi>λ</mi>
                         </mstyle>
                       </math>
                       <asciimath>lambda</asciimath>
                     </stem>
                   </formula>
                 </non-verbal-representation>
               </definition>
             </term>
             <term id="_" anchor="term-Term2">
               <preferred>
                 <expression>
                   <name>Term2<index><primary>Term2</primary></index></name>
                 </expression>
               </preferred>
               <preferred>
                 <letter-symbol>
                   <name>
                     <stem type="MathML" block="false">
                       <math xmlns="http://www.w3.org/1998/Math/MathML">
                         <mstyle displaystyle="false">
                           <msub>
                             <mi>μ</mi>
                             <mn>0</mn>
                           </msub>
                           <mo>/</mo>
                           <mn>2</mn>
                         </mstyle>
                       </math>
                       <asciimath>mu_0 // 2</asciimath>
                     </stem>
                     <index>
                       <primary>
                         <stem type="MathML"  block="false">
                           <math xmlns="http://www.w3.org/1998/Math/MathML">
                             <mstyle displaystyle="false">
                               <msub>
                                 <mi>μ</mi>
                                 <mn>0</mn>
                               </msub>
                               <mo>/</mo>
                               <mn>2</mn>
                             </mstyle>
                           </math>
                           <asciimath>mu_0 // 2</asciimath>
                         </stem>
                       </primary>
                     </index>
                   </name>
                 </letter-symbol>
               </preferred>
             </term>
           </terms>
           <definitions id="_" obligation="normative">
             <title id="_">Symbols and abbreviated terms</title>
             <dl id="_">
               <dt id="_" anchor="symbol-x2">x<sup>2</sup><index><primary>x<sup>2</sup></primary></index></dt>
               <dd id="_">
                 <p id="_">Definition</p>
               </dd>
             </dl>
           </definitions>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

  it "removes identical preferred or admitted designation in a term" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR.sub(":nodoc:\n", ":nodoc:\n:index-terms:\n")}

      == Terms and definitions

      === term

      preferred:[bayonet]

      preferred:[term]

      admitted:[x]

      admitted:[y]

      admitted:[x]

    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
                <sections>
            <terms id="_" obligation="normative">
              <title id="_">Terms and definitions</title>
              <p id="_">For the purposes of this document,
            the following terms and definitions apply.</p>
              <term id="_" anchor="term-term">
                <preferred>
                  <expression>
                    <name>term<index><primary>term</primary></index></name>
                  </expression>
                </preferred>
                <preferred>
                  <expression>
                    <name>bayonet<index><primary>bayonet</primary></index></name>
                  </expression>
                </preferred>
                <admitted>
                  <expression>
                    <name>x</name>
                  </expression>
                </admitted>
                <admitted>
                  <expression>
                    <name>y</name>
                  </expression>
                </admitted>
              </term>
            </terms>
          </sections>
        </metanorma>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

   it "unnests designations in a term" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Terms and definitions

      === ISO Online browsing platform: available at https://www.iso.org/obp
      admitted:[IEC Electropedia: available at https://www.electropedia.org/[\] ]
      admitted:[access point]
      admitted:[AP]
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
          <sections>
             <terms id="_" obligation="normative">
                <title id="_">Terms and definitions</title>
                <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                <term id="_" anchor="term-ISO-Online-browsing-platform_-available-at">
                   <preferred>
                      <expression>
                         <name>
                            ISO Online browsing platform: available at
                            <link target="https://www.iso.org/obp"/>
                         </name>
                      </expression>
                   </preferred>
                   <admitted>
                      <expression>
                         <name>
                            IEC Electropedia: available at
                            <link target="https://www.electropedia.org/"/>
                         </name>
                      </expression>
                   </admitted>
                   <admitted>
                      <expression>
                         <name>access point</name>
                      </expression>
                   </admitted>
                   <admitted>
                      <expression>
                         <name>AP</name>
                      </expression>
                   </admitted>
                </term>
             </terms>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "automates terms & definitions titles if there are no extraneous sections" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms, Definitions, Symbols and Abbreviated Terms

      [.boilerplate]
      === Boilerplate

      Boilerplate text

      === Intro 4

      ==== Term2

      === Symbols and Abbreviated Terms

      [.nonterm]
      ==== General

      ==== Symbols

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <sections>
           <clause id="_" obligation="normative" type="terms">
             <title id="_">Terms, definitions, symbols and abbreviated terms</title>
             <p id="_">Boilerplate text</p>
             <terms id="_" obligation="normative">
               <title id="_">Terms and definitions</title>
               <term id="_" anchor="term-Term2">
                 <preferred>
                   <expression>
                     <name>Term2</name>
                   </expression>
                 </preferred>
               </term>
             </terms>
             <definitions id="_" obligation="normative">
               <title id="_">Symbols and abbreviated terms</title>
               <clause id="_" inline-header="false" obligation="normative">
                 <title id="_">General</title>
               </clause>
               <definitions id="_" type="symbols" obligation="normative">
                 <title id="_">Symbols</title>
               </definitions>
             </definitions>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

  it "does not do automated terms & definitions titles if there are extraneous sections" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms, Definitions, Symbols and Abbreviated Terms

      [.boilerplate]
      === Boilerplate

      Boilerplate text

      [.nonterm]
      === Intro 3

      === Intro 4

      ==== Term2

      === Symbols and Abbreviated Terms

      [.nonterm]
      ==== General

      ==== Symbols

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
              <sections>
           <clause id="_" obligation="normative" type="terms">
             <title id="_">Terms, Definitions, Symbols and Abbreviated Terms</title>
             <p id="_">Boilerplate text</p>
             <clause id="_" inline-header="false" obligation="normative">
               <title id="_">Intro 3</title>
             </clause>
             <terms id="_" obligation="normative">
               <title id="_">Intro 4</title>
               <term id="_" anchor="term-Term2">
                 <preferred>
                   <expression>
                     <name>Term2</name>
                   </expression>
                 </preferred>
               </term>
             </terms>
             <definitions id="_" obligation="normative">
               <title id="_">Symbols and abbreviated terms</title>
               <clause id="_" inline-header="false" obligation="normative">
                 <title id="_">General</title>
               </clause>
               <definitions id="_" type="symbols" obligation="normative">
                 <title id="_">Symbols</title>
               </definitions>
             </definitions>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_equivalent_to output
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms, Definitions, Symbols and Abbreviated Terms

      [.boilerplate]
      === Boilerplate

      Boilerplate text

      === Intro 3

      ==== Term2

      === Intro 4

      ==== Term3

      === Symbols and Abbreviated Terms

      [.nonterm]
      ==== General

      ==== Symbols

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <clause id="_" obligation="normative" type="terms">
             <title id="_">Terms, Definitions, Symbols and Abbreviated Terms</title>
             <p id="_">Boilerplate text</p>
             <terms id="_" obligation="normative">
               <title id="_">Intro 3</title>
               <term id="_" anchor="term-Term2">
                 <preferred>
                   <expression>
                     <name>Term2</name>
                   </expression>
                 </preferred>
               </term>
             </terms>
             <terms id="_" obligation="normative">
               <title id="_">Intro 4</title>
               <term id="_" anchor="term-Term3">
                 <preferred>
                   <expression>
                     <name>Term3</name>
                   </expression>
                 </preferred>
               </term>
             </terms>
             <definitions id="_" obligation="normative">
               <title id="_">Symbols and abbreviated terms</title>
               <clause id="_" inline-header="false" obligation="normative">
                 <title id="_">General</title>
               </clause>
               <definitions id="_" type="symbols" obligation="normative">
                 <title id="_">Symbols</title>
               </definitions>
             </definitions>
           </clause>
         </sections>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_equivalent_to output
  end
end
