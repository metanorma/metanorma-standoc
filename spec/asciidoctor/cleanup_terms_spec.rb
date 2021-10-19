require "spec_helper"
require "relaton_iec"
require "fileutils"

RSpec.describe Asciidoctor::Standoc do
  it "processes term and designation metadata" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === First Designation

      [%metadata]
      language:: fr
      script:: Latn
      type:: prefix
      isInternational:: true
      abbreviationType:: acronym
      pronunciation:: fəɹst
      domain:: Hydraulics
      subject:: pipes
      usageinfo:: This is usage.

      alt:[Third Designation]

      [%metadata]
      language:: he
      script:: Hebr
      type:: suffix
      domain:: Hydraulics1
      subject: pipes1
      usageinfo:: This is usage 1.

      deprecated:[Fourth Designation]

      [%metadata]
      language:: jp
      script:: Japn
      type:: full
      grammar::
      gender::: masculine, feminine
      isPreposition::: false
      isNoun::: true
      grammarValue::: irregular declension

      related:see[<<second>>,Fifth Designation]

      [%metadata]
      type:: abbreviation
      grammar::
      gender::: neuter
      isVerb::: true

      Definition

      [[second]]
      === Second Term

      [%metadata]
      usageinfo::
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
              <preferred language='fr' script='Latn' type='prefix'>
                <expression>
                  <name>First Designation</name>
            <isInternational>true</isInternational>
            <abbreviationType>acronym</abbreviationType>
            <pronunciation>f&#601;&#633;st</pronunciation>
                </expression>
              </preferred>
              <admitted language='he' script='Hebr' type='suffix'>
                <expression>
                  <name>Third Designation</name>
                </expression>
              </admitted>
              <deprecates language='jp' script='Japn' type='full'>
                <expression>
                  <name>Fourth Designation</name>
            <grammar>
              <gender>masculine</gender>
              <gender>feminine</gender>
              <isPreposition>false</isPreposition>
              <isNoun>true</isNoun>
              <grammarValue>irregular declension</grammarValue>
            </grammar>
                </expression>
              </deprecates>
                      <related type='abbreviation'>
          <preferred>
            <expression>
              <name>Fifth Designation</name>
              <grammar>
                <gender>neuter</gender>
              </grammar>
            </expression>
          </preferred>
          <xref target='second'/>
        </related>
              <domain>Hydraulics</domain>
              <subject>pipes</subject>
              <usageinfo>This is usage.</usageinfo>
              <definition>
                <p id='_'>Definition</p>
              </definition>
            </term>
        <term id='second'>
        <preferred>
          <expression>
            <name>Second Term</name>
          </expression>
        </preferred>
        <usageinfo>
          <p id='_'>Usage Info 1.</p>
          <p id='_'>Usage Info 2.</p>
        </usageinfo>
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
          <definition>
            <p id='_'>Definition</p>
          </definition>
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
      abbreviationType:: acronym
      pronunciation:: fəɹst
      domain:: Hydraulics
      subject:: pipes
      usageinfo:: This is usage.

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
      grammarValue::: irregular declension

      alt:[Third Designation]

      [%metadata]
      language:: he
      script:: Hebr
      type:: suffix
      domain:: Hydraulics1
      subject: pipes1
      usageinfo:: This is usage 1.

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
              <preferred language='fr' script='Latn' type='prefix'>
                <expression>
                  <name>First Designation</name>
                  <isInternational>true</isInternational>
                  <abbreviationType>acronym</abbreviationType>
                  <pronunciation>f&#601;&#633;st</pronunciation>
                </expression>
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
              </admitted>
              <deprecates language='jp' script='Japn' type='full'>
                <expression>
                  <name>Fourth Designation</name>
                  <grammar>
                    <gender>masculine</gender>
                    <gender>feminine</gender>
                    <isPreposition>false</isPreposition>
                    <isNoun>true</isNoun>
                    <grammarValue>irregular declension</grammarValue>
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
              <usageinfo>This is usage.</usageinfo>
              <definition>
                <p id='_'>Definition</p>
              </definition>
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
               <term id="term-t90"><preferred><expression><name><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub>
               <mrow>
        <mi>t</mi>
      </mrow>
      <mrow>
        <mn>90</mn>
      </mrow>
      </msub></math></stem></name></expression></preferred>
      <admitted><expression><name><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub>
      <mrow>
        <mi>t</mi>
      </mrow>
      <mrow>
        <mn>91</mn>
      </mrow>
      </msub></math></stem></name></expression></admitted>
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
               <preferred><expression><name>Tempus</name></expression></preferred>
               <domain>relativity</domain><definition><p id="_"> Time</p></definition>
             </term>
             <term id='term-tempus1'>
        <preferred><expression><name>Tempus1</name></expression></preferred>
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
               <term id="term-t90"><preferred><expression><name><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub>
                <mrow>
         <mi>t</mi>
       </mrow>
       <mrow>
         <mn>90</mn>
       </mrow>
      </msub></math></stem></name></expression></preferred><definition><formula id="_">
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
        <term id="term-term"><preferred><expression><name>Term</name></expression></preferred>
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
end
