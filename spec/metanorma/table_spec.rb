require "spec_helper"

RSpec.describe Metanorma::Standoc do
  it "processes basic tables" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      .Table Name
      |===
      |A |B |C

      h|1 |2 |3
      |===
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
      <sections>
        <table id="_">
        <name id="_">Table Name</name>
        <thead>
          <tr id="_" id="_">
            <th id="_" valign="top" align="left">A</th>
            <th id="_" valign="top" align="left">B</th>
            <th id="_" valign="top" align="left">C</th>
          </tr>
        </thead>
        <tbody>
          <tr id="_" id="_">
            <th id="_" valign="top" align="left">1</th>
            <td id="_" valign="top" align="left">2</td>
            <td id="_" valign="top" align="left">3</td>
          </tr>
        </tbody>
      </table>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes table widths" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [width=75%]
      |===
      |A
      |B
      |===

      [width=75]
      |===
      |A
      |B
      |===

      [width=575]
      |===
      |A
      |B
      |===

    INPUT
    output = <<~OUTPUT
                  #{BLANK_HDR}
        <sections>
          <table id='_' width='75%'>
            <tbody>
              <tr id="_" id="_">
                <td id="_" valign='top' align='left'>A</td>
              </tr>
              <tr id="_" id="_">
                <td id="_" valign='top' align='left'>B</td>
              </tr>
            </tbody>
          </table>
          <table id='_' width='75'>
            <tbody>
              <tr id="_" id="_">
                <td id="_" valign='top' align='left'>A</td>
              </tr>
              <tr id="_" id="_">
                <td id="_" valign='top' align='left'>B</td>
              </tr>
            </tbody>
          </table>
          <table id='_' width='575'>
            <tbody>
              <tr id="_" id="_">
                <td id="_" valign='top' align='left'>A</td>
              </tr>
              <tr id="_" id="_">
                <td id="_" valign='top' align='left'>B</td>
              </tr>
            </tbody>
          </table>
        </sections>
      </metanorma>

    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes column widths in tables" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [cols=".<,.^,^.>"]
      |===
      |A |B |C

      |1 |2 |3
      |===

      [cols="3"]
      |===
      |A |B |C

      |1 |2 |3
      |===


      [cols="1,2,6"]
      |===
      |A |B |C

      |1 |2 |3
      |===
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
           <sections>
          <table id='_'>
            <thead>
              <tr id="_" id="_">
                <th id="_" valign='top' align='left'>A</th>
                <th id="_" valign='middle' align='left'>B</th>
                <th id="_" valign='bottom' align='center'>C</th>
              </tr>
            </thead>
            <tbody>
              <tr id="_" id="_">
                <td id="_" valign='top' align='left'>1</td>
                <td id="_" valign='middle' align='left'>2</td>
                <td id="_" valign='bottom' align='center'>3</td>
              </tr>
            </tbody>
          </table>
           <table id='_'>
            <thead>
              <tr id="_" id="_">
                <th id="_" valign='top' align='left'>A</th>
                <th id="_" valign='top' align='left'>B</th>
                <th id="_" valign='top' align='left'>C</th>
              </tr>
            </thead>
            <tbody>
              <tr id="_" id="_">
                <td id="_" valign='top' align='left'>1</td>
                <td id="_" valign='top' align='left'>2</td>
                <td id="_" valign='top' align='left'>3</td>
              </tr>
            </tbody>
          </table>
          <table id='_'>
            <colgroup>
              <col width='11.1111%'/>
              <col width='22.2222%'/>
              <col width='66.6667%'/>
            </colgroup>
            <thead>
              <tr id="_" id="_">
                <th id="_" valign='top' align='left'>A</th>
                <th id="_" valign='top' align='left'>B</th>
                <th id="_" valign='top' align='left'>C</th>
              </tr>
            </thead>
            <tbody>
              <tr id="_" id="_">
                <td id="_" valign='top' align='left'>1</td>
                <td id="_" valign='top' align='left'>2</td>
                <td id="_" valign='top' align='left'>3</td>
              </tr>
            </tbody>
          </table>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "inserts header rows in a table with a name and no header" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [headerrows=2]
      .Table Name
      |===
      |A |B |C
      h|1 |2 |3
      h|1 |2 |3
      |===
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections>
           <table id="_">
           <name id="_">Table Name</name>
           <thead><tr id="_" id="_">
               <th id="_" valign="top" align="left">A</th>
               <th id="_" valign="top" align="left">B</th>
               <th id="_" valign="top" align="left">C</th>
             </tr><tr id="_" id="_">
               <th id="_" valign="top" align="left">1</th>
               <th id="_" valign="top" align="left">2</th>
               <th id="_" valign="top" align="left">3</th>
             </tr></thead>
           <tbody>


             <tr id="_" id="_">
               <th id="_" valign="top" align="left">1</th>
               <td id="_" valign="top" align="left">2</td>
               <td id="_" valign="top" align="left">3</td>
             </tr>
           </tbody>
         </table>
         </sections>
         </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "inserts header rows in a table without a name and no header" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [headerrows=2]
      |===
      |A |B |C
      h|1 |2 |3
      h|1 |2 |3
      |===
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections>
           <table id="_"><thead><tr id="_" id="_">
               <th id="_" valign="top" align="left">A</th>
               <th id="_" valign="top" align="left">B</th>
               <th id="_" valign="top" align="left">C</th>
             </tr><tr id="_" id="_">
               <th id="_" valign="top" align="left">1</th>
               <th id="_" valign="top" align="left">2</th>
               <th id="_" valign="top" align="left">3</th>
             </tr></thead>
           <tbody>


             <tr id="_" id="_">
               <th id="_" valign="top" align="left">1</th>
               <td id="_" valign="top" align="left">2</td>
               <td id="_" valign="top" align="left">3</td>
             </tr>
           </tbody>
         </table>
         </sections>
         </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes complex tables" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [cols="<.^,^.<,^.>,^,^",options="header,footer",headerrows=2,alt="An extensive summary, and illustration, of tables",subsequence="A",options="unnumbered",summary="This is an extremely long, convoluted summary",width=70%,number="3",keep-with-next=true,keep-lines-together=true]
      .Maximum _permissible_ mass fraction of defects
      |===
      .2+|Defect 4+^| Maximum permissible mass fraction of defects in husked rice +
      stem:[w_max]
      | in husked rice | in milled rice (non-glutinous) | in husked parboiled rice | in milled parboiled rice

      | Extraneous matter: organic footnote:[Organic extraneous matter includes foreign seeds, husks, bran, parts of straw, etc.] | 1,0 | 0,5 | 1,0 | 0,5
      // not rendered list here
      | Extraneous matter: inorganic footnote:[Inorganic extraneous matter includes stones, sand, dust, etc.] | 0,5 | 0,5 | 0,5 | 0,5
      | Paddy | 2,5 | 0,3 | 2,5 | 0,3
      | Husked rice, non-parboiled | Not applicable | 1,0 | 1,0 | 1,0
      | Milled rice, non-parboiled | 1,0 | Not applicable | 1,0 | 1,0
      | Husked rice, parboiled | 1,0 | 1,0 | Not applicable | 1,0
      | Milled rice, parboiled | 1,0 | 1,0 | 1,0 | Not applicable
      | Chips | 0,1 | 0,1 | 0,1 | 0,1
      | HDK | 2,0 footnote:defectsmass[The maximum permissible mass fraction of ((defects)) shall be determined with respect to the mass fraction obtained after milling.] | 2,0 | 2,0 footnote:defectsmass[] | 2,0
      | Damaged kernels | 4,0 | 3,0 | 4,0 | 3,0
      | Immature and/or malformed kernels | 8,0 | 2,0 | 8,0 | 2,0
      | Chalky kernels | 5,0 footnote:defectsmass[] | 5,0 | Not applicable | Not applicable
      | Red kernels and red-streaked kernels | 12,0 | 12,0 | 12,0 footnote:defectsmass[] | 12,0
      | Partly gelatinized kernels | Not applicable | Not applicable | 11,0 footnote:defectsmass[] | 11,0
      | Pecks | Not applicable | Not applicable | 4,0 | 2,0
      | Waxy rice | 1,0 footnote:defectsmass[] | 1,0 | 1,0 footnote:defectsmass[] | 1,0

      5+a| Live insects shall not be present. Dead insects shall be included in extraneous matter.
      |===

      [.source,status=generalisation]
      <<ISO2191,section=1>>, with adjustments

      [.source,status=specialisation]
      <<ISO2191,section=2>>, with adjustments

      NOTE: Hello
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
              <sections>
                <table id="_" alt="An extensive summary, and illustration, of tables" unnumbered="true" subsequence="A" summary="This is an extremely long, convoluted summary" width="70%" number="3" keep-with-next="true" keep-lines-together="true">
                <name id="_">Maximum <em>permissible</em> mass fraction of defects</name>
                <thead>
                  <tr id="_" id="_">
                    <th id="_" rowspan="2" valign="middle" align="left">Defect</th>
                    <th id="_" colspan="4" valign="top" align="center">Maximum permissible mass fraction of defects in husked rice<br/>
                    <stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false">
                      <msub>
                          <mi>w</mi>
                                 <mrow>
                                 <mo rspace="thickmathspace"/>
                                 <mi>max</mi>
                              </mrow>
                      </msub>
                      </mstyle></math><asciimath>w_max</asciimath></stem></th>
                  </tr>
                <tr id="_" id="_">
                    <th id="_" valign="middle" align="left">in husked rice</th>
                    <th id="_" valign="top" align="center">in milled rice (non-glutinous)</th>
                    <th id="_" valign="bottom" align="center">in husked parboiled rice</th>
                    <th id="_" valign="top" align="center">in milled parboiled rice</th>
                  </tr></thead>
                <tbody>

                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Extraneous matter: organic<fn id="_" reference="a">
                <p id="_">Organic extraneous matter includes foreign seeds, husks, bran, parts of straw, etc.</p>
              </fn></td>
                    <td id="_" valign="top" align="center">1,0</td>
                    <td id="_" valign="bottom" align="center">0,5</td>
                    <td id="_" valign="top" align="center">1,0</td>
                    <td id="_" valign="top" align="center">0,5</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Extraneous matter: inorganic<fn id="_" reference="b">
                <p id="_">Inorganic extraneous matter includes stones, sand, dust, etc.</p>
              </fn></td>
                    <td id="_" valign="top" align="center">0,5</td>
                    <td id="_" valign="bottom" align="center">0,5</td>
                    <td id="_" valign="top" align="center">0,5</td>
                    <td id="_" valign="top" align="center">0,5</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Paddy</td>
                    <td id="_" valign="top" align="center">2,5</td>
                    <td id="_" valign="bottom" align="center">0,3</td>
                    <td id="_" valign="top" align="center">2,5</td>
                    <td id="_" valign="top" align="center">0,3</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Husked rice, non-parboiled</td>
                    <td id="_" valign="top" align="center">Not applicable</td>
                    <td id="_" valign="bottom" align="center">1,0</td>
                    <td id="_" valign="top" align="center">1,0</td>
                    <td id="_" valign="top" align="center">1,0</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Milled rice, non-parboiled</td>
                    <td id="_" valign="top" align="center">1,0</td>
                    <td id="_" valign="bottom" align="center">Not applicable</td>
                    <td id="_" valign="top" align="center">1,0</td>
                    <td id="_" valign="top" align="center">1,0</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Husked rice, parboiled</td>
                    <td id="_" valign="top" align="center">1,0</td>
                    <td id="_" valign="bottom" align="center">1,0</td>
                    <td id="_" valign="top" align="center">Not applicable</td>
                    <td id="_" valign="top" align="center">1,0</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Milled rice, parboiled</td>
                    <td id="_" valign="top" align="center">1,0</td>
                    <td id="_" valign="bottom" align="center">1,0</td>
                    <td id="_" valign="top" align="center">1,0</td>
                    <td id="_" valign="top" align="center">Not applicable</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Chips</td>
                    <td id="_" valign="top" align="center">0,1</td>
                    <td id="_" valign="bottom" align="center">0,1</td>
                    <td id="_" valign="top" align="center">0,1</td>
                    <td id="_" valign="top" align="center">0,1</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">HDK</td>
                    <td id="_" valign="top" align="center">2,0<fn id="_" reference="c">
                <p id="_">The maximum permissible mass fraction of defects
                         <index>
                           <primary>defects</primary>
                        </index>
                      shall be determined with respect to the mass fraction obtained after milling.</p>
              </fn></td>
                    <td id="_" valign="bottom" align="center">2,0</td>
                    <td id="_" valign="top" align="center">2,0<fn id="_" reference="c">
                <p id="_">The maximum permissible mass fraction of defects shall be determined with respect to the mass fraction obtained after milling.</p>
              </fn></td>
                    <td id="_" valign="top" align="center">2,0</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Damaged kernels</td>
                    <td id="_" valign="top" align="center">4,0</td>
                    <td id="_" valign="bottom" align="center">3,0</td>
                    <td id="_" valign="top" align="center">4,0</td>
                    <td id="_" valign="top" align="center">3,0</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Immature and/or malformed kernels</td>
                    <td id="_" valign="top" align="center">8,0</td>
                    <td id="_" valign="bottom" align="center">2,0</td>
                    <td id="_" valign="top" align="center">8,0</td>
                    <td id="_" valign="top" align="center">2,0</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Chalky kernels</td>
                    <td id="_" valign="top" align="center">5,0<fn id="_" reference="c">
                <p id="_">The maximum permissible mass fraction of defects shall be determined with respect to the mass fraction obtained after milling.</p>
              </fn></td>
                    <td id="_" valign="bottom" align="center">5,0</td>
                    <td id="_" valign="top" align="center">Not applicable</td>
                    <td id="_" valign="top" align="center">Not applicable</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Red kernels and red-streaked kernels</td>
                    <td id="_" valign="top" align="center">12,0</td>
                    <td id="_" valign="bottom" align="center">12,0</td>
                    <td id="_" valign="top" align="center">12,0<fn id="_" reference="c">
                <p id="_">The maximum permissible mass fraction of defects shall be determined with respect to the mass fraction obtained after milling.</p>
              </fn></td>
                    <td id="_" valign="top" align="center">12,0</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Partly gelatinized kernels</td>
                    <td id="_" valign="top" align="center">Not applicable</td>
                    <td id="_" valign="bottom" align="center">Not applicable</td>
                    <td id="_" valign="top" align="center">11,0<fn id="_" reference="c">
                <p id="_">The maximum permissible mass fraction of defects shall be determined with respect to the mass fraction obtained after milling.</p>
              </fn></td>
                    <td id="_" valign="top" align="center">11,0</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Pecks</td>
                    <td id="_" valign="top" align="center">Not applicable</td>
                    <td id="_" valign="bottom" align="center">Not applicable</td>
                    <td id="_" valign="top" align="center">4,0</td>
                    <td id="_" valign="top" align="center">2,0</td>
                  </tr>
                  <tr id="_" id="_">
                    <td id="_" valign="middle" align="left">Waxy rice</td>
                    <td id="_" valign="top" align="center">1,0<fn id="_" reference="c">
                <p id="_">The maximum permissible mass fraction of defects shall be determined with respect to the mass fraction obtained after milling.</p>
              </fn></td>
                    <td id="_" valign="bottom" align="center">1,0</td>
                    <td id="_" valign="top" align="center">1,0<fn id="_" reference="c">
                <p id="_">The maximum permissible mass fraction of defects shall be determined with respect to the mass fraction obtained after milling.</p>
              </fn></td>
                    <td id="_" valign="top" align="center">1,0</td>
                  </tr>
                </tbody>
                <tfoot>
                  <tr id="_" id="_">
                    <td id="_" colspan="5" valign="middle" align="left">
                      <p id="_">Live insects shall not be present. Dead insects shall be included in extraneous matter.</p>
                    </td>
                  </tr>
                </tfoot>
                     <source status="generalisation">
        <origin bibitemid="ISO2191" type="inline" citeas="">
          <localityStack>
            <locality type="section">
              <referenceFrom>1</referenceFrom>
            </locality>
          </localityStack>
        </origin>
        <modification>
          <p id="_">with adjustments</p>
        </modification>
      </source>
                  <source status="specialisation">
               <origin bibitemid="ISO2191" type="inline" citeas="">
                 <localityStack>
                   <locality type="section">
                     <referenceFrom>2</referenceFrom>
                   </locality>
                 </localityStack>
               </origin>
               <modification>
                 <p id="_">with adjustments</p>
               </modification>
             </source>
      <note id="_">
        <p id="_">Hello</p>
      </note>
              </table>
              </sections>
              </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes table styles" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [style: "border: none; color: purple;"]
      |===
      |A tr-style:[color: blue] |B |C tr-style:[background-color: red]

      h|1 td-style:[color: green] td-style:[background-color: blue] |2 tr-style:[color: green] |3 td-style:[color: blue] td-style:[background-color: gren]
      |===
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
          <sections>
             <table id="_" style="border: none; color: purple;">
                <thead>
                   <tr id="_" style="color: blue;background-color: red">
                      <th id="_" valign="top" align="left">A </th>
                      <th id="_" valign="top" align="left">B</th>
                      <th id="_" valign="top" align="left">C </th>
                   </tr>
                </thead>
                <tbody>
                   <tr id="_" style="color: green">
                      <th id="_" valign="top" align="left" style="color: green;background-color: blue">1  </th>
                      <td id="_" valign="top" align="left">2 </td>
                      <td id="_" valign="top" align="left" style="color: blue;background-color: gren">3  </td>
                   </tr>
                </tbody>
             </table>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end
end
