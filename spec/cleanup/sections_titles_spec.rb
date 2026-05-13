require "spec_helper"
require "relaton/iec"
require "fileutils"

RSpec.describe Metanorma::Standoc do
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

      [heading=executivesummary]
      == Executive summary.footnote:[A]

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
      <metanorma xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
              <bibdata type='standard'>
                <title language='en' type='main'>Document title</title>
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
            <abstract id="_" >
               <title id="_">Abstract</title>
               <p id="_">Text</p>
            </abstract>
            <foreword id="_" obligation="informative">
               <title id="_">
                  Foreword
                  <fn id="_" reference="1">
                     <p id="_">A</p>
                  </fn>
               </title>
               <p id="_">Text</p>
            </foreword>
            <introduction id="_" obligation="informative">
               <title id="_">Introduction</title>
               <clause id="_" inline-header="false" obligation="informative">
                  <title id="_">Introduction Subsection</title>
               </clause>
            </introduction>
            <clause id="_" inline-header="false" obligation="informative">
               <title id="_">Dedication</title>
            </clause>
            <acknowledgements id="_" obligation="informative">
               <title id="_">
                  Acknowledgements
                  <fn id="_" reference="1">
                     <p id="_">A</p>
                  </fn>
               </title>
            </acknowledgements>
         <executivesummary id="_" obligation="informative">
           <title id="_">
               Executive summary
               <fn id="_" reference="1">
                 <p id="_">A</p>
               </fn>
           </title>
         </executivesummary>
         </preface>
         <sections>
            <clause id="_" type="scope" inline-header="false" obligation="normative">
               <title id="_">
                  Scope
                  <fn id="_" reference="1">
                     <p id="_">A</p>
                  </fn>
               </title>
               <p id="_">Text</p>
            </clause>
            <terms id="_" obligation="normative">
               <title id="_">
                  Terms and definitions
                  <fn id="_" reference="1">
                     <p id="_">A</p>
                  </fn>
               </title>
               <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
               <term id="_" anchor="term-Term1">
                  <preferred>
                     <expression>
                        <name>Term1</name>
                     </expression>
                  </preferred>
               </term>
            </terms>
            <clause id="_" obligation="normative" type="terms">
               <title id="_">
                  Terms, definitions, symbols and abbreviated terms
                  <fn id="_" reference="1">
                     <p id="_">A</p>
                  </fn>
               </title>
               <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
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
                     <term id="_" anchor="term-Term1-1">
                        <preferred>
                           <expression>
                              <name>Term1</name>
                           </expression>
                        </preferred>
                     </term>
                  </terms>
               </clause>
               <terms id="_" obligation="normative">
                  <title id="_">Normal Terms</title>
                  <term id="_" anchor="term-Term2">
                     <preferred>
                        <expression>
                           <name>Term2</name>
                        </expression>
                     </preferred>
                  </term>
               </terms>
               <definitions id="_" obligation="normative">
                  <title id="_">
                     Symbols and abbreviated terms
                     <fn id="_" reference="1">
                        <p id="_">A</p>
                     </fn>
                  </title>
                  <clause id="_" inline-header="false" obligation="normative">
                     <title id="_">General</title>
                  </clause>
                  <definitions id="_" type="symbols" obligation="normative">
                     <title id="_">
                        Symbols
                        <fn id="_" reference="1">
                           <p id="_">A</p>
                        </fn>
                     </title>
                  </definitions>
               </definitions>
            </clause>
            <definitions id="_" type="abbreviated_terms" obligation="normative">
               <title id="_">
                  Abbreviated terms
                  <fn id="_" reference="1">
                     <p id="_">A</p>
                  </fn>
               </title>
            </definitions>
            <clause id="_" inline-header="false" obligation="normative">
               <title id="_">Clause 4</title>
               <clause id="_" inline-header="false" obligation="normative">
                  <title id="_">Introduction</title>
               </clause>
               <clause id="_" inline-header="false" obligation="normative">
                  <title id="_">Clause 4.2</title>
               </clause>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
               <title id="_">Terms and Definitions</title>
            </clause>
         </sections>
         <annex id="_" inline-header="false" obligation="normative">
            <title id="_">
               Annex.
               <fn id="_" reference="1">
                  <p id="_">A</p>
               </fn>
            </title>
            <clause id="_" inline-header="false" obligation="normative">
               <title id="_">Annex A.1</title>
            </clause>
         </annex>
         <bibliography>
            <references id="_" normative="true" obligation="informative">
               <title id="_">
                  Normative references
                  <fn id="_" reference="1">
                     <p id="_">A</p>
                  </fn>
               </title>
               <p id="_">There are no normative references in this document.</p>
            </references>
            <references id="_" normative="true" obligation="informative">
               <title id="_">
                  Normative References 2.
                  <fn id="_" reference="1">
                     <p id="_">A</p>
                  </fn>
               </title>
            </references>
            <references id="_" normative="false" obligation="informative">
               <title id="_">
                  Bibliography
                  <fn id="_" reference="1">
                     <p id="_">A</p>
                  </fn>
               </title>
            </references>
            <clause id="_" obligation="informative">
               <title id="_">
                  Bibliography 2.
                  <fn id="_" reference="1">
                     <p id="_">A</p>
                  </fn>
               </title>
               <references id="_" normative="false" obligation="informative">
                  <title id="_">Bibliography Subsection</title>
               </references>
            </clause>
         </bibliography>
      </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
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

      [heading=executivesummary]
      == Executive summary

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
      <metanorma xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
                <bibdata type='standard'>
                  <title language='tlh' type='main'>Document title</title>
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
             <abstract id="_" >
                <title id="_">Abstract</title>
                <p id="_">Text</p>
             </abstract>
             <foreword id="_" obligation="informative">
                <title id="_">Foreword</title>
                <p id="_">Text</p>
             </foreword>
             <introduction id="_" obligation="informative">
                <title id="_">Introduction</title>
                <clause id="_" inline-header="false" obligation="informative">
                   <title id="_">Introduction Subsection</title>
                </clause>
             </introduction>
             <clause id="_" inline-header="false" obligation="informative">
                <title id="_">Dedication</title>
             </clause>
             <acknowledgements id="_" obligation="informative">
                <title id="_">Acknowledgements</title>
             </acknowledgements>
            <executivesummary id="_" obligation="informative">
              <title id="_">Executive summary</title>
            </executivesummary>
          </preface>
          <sections>
             <clause id="_" type="scope" inline-header="false" obligation="normative">
                <title id="_">Scope</title>
                <p id="_">Text</p>
             </clause>
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
             <clause id="_" obligation="normative" type="terms">
                <title id="_">Terms, definitions, symbols and abbreviated terms</title>
                <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
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
                      <term id="_" anchor="term-Term1-1">
                         <preferred>
                            <expression>
                               <name>Term1</name>
                            </expression>
                         </preferred>
                      </term>
                   </terms>
                </clause>
                <terms id="_" obligation="normative">
                   <title id="_">Normal Terms</title>
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
             <definitions id="_" type="abbreviated_terms" obligation="normative">
                <title id="_">Abbreviated terms</title>
             </definitions>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Clause 4</title>
                <clause id="_" inline-header="false" obligation="normative">
                   <title id="_">Introduction</title>
                </clause>
                <clause id="_" inline-header="false" obligation="normative">
                   <title id="_">Clause 4.2</title>
                </clause>
             </clause>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Terms and Definitions</title>
             </clause>
          </sections>
          <annex id="_" inline-header="false" obligation="normative">
             <title id="_">Annex</title>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Annex A.1</title>
             </clause>
          </annex>
          <bibliography>
             <references id="_" normative="true" obligation="informative">
                <title id="_">Normative references</title>
                <p id="_">There are no normative references in this document.</p>
             </references>
             <references id="_" normative="true" obligation="informative">
                <title id="_">Normative References 2</title>
             </references>
             <references id="_" normative="false" obligation="informative">
                <title id="_">Bibliography</title>
             </references>
             <clause id="_" obligation="informative">
                <title id="_">Bibliography 2</title>
                <references id="_" normative="false" obligation="informative">
                   <title id="_">Bibliography Subsection</title>
                </references>
             </clause>
          </bibliography>
       </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
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

      [heading=executivesummary]
      == Executive summary

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
      <metanorma xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
                <bibdata type='standard'>
                  <title language='fr' type='main'>Document title</title>
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
             <abstract id="_">
                <title id="_">Résumé</title>
                <p id="_">Text</p>
             </abstract>
             <foreword id="_" obligation="informative">
                <title id="_">Avant-propos</title>
                <p id="_">Text</p>
             </foreword>
             <introduction id="_" obligation="informative">
                <title id="_">Introduction</title>
                <clause id="_" inline-header="false" obligation="informative">
                   <title id="_">Introduction Subsection</title>
                </clause>
             </introduction>
             <clause id="_" inline-header="false" obligation="informative">
                <title id="_">Dedication</title>
             </clause>
             <acknowledgements id="_" obligation="informative">
                <title id="_">Remerciements</title>
             </acknowledgements>
          <executivesummary id="_" obligation="informative">
            <title id="_">Résumé exécutif</title>
          </executivesummary>
          </preface>
          <sections>
             <clause id="_" type="scope" inline-header="false" obligation="normative">
                <title id="_">Domaine d’application</title>
                <p id="_">Text</p>
             </clause>
             <terms id="_" obligation="normative">
                <title id="_">Termes et définitions</title>
                <p id="_">Pour les besoins du présent document, les termes et définitions suivants s’appliquent.</p>
                <term id="_" anchor="term-Term1">
                   <preferred>
                      <expression>
                         <name>Term1</name>
                      </expression>
                   </preferred>
                </term>
             </terms>
             <clause id="_" obligation="normative" type="terms">
                <title id="_">Termes, définitions, symboles et termes abrégés</title>
                <p id="_">Pour les besoins du présent document, les termes et définitions suivants s’appliquent.</p>
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
                      <term id="_" anchor="term-Term1-1">
                         <preferred>
                            <expression>
                               <name>Term1</name>
                            </expression>
                         </preferred>
                      </term>
                   </terms>
                </clause>
                <terms id="_" obligation="normative">
                   <title id="_">Normal Terms</title>
                   <term id="_" anchor="term-Term2">
                      <preferred>
                         <expression>
                            <name>Term2</name>
                         </expression>
                      </preferred>
                   </term>
                </terms>
                <definitions id="_" obligation="normative">
                   <title id="_">Symboles et termes abrégés</title>
                   <clause id="_" inline-header="false" obligation="normative">
                      <title id="_">General</title>
                   </clause>
                   <definitions id="_" type="symbols" obligation="normative">
                      <title id="_">Symboles</title>
                   </definitions>
                </definitions>
             </clause>
             <definitions id="_" type="abbreviated_terms" obligation="normative">
                <title id="_">Termes abrégés</title>
             </definitions>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Clause 4</title>
                <clause id="_" inline-header="false" obligation="normative">
                   <title id="_">Introduction</title>
                </clause>
                <clause id="_" inline-header="false" obligation="normative">
                   <title id="_">Clause 4.2</title>
                </clause>
             </clause>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Terms and Definitions</title>
             </clause>
          </sections>
          <annex id="_" inline-header="false" obligation="normative">
             <title id="_">Annex</title>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Annex A.1</title>
             </clause>
          </annex>
          <bibliography>
             <references id="_" normative="true" obligation="informative">
                <title id="_">Références normatives</title>
                <p id="_">Le présent document ne contient aucune référence normative.</p>
             </references>
             <references id="_" normative="true" obligation="informative">
                <title id="_">Normative References 2</title>
             </references>
             <references id="_" normative="false" obligation="informative">
                <title id="_">Bibliographie</title>
             </references>
             <clause id="_" obligation="informative">
                <title id="_">Bibliography 2</title>
                <references id="_" normative="false" obligation="informative">
                   <title id="_">Bibliography Subsection</title>
                </references>
             </clause>
          </bibliography>
       </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
  end

  it "processes section names, Simplified Chinese" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR.sub(/:nodoc:/, ":language: zh\n:script: Hans\n:nodoc:").sub('<title language="en"', '<title language="zh"')}
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

      [heading=executivesummary]
      == Executive summary

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
      <metanorma xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
                <bibdata type='standard'>
                  <title language='zh' type='main'>Document title</title>
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
             <abstract id="_" >
                <title id="_">摘要</title>
                <p id="_">Text</p>
             </abstract>
             <foreword id="_" obligation="informative">
                <title id="_">前言</title>
                <p id="_">Text</p>
             </foreword>
             <introduction id="_" obligation="informative">
                <title id="_">引言</title>
                <clause id="_" inline-header="false" obligation="informative">
                   <title id="_">Introduction Subsection</title>
                </clause>
             </introduction>
             <clause id="_" inline-header="false" obligation="informative">
                <title id="_">Dedication</title>
             </clause>
             <acknowledgements id="_" obligation="informative">
                <title id="_">致謝</title>
             </acknowledgements>
            <executivesummary id="_" obligation="informative">
              <title id="_">执行摘要</title>
            </executivesummary>
          </preface>
          <sections>
             <clause id="_" type="scope" inline-header="false" obligation="normative">
                <title id="_">范围</title>
                <p id="_">Text</p>
             </clause>
             <terms id="_" obligation="normative">
                <title id="_">术语和定义</title>
                <p id="_">下列术语和定义适用于本文件。</p>
                <term id="_" anchor="term-Term1">
                   <preferred>
                      <expression>
                         <name>Term1</name>
                      </expression>
                   </preferred>
                </term>
             </terms>
             <clause id="_" obligation="normative" type="terms">
                <title id="_">术语、定义、符号、代号和缩略语</title>
                <p id="_">下列术语和定义适用于本文件。</p>
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
                      <term id="_" anchor="term-Term1-1">
                         <preferred>
                            <expression>
                               <name>Term1</name>
                            </expression>
                         </preferred>
                      </term>
                   </terms>
                </clause>
                <terms id="_" obligation="normative">
                   <title id="_">Normal Terms</title>
                   <term id="_" anchor="term-Term2">
                      <preferred>
                         <expression>
                            <name>Term2</name>
                         </expression>
                      </preferred>
                   </term>
                </terms>
                <definitions id="_" obligation="normative">
                   <title id="_">符号、代号和缩略语</title>
                   <clause id="_" inline-header="false" obligation="normative">
                      <title id="_">General</title>
                   </clause>
                   <definitions id="_" type="symbols" obligation="normative">
                      <title id="_">符号</title>
                   </definitions>
                </definitions>
             </clause>
             <definitions id="_" type="abbreviated_terms" obligation="normative">
                <title id="_">代号和缩略语</title>
             </definitions>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Clause 4</title>
                <clause id="_" inline-header="false" obligation="normative">
                   <title id="_">Introduction</title>
                </clause>
                <clause id="_" inline-header="false" obligation="normative">
                   <title id="_">Clause 4.2</title>
                </clause>
             </clause>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Terms and Definitions</title>
             </clause>
          </sections>
          <annex id="_" inline-header="false" obligation="normative">
             <title id="_">Annex</title>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Annex A.1</title>
             </clause>
          </annex>
          <bibliography>
             <references id="_" normative="true" obligation="informative">
                <title id="_">规范性引用文件</title>
                <p id="_">本文件并没有规范性引用文件。</p>
             </references>
             <references id="_" normative="true" obligation="informative">
                <title id="_">Normative References 2</title>
             </references>
             <references id="_" normative="false" obligation="informative">
                <title id="_">参考文献</title>
             </references>
             <clause id="_" obligation="informative">
                <title id="_">Bibliography 2</title>
                <references id="_" normative="false" obligation="informative">
                   <title id="_">Bibliography Subsection</title>
                </references>
             </clause>
          </bibliography>
       </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
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

      [heading=executivesummary]
      == Executive summary

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
      <metanorma xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
                <bibdata type='standard'>
                  <title language='en' type='main'>Document title</title>
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
             <abstract id="_" >
                <title id="_">Abstract</title>
                <p id="_">Text</p>
             </abstract>
             <foreword id="_" obligation="informative">
                <title id="_">Antaŭparolo</title>
                <p id="_">Text</p>
             </foreword>
             <introduction id="_" obligation="informative">
                <title id="_">Enkonduko</title>
                <clause id="_" inline-header="false" obligation="informative">
                   <title id="_">Introduction Subsection</title>
                </clause>
             </introduction>
             <clause id="_" inline-header="false" obligation="informative">
                <title id="_">Dedication</title>
             </clause>
             <acknowledgements id="_" obligation="informative">
                <title id="_">Acknowledgements</title>
             </acknowledgements>
            <executivesummary id="_" obligation="informative">
              <title id="_">Executive summary</title>
            </executivesummary>
          </preface>
          <sections>
             <clause id="_" type="scope" inline-header="false" obligation="normative">
                <title id="_">Amplekso</title>
                <p id="_">Text</p>
             </clause>
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
             <clause id="_" obligation="normative" type="terms">
                <title id="_">Terms, definitions, symbols and abbreviated terms</title>
                <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
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
                      <term id="_" anchor="term-Term1-1">
                         <preferred>
                            <expression>
                               <name>Term1</name>
                            </expression>
                         </preferred>
                      </term>
                   </terms>
                </clause>
                <terms id="_" obligation="normative">
                   <title id="_">Normal Terms</title>
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
                      <title id="_">Simboloj kai mallongigitaj terminoj</title>
                   </definitions>
                </definitions>
             </clause>
             <definitions id="_" type="abbreviated_terms" obligation="normative">
                <title id="_">Abbreviated terms</title>
             </definitions>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Clause 4</title>
                <clause id="_" inline-header="false" obligation="normative">
                   <title id="_">Introduction</title>
                </clause>
                <clause id="_" inline-header="false" obligation="normative">
                   <title id="_">Clause 4.2</title>
                </clause>
             </clause>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Terms and Definitions</title>
             </clause>
          </sections>
          <annex id="_" inline-header="false" obligation="normative">
             <title id="_">Annex</title>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Annex A.1</title>
             </clause>
          </annex>
          <bibliography>
             <references id="_" normative="true" obligation="informative">
                <title id="_">Normaj citaĵoj</title>
                <p id="_">Neniuj normaj referencoj en ĉi tiu standard.</p>
             </references>
             <references id="_" normative="true" obligation="informative">
                <title id="_">Normative References 2</title>
             </references>
             <references id="_" normative="false" obligation="informative">
                <title id="_">Bibliografio</title>
             </references>
             <clause id="_" obligation="informative">
                <title id="_">Bibliography 2</title>
                <references id="_" normative="false" obligation="informative">
                   <title id="_">Bibliography Subsection</title>
                </references>
             </clause>
          </bibliography>
       </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
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
           <clause id="_" inline-header="false" obligation="normative">
             <title id="_">Clause</title>
             <p id="_">Text</p>
             <clause id="_" inline-header="false" obligation="normative">
               <title id="_">Subclause</title>
               <variant-title id="_" type="sub">“A” ‘B’</variant-title>
               <variant-title id="_" type="toc">Clause <em>A</em><stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><mi>x</mi></mstyle></math><asciimath>x</asciimath></stem></variant-title>
               <p id="_">Text</p>
             </clause>
           </clause>
         </sections>
         <annex id="_" inline-header="false" obligation="normative">
           <title id="_">Clause</title>
           <variant-title id="_" type="toc">Clause <em>A</em><stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><mi>y</mi></mstyle></math><asciimath>y</asciimath></stem></variant-title>
           <p id="_">Text</p>
         </annex>
       </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

   it "does not replace titles with keeptitle attribute" do
     input = <<~INPUT
       #{ASCIIDOC_BLANK_HDR}
       .Foreword

       Text

       [abstract,keeptitle=true]
       == Περίληψη

       Text

       [heading=introduction,keeptitle=true]
       == Εισαγωγή

       === Introduction Subsection

       [heading=acknowledgements,keeptitle=true]
       == Ευχαριστίες

       [heading=executivesummary,keeptitle=true]
       == Εκτελιστική Περίληψη

       [heading=normative references,keeptitle=true]
       == Κανονιστικές Παραπομπές

       [heading=terms and definitions,keeptitle=true]
       == Όροι και Ορισμοί

       === Term1

       [heading="terms, definitions, symbols and abbreviated terms",keeptitle=true]
       == Όροι, Ορισμοί, Σύμβολα και Συντομογραφίες

       === Normal Terms

       ==== Term2

       [heading=symbols,keeptitle=true]
       === Σύμβολα και Συντομογραφίες

       [heading=abbreviated terms,keeptitle=true]
       == Σύμβολα και Συντομογραφίες

       [appendix]
       == Annex
       
       === Annex A.1

       [heading=bibliography,keeptitle=true]
       == Βιβλιογραφία

       === Bibliography Subsection
     INPUT
    output = <<~OUTPUT
       #{BLANK_HDR.sub('<status>', '<abstract> <p>Text</p> </abstract><status>')}
          <preface>
              <abstract id="_">
                 <p id="_">Text</p>
              </abstract>
              <foreword id="_" obligation="informative">
                 <title id="_">Foreword</title>
                 <p id="_">Text</p>
              </foreword>
              <introduction id="_" obligation="informative">
                 <title id="_">Introduction</title>
                 <clause id="_" inline-header="false" obligation="informative">
                    <title id="_">Introduction Subsection</title>
                 </clause>
              </introduction>
              <acknowledgements id="_" obligation="informative">
                 <title id="_">Ευχαριστίες</title>
              </acknowledgements>
              <executivesummary id="_" obligation="informative">
                 <title id="_">Εκτελιστική Περίληψη</title>
              </executivesummary>
           </preface>
           <sections>
              <terms id="_" obligation="normative">
                 <title id="_">Όροι και Ορισμοί</title>
                 <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                 <term id="_" anchor="term-Term1">
                    <preferred>
                       <expression>
                          <name>Term1</name>
                       </expression>
                    </preferred>
                 </term>
              </terms>
              <clause id="_" obligation="normative" type="terms">
                 <title id="_">Όροι, Ορισμοί, Σύμβολα και Συντομογραφίες</title>
                 <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                 <terms id="_" obligation="normative">
                    <title id="_">Normal Terms</title>
                    <term id="_" anchor="term-Term2">
                       <preferred>
                          <expression>
                             <name>Term2</name>
                          </expression>
                       </preferred>
                    </term>
                 </terms>
                 <definitions id="_" type="symbols" obligation="normative">
                    <title id="_">Σύμβολα και Συντομογραφίες</title>
                 </definitions>
              </clause>
              <definitions id="_" type="abbreviated_terms" obligation="normative">
                 <title id="_">Σύμβολα και Συντομογραφίες</title>
              </definitions>
           </sections>
           <annex id="_" inline-header="false" obligation="normative">
              <title id="_">Annex</title>
              <clause id="_" inline-header="false" obligation="normative">
                 <title id="_">Annex A.1</title>
              </clause>
           </annex>
           <bibliography>
              <references id="_" normative="true" obligation="informative">
                 <title id="_">Κανονιστικές Παραπομπές</title>
                 <p id="_">There are no normative references in this document.</p>
              </references>
              <clause id="_" obligation="informative">
                 <title id="_">Βιβλιογραφία</title>
                 <references id="_" normative="false" obligation="informative">
                    <title id="_">Bibliography Subsection</title>
                 </references>
              </clause>
           </bibliography>
        </metanorma>
 OUTPUT
     expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
       .to be_xml_equivalent_to output
   end
end
