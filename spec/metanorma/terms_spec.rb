require "spec_helper"
require "open3"

RSpec.describe Metanorma::Standoc do
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "processes term notes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      NOTE: This is a note

      WARNING: This is not a note

      [NOTE,keep-separate=true,tag=X,columns=1,multilingual-rendering=common,type=footnote]
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
             <termnote id='_' tag='X' columns='1' multilingual-rendering='common' type="footnote">
        <p id='_'>XYZ</p>
      </termnote>
            </term>
            </terms>
            </sections>
            </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
      <<ISO2191,droploc%capital%style=id%section=1>>

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
               <origin case="capital" droploc="true" bibitemid="ISO2191" style="id" type="inline" citeas="">
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "tag and multilingual processing attributes on term" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [heading="terms, definitions, symbols and abbreviated terms"]
      == Terms, Definitions, Symbols Section

      [language=en,tag=x123,multilingual-rendering=all-columns]
      === Term
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <terms id="_" obligation='normative'>
             <title id="_">Terms and definitions</title>
             <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
             <term id="_" anchor="term-Term" language='en' tag='x123' multilingual-rendering='all-columns'>
               <preferred>
                 <expression>
                   <name>Term</name>
                 </expression>
               </preferred>
             </term>
           </terms>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "varies terms & symbols title" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [heading="terms, definitions, symbols and abbreviated terms"]
      == Terms, Definitions, Symbols Section

      === Term

      === Symbols

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
          <terms id="_" obligation='normative'>
            <title id="_">Terms, definitions and symbols</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id="_" anchor="term-Term">
              <preferred><expression><name>Term</name></expression></preferred>
            </term>
            <definitions id="_" obligation="normative" type="symbols">
              <title id="_">Symbols</title>
            </definitions>
          </terms>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "varies terms & abbreviated terms title" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [heading="terms, definitions, symbols and abbreviated terms"]
      == Terms, Definitions, Abbreviated Terms Section

      === Term

      [heading="abbreviated terms"]
      === Symbols

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
          <terms id="_" obligation='normative'>
            <title id="_">Terms, definitions and abbreviated terms</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id="_" anchor="term-Term">
              <preferred><expression><name>Term</name></expression></preferred>
            </term>
            <definitions id="_" obligation="normative" type="abbreviated_terms">
              <title id="_">Abbreviated terms</title>
            </definitions>
          </terms>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input,
                                                           *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "varies terms symbols & abbreviated terms title" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [heading="terms, definitions, symbols and abbreviated terms"]
      == Terms, Definitions, Abbreviated Terms Section

      === Term

      === Abbreviated Terms

      === Symbols

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
          <terms id="_" obligation='normative'>
            <title id="_">Terms, definitions, symbols and abbreviated terms</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id="_" anchor="term-Term">
              <preferred><expression><name>Term</name></expression></preferred>
            </term>
            <definitions id="_" type='abbreviated_terms' obligation='normative'>
                <title id="_">Abbreviated terms</title>
                </definitions>
                <definitions id="_" type='symbols' obligation='normative'>
                <title id="_">Symbols</title>
                </definitions>
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input,
                                                           *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input,
                                                           *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "processes non-term clauses" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      == Terms, Definitions, Symbols and Abbreviated Terms

      [.boilerplate]
      === Boilerplate

      Boilerplate text

      [.nonterm]
      === Introduction

      ==== Intro 1

      === Intro 2

      [.nonterm]
      ==== Intro 3

      === Intro 4

      ==== Intro 5

      ===== Term2

      === Normal Terms

      ==== Term3

      === Symbols and Abbreviated Terms

      [.nonterm]
      ==== General

      ==== Symbols
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
                <sections>
            <terms id="_" obligation="normative">
              <title id="_">Terms and definitions</title>
              <p id="_">For the purposes of this document,
            the following terms and definitions apply.</p>
              <term id="_" anchor="term-Term1">
                <preferred>
                  <expression>
                    <name>Term1</name>
                  </expression>
                </preferred>
              </term>
            </terms>
            <clause id="_" obligation="normative" type="terms">
              <title id="_">Terms, definitions, symbols and abbreviated terms</title>
              <p id="_">Boilerplate text</p>
              <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Introduction</title>
                <clause id="_" inline-header="false" obligation="normative">
                  <title id="_">Intro 1</title>
                </clause>
              </clause>
              <terms id="_" obligation="normative">
                <title id="_">Intro 2</title>
                <clause id="_" inline-header="false" obligation="normative">
                  <title id="_">Intro 3</title>
                </clause>
              </terms>
              <clause id="_" obligation="normative" type="terms">
                <title id="_">Intro 4</title>
                <terms id="_" obligation="normative">
                  <title id="_">Intro 5</title>
                  <term id="_" anchor="term-Term2">
                    <preferred>
                      <expression>
                        <name>Term2</name>
                      </expression>
                    </preferred>
                  </term>
                </terms>
              </clause>
              <terms id="_" obligation="normative">
                <title id="_">Normal Terms</title>
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
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input,
                                                           *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "processes terminal nodes in terms with term subsection names" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Terms, definitions, symbols and abbreviated terms

      === Terms and definitions

      === Symbols

    INPUT
    output = <<~OUTPUT
                   #{BLANK_HDR}
                   <sections>
        <terms id="_" obligation='normative'>
          <title id="_">Terms, definitions, symbols and abbreviated terms</title>
          <p id='_'>No terms and definitions are listed in this document.</p>
          <clause id="_" inline-header='false' obligation='normative'>
            <title id="_">Terms and definitions</title>
          </clause>
          <definitions id="_" obligation="normative" type="symbols">
            <title id="_">Symbols</title>
          </definitions>
        </terms>
      </sections>
             </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input,
                                                           *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "treats terminal terms subclause named as terms clause as a normal clause" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [[tda]]
      == Terms, definitions, symbols and abbreviations

      [[terms]]
      === Terms and definitions

      === Symbols

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
          <terms id="_" anchor="tda" obligation='normative'>
            <title id="_">Terms, definitions, symbols and abbreviations</title>
            <p id='_'>No terms and definitions are listed in this document.</p>
            <clause id="_" anchor="terms" inline-header='false' obligation='normative'>
              <title id="_">Terms and definitions</title>
            </clause>
            <definitions id="_" obligation="normative" type="symbols">
              <title id="_">Symbols</title>
            </definitions>
          </terms>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "treats non-terminal terms subclause named as terms clause as a terms clause" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Scope

      [[tda]]
      == Terms, definitions, symbols and abbreviations

      [[terms]]
      === Terms and definitions

      [[terms-concepts]]
      ==== Basic concepts

      [[term-date]]
      ===== date

      _time_ (<<term-time>>) on the _calendar_ (<<term-calendar>>) _time scale_ (<<term-time-scale>>)

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
       <sections>
         <clause id="_" inline-header='false' obligation='normative' type="scope">
           <title id="_">Scope</title>
         </clause>
         <clause id="_" anchor="tda" obligation='normative' type="terms">
           <title id="_">Terms and definitions</title>
           <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
           <clause id="_" anchor="terms" obligation='normative' type="terms">
             <title id="_">Terms and definitions</title>
             <terms id="_" anchor="terms-concepts" obligation='normative'>
               <title id="_">Basic concepts</title>
               <term id="_" anchor="term-date">
                 <preferred><expression><name>date</name></expression></preferred>
                 <definition id="_"><verbal-definition id="_">
                   <p id='_'>
                     <em>time</em>
                      (
                     <xref target='term-time'/>
                     ) on the
                     <em>calendar</em>
                      (
                     <xref target='term-calendar'/>
                     )
                     <em>time scale</em>
                      (
                     <xref target='term-time-scale'/>
                     )
                   </p>
                 </verbal-definition></definition>
               </term>
             </terms>
           </clause>
         </clause>
       </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input,
                                                           *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "ignores second terms section" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Terms and definitions

      === Term1

      == Terms and definitions

      === Term2
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                <sections>
             <terms id="_" obligation="normative">
                <title id="_">Terms and definitions</title>
                <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                <term id="_" anchor="term-Term1">
                   <preferred>
                      <expression>
                         <name>Term1</name>
                      </expression>
                   </preferred>
                </term>
             </terms>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Terms and definitions</title>
                <clause id="_" inline-header="false" obligation="normative">
                   <title id="_">Term2</title>
                </clause>
             </clause>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input,
                                                           *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "does not ignore second terms section if specified as heading" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Terms and definitions

      === Term1

      [heading="Terms and definitions"]
      == Terms and definitions

      === Term2
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                <sections>
             <terms id="_" obligation="normative">
                <title id="_">Terms and definitions</title>
                <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                <term id="_" anchor="term-Term1">
                   <preferred>
                      <expression>
                         <name>Term1</name>
                      </expression>
                   </preferred>
                </term>
             </terms>
             <terms id="_" obligation="normative">
                <title id="_">Terms and definitions</title>
                <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                <term id="_" anchor="term-Term2">
                   <preferred>
                      <expression>
                         <name>Term2</name>
                      </expression>
                   </preferred>
                </term>
             </terms>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input,
                                                           *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end
end
