require "spec_helper"
require "relaton_iec"
require "fileutils"

RSpec.describe Metanorma::Standoc do
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
           <references id='_bibliography' obligation='informative' normative="false">
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
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
      <sections><clause id="_clause" inline-header="false" obligation="normative">
        <title>Clause</title>
        <p id="_">Text</p>
      </clause>
      </sections><annex id="_clause_2" inline-header="false" obligation="normative">
        <title>Clause</title>
        <p id="_">Text</p>
      </annex>
      </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
        <clause id="_clause1" inline-header="false" obligation="normative">
        <title>Clause1</title>
        <clause id="_clause2" inline-header="false" obligation="normative">
        <title>Clause2</title>
        <clause id="_clause3" inline-header="false" obligation="normative">
        <title>Clause3</title>
        <clause id="_clause4" inline-header="false" obligation="normative">
        <title>Clause4</title>
        <clause id="_clause_5" inline-header="false" obligation="normative">
        <title>Clause 5</title>
      <clause id="_clause_6" inline-header="false" obligation="normative">
        <title>Clause 6</title>
      <clause id="_clause_7a" inline-header="false" obligation="normative">
        <title>Clause 7A</title>
      </clause><clause id="_clause_7b" inline-header="false" obligation="normative">
        <title>Clause 7B</title>
      </clause></clause><clause id="_clause_6b" inline-header="false" obligation="normative">
        <title>Clause 6B</title>
      </clause></clause>
      <clause id="_clause_5b" inline-header="false" obligation="normative">
        <title>Clause 5B</title>
      </clause></clause>
      </clause>
      </clause>
      </clause>
      </sections>
      </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
                   <doctype>standard</doctype>
            <flavor>standoc</flavor>
                 </ext>
               </bibdata>
                         <preface>
             <abstract id="_abstract_a">
                <title>Abstract</title>
                <p id="_">Text</p>
             </abstract>
             <foreword id="_" obligation="informative">
                <title>
                   Foreword
                   <fn reference="1">
                      <p id="_">A</p>
                   </fn>
                </title>
                <p id="_">Text</p>
             </foreword>
             <introduction id="_introduction_a" obligation="informative">
                <title>Introduction</title>
                <clause id="_introduction_subsection" inline-header="false" obligation="informative">
                   <title>Introduction Subsection</title>
                </clause>
             </introduction>
             <clause id="_dedication" inline-header="false" obligation="informative">
                <title>Dedication</title>
             </clause>
             <acknowledgements id="_acknowledgements_a" obligation="informative">
                <title>
                   Acknowledgements
                   <fn reference="1">
                      <p id="_">A</p>
                   </fn>
                </title>
             </acknowledgements>
          </preface>
          <sections>
             <clause id="_scope_a" type="scope" inline-header="false" obligation="normative">
                <title>
                   Scope
                   <fn reference="1">
                      <p id="_">A</p>
                   </fn>
                </title>
                <p id="_">Text</p>
             </clause>
             <terms id="_terms_and_definitions_a" obligation="normative">
                <title>
                   Terms and definitions
                   <fn reference="1">
                      <p id="_">A</p>
                   </fn>
                </title>
                <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                <term id="term-Term1">
                   <preferred>
                      <expression>
                         <name>Term1</name>
                      </expression>
                   </preferred>
                </term>
             </terms>
             <clause id="_terms_definitions_symbols_and_abbreviated_terms_a" obligation="normative" type="terms">
                <title>
                   Terms, definitions, symbols and abbreviated terms
                   <fn reference="1">
                      <p id="_">A</p>
                   </fn>
                </title>
                <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                <clause id="_introduction" inline-header="false" obligation="normative">
                   <title>Introduction</title>
                   <clause id="_intro_1" inline-header="false" obligation="normative">
                      <title>Intro 1</title>
                   </clause>
                </clause>
                <terms id="_intro_2" obligation="normative">
                   <title>Intro 2</title>
                   <clause id="_intro_3" inline-header="false" obligation="normative">
                      <title>Intro 3</title>
                   </clause>
                </terms>
                <clause id="_intro_4" obligation="normative" type="terms">
                   <title>Intro 4</title>
                   <terms id="_intro_5" obligation="normative">
                      <title>Intro 5</title>
                      <term id="term-Term1-1">
                         <preferred>
                            <expression>
                               <name>Term1</name>
                            </expression>
                         </preferred>
                      </term>
                   </terms>
                </clause>
                <terms id="_normal_terms" obligation="normative">
                   <title>Normal Terms</title>
                   <term id="term-Term2">
                      <preferred>
                         <expression>
                            <name>Term2</name>
                         </expression>
                      </preferred>
                   </term>
                </terms>
                <definitions id="_symbols_and_abbreviated_terms_a" obligation="normative">
                   <title>
                      Symbols and abbreviated terms
                      <fn reference="1">
                         <p id="_">A</p>
                      </fn>
                   </title>
                   <clause id="_general" inline-header="false" obligation="normative">
                      <title>General</title>
                   </clause>
                   <definitions id="_symbols_1_a" type="symbols" obligation="normative">
                      <title>
                         Symbols
                         <fn reference="1">
                            <p id="_">A</p>
                         </fn>
                      </title>
                   </definitions>
                </definitions>
             </clause>
             <definitions id="_abbreviated_terms_a" type="abbreviated_terms" obligation="normative">
                <title>
                   Abbreviated terms
                   <fn reference="1">
                      <p id="_">A</p>
                   </fn>
                </title>
             </definitions>
             <clause id="_clause_4" inline-header="false" obligation="normative">
                <title>Clause 4</title>
                <clause id="_introduction_2" inline-header="false" obligation="normative">
                   <title>Introduction</title>
                </clause>
                <clause id="_clause_4_2" inline-header="false" obligation="normative">
                   <title>Clause 4.2</title>
                </clause>
             </clause>
             <clause id="_terms_and_definitions" inline-header="false" obligation="normative">
                <title>Terms and Definitions</title>
             </clause>
          </sections>
          <annex id="_annex_a" inline-header="false" obligation="normative">
             <title>
                Annex.
                <fn reference="1">
                   <p id="_">A</p>
                </fn>
             </title>
             <clause id="_annex_a_1" inline-header="false" obligation="normative">
                <title>Annex A.1</title>
             </clause>
          </annex>
          <bibliography>
             <references id="_normative_references_a" normative="true" obligation="informative">
                <title>
                   Normative references
                   <fn reference="1">
                      <p id="_">A</p>
                   </fn>
                </title>
                <p id="_">There are no normative references in this document.</p>
             </references>
             <references id="_normative_references_2_a" normative="true" obligation="informative">
                <title>
                   Normative References 2.
                   <fn reference="1">
                      <p id="_">A</p>
                   </fn>
                </title>
             </references>
             <references id="_bibliography_a" normative="false" obligation="informative">
                <title>
                   Bibliography
                   <fn reference="1">
                      <p id="_">A</p>
                   </fn>
                </title>
             </references>
             <clause id="_bibliography_2_a" obligation="informative">
                <title>
                   Bibliography 2.
                   <fn reference="1">
                      <p id="_">A</p>
                   </fn>
                </title>
                <references id="_bibliography_subsection" normative="false" obligation="informative">
                   <title>Bibliography Subsection</title>
                </references>
             </clause>
          </bibliography>
       </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
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
                    <doctype>standard</doctype>
            <flavor>standoc</flavor>
                  </ext>
                </bibdata>
                          <preface>
             <abstract id="_abstract">
                <title>Abstract</title>
                <p id="_">Text</p>
             </abstract>
             <foreword id="_" obligation="informative">
                <title>Foreword</title>
                <p id="_">Text</p>
             </foreword>
             <introduction id="_introduction" obligation="informative">
                <title>Introduction</title>
                <clause id="_introduction_subsection" inline-header="false" obligation="informative">
                   <title>Introduction Subsection</title>
                </clause>
             </introduction>
             <clause id="_dedication" inline-header="false" obligation="informative">
                <title>Dedication</title>
             </clause>
             <acknowledgements id="_acknowledgements" obligation="informative">
                <title>Acknowledgements</title>
             </acknowledgements>
          </preface>
          <sections>
             <clause id="_scope" type="scope" inline-header="false" obligation="normative">
                <title>Scope</title>
                <p id="_">Text</p>
             </clause>
             <terms id="_terms_and_definitions" obligation="normative">
                <title>Terms and definitions</title>
                <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                <term id="term-Term1">
                   <preferred>
                      <expression>
                         <name>Term1</name>
                      </expression>
                   </preferred>
                </term>
             </terms>
             <clause id="_terms_definitions_symbols_and_abbreviated_terms" obligation="normative" type="terms">
                <title>Terms, definitions, symbols and abbreviated terms</title>
                <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                <clause id="_introduction_2" inline-header="false" obligation="normative">
                   <title>Introduction</title>
                   <clause id="_intro_1" inline-header="false" obligation="normative">
                      <title>Intro 1</title>
                   </clause>
                </clause>
                <terms id="_intro_2" obligation="normative">
                   <title>Intro 2</title>
                   <clause id="_intro_3" inline-header="false" obligation="normative">
                      <title>Intro 3</title>
                   </clause>
                </terms>
                <clause id="_intro_4" obligation="normative" type="terms">
                   <title>Intro 4</title>
                   <terms id="_intro_5" obligation="normative">
                      <title>Intro 5</title>
                      <term id="term-Term1-1">
                         <preferred>
                            <expression>
                               <name>Term1</name>
                            </expression>
                         </preferred>
                      </term>
                   </terms>
                </clause>
                <terms id="_normal_terms" obligation="normative">
                   <title>Normal Terms</title>
                   <term id="term-Term2">
                      <preferred>
                         <expression>
                            <name>Term2</name>
                         </expression>
                      </preferred>
                   </term>
                </terms>
                <definitions id="_symbols_and_abbreviated_terms" obligation="normative">
                   <title>Symbols and abbreviated terms</title>
                   <clause id="_general" inline-header="false" obligation="normative">
                      <title>General</title>
                   </clause>
                   <definitions id="_symbols_1" type="symbols" obligation="normative">
                      <title>Symbols</title>
                   </definitions>
                </definitions>
             </clause>
             <definitions id="_abbreviated_terms" type="abbreviated_terms" obligation="normative">
                <title>Abbreviated terms</title>
             </definitions>
             <clause id="_clause_4" inline-header="false" obligation="normative">
                <title>Clause 4</title>
                <clause id="_introduction_3" inline-header="false" obligation="normative">
                   <title>Introduction</title>
                </clause>
                <clause id="_clause_4_2" inline-header="false" obligation="normative">
                   <title>Clause 4.2</title>
                </clause>
             </clause>
             <clause id="_terms_and_definitions_2" inline-header="false" obligation="normative">
                <title>Terms and Definitions</title>
             </clause>
          </sections>
          <annex id="_annex" inline-header="false" obligation="normative">
             <title>Annex</title>
             <clause id="_annex_a_1" inline-header="false" obligation="normative">
                <title>Annex A.1</title>
             </clause>
          </annex>
          <bibliography>
             <references id="_normative_references" normative="true" obligation="informative">
                <title>Normative references</title>
                <p id="_">There are no normative references in this document.</p>
             </references>
             <references id="_normative_references_2" normative="true" obligation="informative">
                <title>Normative References 2</title>
             </references>
             <references id="_bibliography" normative="false" obligation="informative">
                <title>Bibliography</title>
             </references>
             <clause id="_bibliography_2" obligation="informative">
                <title>Bibliography 2</title>
                <references id="_bibliography_subsection" normative="false" obligation="informative">
                   <title>Bibliography Subsection</title>
                </references>
             </clause>
          </bibliography>
       </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
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
                    <doctype>standard</doctype>
            <flavor>standoc</flavor>
                  </ext>
                </bibdata>
                          <preface>
             <abstract id="_abstract">
                <title>Résumé</title>
                <p id="_">Text</p>
             </abstract>
             <foreword id="_" obligation="informative">
                <title>Avant-propos</title>
                <p id="_">Text</p>
             </foreword>
             <introduction id="_introduction" obligation="informative">
                <title>Introduction</title>
                <clause id="_introduction_subsection" inline-header="false" obligation="informative">
                   <title>Introduction Subsection</title>
                </clause>
             </introduction>
             <clause id="_dedication" inline-header="false" obligation="informative">
                <title>Dedication</title>
             </clause>
             <acknowledgements id="_acknowledgements" obligation="informative">
                <title>Remerciements</title>
             </acknowledgements>
          </preface>
          <sections>
             <clause id="_scope" type="scope" inline-header="false" obligation="normative">
                <title>Domaine d’application</title>
                <p id="_">Text</p>
             </clause>
             <terms id="_terms_and_definitions" obligation="normative">
                <title>Termes et définitions</title>
                <p id="_">Pour les besoins du présent document, les termes et définitions suivants s’appliquent.</p>
                <term id="term-Term1">
                   <preferred>
                      <expression>
                         <name>Term1</name>
                      </expression>
                   </preferred>
                </term>
             </terms>
             <clause id="_terms_definitions_symbols_and_abbreviated_terms" obligation="normative" type="terms">
                <title>Termes, définitions, symboles et termes abrégés</title>
                <p id="_">Pour les besoins du présent document, les termes et définitions suivants s’appliquent.</p>
                <clause id="_introduction_2" inline-header="false" obligation="normative">
                   <title>Introduction</title>
                   <clause id="_intro_1" inline-header="false" obligation="normative">
                      <title>Intro 1</title>
                   </clause>
                </clause>
                <terms id="_intro_2" obligation="normative">
                   <title>Intro 2</title>
                   <clause id="_intro_3" inline-header="false" obligation="normative">
                      <title>Intro 3</title>
                   </clause>
                </terms>
                <clause id="_intro_4" obligation="normative" type="terms">
                   <title>Intro 4</title>
                   <terms id="_intro_5" obligation="normative">
                      <title>Intro 5</title>
                      <term id="term-Term1-1">
                         <preferred>
                            <expression>
                               <name>Term1</name>
                            </expression>
                         </preferred>
                      </term>
                   </terms>
                </clause>
                <terms id="_normal_terms" obligation="normative">
                   <title>Normal Terms</title>
                   <term id="term-Term2">
                      <preferred>
                         <expression>
                            <name>Term2</name>
                         </expression>
                      </preferred>
                   </term>
                </terms>
                <definitions id="_symbols_and_abbreviated_terms" obligation="normative">
                   <title>Symboles et termes abrégés</title>
                   <clause id="_general" inline-header="false" obligation="normative">
                      <title>General</title>
                   </clause>
                   <definitions id="_symbols_1" type="symbols" obligation="normative">
                      <title>Symboles</title>
                   </definitions>
                </definitions>
             </clause>
             <definitions id="_abbreviated_terms" type="abbreviated_terms" obligation="normative">
                <title>Termes abrégés</title>
             </definitions>
             <clause id="_clause_4" inline-header="false" obligation="normative">
                <title>Clause 4</title>
                <clause id="_introduction_3" inline-header="false" obligation="normative">
                   <title>Introduction</title>
                </clause>
                <clause id="_clause_4_2" inline-header="false" obligation="normative">
                   <title>Clause 4.2</title>
                </clause>
             </clause>
             <clause id="_terms_and_definitions_2" inline-header="false" obligation="normative">
                <title>Terms and Definitions</title>
             </clause>
          </sections>
          <annex id="_annex" inline-header="false" obligation="normative">
             <title>Annex</title>
             <clause id="_annex_a_1" inline-header="false" obligation="normative">
                <title>Annex A.1</title>
             </clause>
          </annex>
          <bibliography>
             <references id="_normative_references" normative="true" obligation="informative">
                <title>Références normatives</title>
                <p id="_">Le présent document ne contient aucune référence normative.</p>
             </references>
             <references id="_normative_references_2" normative="true" obligation="informative">
                <title>Normative References 2</title>
             </references>
             <references id="_bibliography" normative="false" obligation="informative">
                <title>Bibliographie</title>
             </references>
             <clause id="_bibliography_2" obligation="informative">
                <title>Bibliography 2</title>
                <references id="_bibliography_subsection" normative="false" obligation="informative">
                   <title>Bibliography Subsection</title>
                </references>
             </clause>
          </bibliography>
       </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
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
                    <doctype>standard</doctype>
            <flavor>standoc</flavor>
                  </ext>
                </bibdata>
                          <preface>
             <abstract id="_abstract">
                <title>摘要</title>
                <p id="_">Text</p>
             </abstract>
             <foreword id="_" obligation="informative">
                <title>前言</title>
                <p id="_">Text</p>
             </foreword>
             <introduction id="_introduction" obligation="informative">
                <title>引言</title>
                <clause id="_introduction_subsection" inline-header="false" obligation="informative">
                   <title>Introduction Subsection</title>
                </clause>
             </introduction>
             <clause id="_dedication" inline-header="false" obligation="informative">
                <title>Dedication</title>
             </clause>
             <acknowledgements id="_acknowledgements" obligation="informative">
                <title>致謝</title>
             </acknowledgements>
          </preface>
          <sections>
             <clause id="_scope" type="scope" inline-header="false" obligation="normative">
                <title>范围</title>
                <p id="_">Text</p>
             </clause>
             <terms id="_terms_and_definitions" obligation="normative">
                <title>术语和定义</title>
                <p id="_">下列术语和定义适用于本文件。</p>
                <term id="term-Term1">
                   <preferred>
                      <expression>
                         <name>Term1</name>
                      </expression>
                   </preferred>
                </term>
             </terms>
             <clause id="_terms_definitions_symbols_and_abbreviated_terms" obligation="normative" type="terms">
                <title>术语、定义、符号、代号和缩略语</title>
                <p id="_">下列术语和定义适用于本文件。</p>
                <clause id="_introduction_2" inline-header="false" obligation="normative">
                   <title>Introduction</title>
                   <clause id="_intro_1" inline-header="false" obligation="normative">
                      <title>Intro 1</title>
                   </clause>
                </clause>
                <terms id="_intro_2" obligation="normative">
                   <title>Intro 2</title>
                   <clause id="_intro_3" inline-header="false" obligation="normative">
                      <title>Intro 3</title>
                   </clause>
                </terms>
                <clause id="_intro_4" obligation="normative" type="terms">
                   <title>Intro 4</title>
                   <terms id="_intro_5" obligation="normative">
                      <title>Intro 5</title>
                      <term id="term-Term1-1">
                         <preferred>
                            <expression>
                               <name>Term1</name>
                            </expression>
                         </preferred>
                      </term>
                   </terms>
                </clause>
                <terms id="_normal_terms" obligation="normative">
                   <title>Normal Terms</title>
                   <term id="term-Term2">
                      <preferred>
                         <expression>
                            <name>Term2</name>
                         </expression>
                      </preferred>
                   </term>
                </terms>
                <definitions id="_symbols_and_abbreviated_terms" obligation="normative">
                   <title>符号、代号和缩略语</title>
                   <clause id="_general" inline-header="false" obligation="normative">
                      <title>General</title>
                   </clause>
                   <definitions id="_symbols_1" type="symbols" obligation="normative">
                      <title>符号</title>
                   </definitions>
                </definitions>
             </clause>
             <definitions id="_abbreviated_terms" type="abbreviated_terms" obligation="normative">
                <title>代号和缩略语</title>
             </definitions>
             <clause id="_clause_4" inline-header="false" obligation="normative">
                <title>Clause 4</title>
                <clause id="_introduction_3" inline-header="false" obligation="normative">
                   <title>Introduction</title>
                </clause>
                <clause id="_clause_4_2" inline-header="false" obligation="normative">
                   <title>Clause 4.2</title>
                </clause>
             </clause>
             <clause id="_terms_and_definitions_2" inline-header="false" obligation="normative">
                <title>Terms and Definitions</title>
             </clause>
          </sections>
          <annex id="_annex" inline-header="false" obligation="normative">
             <title>Annex</title>
             <clause id="_annex_a_1" inline-header="false" obligation="normative">
                <title>Annex A.1</title>
             </clause>
          </annex>
          <bibliography>
             <references id="_normative_references" normative="true" obligation="informative">
                <title>规范性引用文件</title>
                <p id="_">本文件并没有规范性引用文件。</p>
             </references>
             <references id="_normative_references_2" normative="true" obligation="informative">
                <title>Normative References 2</title>
             </references>
             <references id="_bibliography" normative="false" obligation="informative">
                <title>参考文献</title>
             </references>
             <clause id="_bibliography_2" obligation="informative">
                <title>Bibliography 2</title>
                <references id="_bibliography_subsection" normative="false" obligation="informative">
                   <title>Bibliography Subsection</title>
                </references>
             </clause>
          </bibliography>
       </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
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
                    <doctype>standard</doctype>
                <flavor>standoc</flavor>
                  </ext>
                </bibdata>
                          <preface>
             <abstract id="_abstract">
                <title>Abstract</title>
                <p id="_">Text</p>
             </abstract>
             <foreword id="_" obligation="informative">
                <title>Antaŭparolo</title>
                <p id="_">Text</p>
             </foreword>
             <introduction id="_introduction" obligation="informative">
                <title>Enkonduko</title>
                <clause id="_introduction_subsection" inline-header="false" obligation="informative">
                   <title>Introduction Subsection</title>
                </clause>
             </introduction>
             <clause id="_dedication" inline-header="false" obligation="informative">
                <title>Dedication</title>
             </clause>
             <acknowledgements id="_acknowledgements" obligation="informative">
                <title>Acknowledgements</title>
             </acknowledgements>
          </preface>
          <sections>
             <clause id="_scope" type="scope" inline-header="false" obligation="normative">
                <title>Amplekso</title>
                <p id="_">Text</p>
             </clause>
             <terms id="_terms_and_definitions" obligation="normative">
                <title>Terms and definitions</title>
                <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                <term id="term-Term1">
                   <preferred>
                      <expression>
                         <name>Term1</name>
                      </expression>
                   </preferred>
                </term>
             </terms>
             <clause id="_terms_definitions_symbols_and_abbreviated_terms" obligation="normative" type="terms">
                <title>Terms, definitions, symbols and abbreviated terms</title>
                <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                <clause id="_introduction_2" inline-header="false" obligation="normative">
                   <title>Introduction</title>
                   <clause id="_intro_1" inline-header="false" obligation="normative">
                      <title>Intro 1</title>
                   </clause>
                </clause>
                <terms id="_intro_2" obligation="normative">
                   <title>Intro 2</title>
                   <clause id="_intro_3" inline-header="false" obligation="normative">
                      <title>Intro 3</title>
                   </clause>
                </terms>
                <clause id="_intro_4" obligation="normative" type="terms">
                   <title>Intro 4</title>
                   <terms id="_intro_5" obligation="normative">
                      <title>Intro 5</title>
                      <term id="term-Term1-1">
                         <preferred>
                            <expression>
                               <name>Term1</name>
                            </expression>
                         </preferred>
                      </term>
                   </terms>
                </clause>
                <terms id="_normal_terms" obligation="normative">
                   <title>Normal Terms</title>
                   <term id="term-Term2">
                      <preferred>
                         <expression>
                            <name>Term2</name>
                         </expression>
                      </preferred>
                   </term>
                </terms>
                <definitions id="_symbols_and_abbreviated_terms" obligation="normative">
                   <title>Symbols and abbreviated terms</title>
                   <clause id="_general" inline-header="false" obligation="normative">
                      <title>General</title>
                   </clause>
                   <definitions id="_symbols_1" type="symbols" obligation="normative">
                      <title>Simboloj kai mallongigitaj terminoj</title>
                   </definitions>
                </definitions>
             </clause>
             <definitions id="_abbreviated_terms" type="abbreviated_terms" obligation="normative">
                <title>Abbreviated terms</title>
             </definitions>
             <clause id="_clause_4" inline-header="false" obligation="normative">
                <title>Clause 4</title>
                <clause id="_introduction_3" inline-header="false" obligation="normative">
                   <title>Introduction</title>
                </clause>
                <clause id="_clause_4_2" inline-header="false" obligation="normative">
                   <title>Clause 4.2</title>
                </clause>
             </clause>
             <clause id="_terms_and_definitions_2" inline-header="false" obligation="normative">
                <title>Terms and Definitions</title>
             </clause>
          </sections>
          <annex id="_annex" inline-header="false" obligation="normative">
             <title>Annex</title>
             <clause id="_annex_a_1" inline-header="false" obligation="normative">
                <title>Annex A.1</title>
             </clause>
          </annex>
          <bibliography>
             <references id="_normative_references" normative="true" obligation="informative">
                <title>Normaj citaĵoj</title>
                <p id="_">There are no normative references in this document.</p>
             </references>
             <references id="_normative_references_2" normative="true" obligation="informative">
                <title>Normative References 2</title>
             </references>
             <references id="_bibliography" normative="false" obligation="informative">
                <title>Bibliografio</title>
             </references>
             <clause id="_bibliography_2" obligation="informative">
                <title>Bibliography 2</title>
                <references id="_bibliography_subsection" normative="false" obligation="informative">
                   <title>Bibliography Subsection</title>
                </references>
             </clause>
          </bibliography>
       </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
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
      Clause _A_ stem:[y]

      Text
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <clause id="_clause" inline-header="false" obligation="normative">
             <title>Clause</title>
             <p id="_">Text</p>
             <clause id="_subclause" inline-header="false" obligation="normative">
               <title>Subclause</title>
               <variant-title type="sub">“A” ‘B’</variant-title>
               <variant-title type="toc">Clause <em>A</em><stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><mi>x</mi></mstyle></math><asciimath>x</asciimath></stem></variant-title>
               <p id="_">Text</p>
             </clause>
           </clause>
         </sections>
         <annex id="_clause_2" inline-header="false" obligation="normative">
           <title>Clause</title>
           <variant-title type="toc">Clause <em>A</em><stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><mi>y</mi></mstyle></math><asciimath>y</asciimath></stem></variant-title>
           <p id="_">Text</p>
         </annex>
       </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes TOC clause" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause
      Text

      [type=toc]
      === Table of contents

      Text at the start

      ==== Toc 1

      * <<cl2>>
      ** <<a1>>

      ==== Toc 2

      * <<cl2,some text>>
      ** <<a1,some more text>>

      [[cl2]]
      == Clause2

      [.variant-title,type=toc]
      Clause _A_ stem:[x]

      [.variant-title,type=sub]
      "A" 'B'

      Text

      [[a1]]
      [appendix]
      == Clause

      [.variant-title,type=toc]
      Clause _A_ stem:[y]

      Text
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <clause id="_clause" inline-header="false" obligation="normative">
             <title>Clause</title>
             <p id="_">Text</p>
             <clause id="_table_of_contents" type="toc" inline-header="false" obligation="normative">
               <title>Table of contents</title>
               <p id="_">Text at the start</p>
               <clause id="_toc_1" inline-header="false" obligation="normative">
                 <title>Toc 1</title>
                 <toc>
                   <ul id="_">
                     <li>
                       <p id="_">
                         <xref target="cl2">Clause <em>A</em><stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><mi>x</mi></mstyle></math><asciimath>x</asciimath></stem></xref>
                       </p>
                       <ul id="_">
                         <li>
                           <p id="_">
                             <xref target="a1">Clause <em>A</em><stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><mi>y</mi></mstyle></math><asciimath>y</asciimath></stem></xref>
                           </p>
                         </li>
                       </ul>
                     </li>
                   </ul>
                 </toc>
               </clause>
               <clause id="_toc_2" inline-header="false" obligation="normative">
                 <title>Toc 2</title>
                 <toc>
                   <ul id="_">
                     <li>
                       <p id="_">
                         <xref target="cl2">some text</xref>
                       </p>
                       <ul id="_">
                         <li>
                           <p id="_">
                             <xref target="a1">some more text</xref>
                           </p>
                         </li>
                       </ul>
                     </li>
                   </ul>
                 </toc>
               </clause>
             </clause>
           </clause>
           <clause id="cl2" inline-header="false" obligation="normative">
             <title>Clause2</title>
             <variant-title type="sub">“A” ‘B’</variant-title>
             <variant-title type="toc">Clause <em>A</em><stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><mi>x</mi></mstyle></math><asciimath>x</asciimath></stem></variant-title>
             <p id="_">Text</p>
           </clause>
         </sections>
         <annex id="a1" inline-header="false" obligation="normative">
           <title>Clause</title>
           <variant-title type="toc">Clause <em>A</em><stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><mi>y</mi></mstyle></math><asciimath>y</asciimath></stem></variant-title>
           <p id="_">Text</p>
         </annex>
       </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes bibliography annex" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [appendix]
      == Bibliography

      [bibliography]
      === Bibliography
    INPUT
    output = <<~OUTPUT
      <annex id='_' obligation='' language='' script=''>
          <title>Bibliography</title>
          <references id='_bibliography_2' normative='false' obligation='informative'>
            <title>Bibliography</title>
          </references>
      </annex>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(Xml::C14n.format(strip_guid(ret.at("//xmlns:annex").to_xml)))
      .to be_equivalent_to(Xml::C14n.format(output))
  end

  it "processes terms annex" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [appendix]
      == Terms and definitions

      === Terms and definitions
    INPUT
    output = <<~OUTPUT
      <annex id='_' obligation='' language='' script=''>
        <terms id='_terms_and_definitions' obligation='normative'>
          <title>Terms and definitions</title>
          <term id='term-Terms-and-definitions'>
            <preferred>
              <expression>
                <name>Terms and definitions</name>
              </expression>
            </preferred>
          </term>
        </terms>
      </annex>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(Xml::C14n.format(strip_guid(ret.at("//xmlns:annex").to_xml)))
      .to be_equivalent_to(Xml::C14n.format(output))
  end

  it "puts floating title before scope into sections container" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Foreword

      [discrete%section]
      == Basic layout and preliminary elements

      == Scope
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <preface>
           <foreword id="_foreword" obligation="informative">
             <title>Foreword</title>
           </foreword>
         </preface>
         <sections>
           <floating-title id="_basic_layout_and_preliminary_elements" depth="1" type="floating-title">Basic layout and preliminary elements</floating-title>
           <clause id="_scope" type="scope" inline-header="false" obligation="normative">
             <title>Scope</title>
           </clause>
         </sections>
       </standard-document>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(Xml::C14n.format(strip_guid(ret.to_xml)))
      .to be_equivalent_to(Xml::C14n.format(output))
  end

  it "puts floating title + clausebefore note before scope into sections container" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Foreword

      A

      [discrete%section]
      == Basic layout and preliminary elements

      [NOTE,beforeclauses=true]
      Initial Note

      == Scope
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <preface>
           <foreword id="_foreword" obligation="informative">
             <title>Foreword</title>
             <p id="_">A</p>
           </foreword>
         </preface>
         <sections>
           <floating-title id="_basic_layout_and_preliminary_elements" depth="1" type="floating-title">Basic layout and preliminary elements</floating-title>
          <note id="_">
            <p id="_">Initial Note</p>
          </note>
           <clause id="_scope" type="scope" inline-header="false" obligation="normative">
             <title>Scope</title>
           </clause>
         </sections>
       </standard-document>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(Xml::C14n.format(strip_guid(ret.to_xml)))
      .to be_equivalent_to(Xml::C14n.format(output))

    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Foreword

      A

      [discrete%section]
      == Basic layout and preliminary elements

      [NOTE,beforeclauses=true]
      Initial Note

      More

      == Scope
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <preface>
           <note id="_">
             <p id="_">Initial Note</p>
           </note>
           <foreword id="_foreword" obligation="informative">
             <title>Foreword</title>
             <p id="_">A</p>
             <floating-title id="_basic_layout_and_preliminary_elements" depth="1" type="floating-title">Basic layout and preliminary elements</floating-title>
             <p id="_">More</p>
           </foreword>
         </preface>
         <sections>
           <clause id="_scope" type="scope" inline-header="false" obligation="normative">
             <title>Scope</title>
           </clause>
         </sections>
       </standard-document>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(Xml::C14n.format(strip_guid(ret.to_xml)))
      .to be_equivalent_to(Xml::C14n.format(output))
  end
end
