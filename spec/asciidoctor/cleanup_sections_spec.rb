require "spec_helper"
require "relaton_iec"
require "fileutils"

RSpec.describe Asciidoctor::Standoc do
  it "appends any initial user-supplied text to boilerplate in terms and definitions" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      I am boilerplate

      * So am I

      === Time

      This paragraph is extraneous
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
               <terms id="_" obligation="normative"><title>Terms and definitions</title>
               <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
      <p id='_'>I am boilerplate</p>
      <ul id='_'>
        <li>
          <p id='_'>So am I</p>
        </li>
      </ul>
             <term id="term-time">
             <preferred>Time</preferred>
               <definition><p id="_">This paragraph is extraneous</p></definition>
             </term></terms>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "removes initial extraneous material from Normative References" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      This is extraneous information

      * [[[iso216,ISO 216]]], _Reference_

      This is also extraneous information
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections></sections>
      <bibliography><references id="_" obligation="informative" normative="true"><title>Normative references</title>
        #{NORM_REF_BOILERPLATE}
             <bibitem id="iso216" type="standard">
         <title format="text/plain">Reference</title>
         <docidentifier>ISO 216</docidentifier>
         <docnumber>216</docnumber>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>ISO</name>
           </organization>
         </contributor>
       </bibitem>
       <p id='_'>This is also extraneous information</p>
      </references>
      </bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "preserves user-supplied boilerplate in Normative References" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      [NOTE,type=boilerplate]
      --
      This is extraneous information
      --

      * [[[iso216,ISO 216]]], _Reference_

      This is also extraneous information
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections></sections>
      <bibliography><references id="_" obligation="informative" normative="true"><title>Normative references</title>
       <p id='_'>This is extraneous information</p>
         <bibitem id="iso216" type="standard">
         <title format="text/plain">Reference</title>
         <docidentifier>ISO 216</docidentifier>
         <docnumber>216</docnumber>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>ISO</name>
           </organization>
         </contributor>
       </bibitem>
       <p id='_'>This is also extraneous information</p>
      </references>
      </bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "sorts references with their notes in Bibliography" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Bibliography

      This is extraneous information

      * [[[iso216,ISO 216]]], _Reference_

      NOTE: ABC

      NOTE: DEF

      This is further extraneous information

      NOTE: GHI

      * [[[iso216,ISO 215]]], _Reference_

      NOTE: JKL

      This is also extraneous information
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections> </sections>
         <bibliography>
           <references id='_' obligation='informative' normative="false">
             <title>Bibliography</title>
             <p id='_'>This is extraneous information</p>
             <bibitem id='iso216' type='standard'>
               <title format='text/plain'>Reference</title>
               <docidentifier>ISO 216</docidentifier>
               <docnumber>216</docnumber>
               <contributor>
                 <role type='publisher'/>
                 <organization>
                   <name>ISO</name>
                 </organization>
               </contributor>
             </bibitem>
             <note id='_'>
               <p id='_'>ABC</p>
             </note>
             <note id='_'>
               <p id='_'>DEF</p>
             </note>
             <bibitem id='iso216' type='standard'>
               <title format='text/plain'>Reference</title>
               <docidentifier>ISO 215</docidentifier>
               <docnumber>215</docnumber>
               <contributor>
                 <role type='publisher'/>
                 <organization>
                   <name>ISO</name>
                 </organization>
               </contributor>
             </bibitem>
             <note id='_'>
               <p id='_'>JKL</p>
             </note>
             <p id='_'>
               This is further extraneous information
               <note id='_'>
                 <p id='_'>GHI</p>
               </note>
             </p>
             <p id='_'>This is also extraneous information</p>
           </references>
         </bibliography>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "defaults section obligations" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause
      Text

      [appendix]
      == Clause

      Text
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections><clause id="_" inline-header="false" obligation="normative">
        <title>Clause</title>
        <p id="_">Text</p>
      </clause>
      </sections><annex id="_" inline-header="false" obligation="normative">
        <title>Clause</title>
        <p id="_">Text</p>
      </annex>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "extends clause levels past 5" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause1

      === Clause2

      ==== Clause3

      ===== Clause4

      ====== Clause 5

      [level=6]
      ====== Clause 6

      [level=7]
      ====== Clause 7A

      [level=7]
      ====== Clause 7B

      [level=6]
      ====== Clause 6B

      ====== Clause 5B

    INPUT
    output = <<~OUTPUT
          #{BLANK_HDR}
          <sections>
        <clause id="_" inline-header="false" obligation="normative">
        <title>Clause1</title>
        <clause id="_" inline-header="false" obligation="normative">
        <title>Clause2</title>
        <clause id="_" inline-header="false" obligation="normative">
        <title>Clause3</title>
        <clause id="_" inline-header="false" obligation="normative"><title>Clause4</title><clause id="_" inline-header="false" obligation="normative">
        <title>Clause 5</title>
      <clause id="_" inline-header="false" obligation="normative">
        <title>Clause 6</title>
      <clause id="_" inline-header="false" obligation="normative">
        <title>Clause 7A</title>
      </clause><clause id="_" inline-header="false" obligation="normative">
        <title>Clause 7B</title>
      </clause></clause><clause id="_" inline-header="false" obligation="normative">
        <title>Clause 6B</title>
      </clause></clause>
      <clause id="_" inline-header="false" obligation="normative">
        <title>Clause 5B</title>
      </clause></clause>
      </clause>
      </clause>
      </clause>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "inserts boilerplate before empty Normative References" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [bibliography]
      == Normative References

    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
            <sections>
      </sections><bibliography><references id="_" obligation="informative" normative="true">
        <title>Normative references</title><p id="_">There are no normative references in this document.</p>
      </references></bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "inserts boilerplate before non-empty Normative References" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [bibliography]
      == Normative References
      * [[[a,b]]] A

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>

         </sections><bibliography><references id="_" obligation="informative" normative="true">
           <title>Normative references</title><p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
           <bibitem id="a">
           <formattedref format="application/x-isodoc+xml">A</formattedref>
           <docidentifier>b</docidentifier>
         </bibitem>
         </references></bibliography>
         </standard-document>

    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "inserts boilerplate before empty Normative References in French" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :language: fr

      [bibliography]
      == Normative References

    INPUT
    output = <<~OUTPUT
          #{BLANK_HDR.sub(/<language>en/, '<language>fr')}
          <sections>
      </sections><bibliography><references id="_" obligation="informative" normative="true">
        <title>Références normatives</title><p id="_">Le présent document ne contient aucune référence normative.</p>
      </references></bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes section names, with footnotes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      .Foreword.footnote:[A]

      Text

      [abstract]
      == Abstract.footnote:[A]

      Text

      [heading=introduction]
      == Introduction.footnote:[A]

      === Introduction Subsection

      [heading=acknowledgements]
      == Acknowledgements.footnote:[A]

      [.preface]
      == Dedication

      [heading=scope]
      == Scope.footnote:[A]

      Text

      [bibliography,heading=normative references]
      == Normative References.footnote:[A]

      [bibliography,normative=true]
      == Normative References 2.footnote:[A]

      [heading=terms and definitions]
      == Terms and Definitions.footnote:[A]

      === Term1

      [heading="terms and definitions"]
      == Terms, Definitions, Symbols and Abbreviated Terms.footnote:[A]

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

      [heading=symbols and abbreviated terms]
      === Symbols and Abbreviated Terms.footnote:[A]

      [.nonterm]
      ==== General

      [heading=symbols]
      ==== Symbols 1.footnote:[A]

      [heading=abbreviated terms]
      == Abbreviated Terms.footnote:[A]

      == Clause 4

      === Introduction

      === Clause 4.2

      == Terms and Definitions

      [appendix]
      == Annex.footnote:[A]

      === Annex A.1

      [bibliography,heading=bibliography]
      == Bibliography.footnote:[A]

      [bibliography,normative=false]
      == Bibliography 2.footnote:[A]

      === Bibliography Subsection

    INPUT
    output = <<~OUTPUT
       <standard-document xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}">
               <bibdata type='standard'>
                 <title language='en' format='text/plain'>Document title</title>
                 <language>en</language>
                 <script>Latn</script>
                 <abstract>
                   <p>Text</p>
                 </abstract>
                 <status>
                   <stage>published</stage>
                 </status>
                 <copyright>
                   <from>#{Time.now.year}</from>
                 </copyright>
                 <ext>
                   <doctype>article</doctype>
                 </ext>
               </bibdata>
               <preface>
                 <abstract id='_'>
                   <title>Abstract</title>
                   <p id='_'>Text</p>
                 </abstract>
                 <foreword id='_' obligation='informative'>
                   <title>
                     Foreword
                     <fn reference='1'>
                       <p id='_'>A</p>
                     </fn>
                   </title>
                   <p id='_'>Text</p>
                 </foreword>
                 <introduction id='_' obligation='informative'>
                   <title>Introduction</title>
                   <clause id='_' inline-header='false' obligation='informative'>
                     <title>Introduction Subsection</title>
                   </clause>
                 </introduction>
                 <clause id='_' inline-header='false' obligation='informative'>
                   <title>Dedication</title>
                 </clause>
                 <acknowledgements id='_' obligation='informative'>
                   <title>
                     Acknowledgements
                     <fn reference='1'>
                       <p id='_'>A</p>
                     </fn>
                   </title>
                 </acknowledgements>
               </preface>
               <sections>
                 <clause id='_' type='scope' inline-header='false' obligation='normative'>
                   <title>
                     Scope
                     <fn reference='1'>
                       <p id='_'>A</p>
                     </fn>
                   </title>
                   <p id='_'>Text</p>
                 </clause>
                 <terms id='_' obligation='normative'>
                   <title>
                     Terms and definitions
                     <fn reference='1'>
                       <p id='_'>A</p>
                     </fn>
                   </title>
                   <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
                   <term id='term-term1'>
                     <preferred>Term1</preferred>
                   </term>
                 </terms>
                 <clause id='_' inline-header='false' obligation='normative'>
                   <title>
                     Terms, Definitions, Symbols and Abbreviated Terms.
                     <fn reference='1'>
                       <p id='_'>A</p>
                     </fn>
                   </title>
                   <clause id='_' inline-header='false' obligation='normative'>
                     <title>Introduction</title>
                     <clause id='_' inline-header='false' obligation='normative'>
                       <title>Intro 1</title>
                     </clause>
                   </clause>
                   <clause id='_' inline-header='false' obligation='normative'>
                     <title>Intro 2</title>
                     <clause id='_' inline-header='false' obligation='normative'>
                       <title>Intro 3</title>
                     </clause>
                   </clause>
                   <clause id='_' inline-header='false' obligation='normative'>
                     <title>Intro 4</title>
                     <clause id='_' inline-header='false' obligation='normative'>
                       <title>Intro 5</title>
                       <clause id='_' inline-header='false' obligation='normative'>
                         <title>Term1</title>
                       </clause>
                     </clause>
                   </clause>
                   <clause id='_' inline-header='false' obligation='normative'>
                     <title>Normal Terms</title>
                     <clause id='_' inline-header='false' obligation='normative'>
                       <title>Term2</title>
                     </clause>
                   </clause>
                   <definitions id='_' obligation='normative'>
                     <title>
                       Symbols and abbreviated terms
                       <fn reference='1'>
                         <p id='_'>A</p>
                       </fn>
                     </title>
                     <clause id='_' inline-header='false' obligation='normative'>
                       <title>General</title>
                     </clause>
                     <definitions id='_' type='symbols' obligation='normative'>
                       <title>
                         Symbols
                         <fn reference='1'>
                           <p id='_'>A</p>
                         </fn>
                       </title>
                     </definitions>
                   </definitions>
                 </clause>
                 <definitions id='_' type='abbreviated_terms' obligation='normative'>
                   <title>
                     Abbreviated terms
                     <fn reference='1'>
                       <p id='_'>A</p>
                     </fn>
                   </title>
                 </definitions>
                 <clause id='_' inline-header='false' obligation='normative'>
                   <title>Clause 4</title>
                   <clause id='_' inline-header='false' obligation='normative'>
                     <title>Introduction</title>
                   </clause>
                   <clause id='_' inline-header='false' obligation='normative'>
                     <title>Clause 4.2</title>
                   </clause>
                 </clause>
                 <clause id='_' inline-header='false' obligation='normative'>
                   <title>Terms and Definitions</title>
                 </clause>
               </sections>
               <annex id='_' inline-header='false' obligation='normative'>
                 <title>
                   Annex.
                   <fn reference='1'>
                     <p id='_'>A</p>
                   </fn>
                 </title>
                 <clause id='_' inline-header='false' obligation='normative'>
                   <title>Annex A.1</title>
                 </clause>
               </annex>
               <bibliography>
                 <references id='_' normative='true' obligation='informative'>
                   <title>Normative references
      <fn reference='1'>
        <p id='_'>A</p>
      </fn>
      </title>
                   <p id='_'>There are no normative references in this document.</p>
                 </references>
                 <references id='_' normative='true' obligation='informative'>
                   <title>Normative References 2.
      <fn reference='1'>
        <p id='_'>A</p>
      </fn>
      </title>
                 </references>
                 <references id='_' normative='false' obligation='informative'>
                   <title>Bibliography
      <fn reference='1'>
        <p id='_'>A</p>
      </fn>
      </title>
                 </references>
                 <clause id='_' obligation='informative'>
                   <title>Bibliography 2.
      <fn reference='1'>
        <p id='_'>A</p>
      </fn>
      </title>
                   <references id='_' normative='false' obligation='informative'>
                     <title>Bibliography Subsection</title>
                   </references>
                 </clause>
               </bibliography>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes section names, default to English" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR.sub(/:nodoc:/, ":language: tlh\n:script: Latn\n:nodoc:")}
      .Foreword

      Text

      [abstract]
      == Abstract

      Text

      [heading=introduction]
      == Introduction

      === Introduction Subsection

      [heading=acknowledgements]
      == Acknowledgements

      [.preface]
      == Dedication

      [heading=scope]
      == Scope

      Text

      [bibliography,heading=normative references]
      == Normative References

      [bibliography,normative=true]
      == Normative References 2

      [heading=terms and definitions]
      == Terms and Definitions

      === Term1

      [heading="terms and definitions"]
      == Terms, Definitions, Symbols and Abbreviated Terms

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

      [heading=symbols and abbreviated terms]
      === Symbols and Abbreviated Terms

      [.nonterm]
      ==== General

      [heading=symbols]
      ==== Symbols 1

      [heading=abbreviated terms]
      == Abbreviated Terms

      == Clause 4

      === Introduction

      === Clause 4.2

      == Terms and Definitions

      [appendix]
      == Annex

      === Annex A.1

      [bibliography,heading=bibliography]
      == Bibliography

      [bibliography,normative=false]
      == Bibliography 2

      === Bibliography Subsection

    INPUT
    output = <<~OUTPUT
      <standard-document xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}">
                <bibdata type='standard'>
                  <title language='en' format='text/plain'>Document title</title>
                  <language>tlh</language>
                  <script>Latn</script>
                  <abstract>
                    <p>Text</p>
                  </abstract>
                  <status>
                    <stage>published</stage>
                  </status>
                  <copyright>
                    <from>#{Time.now.year}</from>
                  </copyright>
                  <ext>
                    <doctype>article</doctype>
                  </ext>
                </bibdata>
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
                  <clause id='_' inline-header='false' obligation='informative'>
                    <title>Dedication</title>
                  </clause>
                  <acknowledgements id='_' obligation='informative'>
                    <title>Acknowledgements</title>
                  </acknowledgements>
                </preface>
                <sections>
                  <clause id='_' type='scope' inline-header='false' obligation='normative'>
                    <title>Scope</title>
                    <p id='_'>Text</p>
                  </clause>
                  <terms id='_' obligation='normative'>
                    <title>Terms and definitions</title>
                    <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
                    <term id='term-term1'>
                      <preferred>Term1</preferred>
                    </term>
                  </terms>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Terms, Definitions, Symbols and Abbreviated Terms</title>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Introduction</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Intro 1</title>
                      </clause>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Intro 2</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Intro 3</title>
                      </clause>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Intro 4</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Intro 5</title>
                        <clause id='_' inline-header='false' obligation='normative'>
                          <title>Term1</title>
                        </clause>
                      </clause>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Normal Terms</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Term2</title>
                      </clause>
                    </clause>
                    <definitions id='_' obligation='normative'>
                      <title>Symbols and abbreviated terms</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>General</title>
                      </clause>
                      <definitions id='_' type='symbols' obligation='normative'>
                        <title>Symbols</title>
                      </definitions>
                    </definitions>
                  </clause>
                  <definitions id='_' type='abbreviated_terms' obligation='normative'>
                    <title>Abbreviated terms</title>
                  </definitions>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Clause 4</title>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Introduction</title>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Clause 4.2</title>
                    </clause>
                  </clause>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Terms and Definitions</title>
                  </clause>
                </sections>
                <annex id='_' inline-header='false' obligation='normative'>
                  <title>Annex</title>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Annex A.1</title>
                  </clause>
                </annex>
                <bibliography>
                  <references id='_' normative='true' obligation='informative'>
                    <title>Normative references</title>
                    <p id='_'>There are no normative references in this document.</p>
                  </references>
                  <references id='_' normative='true' obligation='informative'>
                    <title>Normative References 2</title>
                  </references>
                  <references id='_' normative='false' obligation='informative'>
                    <title>Bibliography</title>
                  </references>
                  <clause id='_' obligation='informative'>
                    <title>Bibliography 2</title>
                    <references id='_' normative='false' obligation='informative'>
                      <title>Bibliography Subsection</title>
                    </references>
                  </clause>
                </bibliography>
              </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes section names, French" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR.sub(/:nodoc:/, ":language: fr\n:script: Latn\n:nodoc:")}
      .Foreword

      Text

      [abstract]
      == Abstract

      Text

      [heading=introduction]
      == Introduction

      === Introduction Subsection

      [heading=acknowledgements]
      == Acknowledgements

      [.preface]
      == Dedication

      [heading=scope]
      == Scope

      Text

      [bibliography,heading=normative references]
      == Normative References

      [bibliography,normative=true]
      == Normative References 2

      [heading=terms and definitions]
      == Terms and Definitions

      === Term1

      [heading="terms and definitions"]
      == Terms, Definitions, Symbols and Abbreviated Terms

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

      [heading=symbols and abbreviated terms]
      === Symbols and Abbreviated Terms

      [.nonterm]
      ==== General

      [heading=symbols]
      ==== Symbols 1

      [heading=abbreviated terms]
      == Abbreviated Terms

      == Clause 4

      === Introduction

      === Clause 4.2

      == Terms and Definitions

      [appendix]
      == Annex

      === Annex A.1

      [bibliography,heading=bibliography]
      == Bibliography

      [bibliography,normative=false]
      == Bibliography 2

      === Bibliography Subsection

    INPUT
    output = <<~OUTPUT
      <standard-document xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}">
                <bibdata type='standard'>
                  <title language='en' format='text/plain'>Document title</title>
                  <language>fr</language>
                  <script>Latn</script>
                  <abstract>
                    <p>Text</p>
                  </abstract>
                  <status>
                    <stage>published</stage>
                  </status>
                  <copyright>
                    <from>#{Time.now.year}</from>
                  </copyright>
                  <ext>
                    <doctype>article</doctype>
                  </ext>
                </bibdata>
                <preface>
                  <abstract id='_'>
                    <title>Résumé</title>
                    <p id='_'>Text</p>
                  </abstract>
                  <foreword id='_' obligation='informative'>
                    <title>Avant-propos</title>
                    <p id='_'>Text</p>
                  </foreword>
                  <introduction id='_' obligation='informative'>
                    <title>Introduction</title>
                    <clause id='_' inline-header='false' obligation='informative'>
                      <title>Introduction Subsection</title>
                    </clause>
                  </introduction>
                  <clause id='_' inline-header='false' obligation='informative'>
                    <title>Dedication</title>
                  </clause>
                  <acknowledgements id='_' obligation='informative'>
                    <title>Remerciements</title>
                  </acknowledgements>
                </preface>
                <sections>
                  <clause id='_' type='scope' inline-header='false' obligation='normative'>
                    <title>Domaine d’application</title>
                    <p id='_'>Text</p>
                  </clause>
                  <terms id='_' obligation='normative'>
                    <title>Terms et définitions</title>
                    <p id='_'>
                      Pour les besoins du présent document, les termes et définitions suivants
                      s’appliquent.
                    </p>
                    <term id='term-term1'>
                      <preferred>Term1</preferred>
                    </term>
                  </terms>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Terms, Definitions, Symbols and Abbreviated Terms</title>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Introduction</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Intro 1</title>
                      </clause>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Intro 2</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Intro 3</title>
                      </clause>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Intro 4</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Intro 5</title>
                        <clause id='_' inline-header='false' obligation='normative'>
                          <title>Term1</title>
                        </clause>
                      </clause>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Normal Terms</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Term2</title>
                      </clause>
                    </clause>
                    <definitions id='_' obligation='normative'>
                      <title>Symboles et termes abrégés</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>General</title>
                      </clause>
                      <definitions id='_' type='symbols' obligation='normative'>
                        <title>Symboles</title>
                      </definitions>
                    </definitions>
                  </clause>
                  <definitions id='_' type='abbreviated_terms' obligation='normative'>
                    <title>Termes abrégés</title>
                  </definitions>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Clause 4</title>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Introduction</title>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Clause 4.2</title>
                    </clause>
                  </clause>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Terms and Definitions</title>
                  </clause>
                </sections>
                <annex id='_' inline-header='false' obligation='normative'>
                  <title>Annex</title>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Annex A.1</title>
                  </clause>
                </annex>
                <bibliography>
                  <references id='_' normative='true' obligation='informative'>
                    <title>Références normatives</title>
                    <p id='_'>Le présent document ne contient aucune référence normative.</p>
                  </references>
                  <references id='_' normative='true' obligation='informative'>
                    <title>Normative References 2</title>
                  </references>
                  <references id='_' normative='false' obligation='informative'>
                    <title>Bibliographie</title>
                  </references>
                  <clause id='_' obligation='informative'>
                    <title>Bibliography 2</title>
                    <references id='_' normative='false' obligation='informative'>
                      <title>Bibliography Subsection</title>
                    </references>
                  </clause>
                </bibliography>
              </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes section names, Simplified Chinese" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR.sub(/:nodoc:/, ":language: zh\n:script: Hans\n:nodoc:")}
      .Foreword

      Text

      [abstract]
      == Abstract

      Text

      [heading=introduction]
      == Introduction

      === Introduction Subsection

      [heading=acknowledgements]
      == Acknowledgements

      [.preface]
      == Dedication

      [heading=scope]
      == Scope

      Text

      [bibliography,heading=normative references]
      == Normative References

      [bibliography,normative=true]
      == Normative References 2

      [heading=terms and definitions]
      == Terms and Definitions

      === Term1

      [heading="terms and definitions"]
      == Terms, Definitions, Symbols and Abbreviated Terms

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

      [heading=symbols and abbreviated terms]
      === Symbols and Abbreviated Terms

      [.nonterm]
      ==== General

      [heading=symbols]
      ==== Symbols 1

      [heading=abbreviated terms]
      == Abbreviated Terms

      == Clause 4

      === Introduction

      === Clause 4.2

      == Terms and Definitions

      [appendix]
      == Annex

      === Annex A.1

      [bibliography,heading=bibliography]
      == Bibliography

      [bibliography,normative=false]
      == Bibliography 2

      === Bibliography Subsection

    INPUT
    output = <<~OUTPUT
      <standard-document xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}">
                <bibdata type='standard'>
                  <title language='en' format='text/plain'>Document title</title>
                  <language>zh</language>
                  <script>Hans</script>
                  <abstract>
                    <p>Text</p>
                  </abstract>
                  <status>
                    <stage>published</stage>
                  </status>
                  <copyright>
                    <from>#{Time.now.year}</from>
                  </copyright>
                  <ext>
                    <doctype>article</doctype>
                  </ext>
                </bibdata>
                <preface>
                  <abstract id='_'>
                    <title>摘要</title>
                    <p id='_'>Text</p>
                  </abstract>
                  <foreword id='_' obligation='informative'>
                    <title>前言</title>
                    <p id='_'>Text</p>
                  </foreword>
                  <introduction id='_' obligation='informative'>
                    <title>引言</title>
                    <clause id='_' inline-header='false' obligation='informative'>
                      <title>Introduction Subsection</title>
                    </clause>
                  </introduction>
                  <clause id='_' inline-header='false' obligation='informative'>
                    <title>Dedication</title>
                  </clause>
                  <acknowledgements id='_' obligation='informative'>
                    <title>致謝</title>
                  </acknowledgements>
                </preface>
                <sections>
                  <clause id='_' type='scope' inline-header='false' obligation='normative'>
                    <title>范围</title>
                    <p id='_'>Text</p>
                  </clause>
                  <terms id='_' obligation='normative'>
                    <title>术语和定义</title>
                    <p id='_'>下列术语和定义适用于本文件。</p>
                    <term id='term-term1'>
                      <preferred>Term1</preferred>
                    </term>
                  </terms>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Terms, Definitions, Symbols and Abbreviated Terms</title>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Introduction</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Intro 1</title>
                      </clause>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Intro 2</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Intro 3</title>
                      </clause>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Intro 4</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Intro 5</title>
                        <clause id='_' inline-header='false' obligation='normative'>
                          <title>Term1</title>
                        </clause>
                      </clause>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Normal Terms</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Term2</title>
                      </clause>
                    </clause>
                    <definitions id='_' obligation='normative'>
                      <title>符号、代号和缩略语</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>General</title>
                      </clause>
                      <definitions id='_' type='symbols' obligation='normative'>
                        <title>符号</title>
                      </definitions>
                    </definitions>
                  </clause>
                  <definitions id='_' type='abbreviated_terms' obligation='normative'>
                    <title>代号和缩略语</title>
                  </definitions>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Clause 4</title>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Introduction</title>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Clause 4.2</title>
                    </clause>
                  </clause>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Terms and Definitions</title>
                  </clause>
                </sections>
                <annex id='_' inline-header='false' obligation='normative'>
                  <title>Annex</title>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Annex A.1</title>
                  </clause>
                </annex>
                <bibliography>
                  <references id='_' normative='true' obligation='informative'>
                    <title>规范性引用文件</title>
                    <p id='_'>本文件并没有规范性引用文件。</p>
                  </references>
                  <references id='_' normative='true' obligation='informative'>
                    <title>Normative References 2</title>
                  </references>
                  <references id='_' normative='false' obligation='informative'>
                    <title>参考文献</title>
                  </references>
                  <clause id='_' obligation='informative'>
                    <title>Bibliography 2</title>
                    <references id='_' normative='false' obligation='informative'>
                      <title>Bibliography Subsection</title>
                    </references>
                  </clause>
                </bibliography>
              </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes section names, internationalisation file" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR.sub(/:nodoc:/, ":no-pdf:\n:i18nyaml: spec/assets/i18n.yaml")}
      .Foreword

      Text

      [abstract]
      == Abstract

      Text

      [heading=introduction]
      == Introduction

      === Introduction Subsection

      [heading=acknowledgements]
      == Acknowledgements

      [.preface]
      == Dedication

      [heading=scope]
      == Scope

      Text

      [bibliography,heading=normative references]
      == Normative References

      [bibliography,normative=true]
      == Normative References 2

      [heading=terms and definitions]
      == Terms and Definitions

      === Term1

      [heading="terms and definitions"]
      == Terms, Definitions, Symbols and Abbreviated Terms

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

      [heading=symbols and abbreviated terms]
      === Symbols and Abbreviated Terms

      [.nonterm]
      ==== General

      [heading=symbols]
      ==== Symbols 1

      [heading=abbreviated terms]
      == Abbreviated Terms

      == Clause 4

      === Introduction

      === Clause 4.2

      == Terms and Definitions

      [appendix]
      == Annex

      === Annex A.1

      [bibliography,heading=bibliography]
      == Bibliography

      [bibliography,normative=false]
      == Bibliography 2

      === Bibliography Subsection

    INPUT
    output = <<~OUTPUT
      <standard-document xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}">
                <bibdata type='standard'>
                  <title language='en' format='text/plain'>Document title</title>
                  <language>en</language>
                  <script>Latn</script>
                  <abstract>
                    <p>Text</p>
                  </abstract>
                  <status>
                    <stage>published</stage>
                  </status>
                  <copyright>
                    <from>#{Time.now.year}</from>
                  </copyright>
                  <ext>
                    <doctype>article</doctype>
                  </ext>
                </bibdata>
                <preface>
                  <abstract id='_'>
                    <title>Abstract</title>
                    <p id='_'>Text</p>
                  </abstract>
                  <foreword id='_' obligation='informative'>
                    <title>Antaŭparolo</title>
                    <p id='_'>Text</p>
                  </foreword>
                  <introduction id='_' obligation='informative'>
                    <title>Enkonduko</title>
                    <clause id='_' inline-header='false' obligation='informative'>
                      <title>Introduction Subsection</title>
                    </clause>
                  </introduction>
                  <clause id='_' inline-header='false' obligation='informative'>
                    <title>Dedication</title>
                  </clause>
                  <acknowledgements id='_' obligation='informative'>
                    <title>Acknowledgements</title>
                  </acknowledgements>
                </preface>
                <sections>
                  <clause id='_' type='scope' inline-header='false' obligation='normative'>
                    <title>Amplekso</title>
                    <p id='_'>Text</p>
                  </clause>
                  <terms id='_' obligation='normative'>
                    <title>Terms and definitions</title>
                    <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
                    <term id='term-term1'>
                      <preferred>Term1</preferred>
                    </term>
                  </terms>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Terms, Definitions, Symbols and Abbreviated Terms</title>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Introduction</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Intro 1</title>
                      </clause>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Intro 2</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Intro 3</title>
                      </clause>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Intro 4</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Intro 5</title>
                        <clause id='_' inline-header='false' obligation='normative'>
                          <title>Term1</title>
                        </clause>
                      </clause>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Normal Terms</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>Term2</title>
                      </clause>
                    </clause>
                    <definitions id='_' obligation='normative'>
                      <title>Symbols and abbreviated terms</title>
                      <clause id='_' inline-header='false' obligation='normative'>
                        <title>General</title>
                      </clause>
                      <definitions id='_' type='symbols' obligation='normative'>
                        <title>Simboloj kai mallongigitaj terminoj</title>
                      </definitions>
                    </definitions>
                  </clause>
                  <definitions id='_' type='abbreviated_terms' obligation='normative'>
                    <title>Abbreviated terms</title>
                  </definitions>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Clause 4</title>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Introduction</title>
                    </clause>
                    <clause id='_' inline-header='false' obligation='normative'>
                      <title>Clause 4.2</title>
                    </clause>
                  </clause>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Terms and Definitions</title>
                  </clause>
                </sections>
                <annex id='_' inline-header='false' obligation='normative'>
                  <title>Annex</title>
                  <clause id='_' inline-header='false' obligation='normative'>
                    <title>Annex A.1</title>
                  </clause>
                </annex>
                <bibliography>
                  <references id='_' normative='true' obligation='informative'>
                    <title>Normaj citaĵoj</title>
                    <p id='_'>There are no normative references in this document.</p>
                  </references>
                  <references id='_' normative='true' obligation='informative'>
                    <title>Normative References 2</title>
                  </references>
                  <references id='_' normative='false' obligation='informative'>
                    <title>Bibliografio</title>
                  </references>
                  <clause id='_' obligation='informative'>
                    <title>Bibliography 2</title>
                    <references id='_' normative='false' obligation='informative'>
                      <title>Bibliography Subsection</title>
                    </references>
                  </clause>
                </bibliography>
              </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "adds variant titles" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause
      Text

      === Subclause

      [.variant-title,type=toc]
      Clause _A_ stem:[x]

      [.variant-title,type=sub]
      "A" 'B'

      Text

      [appendix]
      == Clause

      [.variant-title,type=toc]
      Clause _A_ stem:[x]

      Text
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <sections>
           <clause id='_' inline-header='false' obligation='normative'>
             <title>Clause</title>
             <p id='_'>Text</p>
             <clause id='_' inline-header='false' obligation='normative'>
               <title>Subclause</title>
               <variant-title variant_title='true' type='sub'>&#8220;A&#8221; &#8216;B&#8217;</variant-title>
               <variant-title variant_title='true' type='toc'>
                 Clause
                 <em>A</em>
                 <stem type='MathML'>
                   <math xmlns='http://www.w3.org/1998/Math/MathML'>
                     <mi>x</mi>
                   </math>
                 </stem>
               </variant-title>
               <p id='_'>Text</p>
             </clause>
           </clause>
         </sections>
         <annex id='_' inline-header='false' obligation='normative'>
           <title>Clause</title>
           <variant-title variant_title='true' type='toc'>
             Clause
             <em>A</em>
             <stem type='MathML'>
               <math xmlns='http://www.w3.org/1998/Math/MathML'>
                 <mi>x</mi>
               </math>
             </stem>
           </variant-title>
           <p id='_'>Text</p>
         </annex>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end
end
