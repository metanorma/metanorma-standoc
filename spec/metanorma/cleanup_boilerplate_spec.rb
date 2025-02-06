require "spec_helper"
require "relaton_iec"
require "fileutils"

RSpec.describe Metanorma::Standoc do
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
      <bibliography><references id="_normative_references" obligation="informative" normative="true"><title>Normative references</title>
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
      </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
      <bibliography><references id="_normative_references" obligation="informative" normative="true"><title>Normative references</title>
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
      </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)

    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      [.boilerplate]
      --
      This is extraneous information
      --

      * [[[iso216,ISO 216]]], _Reference_

      This is also extraneous information
    INPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "provides default boilerplate in designated location in Normative References" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      [NOTE,type=boilerplate]
      --
      (DefauLT)
      --

      * [[[iso216,ISO 216]]], _Reference_

      This is also extraneous information
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections></sections>
               <bibliography>
           <references id="_normative_references" normative="true" obligation="informative">
             <title>Normative references</title>
             <p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
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
             <p id="_">This is also extraneous information</p>
           </references>
         </bibliography>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)

    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      [.boilerplate]
      --
      (DefauLT)
      --

      * [[[iso216,ISO 216]]], _Reference_

      This is also extraneous information
    INPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)

    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      [.boilerplate]
      --
      (DefauLT)
      --

      This is also extraneous information
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections></sections>
               <bibliography>
           <references id="_normative_references" normative="true" obligation="informative">
             <title>Normative references</title>
             <p id="_">There are no normative references in this document.</p>
             <p id="_">This is also extraneous information</p>
           </references>
         </bibliography>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "infers location for boilerplate in Normative References #1" do
    mock_norm_ref_boilerplate_insert_iso
    mock_sectiontype_iso(3)
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == A clause

      [bibliography]
      === Normative References

      * [[[iso216,ISO 216]]], _Reference_

      === Another clause
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <sections>
           <clause id="_a_clause" inline-header="false" obligation="normative">
             <title>A clause</title>
             <references id="_normative_references" normative="true" obligation="informative">
               <title>Normative References</title>
               <p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
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
             </references>
             <clause id="_another_clause" inline-header="false" obligation="normative">
               <title>Another clause</title>
             </clause>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "infers location for boilerplate in Normative References #2" do
    mock_norm_ref_boilerplate_insert_iso
    mock_sectiontype_iso(4)
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == A clause

      [bibliography]
      === Normative References

      * [[[iso216,ISO 216]]], _Reference_

      [bibliography]
      === Another clause

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <sections>
           <clause id="_a_clause" inline-header="false" obligation="normative">
             <title>A clause</title>
             <p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
             <references id="_normative_references" normative="true" obligation="informative">
               <title>Normative References</title>
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
             </references>
             <references id="_another_clause" normative="false" obligation="informative">
               <title>Another clause</title>
             </references>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "infers location for boilerplate in Normative References #3" do
    mock_norm_ref_boilerplate_insert_iso
    mock_sectiontype_iso(3)
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == A clause

      [bibliography]
      === Normative References

      * [[[iso216,ISO 216]]], _Reference_

      [type=boilerplate]
      === Another clause

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <clause id="_a_clause" inline-header="false" obligation="normative">
             <title>A clause</title>
             <p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
             <references id="_normative_references" normative="true" obligation="informative">
               <title>Normative References</title>
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
             </references>
             <clause id="_another_clause" type="boilerplate" inline-header="false" obligation="normative">
               <title>Another clause</title>
             </clause>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "preserves user-supplied boilerplate in Terms & Definitions" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and definitions

      [.boilerplate]
      --
      This is extraneous information
      --

      === Term 1
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <terms id="_terms_and_definitions" obligation="normative">
             <title>Terms and definitions</title>
             <p id="_">This is extraneous information</p>
             <term id="term-Term-1">
               <preferred>
                 <expression>
                   <name>Term 1</name>
                 </expression>
               </preferred>
             </term>
           </terms>
         </sections>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "provides default boilerplate in designated location in Terms & Definitions" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and definitions

      [.boilerplate]
      --
      (DefauLT)
      --

      === Term 1
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <terms id="_terms_and_definitions" obligation="normative">
             <title>Terms and definitions</title>
                <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
             <term id="term-Term-1">
               <preferred>
                 <expression>
                   <name>Term 1</name>
                 </expression>
               </preferred>
             </term>
           </terms>
         </sections>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)

    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and definitions

      [.boilerplate]
      --
      (DefauLT)
      --

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <terms id="_terms_and_definitions" obligation="normative">
             <title>Terms and definitions</title>
                <p id="_">No terms and definitions are listed in this document.</p>
           </terms>
         </sections>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

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
               <terms id="_terms_and_definitions" obligation="normative"><title>Terms and definitions</title>
               <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
      <p id='_'>I am boilerplate</p>
      <ul id='_'>
        <li>
          <p id='_'>So am I</p>
        </li>
      </ul>
             <term id="term-Time">
             <preferred><expression><name>Time</name></expression></preferred>
               <definition><verbal-definition><p id="_">This paragraph is extraneous</p></verbal-definition></definition>
             </term></terms>
             </sections>
             </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "infers location for boilerplate in Terms & Definitions #1" do
    mock_termdef_boilerplate_insert_iso(1)
    mock_sectiontype_iso(5)

    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == A clause

      [heading=terms and definitions]
      === Terms and definitions

      ==== Term 1

      === Another clause
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <clause id="_a_clause" inline-header="false" obligation="normative">
             <title>A clause</title>
             <terms id="_terms_and_definitions" obligation="normative">
               <title>Terms and definitions</title>
               <p id="_">For the purposes of this document,
           the following terms and definitions apply.</p>
               <term id="term-Term-1">
                 <preferred>
                   <expression>
                     <name>Term 1</name>
                   </expression>
                 </preferred>
               </term>
             </terms>
             <clause id="_another_clause" inline-header="false" obligation="normative">
               <title>Another clause</title>
             </clause>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "infers location for boilerplate in Terms & Definitions #2" do
    mock_termdef_boilerplate_insert_iso(1)
    mock_sectiontype_iso(7)
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == A clause

      [heading=terms and definitions]
      === Terms and definitions

      ==== Term 1

      [heading=terms and definitions]
      === More terms and definitions

      ==== Term 2

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <clause id="_a_clause" inline-header="false" obligation="normative">
             <title>A clause</title>
             <terms id="_terms_and_definitions" obligation="normative">
               <title>Terms and definitions</title>
               <p id="_">For the purposes of this document,
           the following terms and definitions apply.</p>
               <term id="term-Term-1">
                 <preferred>
                   <expression>
                     <name>Term 1</name>
                   </expression>
                 </preferred>
               </term>
             </terms>
             <terms id="_more_terms_and_definitions" obligation="normative">
               <title>More terms and definitions</title>
               <term id="term-Term-2">
                 <preferred>
                   <expression>
                     <name>Term 2</name>
                   </expression>
                 </preferred>
               </term>
             </terms>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes boilerplate for nested terms sections, multiple boilerplates" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == First section

      === Normative References

      [heading=Terms and definitions]
      === Terms and definitions

      ==== Term1

      [heading=Terms, definitions, symbols and abbreviated terms]
      === Terms, definitions, symbols and abbreviated terms

      ==== Normal Terms

      ===== Term2

      ==== Symbols

      === Abbreviated terms

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                <sections>
           <clause id="_first_section" inline-header="false" obligation="normative">
             <title>First section</title>
             <clause id="_normative_references" inline-header="false" obligation="normative">
               <title>Normative References</title>
             </clause>
             <terms id="_terms_and_definitions" obligation="normative">
               <title>Terms and definitions</title>
                <p id="_">For the purposes of this document,
                the following terms and definitions apply.</p>
               <term id="term-Term1">
                 <preferred>
                   <expression>
                     <name>Term1</name>
                   </expression>
                 </preferred>
               </term>
             </terms>
             <clause id="_terms_definitions_symbols_and_abbreviated_terms" inline-header="false" obligation="normative">
               <title>Terms, definitions, symbols and abbreviated terms</title>
               <clause id="_normal_terms" inline-header="false" obligation="normative">
                 <title>Normal Terms</title>
                 <clause id="_term2" inline-header="false" obligation="normative">
                   <title>Term2</title>
                 </clause>
               </clause>
               <definitions id="_symbols" type="symbols" obligation="normative">
                 <title>Symbols</title>
               </definitions>
             </clause>
             <definitions id="_abbreviated_terms" type="abbreviated_terms" obligation="normative">
               <title>Abbreviated terms</title>
             </definitions>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes boilerplate for nested terms sections, single boilerplate" do
    mock_termdef_boilerplate_insert_iso(1)
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == First section

      === Normative References

      [heading=Terms and definitions]
      === Terms and definitions

      ==== Term1

      [heading=Terms, definitions, symbols and abbreviated terms]
      === Terms, definitions, symbols and abbreviated terms

      ==== Normal Terms

      ===== Term2

      ==== Symbols

      === Abbreviated terms

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                <sections>
           <clause id="_first_section" inline-header="false" obligation="normative">
             <title>First section</title>
             <clause id="_normative_references" inline-header="false" obligation="normative">
               <title>Normative References</title>
             </clause>
             <terms id="_terms_and_definitions" obligation="normative">
               <title>Terms and definitions</title>
                <p id="_">For the purposes of this document,
                the following terms and definitions apply.</p>
               <term id="term-Term1">
                 <preferred>
                   <expression>
                     <name>Term1</name>
                   </expression>
                 </preferred>
               </term>
             </terms>
             <clause id="_terms_definitions_symbols_and_abbreviated_terms" inline-header="false" obligation="normative">
               <title>Terms, definitions, symbols and abbreviated terms</title>
               <clause id="_normal_terms" inline-header="false" obligation="normative">
                 <title>Normal Terms</title>
                 <clause id="_term2" inline-header="false" obligation="normative">
                   <title>Term2</title>
                 </clause>
               </clause>
               <definitions id="_symbols" type="symbols" obligation="normative">
                 <title>Symbols</title>
               </definitions>
             </clause>
             <definitions id="_abbreviated_terms" type="abbreviated_terms" obligation="normative">
               <title>Abbreviated terms</title>
             </definitions>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
      </sections><bibliography><references id="_normative_references" obligation="informative" normative="true">
        <title>Normative references</title><p id="_">There are no normative references in this document.</p>
      </references></bibliography>
      </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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

         </sections><bibliography><references id="_normative_references" obligation="informative" normative="true">
           <title>Normative references</title><p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
           <bibitem id="a">
           <formattedref format="application/x-isodoc+xml">A</formattedref>
           <docidentifier>b</docidentifier>
         </bibitem>
         </references></bibliography>
         </metanorma>

    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
      </sections><bibliography><references id="_normative_references" obligation="informative" normative="true">
        <title>Références normatives</title><p id="_">Le présent document ne contient aucune référence normative.</p>
      </references></bibliography>
      </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "places single terms boilerplate in expected location for ISO" do
    mock_termdef_boilerplate_insert_iso(1)
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Terms and definitions

      === Terms

      ==== term

      === Symbols

    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
                 <sections>
          <clause id="_terms_and_definitions" obligation="normative" type="terms">
            <title>Terms, definitions and symbols</title>
            <terms id="_terms" obligation="normative">
              <title>Terms and definitions</title>
            <p id="_">For the purposes of this document,
          the following terms and definitions apply.</p>
              <term id="term-term">
                <preferred>
                  <expression>
                    <name>term</name>
                  </expression>
                </preferred>
              </term>
            </terms>
            <definitions id="_symbols" type="symbols" obligation="normative">
              <title>Symbols</title>
            </definitions>
          </clause>
        </sections>
      </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "places single terms boilerplate at root if there are multiple terms collections" do
    mock_termdef_boilerplate_insert_iso(1)
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Terms and definitions

      === Terms

      ==== term

      === Terms 2

      ==== term

    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
        <sections>
          <clause id="_terms_and_definitions" obligation="normative" type="terms">
            <title>Terms and definitions</title>
            <p id="_">For the purposes of this document,
          the following terms and definitions apply.</p>
            <terms id="_terms" obligation="normative">
              <title>Terms</title>
              <term id="term-term">
                <preferred>
                  <expression>
                    <name>term</name>
                  </expression>
                </preferred>
              </term>
            </terms>
            <terms id="_terms_2" obligation="normative">
              <title>Terms 2</title>
              <term id="term-term-1">
                <preferred>
                  <expression>
                    <name>term</name>
                  </expression>
                </preferred>
              </term>
            </terms>
          </clause>
        </sections>
      </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "places single terms boilerplate at root if there are clauses preceding the terms collection, other than boilerplate" do
    mock_termdef_boilerplate_insert_iso(1)
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Terms and definitions

      [.nonterm]
      === Terms0
      Boilerplate

      === Terms

      ==== term


    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
                <sections>
          <clause id="_terms_and_definitions" obligation="normative" type="terms">
            <title>Terms and definitions</title>
            <p id="_">For the purposes of this document,
          the following terms and definitions apply.</p>
            <clause id="_terms0" inline-header="false" obligation="normative">
              <title>Terms0</title>
              <p id="_">Boilerplate</p>
            </clause>
            <terms id="_terms" obligation="normative">
              <title>Terms</title>
              <term id="term-term">
                <preferred>
                  <expression>
                    <name>term</name>
                  </expression>
                </preferred>
              </term>
            </terms>
          </clause>
        </sections>
      </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes terms & definitions with external source" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      Foreword

      [source="iso1234,iso5678"]
      == Terms and Definitions

      === Term1

      [bibliography]
      == Bibliography
      * [[[iso1234,A]]]
      * [[[iso5678,B]]]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                   <termdocsource bibitemid="iso1234"/><termdocsource bibitemid="iso5678"/>
              <preface><foreword id='_' obligation="informative">
               <title>Foreword</title>
               <p id="_">Foreword</p>
             </foreword></preface>
             <sections>
             <terms id="_terms_and_definitions" obligation="normative">
                <title>Terms and definitions</title>
                <p id="_">
                   For the purposes of this document, the terms and definitions given in
                   <eref bibitemid="iso1234" citeas="A"/>
                   and
                   <eref bibitemid="iso5678" citeas="B"/>
                   and the following apply.
                </p>
                <term id="term-Term1">
                   <preferred>
                      <expression>
                         <name>Term1</name>
                      </expression>
                   </preferred>
                </term>
             </terms>
          </sections>
          <bibliography>
             <references id="_bibliography" normative="false" obligation="informative">
                <title>Bibliography</title>
                <bibitem id="iso1234">
                   <formattedref format="application/x-isodoc+xml">[NO INFORMATION AVAILABLE]</formattedref>
                   <docidentifier>A</docidentifier>
                </bibitem>
                <bibitem id="iso5678">
                   <formattedref format="application/x-isodoc+xml">[NO INFORMATION AVAILABLE]</formattedref>
                   <docidentifier>B</docidentifier>
                </bibitem>
             </references>
          </bibliography>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
      <terms id="_terms_and_definitions" obligation="normative">
         <title>Terms and definitions</title><p id="_">No terms and definitions are listed in this document.</p>
      </terms></sections>
      </metanorma>

    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes empty terms & definitions with external source" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      Foreword

      [source="iso1234,iso5678"]
      == Terms and Definitions

      [bibliography]
      == Bibliography
      * [[[iso1234,A]]]
      * [[[iso5678,B]]]
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
            <termdocsource bibitemid="iso1234"/><termdocsource bibitemid="iso5678"/>
       <preface><foreword id='_' obligation="informative">
        <title>Foreword</title>
        <p id="_">Foreword</p>
      </foreword></preface>
      <sections>
             <terms id="_terms_and_definitions" obligation="normative">
                <title>Terms and definitions</title>
                <p id="_">
                   For the purposes of this document, the terms and definitions given in
                   <eref bibitemid="iso1234" citeas="A"/>
                   and
                   <eref bibitemid="iso5678" citeas="B"/>
                   apply.
                </p>
             </terms>
          </sections>
          <bibliography>
             <references id="_bibliography" normative="false" obligation="informative">
                <title>Bibliography</title>
                <bibitem id="iso1234">
                   <formattedref format="application/x-isodoc+xml">[NO INFORMATION AVAILABLE]</formattedref>
                   <docidentifier>A</docidentifier>
                </bibitem>
                <bibitem id="iso5678">
                   <formattedref format="application/x-isodoc+xml">[NO INFORMATION AVAILABLE]</formattedref>
                   <docidentifier>B</docidentifier>
                </bibitem>
             </references>
          </bibliography>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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

      [bibliography]
      == Bibliography
      * [[[iso1234,A]]]
      * [[[iso5678,B]]]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR.sub(%r{<language>en</language>}, '<language>fr</language>')}
              <termdocsource bibitemid="iso1234"/><termdocsource bibitemid="iso5678"/>
         <preface><foreword id='_' obligation="informative">
          <title>Avant-propos</title>
          <p id="_">Foreword</p>
        </foreword></preface>
                  <sections>
             <terms id="_terms_and_definitions" obligation="normative">
                <title>Termes et définitions</title>
                <p id="_">
                   Pour les besoins du présent document, les termes et définitions de
                   <eref bibitemid="iso1234" citeas="A"/>
                   et
                   <eref bibitemid="iso5678" citeas="B"/>
                   s’appliquent.
                </p>
             </terms>
          </sections>
          <bibliography>
             <references id="_bibliography" normative="false" obligation="informative">
                <title>Bibliographie</title>
                <bibitem id="iso1234">
                   <formattedref format="application/x-isodoc+xml">[PAS D’INFORMATION DISPONIBLE]</formattedref>
                   <docidentifier>A</docidentifier>
                </bibitem>
                <bibitem id="iso5678">
                   <formattedref format="application/x-isodoc+xml">[PAS D’INFORMATION DISPONIBLE]</formattedref>
                   <docidentifier>B</docidentifier>
                </bibitem>
             </references>
          </bibliography>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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

      [bibliography]
      == Bibliography
      * [[[iso1234,A]]]
      * [[[iso5678,B]]]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR.sub(%r{<language>en</language>}, '<language>zh</language>').sub(%r{<script>Latn</script>}, '<script>Hans</script>')}
        <termdocsource bibitemid="iso1234"/><termdocsource bibitemid="iso5678"/><preface><foreword id='_' obligation="informative">
          <title>前言</title>
          <p id="_">Foreword</p>
        </foreword></preface>
        <sections>
             <terms id="_terms_and_definitions" obligation="normative">
                <title>术语和定义</title>
                <p id="_">
                   <eref bibitemid="iso1234" citeas="A"/>
                   和
                   <eref bibitemid="iso5678" citeas="B"/>
                   界定的术语和定义适用于本文件。
                </p>
             </terms>
          </sections>
          <bibliography>
             <references id="_bibliography" normative="false" obligation="informative">
                <title>参考文献</title>
                <bibitem id="iso1234">
                   <formattedref format="application/x-isodoc+xml">[无资料]</formattedref>
                   <docidentifier>A</docidentifier>
                </bibitem>
                <bibitem id="iso5678">
                   <formattedref format="application/x-isodoc+xml">[无资料]</formattedref>
                   <docidentifier>B</docidentifier>
                </bibitem>
             </references>
          </bibliography>
       </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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

  it "imports boilerplate file in XML" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :docstage: 10
      :boilerplate-authority: spec/assets/boilerplate.xml
      :publisher: Fred
      :pub-address: 10 Jack St + \\
      Antarctica

      == Clause 1

    INPUT
    output = <<~OUTPUT
          <metanorma xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
        <bibdata type='standard'>
          <title language='en' format='text/plain'>Document title</title>
                     <contributor>
             <role type="author"/>
             <organization>
               <name>Fred</name>
               <address>
                <formattedAddress>10 Jack St<br/>Antarctica</formattedAddress>
            </address>
             </organization>
           </contributor>
           <contributor>
             <role type="publisher"/>
             <organization>
               <name>Fred</name>
               <address>
                 <formattedAddress>10 Jack St<br/>Antarctica</formattedAddress>
               </address>
             </organization>
           </contributor>
          <language>en</language>
          <script>Latn</script>
          <status>
            <stage>10</stage>
          </status>
          <copyright>
            <from>#{Date.today.year}</from>
                  <owner>
        <organization>
          <name>Fred</name>
          <address>
            <formattedAddress>10 Jack St<br/>Antarctica</formattedAddress>
          </address>
        </organization>
      </owner>
          </copyright>
          <ext>
            <doctype>standard</doctype>
            <flavor>standoc</flavor>
          </ext>
        </bibdata>
        <boilerplate>
          <text>10</text>
          <text>10 Jack St<br/>Antarctica</text>
        </boilerplate>
        <sections>
          <clause id='_clause_1' inline-header='false' obligation='normative'>
            <title>Clause 1</title>
          </clause>
        </sections>
      </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "imports boilerplate file in ADOC" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :docstage: 10
      :boilerplate-authority: spec/assets/boilerplate.adoc
      :publisher: Fred
      :pub-address: 10 Jack St + \\
      Antarctica

      == Clause 1

    INPUT
    output = <<~OUTPUT
      <metanorma xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
                   <boilerplate>
           <copyright-statement>
             <clause id="B" inline-header="false" obligation="normative">
               <p id="_">A</p>
             </clause>
           </copyright-statement>
           <license-statement>
             <clause id="_" inline-header="false" obligation="normative">
               <title>clause 1</title>
             </clause>
             <clause id="_" inline-header="false" obligation="normative">
               <title>clause 2</title>
             </clause>
           </license-statement>
           <feedback-statement>
             <p id="_">10 Jack St<br/>Antarctica</p>
           </feedback-statement>
           <clause id="_" inline-header="false" obligation="normative">
             <title>Random Title</title>
             <clause id="_" inline-header="false" obligation="normative">
               <title>feedback-statement</title>
             </clause>
           </clause>
         </boilerplate>
         <sections>
           <clause id="_clause_1" inline-header="false" obligation="normative">
             <title>Clause 1</title>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    xml.at("//xmlns:bibdata")&.remove
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "overrides boilerplate file in ADOC" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :docstage: 10
      :boilerplate-authority: spec/assets/boilerplate1.adoc
      :publisher: Fred
      :pub-address: 10 Jack St + \\
      Antarctica

      == Clause 1

    INPUT
    output = <<~OUTPUT
      <metanorma xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
         <boilerplate>
           <license-statement>
             <clause id="_" inline-header="false" obligation="normative">
               <title>clause 3</title>
             </clause>
             <clause id="_" inline-header="false" obligation="normative">
               <title>clause 4</title>
             </clause>
           </license-statement>
           <feedback-statement>
             <p id="_">10 Jack St<br/>Antarctica</p>
           </feedback-statement>
           <clause id="_" inline-header="false" obligation="normative">
             <title>Random Title</title>
             <clause id="_" inline-header="false" obligation="normative">
               <title>feedback-statement</title>
             </clause>
           </clause>
           <legal-statement>
             <p id="_">Stuff</p>
           </legal-statement>
         </boilerplate>
         <sections>
           <clause id="_clause_1" inline-header="false" obligation="normative">
             <title>Clause 1</title>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    mock_boilerplate_file
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    xml.at("//xmlns:bibdata")&.remove
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "appends to boilerplate file in ADOC" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :docstage: 10
      :boilerplate-authority: spec/assets/boilerplate2.adoc
      :publisher: Fred
      :pub-address: 10 Jack St + \\
      Antarctica

      == Clause 1

    INPUT
    output = <<~OUTPUT
      <metanorma xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
                 <boilerplate>
              <copyright-statement>
                 <clause id="B" inline-header="false" obligation="normative">
                    <p id="_">A</p>
                 </clause>
                 <clause id="_boilerplate-copyright-statement-append">
                    <p id="_">Hello</p>
                 </clause>
              </copyright-statement>
              <license-statement>
                 <clause id="_" inline-header="false" obligation="normative">
                    <title>clause 1</title>
                 </clause>
                 <clause id="_" inline-header="false" obligation="normative">
                    <title>clause 2</title>
                 </clause>
                 <clause id="_" inline-header="false" obligation="normative">
                    <title>clause 3</title>
                 </clause>
                 <clause id="_" inline-header="false" obligation="normative">
                    <title>clause 4</title>
                 </clause>
              </license-statement>
              <feedback-statement>
                 <p id="_">
                    10 Jack St
                    <br/>
                    Antarctica
                 </p>
              </feedback-statement>
              <clause id="_" inline-header="false" obligation="normative">
                 <title>Random Title</title>
                 <clause id="_" inline-header="false" obligation="normative">
                    <title>feedback-statement</title>
                 </clause>
              </clause>
              <legal-statement>
                 <p id="_">Stuff</p>
              </legal-statement>
           </boilerplate>
           <sections>
              <clause id="_clause_1" inline-header="false" obligation="normative">
                 <title>Clause 1</title>
              </clause>
           </sections>
        </metanorma>
    OUTPUT
    mock_boilerplate_file
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    xml.at("//xmlns:bibdata")&.remove
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  private

  def mock_norm_ref_boilerplate_insert_iso
    stub_const("Metanorma::Standoc::Converter::NORM_REF",
               "//sections//references | //bibliography//references")
  end

  def mock_termdef_boilerplate_insert_iso(m)
    stub_const("Metanorma::Standoc::Converter::TERM_CLAUSE",
               "//sections//terms")

    expect_any_instance_of(Metanorma::Standoc::Converter)
      .to receive(:termdef_boilerplate_insert).exactly(m).times
      .and_wrap_original do |method, a, b|
      method.call(a, b, true)
    end
  end

  def mock_sectiontype_iso(n)
    expect_any_instance_of(Metanorma::Standoc::Converter)
      .to receive(:sectiontype).exactly(n).times
      .and_wrap_original do |method, node, level|
        if node.attr("heading")&.downcase == "terms and definitions"
          "terms and definitions"
        elsif node.attr("heading")&.downcase == "normative references"
          "normative references"
        else
          method.call(node, level)
        end
      end
  end

  def mock_boilerplate_file
    allow_any_instance_of(Metanorma::Standoc::Cleanup)
      .to receive(:boilerplate_file).and_return(
        "spec/assets/boilerplate.adoc",
      )
  end
end
