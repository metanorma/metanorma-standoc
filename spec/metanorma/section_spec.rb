require "spec_helper"

RSpec.describe Metanorma::Standoc do
  it "processes sections" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      .Foreword

      Text

      == Misc-Container

      Content

      [abstract]
      == Abstract

      Text

      == Introduction

      === Introduction Subsection

      == Acknowledgements

      [.preface]
      == Dedication

      == Scope

      Text

      [bibliography]
      == Normative References

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

      ===== Term1

      === Normal Terms

      ==== Term2

      === Symbols and Abbreviated Terms

      [.nonterm]
      ==== General

      ==== Symbols

      == Abbreviated Terms

      == Clause 4

      === Introduction

      === Clause 4.2

      == Terms and Definitions

      == Acknowledgements

      [appendix]
      == Annex

      === Annex A.1

      [bibliography]
      == Bibliography

      === Bibliography Subsection

      [index]
      == Index

      This is an index

      [index,type=thematic]
      == Thematic Index
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR.sub(/<status>/, '<abstract> <p>Text</p> </abstract><status>')}
              <metanorma-extension><p id='_'>Content</p></metanorma-extension>
          <preface><abstract id="_">
          <title>Abstract</title>
        <p id="_">Text</p>
      </abstract><foreword id='_' obligation="informative">
        <title>Foreword</title>
        <p id="_">Text</p>
      </foreword><introduction id="_" obligation="informative">
        <title>Introduction</title>
        <clause id="_" inline-header="false" obligation="informative">
        <title>Introduction Subsection</title>
      </clause>
      </introduction>
      <clause id='_' inline-header='false' obligation='informative'>
        <title>Dedication</title>
      </clause>
       <acknowledgements id='_' obligation='informative'>
         <title>Acknowledgements</title>
       </acknowledgements>
      </preface><sections>
      <clause id="_" inline-header="false" obligation="normative" type="scope">
        <title>Scope</title>
        <p id="_">Text</p>
      </clause>
      <terms id="_" obligation="normative">
        <title>Terms and definitions</title>
        <p id="_">For the purposes of this document,
             the following terms and definitions apply.</p>
        <term id="term-Term1">
        <preferred><expression><name>Term1</name></expression></preferred>
      </term>
      </terms>
      <clause id="_" obligation="normative"><title>Terms, definitions, symbols and abbreviated terms</title>
      <p id='_'>Boilerplate text</p>
      <clause id="_" inline-header="false" obligation="normative">
        <title>Introduction</title>
        <clause id="_" inline-header="false" obligation="normative">
        <title>Intro 1</title>
      </clause>
      </clause>
      <terms id="_" obligation="normative">
        <title>Intro 2</title>
        <clause id="_" inline-header="false" obligation="normative">
        <title>Intro 3</title>
      </clause>
      </terms>
      <clause id="_" obligation="normative">
        <title>Intro 4</title>
        <terms id="_" obligation="normative">
        <title>Intro 5</title>
        <term id="term-Term1-1">
        <preferred><expression><name>Term1</name></expression></preferred>
      </term>
      </terms>
      </clause>
      <terms id="_" obligation="normative">
        <title>Normal Terms</title>
        <term id="term-Term2">
        <preferred><expression><name>Term2</name></expression></preferred>
      </term>
      </terms>
      <definitions id="_" obligation="normative"><title>Symbols and abbreviated terms</title><clause id="_" inline-header="false" obligation="normative">
        <title>General</title>
      </clause>
      <definitions id="_" obligation="normative" type="symbols">
        <title>Symbols</title>
      </definitions></definitions></clause>
      <definitions id="_" obligation="normative" type="abbreviated_terms">
        <title>Abbreviated terms</title>
      </definitions>
      <clause id="_" inline-header="false" obligation="normative"><title>Clause 4</title><clause id="_" inline-header="false" obligation="normative">
        <title>Introduction</title>
      </clause>
      <clause id="_" inline-header="false" obligation="normative">
        <title>Clause 4.2</title>
      </clause></clause>
      <clause id="_" inline-header="false" obligation="normative">
        <title>Terms and Definitions</title>
      </clause>
      <clause id='_' inline-header='false' obligation='normative'>
        <title>Acknowledgements</title>
      </clause>
      </sections><annex id="_" inline-header="false" obligation="normative">
        <title>Annex</title>
        <clause id="_" inline-header="false" obligation="normative">
        <title>Annex A.1</title>
      </clause>
      </annex><bibliography><references id="_" obligation="informative" normative="true">
        <title>Normative references</title>
        <p id="_">There are no normative references in this document.</p>
      </references><clause id="_" obligation="informative">
        <title>Bibliography</title>
        <references id="_" obligation="informative" normative="false">
        <title>Bibliography Subsection</title>
      </references>
      </clause></bibliography>
      <indexsect id='_'>
        <title>Index</title>
        <p id='_'>This is an index</p>
      </indexsect>
      <indexsect id='_' type='thematic'>
        <title>Thematic Index</title>
      </indexsect>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes sections: explicit foreword section, and preface section at start" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [.preface]
      == Frontispiece

      == Foreword

      Text

      == Scope

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <preface>
             <foreword id="_" obligation="informative">
               <title>Foreword</title>
               <p id="_">Text</p>
             </foreword>
             <clause id="_" inline-header="false" obligation="informative">
               <title>Frontispiece</title>
             </clause>
           </preface>
           <sections>
             <clause id="_" type="scope" inline-header="false" obligation="normative">
               <title>Scope</title>
             </clause>
           </sections>
         </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes sections with number attributes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [number=1bis]
      == Scope

      Text

      [number=2bis]
      == Normative References

      [number=3bis]
      == Terms and Definitions

      [number=4bis]
      === Term1

      [number=5bis]
      == Terms, Definitions, Symbols and Abbreviated Terms

      [.nonterm,number=6bis]
      === Introduction

      [number=7bis]
      ==== Intro 1

      [number=8bis]
      === Intro 2

      [number=9bis]
      === Symbols and Abbreviated Terms

      [.nonterm,number=10bis]
      ==== General

      [number=11bis]
      ==== Symbols

      [number=12bis]
      == Abbreviated Terms

      [number=13bis]
      == Clause 4

      [number=14bis]
      === Introduction

      [number=15bis]
      === Clause 4.2

      [number=16bis]
      == Terms and Definitions

      [appendix,number=17bis]
      == Annex

      [number=18bis]
      === Annex A.1

      [bibliography,number=19bis]
      == Bibliography

      [number=20bis]
      === Bibliography Subsection
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
           <sections>
             <clause id='_' number='1bis' type='scope' inline-header='false' obligation='normative'>
               <title>Scope</title>
               <p id='_'>Text</p>
             </clause>
             <terms id='_' number='3bis' obligation='normative'>
               <title>Terms and definitions</title>
               <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
               <term id='term-Term1' number='4bis'>
                 <preferred><expression><name>Term1</name></expression></preferred>
               </term>
             </terms>
             <terms id='_' number='5bis' obligation='normative'>
               <title>Terms, definitions, symbols and abbreviated terms</title>
               <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
               <clause id='_' number='6bis' inline-header='false' obligation='normative'>
                 <title>Introduction</title>
                 <clause id='_' number='7bis' inline-header='false' obligation='normative'>
                   <title>Intro 1</title>
                 </clause>
               </clause>
               <term id='term-Intro-2' number='8bis'>
                 <preferred><expression><name>Intro 2</name></expression></preferred>
               </term>
               <definitions id='_' number='9bis' obligation='normative'>
                 <title>Symbols and abbreviated terms</title>
                 <clause id='_' number='10bis' inline-header='false' obligation='normative'>
                   <title>General</title>
                 </clause>
                 <definitions id='_' number='11bis' type='symbols' obligation='normative'>
                   <title>Symbols</title>
                 </definitions>
               </definitions>
             </terms>
             <definitions id='_' number='12bis' type='abbreviated_terms' obligation='normative'>
               <title>Abbreviated terms</title>
             </definitions>
             <clause id='_' number='13bis' inline-header='false' obligation='normative'>
               <title>Clause 4</title>
               <clause id='_' number='14bis' inline-header='false' obligation='normative'>
                 <title>Introduction</title>
               </clause>
               <clause id='_' number='15bis' inline-header='false' obligation='normative'>
                 <title>Clause 4.2</title>
               </clause>
             </clause>
             <clause id='_' number='16bis' inline-header='false' obligation='normative'>
               <title>Terms and Definitions</title>
             </clause>
           </sections>
           <annex id='_' number='17bis' inline-header='false' obligation='normative'>
             <title>Annex</title>
             <clause id='_' number='18bis' inline-header='false' obligation='normative'>
               <title>Annex A.1</title>
             </clause>
           </annex>
           <bibliography>
             <references id='_' number='2bis' normative='true' obligation='informative'>
               <title>Normative references</title>
               <p id='_'>There are no normative references in this document.</p>
             </references>
             <clause id='_' number='19bis' obligation='informative'>
               <title>Bibliography</title>
               <references id='_' number='20bis' normative='false' obligation='informative'>
                 <title>Bibliography Subsection</title>
               </references>
             </clause>
           </bibliography>
         </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes sections with language and script attributes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [language=en,script=Latn]
      == Foreword

      Text

      [abstract,language=en,script=Latn]
      == Abstract

      Text

      [language=en,script=Latn]
      == Introduction

      [language=en,script=Latn]
      === Introduction Subsection

      [language=en,script=Latn]
      == Acknowledgements

      [.preface]
      [language=en,script=Latn]
      == Dedication

      [language=en,script=Latn]
      == Scope

      Text

      [language=en,script=Latn]
      == Normative References

      [language=en,script=Latn]
      == Terms and Definitions

      [language=en,script=Latn]
      === Term1

      [language=en,script=Latn]
      == Terms, Definitions, Symbols and Abbreviated Terms

      [.nonterm]
      [language=en,script=Latn]
      === Introduction

      ==== Intro 1

      [language=en,script=Latn]
      === Intro 2

      [.nonterm]
      [language=en,script=Latn]
      ==== Intro 3

      [language=en,script=Latn]
      === Intro 4

      [language=en,script=Latn]
      ==== Intro 5

      ===== Term1

      [language=en,script=Latn]
      === Normal Terms

      ==== Term2

      [language=en,script=Latn]
      === Symbols and Abbreviated Terms

      [.nonterm]
      [language=en,script=Latn]
      ==== General

      ==== Symbols

      [language=en,script=Latn]
      == Abbreviated Terms

      [language=en,script=Latn]
      == Clause 4

      [language=en,script=Latn]
      === Introduction

      [language=en,script=Latn]
      === Clause 4.2

      [language=en,script=Latn]
      == Terms and Definitions

      [appendix,language=en,script=Latn]
      == Annex

      [language=en,script=Latn]
      === Annex A.1

      [language=en,script=Latn]
      == Bibliography

      [language=en,script=Latn]
      === Bibliography Subsection
    INPUT
    output = <<~OUTPUT
                   #{BLANK_HDR.sub(/<status>/, '<abstract> <p>Text</p> </abstract><status>')}
           <preface><abstract id="_" language="en" script="Latn">
           <title>Abstract</title>
               <p id="_">Text</p>
             </abstract><foreword id='_' language='en' script='Latn' obligation='informative'>
               <title>Foreword</title>
               <p id="_">Text</p>
             </foreword><introduction id="_" language="en" script="Latn" obligation="informative">
               <title>Introduction</title>
               <clause id="_" language="en" script="Latn" inline-header="false" obligation="informative">
               <title>Introduction Subsection</title>
             </clause>
             </introduction>
             <clause id='_' language='en' script='Latn' inline-header='false' obligation='informative'>
        <title>Dedication</title>
      </clause>
             <acknowledgements id='_' language='en' script='Latn' obligation='informative'>
        <title>Acknowledgements</title>
      </acknowledgements>
      </preface><sections>
             <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative" type="scope">
               <title>Scope</title>
               <p id="_">Text</p>
             </clause>
             <terms id="_" language="en" script="Latn" obligation="normative">
               <title>Terms and definitions</title>
               <p id="_">For the purposes of this document,
             the following terms and definitions apply.</p>
               <term id="term-Term1" language="en" script="Latn">
               <preferred><expression><name>Term1</name></expression></preferred>
             </term>
             </terms>
             <clause id="_" language="en" script="Latn" obligation="normative"><title>Terms, definitions, symbols and abbreviated terms</title>
        <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
      <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
               <title>Introduction</title>
               <clause id="_" inline-header="false" obligation="normative">
               <title>Intro 1</title>
             </clause>
             </clause>
             <terms id="_" language="en" script="Latn" obligation="normative">
               <title>Intro 2</title>
               <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
               <title>Intro 3</title>
             </clause>
             </terms>
             <clause id="_" language="en" script="Latn" obligation="normative">
               <title>Intro 4</title>
               <terms id="_" language="en" script="Latn" obligation="normative">
               <title>Intro 5</title>
               <term id="term-Term1-1">
               <preferred><expression><name>Term1</name></expression></preferred>
             </term>
             </terms>
             </clause>
             <terms id="_" language="en" script="Latn" obligation="normative">
               <title>Normal Terms</title>
               <term id="term-Term2">
               <preferred><expression><name>Term2</name></expression></preferred>
             </term>
             </terms>
             <definitions id="_" language="en" script="Latn" obligation="normative"><title>Symbols and abbreviated terms</title><clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
               <title>General</title>
             </clause>
             <definitions id="_" obligation="normative" type="symbols">
               <title>Symbols</title>
             </definitions></definitions></clause>
             <definitions id="_" language="en" script="Latn" obligation="normative" type="abbreviated_terms">
               <title>Abbreviated terms</title>
             </definitions>
             <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative"><title>Clause 4</title><clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
               <title>Introduction</title>
             </clause>
             <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
               <title>Clause 4.2</title>
             </clause></clause>
             <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
               <title>Terms and Definitions</title>
             </clause>
             </sections><annex id="_" language="en" script="Latn" inline-header="false" obligation="normative">
               <title>Annex</title>
               <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
               <title>Annex A.1</title>
             </clause>
             </annex><bibliography><references id="_" language="en" script="Latn" obligation="informative" normative="true">
               <title>Normative references</title>
               <p id="_">There are no normative references in this document.</p>
             </references><clause id="_" language="en" script="Latn" obligation="informative">
               <title>Bibliography</title>
               <references id="_" language="en" script="Latn" obligation="informative" normative="false">
               <title>Bibliography Subsection</title>
             </references>
             </clause></bibliography>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes sections with title and type attributes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      .Foreword

      Text

      [abstract]
      == Περίληψη

      Text

      [heading=introduction]
      == Εισαγωγή

      === Introduction Subsection

      [heading=acknowledgements]
      == Ευχαριστίες

      [heading=normative references]
      == Κανονιστικές Παραπομπές

      [heading=terms and definitions]
      == Όροι και Ορισμοί

      === Term1

      [heading="terms, definitions, symbols and abbreviated terms"]
      == Όροι, Ορισμοί, Σύμβολα και Συντομογραφίες

      === Normal Terms

      ==== Term2

      [heading=symbols]
      === Σύμβολα και Συντομογραφίες

      [heading=abbreviated terms]
      == Σύμβολα και Συντομογραφίες

      [type=ABC]
      == Clause 4

      [type=DEF]
      === Introduction

      === Clause 4.2

      [appendix]
      == Annex

      === Annex A.1

      [heading=bibliography]
      == Βιβλιογραφία

      === Bibliography Subsection
    INPUT
    output = <<~OUTPUT
                   #{BLANK_HDR.sub(/<status>/, '<abstract> <p>Text</p> </abstract><status>')}
            <preface>
          <abstract id='_'>
          <title>Abstract</title>
            <p id='_'>Text</p>
          </abstract>
          <foreword id='_' obligation='informative'>
            <title>Foreword</title>
            <p id='_'>Text</p>
          </foreword>
          <introduction id='_' obligation='informative'>
            <title>Introduction</title>
            <clause id='_' inline-header='false' obligation='informative'>
              <title>Introduction Subsection</title>
            </clause>
          </introduction>
          <acknowledgements id='_' obligation='informative'>
        <title>Acknowledgements</title>
      </acknowledgements>
        </preface>
        <sections>
          <terms id='_' obligation='normative'>
            <title>Terms and definitions</title>
            <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
            <term id='term-Term1'>
              <preferred><expression><name>Term1</name></expression></preferred>
            </term>
          </terms>
          <clause id='_' obligation='normative'>
            <title>Terms, definitions and symbols</title>
        <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <terms id='_' obligation='normative'>
              <title>Normal Terms</title>
              <term id='term-Term2'>
                <preferred><expression><name>Term2</name></expression></preferred>
              </term>
            </terms>
            <definitions id='_' obligation="normative" type="symbols">
              <title>Symbols</title>
            </definitions>
          </clause>
          <definitions id='_' obligation="normative" type="abbreviated_terms">
            <title>Abbreviated terms</title>
          </definitions>
          <clause id='_' inline-header='false' obligation='normative' type="ABC">
            <title>Clause 4</title>
            <clause id='_' inline-header='false' obligation='normative' type="DEF">
              <title>Introduction</title>
            </clause>
            <clause id='_' inline-header='false' obligation='normative'>
              <title>Clause 4.2</title>
            </clause>
          </clause>
        </sections>
        <annex id='_' inline-header='false' obligation='normative'>
          <title>Annex</title>
          <clause id='_' inline-header='false' obligation='normative'>
            <title>Annex A.1</title>
          </clause>
        </annex>
        <bibliography>
          <references id='_' obligation='informative' normative="true">
            <title>Normative references</title>
            <p id="_">There are no normative references in this document.</p>
          </references>
          <clause id='_' obligation='informative'>
            <title>Bibliography</title>
            <references id='_' obligation='informative' normative="false">
              <title>Bibliography Subsection</title>
            </references>
          </clause>
        </bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
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
           <terms id='_' obligation='normative'>
             <title>Terms and definitions</title>
             <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
             <term id='term-Term' language='en' tag='x123' multilingual-rendering='all-columns'>
               <preferred>
                 <expression>
                   <name>Term</name>
                 </expression>
               </preferred>
             </term>
           </terms>
         </sections>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
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
          <terms id='_' obligation='normative'>
            <title>Terms, definitions and symbols</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id='term-Term'>
              <preferred><expression><name>Term</name></expression></preferred>
            </term>
            <definitions id='_' obligation="normative" type="symbols">
              <title>Symbols</title>
            </definitions>
          </terms>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
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
          <terms id='_' obligation='normative'>
            <title>Terms, definitions and abbreviated terms</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id='term-Term'>
              <preferred><expression><name>Term</name></expression></preferred>
            </term>
            <definitions id='_' obligation="normative" type="abbreviated_terms">
              <title>Abbreviated terms</title>
            </definitions>
          </terms>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
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
          <terms id='_' obligation='normative'>
            <title>Terms, definitions, symbols and abbreviated terms</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id='term-Term'>
              <preferred><expression><name>Term</name></expression></preferred>
            </term>
            <definitions id='_' type='abbreviated_terms' obligation='normative'>
                <title>Abbreviated terms</title>
                </definitions>
                <definitions id='_' type='symbols' obligation='normative'>
                <title>Symbols</title>
                </definitions>
          </terms>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes section obligations" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [obligation=informative]
      == Clause 1

      === Clause 1a

      [obligation=normative]
      == Clause 2

      [appendix,obligation=informative]
      == Annex
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
      <sections><clause id="_" inline-header="false" obligation="informative">
        <title>Clause 1</title>
        <clause id="_" inline-header="false" obligation="informative">
        <title>Clause 1a</title>
      </clause>
      </clause>
      <clause id="_" inline-header="false" obligation="normative">
        <title>Clause 2</title>
      </clause>
      </sections><annex id="_" inline-header="false" obligation="informative">
        <title>Annex</title>
      </annex>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes inline headers" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Clause 1

      [%inline-header]
      === Clause 1a

      [appendix]
      == Annex A

      [%inline-header]
      === Clause Aa
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
      <sections><clause id="_" inline-header="false" obligation="normative">
        <title>Clause 1</title>
        <clause id="_" inline-header="true" obligation="normative">
        <title>Clause 1a</title>
      </clause>
      </clause>
      </sections><annex id="_" inline-header="false" obligation="normative">
        <title>Annex A</title>
        <clause id="_" inline-header="true" obligation="normative">
        <title>Clause Aa</title>
      </clause>
      </annex>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes blank headers" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Clause 1

      === {blank}

    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
      <sections>
        <clause id="_" inline-header="false" obligation="normative">
        <title>Clause 1</title>
        <clause id="_" inline-header="false" obligation="normative">
      </clause>
      </clause>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
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
        <terms id='_' obligation='normative'>
          <title>Terms, definitions and symbols</title>
          <p id='_'>No terms and definitions are listed in this document.</p>
          <clause id='_' inline-header='false' obligation='normative'>
            <title>Terms and definitions</title>
          </clause>
          <definitions id='_' obligation="normative" type="symbols">
            <title>Symbols</title>
          </definitions>
        </terms>
      </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes terms & definitions with external source" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      Foreword

      [source="iso1234,iso5678"]
      == Terms and Definitions

      === Term1

    INPUT
    output = <<~OUTPUT
                   #{BLANK_HDR}
                   <termdocsource bibitemid="iso1234"/><termdocsource bibitemid="iso5678"/>
              <preface><foreword id='_' obligation="informative">
               <title>Foreword</title>
               <p id="_">Foreword</p>
             </foreword></preface><sections>
             <terms id="_" obligation="normative">
                <title>Terms and definitions</title><p id="_">For the purposes of this document, the terms and definitions
        given in <eref bibitemid="iso1234"/> and <eref bibitemid="iso5678"/> and the following apply.</p>
        <term id="term-Term1">
        <preferred><expression><name>Term1</name></expression></preferred>
      </term>
             </terms></sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes empty terms & definitions" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      Foreword

      == Terms and Definitions


    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
       <preface><foreword id='_' obligation="informative">
        <title>Foreword</title>
        <p id="_">Foreword</p>
      </foreword></preface><sections>
      <terms id="_" obligation="normative">
         <title>Terms and definitions</title><p id="_">No terms and definitions are listed in this document.</p>
      </terms></sections>
      </standard-document>

    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes empty terms & definitions with external source" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      Foreword

      [source="iso1234,iso5678"]
      == Terms and Definitions

    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
            <termdocsource bibitemid="iso1234"/><termdocsource bibitemid="iso5678"/>
       <preface><foreword id='_' obligation="informative">
        <title>Foreword</title>
        <p id="_">Foreword</p>
      </foreword></preface><sections>
      <terms id="_" obligation="normative">
        <title>Terms and definitions</title>
        <p id="_">For the purposes of this document,
       the terms and definitions given in <eref bibitemid="iso1234"/> and <eref bibitemid="iso5678"/> apply.</p>
      </terms></sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes term document sources in French" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :language: fr

      Foreword

      [source="iso1234,iso5678"]
      == Terms and Definitions

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR.sub(%r{<language>en</language>}, '<language>fr</language>')}
              <termdocsource bibitemid="iso1234"/><termdocsource bibitemid="iso5678"/>
         <preface><foreword id='_' obligation="informative">
          <title>Avant-propos</title>
          <p id="_">Foreword</p>
        </foreword></preface><sections>
        <terms id="_" obligation="normative">
          <title>Termes et définitions</title>
         <p id="_">Pour les besoins du présent document, les termes et définitions de <eref bibitemid="iso1234"/> et <eref bibitemid="iso5678"/> s’appliquent.</p>
        </terms></sections>
        </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes term document sources in Chinese" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :language: zh
      :script: Hans

      Foreword

      [source="iso1234,iso5678"]
      == Terms and Definitions

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR.sub(%r{<language>en</language>}, '<language>zh</language>').sub(%r{<script>Latn</script>}, '<script>Hans</script>')}
        <termdocsource bibitemid="iso1234"/><termdocsource bibitemid="iso5678"/><preface><foreword id='_' obligation="informative">
          <title>前言</title>
          <p id="_">Foreword</p>
        </foreword></preface><sections>
        <terms id="_" obligation="normative">
          <title>术语和定义</title><p id="_"><eref bibitemid="iso1234"/>和<eref bibitemid="iso5678"/>界定的术语和定义适用于本文件。</p>
        </terms></sections>
        </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "warn about external source for terms & definitions that does not point anywhere" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [source="iso712"]
      == Terms and Definitions
      === Term2
    INPUT
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(/not referenced/).to_stderr
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
          <terms id='tda' obligation='normative'>
            <title>Terms, definitions and symbols</title>
            <p id='_'>No terms and definitions are listed in this document.</p>
            <clause id='terms' inline-header='false' obligation='normative'>
              <title>Terms and definitions</title>
            </clause>
            <definitions id='_' obligation="normative" type="symbols">
              <title>Symbols</title>
            </definitions>
          </terms>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
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
         <clause id='_' inline-header='false' obligation='normative' type="scope">
           <title>Scope</title>
         </clause>
         <clause id='tda' obligation='normative'>
           <title>Terms and definitions</title>
           <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
           <clause id='terms' obligation='normative'>
             <title>Terms and definitions</title>
             <terms id='terms-concepts' obligation='normative'>
               <title>Basic concepts</title>
               <term id='term-date'>
                 <preferred><expression><name>date</name></expression></preferred>
                 <definition><verbal-definition>
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
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "ignore special titles in preface but not appendix" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [.preface]
      [[t1]]
      == Terms and definitions

      [[t2]]
      === Term1

      [appendix,language=fr]
      [[sym]]
      == Symbols and abbreviated terms

      [.appendix]
      [[app]]
      [bibliography]
      == Normative Reference
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <preface>
           <clause id="t1" inline-header="false" obligation="informative">
             <title>Terms and definitions</title>
             <clause id="t2" inline-header="false" obligation="informative">
               <title>Term1</title>
             </clause>
           </clause>
         </preface>
        <sections> </sections>
        <annex id='_' obligation='' language='fr' script=''>
          <definitions id='sym' language='fr' obligation="normative">
            <title>Symbols and abbreviated terms</title>
          </definitions>
        </annex>
        <annex id='_' obligation='' language='' script=''>
          <references id='app' obligation='informative' normative="false">
            <title>Normative Reference</title>
          </references>
        </annex>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "recognises special titles despite following indexterms" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Scope (((indexterm)))
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
        <clause id='_' type='scope' inline-header='false' obligation='normative'>
          <title>Scope</title>
        </clause>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "handles floating titles" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      ABC

      [discrete]
      == I am a top-level _floating_ title

      == Clause 1

      [discrete]
      === I am a _floating_ title

      === Clause 1.2

      [discrete]
      == Another top-level floating title

      == Clause 2

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <preface>
           <foreword id='_' obligation='informative'>
             <title>Foreword</title>
             <p id='_'>ABC</p>
           </foreword>
         </preface>
         <sections>
           <floating-title id='_' depth='1' type='floating-title'>
             I am a top-level
             <em>floating</em>
              title
           </floating-title>
           <clause id='_' inline-header='false' obligation='normative'>
             <title>Clause 1</title>
             <floating-title id='_' depth='2' type='floating-title'>
               I am a
               <em>floating</em>
                title
             </floating-title>
             <clause id='_' inline-header='false' obligation='normative'>
               <title>Clause 1.2</title>
             </clause>
           </clause>
           <floating-title id='_' depth='1' type='floating-title'>Another top-level floating title</floating-title>
           <clause id='_' inline-header='false' obligation='normative'>
             <title>Clause 2</title>
           </clause>
         </sections>
         </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end
end
