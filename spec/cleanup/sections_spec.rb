require "spec_helper"
require "relaton_iec"
require "fileutils"

RSpec.describe Metanorma::Standoc do
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
        <title id="_">Clause</title>
        <p id="_">Text</p>
      </clause>
      </sections><annex id="_" inline-header="false" obligation="normative">
        <title id="_">Clause</title>
        <p id="_">Text</p>
      </annex>
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
        <title id="_">Clause1</title>
        <clause id="_" inline-header="false" obligation="normative">
        <title id="_">Clause2</title>
        <clause id="_" inline-header="false" obligation="normative">
        <title id="_">Clause3</title>
        <clause id="_" inline-header="false" obligation="normative">
        <title id="_">Clause4</title>
        <clause id="_" inline-header="false" obligation="normative">
        <title id="_">Clause 5</title>
      <clause id="_" inline-header="false" obligation="normative">
        <title id="_">Clause 6</title>
      <clause id="_" inline-header="false" obligation="normative">
        <title id="_">Clause 7A</title>
      </clause><clause id="_" inline-header="false" obligation="normative">
        <title id="_">Clause 7B</title>
      </clause></clause><clause id="_" inline-header="false" obligation="normative">
        <title id="_">Clause 6B</title>
      </clause></clause>
      <clause id="_" inline-header="false" obligation="normative">
        <title id="_">Clause 5B</title>
      </clause></clause>
      </clause>
      </clause>
      </clause>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
           <clause id="_" inline-header="false" obligation="normative">
             <title id="_">Clause</title>
             <p id="_">Text</p>
             <clause id="_" type="toc" inline-header="false" obligation="normative">
               <title id="_">Table of contents</title>
               <p id="_">Text at the start</p>
               <clause id="_" inline-header="false" obligation="normative">
                 <title id="_">Toc 1</title>
                 <toc>
                   <ul id="_">
                     <li>
                       <p id="_">
                         <xref target="cl2"><display-text>Clause <em>A</em><stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><mi>x</mi></mstyle></math><asciimath>x</asciimath></stem></display-text></xref>
                       </p>
                       <ul id="_">
                         <li>
                           <p id="_">
                             <xref target="a1"><display-text>Clause <em>A</em><stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><mi>y</mi></mstyle></math><asciimath>y</asciimath></stem></display-text></xref>
                           </p>
                         </li>
                       </ul>
                     </li>
                   </ul>
                 </toc>
               </clause>
               <clause id="_" inline-header="false" obligation="normative">
                 <title id="_">Toc 2</title>
                 <toc>
                   <ul id="_">
                     <li>
                       <p id="_">
                         <xref target="cl2"><display-text>some text</display-text></xref>
                       </p>
                       <ul id="_">
                         <li>
                           <p id="_">
                             <xref target="a1"><display-text>some more text</display-text></xref>
                           </p>
                         </li>
                       </ul>
                     </li>
                   </ul>
                 </toc>
               </clause>
             </clause>
           </clause>
           <clause id="_" anchor="cl2" inline-header="false" obligation="normative">
             <title id="_">Clause2</title>
             <variant-title id="_" type="sub">“A” ‘B’</variant-title>
             <variant-title id="_" type="toc">Clause <em>A</em><stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><mi>x</mi></mstyle></math><asciimath>x</asciimath></stem></variant-title>
             <p id="_">Text</p>
           </clause>
         </sections>
         <annex id="_" anchor="a1" inline-header="false" obligation="normative">
           <title id="_">Clause</title>
           <variant-title id="_" type="toc">Clause <em>A</em><stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><mi>y</mi></mstyle></math><asciimath>y</asciimath></stem></variant-title>
           <p id="_">Text</p>
         </annex>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
          <title id="_">Bibliography</title>
          <references id="_" normative='false' obligation='informative'>
            <title id="_">Bibliography</title>
          </references>
      </annex>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(strip_guid(Canon.format_xml(ret.at("//xmlns:annex").to_xml)))
      .to be_equivalent_to(Canon.format_xml(output))
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
        <terms id="_" obligation='normative'>
          <title id="_">Terms and definitions</title>
          <term id="_" anchor="term-Terms-and-definitions">
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
    expect(strip_guid(Canon.format_xml(ret.at("//xmlns:annex").to_xml)))
      .to be_equivalent_to(Canon.format_xml(output))
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
           <foreword id="_" obligation="informative">
             <title id="_">Foreword</title>
           </foreword>
         </preface>
         <sections>
           <floating-title id="_" depth="1" type="floating-title">Basic layout and preliminary elements</floating-title>
           <clause id="_" type="scope" inline-header="false" obligation="normative">
             <title id="_">Scope</title>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(strip_guid(Canon.format_xml(ret.to_xml)))
      .to be_equivalent_to(Canon.format_xml(output))
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
           <foreword id="_" obligation="informative">
             <title id="_">Foreword</title>
             <p id="_">A</p>
           </foreword>
         </preface>
         <sections>
           <floating-title id="_" depth="1" type="floating-title">Basic layout and preliminary elements</floating-title>
          <note id="_">
            <p id="_">Initial Note</p>
          </note>
           <clause id="_" type="scope" inline-header="false" obligation="normative">
             <title id="_">Scope</title>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(strip_guid(Canon.format_xml(ret.to_xml)))
      .to be_equivalent_to(Canon.format_xml(output))

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
           <foreword id="_" obligation="informative">
             <title id="_">Foreword</title>
             <p id="_">A</p>
             <floating-title id="_" depth="1" type="floating-title">Basic layout and preliminary elements</floating-title>
             <p id="_">More</p>
           </foreword>
         </preface>
         <sections>
           <clause id="_" type="scope" inline-header="false" obligation="normative">
             <title id="_">Scope</title>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(strip_guid(Canon.format_xml(ret.to_xml)))
      .to be_equivalent_to(Canon.format_xml(output))
  end

  it "processes delete change clauses" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [change="modify",locality="page=27",path="//table[2]",path_end="//table[2]/following-sibling:example[1]",title="Change"]
      ==== Change Clause
      _This table contains information on polygon cells which are not included in ISO 10303-52. Remove table 2 completely and replace with:_
    INPUT
    output = <<~"OUTPUT"
                  #{BLANK_HDR}
                  <sections>
        <clause id="_" inline-header='false' obligation='normative'>
          <title id="_">Change Clause</title>
          <amend id='_' change='modify' path='//table[2]' path_end='//table[2]/following-sibling:example[1]' title='Change'>
            <description>
              <p id='_'>
                <em>
                  This table contains information on polygon cells which are not
                  included in ISO 10303-52. Remove table 2 completely and replace
                  with:
                </em>
              </p>
            </description>
          </amend>
        </clause>
      </sections>
                  </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

    it "processes modify change clauses" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [change="modify",locality="page=27",path="//table[2]",path_end="//table[2]/following-sibling:example[1]",title="Change",position="before"]
      ==== Change Clause

      autonumber:table[2]
      autonumber:note[7]

      _This table contains information on polygon cells which are not included in ISO 10303-52. Remove table 2 completely and replace with:_

      ____
      .Edges of triangle and quadrilateral cells
      |===
      2+^.^h| triangle 2+^.^h| quadrilateral
      ^.^| edge ^.^| vertices ^.^| edge ^.^| vertices
      ^.^| 1 ^.^| 1, 2 ^.^| 1 ^.^| 1, 2
      ^.^| 2 ^.^| 2, 3 ^.^| 2 ^.^| 2, 3
      ^.^| 3 ^.^| 3, 1 ^.^| 3 ^.^| 3, 4
      | | ^.^| 4 ^.^| 4, 1
      |===

      ====
      This is not generalised further.
      ====
      ____

      Any further exceptions can be ignored.
    INPUT

    output = <<~"OUTPUT"
                  #{BLANK_HDR}
           <sections>
        <clause id="_" inline-header='false' obligation='normative'>
          <title id="_">Change Clause</title>
          <amend id='_' change='modify' path='//table[2]' path_end='//table[2]/following-sibling:example[1]' title='Change' position="before">
          <autonumber type='table'>2</autonumber>
                     <autonumber type='note'>7</autonumber>
                     <description>
                       <p id='_'>
                         <em>
                           This table contains information on polygon cells which are not
                           included in ISO 10303-52. Remove table 2 completely and replace
                           with:
                         </em>
                       </p>
                     </description>
            <newcontent>
              <table id='_'>
                <name id="_">Edges of triangle and quadrilateral cells</name>
                <tbody>
                  <tr id="_">
                    <th id="_" colspan='2' valign='middle' align='center'>triangle</th>
                    <th id="_" colspan='2' valign='middle' align='center'>quadrilateral</th>
                  </tr>
                  <tr id="_">
                    <td id="_" valign='middle' align='center'>edge</td>
                    <td id="_" valign='middle' align='center'>vertices</td>
                    <td id="_" valign='middle' align='center'>edge</td>
                    <td id="_" valign='middle' align='center'>vertices</td>
                  </tr>
                  <tr id="_">
                    <td id="_" valign='middle' align='center'>1</td>
                    <td id="_" valign='middle' align='center'>1, 2</td>
                    <td id="_" valign='middle' align='center'>1</td>
                    <td id="_" valign='middle' align='center'>1, 2</td>
                  </tr>
                  <tr id="_">
                    <td id="_" valign='middle' align='center'>2</td>
                    <td id="_" valign='middle' align='center'>2, 3</td>
                    <td id="_" valign='middle' align='center'>2</td>
                    <td id="_" valign='middle' align='center'>2, 3</td>
                  </tr>
                  <tr id="_">
                    <td id="_" valign='middle' align='center'>3</td>
                    <td id="_" valign='middle' align='center'>3, 1</td>
                    <td id="_" valign='middle' align='center'>3</td>
                    <td id="_" valign='middle' align='center'>3, 4</td>
                  </tr>
                  <tr id="_">
                    <td id="_" valign='top' align='left'/>
                    <td id="_" valign='top' align='left'/>
                    <td id="_" valign='middle' align='center'>4</td>
                    <td id="_" valign='middle' align='center'>4, 1</td>
                  </tr>
                </tbody>
              </table>
              <example id='_'>
                <p id='_'>This is not generalised further.</p>
              </example>
            </newcontent>
            <description>
        <p id='_'>Any further exceptions can be ignored.</p>
      </description>
          </amend>
        </clause>
      </sections>
           </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "processes modify change subclauses" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [change="modify",locality="page=27",path="//table[2]",path_end="//table[2]/following-sibling:example[1]",title="Change"]
      == Change Clause

      autonumber:example[2]

      _This table contains information on polygon cells which are not included in ISO 10303-52. Remove table 2 completely and replace with:_

      ____
      ====
      This is not generalised further.
      ====
      ____

      === A subclause

      autonumber:example[5]

      This content as a subclause is also to be added

      ====
      This is an independently numbered example
      ====

      ==== A subsubclause

      This is a subclause of a subclause
    INPUT

    output = <<~"OUTPUT"
      #{BLANK_HDR}
           <sections>
              <clause id="_" inline-header="false" obligation="normative">
                 <title id="_">Change Clause</title>
                 <amend id="_" change="modify" path="//table[2]" path_end="//table[2]/following-sibling:example[1]" title="Change">
                    <autonumber type="example">2</autonumber>
                    <description>
                       <p id="_">
                          <em>This table contains information on polygon cells which are not included in ISO 10303-52. Remove table 2 completely and replace with:</em>
                       </p>
                    </description>
                    <newcontent>
                       <example id="_">
                          <p id="_">This is not generalised further.</p>
                       </example>
                       <clause id="_" inline-header="false" obligation="normative">
                          <autonumber type="example">5</autonumber>
                          <title id="_">A subclause</title>
                          <p id="_">This content as a subclause is also to be added</p>
                          <example id="_">
                             <p id="_">This is an independently numbered example</p>
                          </example>
                       <clause id="_" inline-header="false" obligation="normative">
                     <title id="_">A subsubclause</title>
                     <p id="_">This is a subclause of a subclause</p>
                  </clause>
                       </clause>
                    </newcontent>
                 </amend>
              </clause>
           </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end
end
