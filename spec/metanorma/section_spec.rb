 require "spec_helper"

 RSpec.describe Metanorma::Standoc do
   it "processes sections" do
     input = <<~INPUT
       #{ASCIIDOC_BLANK_HDR}
       .Foreword

       Text

       == Misc-Container

       Content

       == Metanorma-Extension

       More content

       == metanorma-extension

       Yet more content

       [.preface,heading=clause]
       == metanorma-extension

       Yet again more content

       [abstract]
       == Abstract

       Text

       == Introduction

       === Introduction Subsection

       == Acknowledgements

       == Executive summary

       [.preface]
       == Dedication

       [.colophon]
       == First Colophon Section

       [.colophon]
       == Second Colophon Section

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
     ext = <<~EXT
           <p id="_">Content</p>
       <p id="_">More content</p>
       <p id="_">Yet more content</p>
     EXT
     output = <<~OUTPUT
            #{BLANK_HDR.sub('<status>', '<abstract> <p>Text</p> </abstract><status>').sub('<metanorma-extension>', "<metanorma-extension>#{ext}")}
                      <preface>
             <abstract id="_">
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
          <title id="_">metanorma-extension</title>
         <p id="_">Yet again more content</p>
        </clause>
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
                <p id="_">Boilerplate text</p>
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
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Acknowledgements</title>
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
             <clause id="_" obligation="informative">
                <title id="_">Bibliography</title>
                <references id="_" normative="false" obligation="informative">
                   <title id="_">Bibliography Subsection</title>
                </references>
             </clause>
          </bibliography>
          <indexsect id="_">
             <title id="_">Index</title>
             <p id="_">This is an index</p>
          </indexsect>
          <indexsect id="_" type="thematic">
             <title id="_">Thematic Index</title>
          </indexsect>
          <colophon>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">First Colophon Section</title>
             </clause>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">Second Colophon Section</title>
             </clause>
          </colophon>
       </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
                <title id="_">Foreword</title>
                <p id="_">Text</p>
              </foreword>
              <clause id="_" inline-header="false" obligation="informative">
                <title id="_">Frontispiece</title>
              </clause>
            </preface>
            <sections>
              <clause id="_" type="scope" inline-header="false" obligation="normative">
                <title id="_">Scope</title>
              </clause>
            </sections>
          </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
              <clause id="_" number='1bis' type='scope' inline-header='false' obligation='normative'>
                <title id="_">Scope</title>
                <p id='_'>Text</p>
              </clause>
              <terms id="_" number='3bis' obligation='normative'>
                <title id="_">Terms and definitions</title>
                <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
                <term id="_" anchor="term-Term1" number='4bis'>
                  <preferred><expression><name>Term1</name></expression></preferred>
                </term>
              </terms>
              <terms id="_" number='5bis' obligation='normative'>
                <title id="_">Terms, definitions, symbols and abbreviated terms</title>
                <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
                <clause id="_" number='6bis' inline-header='false' obligation='normative'>
                  <title id="_">Introduction</title>
                  <clause id="_" number='7bis' inline-header='false' obligation='normative'>
                    <title id="_">Intro 1</title>
                  </clause>
                </clause>
                <term id="_" anchor="term-Intro-2" number='8bis'>
                  <preferred><expression><name>Intro 2</name></expression></preferred>
                </term>
                <definitions id="_" number='9bis' obligation='normative'>
                  <title id="_">Symbols and abbreviated terms</title>
                  <clause id="_" number='10bis' inline-header='false' obligation='normative'>
                    <title id="_">General</title>
                  </clause>
                  <definitions id="_" number='11bis' type='symbols' obligation='normative'>
                    <title id="_">Symbols</title>
                  </definitions>
                </definitions>
              </terms>
              <definitions id="_" number='12bis' type='abbreviated_terms' obligation='normative'>
                <title id="_">Abbreviated terms</title>
              </definitions>
              <clause id="_" number='13bis' inline-header='false' obligation='normative'>
                <title id="_">Clause 4</title>
                <clause id="_" number='14bis' inline-header='false' obligation='normative'>
                  <title id="_">Introduction</title>
                </clause>
                <clause id="_" number='15bis' inline-header='false' obligation='normative'>
                  <title id="_">Clause 4.2</title>
                </clause>
              </clause>
              <clause id="_" number='16bis' inline-header='false' obligation='normative'>
                <title id="_">Terms and Definitions</title>
              </clause>
            </sections>
            <annex id="_" number='17bis' inline-header='false' obligation='normative'>
              <title id="_">Annex</title>
              <clause id="_" number='18bis' inline-header='false' obligation='normative'>
                <title id="_">Annex A.1</title>
              </clause>
            </annex>
            <bibliography>
              <references id="_" number='2bis' normative='true' obligation='informative'>
                <title id="_">Normative references</title>
                <p id='_'>There are no normative references in this document.</p>
              </references>
              <clause id="_" number='19bis' obligation='informative'>
                <title id="_">Bibliography</title>
                <references id="_" number='20bis' normative='false' obligation='informative'>
                  <title id="_">Bibliography Subsection</title>
                </references>
              </clause>
            </bibliography>
          </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
   end

   it "processes sections with number attributes" do
     input = <<~INPUT
       #{ASCIIDOC_BLANK_HDR}
       [branch-number=1bis]
       == Scope

       Text

       [branch-number=2bis]
       == Normative References

       [branch-number=3bis]
       == Terms and Definitions

       [branch-number=4bis]
       === Term1

       [branch-number=5bis]
       == Terms, Definitions, Symbols and Abbreviated Terms

       [.nonterm,branch-number=6bis]
       === Introduction

       [branch-number=7bis]
       ==== Intro 1

       [branch-number=8bis]
       === Intro 2

       [branch-number=9bis]
       === Symbols and Abbreviated Terms

       [.nonterm,branch-number=10bis]
       ==== General

       [branch-number=11bis]
       ==== Symbols

       [branch-number=12bis]
       == Abbreviated Terms

       [branch-number=13bis]
       == Clause 4

       [branch-number=14bis]
       === Introduction

       [branch-number=15bis]
       === Clause 4.2

       [branch-number=16bis]
       == Terms and Definitions

       [appendix,branch-number=17bis]
       == Annex

       [branch-number=18bis]
       === Annex A.1

       [bibliography,branch-number=19bis]
       == Bibliography

       [branch-number=20bis]
       === Bibliography Subsection
     INPUT
     output = <<~OUTPUT
       #{BLANK_HDR}
            <sections>
              <clause id="_" branch-number='1bis' type='scope' inline-header='false' obligation='normative'>
                <title id="_">Scope</title>
                <p id='_'>Text</p>
              </clause>
              <terms id="_" branch-number='3bis' obligation='normative'>
                <title id="_">Terms and definitions</title>
                <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
                <term id="_" anchor="term-Term1" branch-number='4bis'>
                  <preferred><expression><name>Term1</name></expression></preferred>
                </term>
              </terms>
              <terms id="_" branch-number='5bis' obligation='normative'>
                <title id="_">Terms, definitions, symbols and abbreviated terms</title>
                <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
                <clause id="_" branch-number='6bis' inline-header='false' obligation='normative'>
                  <title id="_">Introduction</title>
                  <clause id="_" branch-number='7bis' inline-header='false' obligation='normative'>
                    <title id="_">Intro 1</title>
                  </clause>
                </clause>
                <term id="_" anchor="term-Intro-2" branch-number='8bis'>
                  <preferred><expression><name>Intro 2</name></expression></preferred>
                </term>
                <definitions id="_" branch-number='9bis' obligation='normative'>
                  <title id="_">Symbols and abbreviated terms</title>
                  <clause id="_" branch-number='10bis' inline-header='false' obligation='normative'>
                    <title id="_">General</title>
                  </clause>
                  <definitions id="_" branch-number='11bis' type='symbols' obligation='normative'>
                    <title id="_">Symbols</title>
                  </definitions>
                </definitions>
              </terms>
              <definitions id="_" branch-number='12bis' type='abbreviated_terms' obligation='normative'>
                <title id="_">Abbreviated terms</title>
              </definitions>
              <clause id="_" branch-number='13bis' inline-header='false' obligation='normative'>
                <title id="_">Clause 4</title>
                <clause id="_" branch-number='14bis' inline-header='false' obligation='normative'>
                  <title id="_">Introduction</title>
                </clause>
                <clause id="_" branch-number='15bis' inline-header='false' obligation='normative'>
                  <title id="_">Clause 4.2</title>
                </clause>
              </clause>
              <clause id="_" branch-number='16bis' inline-header='false' obligation='normative'>
                <title id="_">Terms and Definitions</title>
              </clause>
            </sections>
            <annex id="_" branch-number='17bis' inline-header='false' obligation='normative'>
              <title id="_">Annex</title>
              <clause id="_" branch-number='18bis' inline-header='false' obligation='normative'>
                <title id="_">Annex A.1</title>
              </clause>
            </annex>
            <bibliography>
              <references id="_" branch-number='2bis' normative='true' obligation='informative'>
                <title id="_">Normative references</title>
                <p id='_'>There are no normative references in this document.</p>
              </references>
              <clause id="_" branch-number='19bis' obligation='informative'>
                <title id="_">Bibliography</title>
                <references id="_" branch-number='20bis' normative='false' obligation='informative'>
                  <title id="_">Bibliography Subsection</title>
                </references>
              </clause>
            </bibliography>
          </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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

       [language=en,script=Latn]
       == Executive summary

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

       [bibliography,language=en,script=Latn]
       == Bibliography

       [language=en,script=Latn]
       === Bibliography Subsection
     INPUT
     output = <<~OUTPUT
       #{BLANK_HDR.sub('<status>', '<abstract> <p>Text</p> </abstract><status>')}
                              <preface>
              <abstract id="_" language="en" script="Latn">
                 <title id="_">Abstract</title>
                 <p id="_">Text</p>
              </abstract>
              <foreword id="_" language="en" script="Latn" obligation="informative">
                 <title id="_">Foreword</title>
                 <p id="_">Text</p>
              </foreword>
              <introduction id="_" language="en" script="Latn" obligation="informative">
                 <title id="_">Introduction</title>
                 <clause id="_" language="en" script="Latn" inline-header="false" obligation="informative">
                    <title id="_">Introduction Subsection</title>
                 </clause>
              </introduction>
              <clause id="_" language="en" script="Latn" inline-header="false" obligation="informative">
                 <title id="_">Dedication</title>
              </clause>
              <acknowledgements id="_" language="en" script="Latn" obligation="informative">
                 <title id="_">Acknowledgements</title>
              </acknowledgements>
             <executivesummary id="_" language="en" script="Latn" obligation="informative">
               <title id="_">Executive summary</title>
             </executivesummary>
           </preface>
           <sections>
              <clause id="_" language="en" script="Latn" type="scope" inline-header="false" obligation="normative">
                 <title id="_">Scope</title>
                 <p id="_">Text</p>
              </clause>
              <terms id="_" language="en" script="Latn" obligation="normative">
                 <title id="_">Terms and definitions</title>
                 <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                 <term id="_" anchor="term-Term1" language="en" script="Latn">
                    <preferred>
                       <expression>
                          <name>Term1</name>
                       </expression>
                    </preferred>
                 </term>
              </terms>
              <clause id="_" language="en" script="Latn" obligation="normative" type="terms">
                 <title id="_">Terms, definitions, symbols and abbreviated terms</title>
                 <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                 <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
                    <title id="_">Introduction</title>
                    <clause id="_" inline-header="false" obligation="normative">
                       <title id="_">Intro 1</title>
                    </clause>
                 </clause>
                 <terms id="_" language="en" script="Latn" obligation="normative">
                    <title id="_">Intro 2</title>
                    <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
                       <title id="_">Intro 3</title>
                    </clause>
                 </terms>
                 <clause id="_" language="en" script="Latn" obligation="normative" type="terms">
                    <title id="_">Intro 4</title>
                    <terms id="_" language="en" script="Latn" obligation="normative">
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
                 <terms id="_" language="en" script="Latn" obligation="normative">
                    <title id="_">Normal Terms</title>
                    <term id="_" anchor="term-Term2">
                       <preferred>
                          <expression>
                             <name>Term2</name>
                          </expression>
                       </preferred>
                    </term>
                 </terms>
                 <definitions id="_" language="en" script="Latn" obligation="normative">
                    <title id="_">Symbols and abbreviated terms</title>
                    <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
                       <title id="_">General</title>
                    </clause>
                    <definitions id="_" type="symbols" obligation="normative">
                       <title id="_">Symbols</title>
                    </definitions>
                 </definitions>
              </clause>
              <definitions id="_" language="en" script="Latn" type="abbreviated_terms" obligation="normative">
                 <title id="_">Abbreviated terms</title>
              </definitions>
              <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
                 <title id="_">Clause 4</title>
                 <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
                    <title id="_">Introduction</title>
                 </clause>
                 <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
                    <title id="_">Clause 4.2</title>
                 </clause>
              </clause>
              <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
                 <title id="_">Terms and Definitions</title>
              </clause>
           </sections>
           <annex id="_" language="en" script="Latn" inline-header="false" obligation="normative">
              <title id="_">Annex</title>
              <clause id="_" language="en" script="Latn" inline-header="false" obligation="normative">
                 <title id="_">Annex A.1</title>
              </clause>
           </annex>
           <bibliography>
              <references id="_" language="en" script="Latn" normative="true" obligation="informative">
                 <title id="_">Normative references</title>
                 <p id="_">There are no normative references in this document.</p>
              </references>
              <clause id="_" language="en" script="Latn" obligation="informative">
                 <title id="_">Bibliography</title>
                 <references id="_" language="en" script="Latn" normative="false" obligation="informative">
                    <title id="_">Bibliography Subsection</title>
                 </references>
              </clause>
           </bibliography>
        </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
   end

   it "processes sections with title, type, and unnumbered attributes" do
     input = <<~INPUT
       #{ASCIIDOC_BLANK_HDR}
       .Foreword

       Text

       [abstract%unnumbered]
       == Περίληψη

       Text

       [%unnumbered,heading=introduction]
       == Εισαγωγή

       [%unnumbered]
       === Introduction Subsection

       [%unnumbered,heading=acknowledgements]
       == Ευχαριστίες

       [%unnumbered,heading=executivesummary]
       == Εκτελεστική Περίληψη

       [%unnumbered,heading=normative references]
       == Κανονιστικές Παραπομπές

       [%unnumbered,heading=terms and definitions]
       == Όροι και Ορισμοί

       [%unnumbered]
       === Term1

       [%unnumbered,heading="terms, definitions, symbols and abbreviated terms"]
       == Όροι, Ορισμοί, Σύμβολα και Συντομογραφίες

       [%unnumbered]
       === Normal Terms

       [%unnumbered]
       ==== Term2

       [%unnumbered,heading=symbols]
       === Σύμβολα και Συντομογραφίες

       [%unnumbered,heading=abbreviated terms]
       == Σύμβολα και Συντομογραφίες

       [%unnumbered,type=ABC]
       == Clause 4

       [%unnumbered,type=DEF]
       === Introduction

       [%unnumbered]
       === Clause 4.2

       [appendix%unnumbered]
       == Annex

       [%unnumbered]
       === Annex A.1

       [%unnumbered,heading=bibliography]
       == Βιβλιογραφία

       [%unnumbered]
       === Bibliography Subsection
     INPUT
     output = <<~OUTPUT
       #{BLANK_HDR.sub('<status>', '<abstract> <p>Text</p> </abstract><status>')}
           <preface>
              <abstract id="_" unnumbered="true">
                 <title id="_">Abstract</title>
                 <p id="_">Text</p>
              </abstract>
              <foreword id="_" obligation="informative">
                 <title id="_">Foreword</title>
                 <p id="_">Text</p>
              </foreword>
              <introduction id="_" unnumbered="true" obligation="informative">
                 <title id="_">Introduction</title>
                 <clause id="_" unnumbered="true" inline-header="false" obligation="informative">
                    <title id="_">Introduction Subsection</title>
                 </clause>
              </introduction>
              <acknowledgements id="_" unnumbered="true" obligation="informative">
                 <title id="_">Acknowledgements</title>
              </acknowledgements>
              <executivesummary id="_" unnumbered="true" obligation="informative">
                 <title id="_">Executive summary</title>
              </executivesummary>
           </preface>
           <sections>
              <terms id="_" unnumbered="true" obligation="normative">
                 <title id="_">Terms and definitions</title>
                 <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                 <term id="_" anchor="term-Term1" unnumbered="true">
                    <preferred>
                       <expression>
                          <name>Term1</name>
                       </expression>
                    </preferred>
                 </term>
              </terms>
              <clause id="_" unnumbered="true" obligation="normative" type="terms">
                 <title id="_">Terms, definitions and symbols</title>
                 <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                 <terms id="_" unnumbered="true" obligation="normative">
                    <title id="_">Normal Terms</title>
                    <term id="_" anchor="term-Term2" unnumbered="true">
                       <preferred>
                          <expression>
                             <name>Term2</name>
                          </expression>
                       </preferred>
                    </term>
                 </terms>
                 <definitions id="_" unnumbered="true" type="symbols" obligation="normative">
                    <title id="_">Symbols</title>
                 </definitions>
              </clause>
              <definitions id="_" unnumbered="true" type="abbreviated_terms" obligation="normative">
                 <title id="_">Abbreviated terms</title>
              </definitions>
              <clause id="_" unnumbered="true" type="ABC" inline-header="false" obligation="normative">
                 <title id="_">Clause 4</title>
                 <clause id="_" unnumbered="true" type="DEF" inline-header="false" obligation="normative">
                    <title id="_">Introduction</title>
                 </clause>
                 <clause id="_" unnumbered="true" inline-header="false" obligation="normative">
                    <title id="_">Clause 4.2</title>
                 </clause>
              </clause>
           </sections>
           <annex id="_" unnumbered="true" inline-header="false" obligation="normative">
              <title id="_">Annex</title>
              <clause id="_" unnumbered="true" inline-header="false" obligation="normative">
                 <title id="_">Annex A.1</title>
              </clause>
           </annex>
           <bibliography>
              <references id="_" unnumbered="true" normative="true" obligation="informative">
                 <title id="_">Normative references</title>
                 <p id="_">There are no normative references in this document.</p>
              </references>
              <clause id="_" unnumbered="true" obligation="informative">
                 <title id="_">Bibliography</title>
                 <references id="_" unnumbered="true" normative="false" obligation="informative">
                    <title id="_">Bibliography Subsection</title>
                 </references>
              </clause>
           </bibliography>
        </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
   end

   it "processes nested sections with title attributes" do
     input = <<~INPUT
       #{ASCIIDOC_BLANK_HDR}

       == First section

       [heading=normative references]
       === Κανονιστικές Παραπομπές

       [heading=terms and definitions]
       === Όροι και Ορισμοί

       ==== Term1

       [heading="terms, definitions, symbols and abbreviated terms"]
       === Όροι, Ορισμοί, Σύμβολα και Συντομογραφίες

       ==== Normal Terms

       ===== Term2

       [heading=symbols]
       ==== Σύμβολα και Συντομογραφίες

       [heading=abbreviated terms]
       === Σύμβολα και Συντομογραφίες

     INPUT
     output = <<~OUTPUT
       #{BLANK_HDR}
          <sections>
              <clause id="_" inline-header="false" obligation="normative">
                 <title id="_">First section</title>
                 <references id="_" normative="true" obligation="informative">
                    <title id="_">Κανονιστικές Παραπομπές</title>
                 </references>
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
                    <title id="_">Terms, definitions and symbols</title>
                    <terms id="_" obligation="normative">
                       <title id="_">Normal Terms</title>
                       <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
                       <term id="_" anchor="term-Term2">
                          <preferred>
                             <expression>
                                <name>Term2</name>
                             </expression>
                          </preferred>
                       </term>
                    </terms>
                    <definitions id="_" type="symbols" obligation="normative">
                       <title id="_">Symbols</title>
                    </definitions>
                 </clause>
                 <definitions id="_" type="abbreviated_terms" obligation="normative">
                    <title id="_">Abbreviated terms</title>
                 </definitions>
              </clause>
           </sections>
        </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)

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
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
         <title id="_">Clause 1</title>
         <clause id="_" inline-header="false" obligation="informative">
         <title id="_">Clause 1a</title>
       </clause>
       </clause>
       <clause id="_" inline-header="false" obligation="normative">
         <title id="_">Clause 2</title>
       </clause>
       </sections><annex id="_" inline-header="false" obligation="informative">
         <title id="_">Annex</title>
       </annex>
       </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
         <title id="_">Clause 1</title>
         <clause id="_" inline-header="true" obligation="normative">
         <title id="_">Clause 1a</title>
       </clause>
       </clause>
       </sections><annex id="_" inline-header="false" obligation="normative">
         <title id="_">Annex A</title>
         <clause id="_" inline-header="true" obligation="normative">
         <title id="_">Clause Aa</title>
       </clause>
       </annex>
       </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
         <title id="_">Clause 1</title>
         <clause id="_" inline-header="false" obligation="normative">
       </clause>
       </clause>
       </sections>
       </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
            <clause id="_" anchor="t1" inline-header="false" obligation="informative">
              <title id="_">Terms and definitions</title>
              <clause id="_" anchor="t2" inline-header="false" obligation="informative">
                <title id="_">Term1</title>
              </clause>
            </clause>
          </preface>
         <sections> </sections>
         <annex id='_' obligation='' language='fr' script=''>
           <definitions id="_" anchor="sym" language='fr' obligation="normative">
             <title id="_">Symbols and abbreviated terms</title>
           </definitions>
         </annex>
         <annex id='_' obligation='' language='' script=''>
           <references id="_" anchor="app" obligation='informative' normative="false">
             <title id="_">Normative Reference</title>
           </references>
         </annex>
       </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
   end

   it "recognises special titles despite following indexterms" do
     input = <<~INPUT
       #{ASCIIDOC_BLANK_HDR}

       == Scope (((indexterm)))
     INPUT
     output = <<~OUTPUT
       #{BLANK_HDR}
       <sections>
         <clause id="_" type='scope' inline-header='false' obligation='normative'>
           <title id="_">Scope<index><primary>indexterm</primary></index></title>
         </clause>
       </sections>
       </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
              <title id="_">Foreword</title>
              <p id='_'>ABC</p>
            </foreword>
          </preface>
          <sections>
            <floating-title id="_" depth='1' type='floating-title'>
              I am a top-level
              <em>floating</em>
               title
            </floating-title>
            <clause id="_" inline-header='false' obligation='normative'>
              <title id="_">Clause 1</title>
              <floating-title id="_" depth='2' type='floating-title'>
                I am a
                <em>floating</em>
                 title
              </floating-title>
              <clause id="_" inline-header='false' obligation='normative'>
                <title id="_">Clause 1.2</title>
              </clause>
            </clause>
            <floating-title id="_" depth='1' type='floating-title'>Another top-level floating title</floating-title>
            <clause id="_" inline-header='false' obligation='normative'>
              <title id="_">Clause 2</title>
            </clause>
          </sections>
          </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
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
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
   end

   it "conditionally supports annex appendixes" do
     input = <<~INPUT
       #{ASCIIDOC_BLANK_HDR}

       [appendix]
       == Mammals

       [%appendix]
       === Cetaceae

     INPUT
     output = <<~OUTPUT
       #{BLANK_HDR}
           <sections>
        </sections>
           <annex id="_" inline-header="false" obligation="normative">
              <title id="_">Mammals</title>
              <clause id="_" inline-header="false" obligation="normative">
                 <title id="_">Cetaceae</title>
              </clause>
           </annex>
        </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
     mock_support_appendix
     output = <<~OUTPUT
       #{BLANK_HDR}
           <sections>
        </sections>
           <annex id="_" inline-header="false" obligation="normative">
              <title id="_">Mammals</title>
               <appendix id="_" inline-header="false" obligation="normative">
                 <title id="_">Cetaceae</title>
              </appendix>
           </annex>
        </metanorma>
     OUTPUT
     expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
       .to be_equivalent_to Xml::C14n.format(output)
   end

   private

   def mock_support_appendix
     allow_any_instance_of(Metanorma::Standoc::Section)
       .to receive(:support_appendix?).and_return(true)
   end
 end
