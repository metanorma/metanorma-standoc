require "spec_helper"

RSpec.describe Asciidoctor::Standoc do
  it "processes the Asciidoctor::Standoc inline macros" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      alt:[term1]
      deprecated:[term1]
      domain:[term1]
      inherit:[<<ref1>>]
      autonumber:table[3]
      add:[a <<clause>>] del:[B]

      [bibliography]
      == Bibliography
      * [[[ref1,XYZ 123]]] _Title_
    INPUT
      #{BLANK_HDR}
      <preface>
          <foreword id='_' obligation='informative'>
          <title>Foreword</title>
          <admitted>term1</admitted>
          <deprecates>term1</deprecates>
          <domain>term1</domain>
          <inherit>
            <eref type='inline' bibitemid='ref1' citeas='XYZ 123'/>
          </inherit>
          <autonumber type='table'>3</autonumber>
          <add>
                      a
                      <xref target='clause'/>
                    </add>
                    <del>B</del>
        </foreword>
      </preface>
      <sections> </sections>
      <bibliography>
        <references id='_' obligation='informative' normative="false">
          <title>Bibliography</title>
          <bibitem id='ref1'>
            <formattedref format='application/x-isodoc+xml'>
              <em>Title</em>
            </formattedref>
            <docidentifier>XYZ 123</docidentifier>
            <docnumber>123</docnumber>
          </bibitem>
        </references>
      </bibliography>
      </standard-document>
    OUTPUT
  end

  it "processes the Asciidoctor::Standoc index macros" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      index:also[]
      index:see[A]
      index:also[B,C~x~]
      index:see[D,_E_,F]
      index:also[G,H,I,J]
      index:see[K,L,M,N,O]
      index-range:id2[P]
      index-range:id3[((_P_))]
      index-range:id3[(((Q, R, S)))]

      Text [[id2]]

      Text [[id3]]
    INPUT
                  #{BLANK_HDR}
        <sections>
          <p id='_'>
            <index-xref also='true'>
              <primary>B</primary>
              <target>
                C
                <sub>x</sub>
              </target>
            </index-xref>
            <index-xref also='false'>
              <primary>D</primary>
              <secondary>
                <em>E</em>
              </secondary>
              <target>F</target>
            </index-xref>
            <index-xref also='true'>
              <primary>G</primary>
              <secondary>H</secondary>
              <tertiary>I</tertiary>
              <target>J</target>
            </index-xref>
             P
      <index to="id2">
        <primary>P</primary>
      </index>
      <em>P</em>
      <index to="id3">
        <primary>
          <em>P</em>
        </primary>
      </index>
      <index to="id3">
        <primary>Q</primary>
        <secondary>R</secondary>
        <tertiary>S</tertiary>
      </index>
          </p>
          <p id='_'>
                   Text
                   <bookmark id='id2'/>
                 </p>
                 <p id='_'>
                   Text
                   <bookmark id='id3'/>
                 </p>
        </sections>
      </standard-document>
    OUTPUT
  end

  it "processes the Asciidoctor::Standoc variant macros" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == lang:en[English] lang:fr-Latn[Français]

      this lang:en[English] lang:fr-Latn[Français] section is lang:en[silly]  lang:fr[fou]

    INPUT
      #{BLANK_HDR}
      <sections>
        <clause id='_' inline-header='false' obligation='normative'>
          <title>
            <variant lang='en'>English</variant>
            <variant lang='fr' script='Latn'>Français</variant>
          </title>
          <p id='_'>
            this
            <variant>
              <variant lang='en'>English</variant>
              <variant lang='fr' script='Latn'>Français</variant>
            </variant>
             section is
            <variant>
              <variant lang='en'>silly</variant>
              <variant lang='fr'>fou</variant>
            </variant>
          </p>
        </clause>
      </sections>
      </standard-document>
    OUTPUT
  end

  it "processes the Asciidoctor::Standoc concept macros" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      {{clause1}}
      {{clause1,w\[o\]rd}}
      {{clause1,w\[o\]rd,term}}
      {{blah}}
      {{blah,word}}
      {{blah,word,term}}
      {{blah,clause=3.1}}
      {{blah,clause=3.1,word}}
      {{blah,clause=3.1,word,term}}
      {{blah,clause=3.1,figure=a}}
      {{blah,clause=3.1,figure=a,word}}
      {{blah,clause=3.1,figure=a,word,term}}
      {{IEV:135-13-13}}
      {{IEV:135-13-13,word}}
      {{IEV:135-13-13,word,term}}

      [[clause1]]
      == Clause
      Terms are defined here

      [bibliography]
      == Bibliography
      * [[[blah,blah]]] _Blah_
    INPUT
      #{BLANK_HDR}
      <preface>
        <foreword id='_' obligation='informative'>
          <title>Foreword</title>
          <p id='_'>
            <concept>
              <xref target='clause1'/>
            </concept>
            <concept>
              <xref target='clause1'>w[o]rd</xref>
            </concept>
            <concept term='term'>
              <xref target='clause1'>w[o]rd</xref>
            </concept>
            <concept>
              <eref/>
            </concept>
            <concept>
              <eref>word</eref>
            </concept>
            <concept term='term'>
              <eref>word</eref>
            </concept>
            <concept>
              <eref>
              <localityStack>
                <locality type='clause'>
                  <referenceFrom>3.1</referenceFrom>
                </locality>
              </localityStack>
              </eref>
            </concept>
            <concept>
              <eref>
              <localityStack>
                <locality type='clause'>
                  <referenceFrom>3.1</referenceFrom>
                </locality>
              </localityStack>
                word
              </eref>
            </concept>
            <concept term='term'>
              <eref>
              <localityStack>
                <locality type='clause'>
                  <referenceFrom>3.1</referenceFrom>
                </locality>
              </localityStack>
                word
              </eref>
            </concept>
            <concept>
              <eref>
              <localityStack>
                <locality type='clause'>
                  <referenceFrom>3.1</referenceFrom>
                </locality>
                <locality type='figure'>
                  <referenceFrom>a</referenceFrom>
                </locality>
              </localityStack>
              </eref>
            </concept>
            <concept>
              <eref>
              <localityStack>
                <locality type='clause'>
                  <referenceFrom>3.1</referenceFrom>
                </locality>
                <locality type='figure'>
                  <referenceFrom>a</referenceFrom>
                </locality>
              </localityStack>
                word
              </eref>
            </concept>
            <concept term='term'>
              <eref>
              <localityStack>
                <locality type='clause'>
                  <referenceFrom>3.1</referenceFrom>
                </locality>
                <locality type='figure'>
                  <referenceFrom>a</referenceFrom>
                </locality>
              </localityStack>
                word
              </eref>
            </concept>
            <concept>
              <termref base='IEV' target='135-13-13'/>
            </concept>
            <concept>
              <termref base='IEV' target='135-13-13'>word</termref>
            </concept>
            <concept term='term'>
              <termref base='IEV' target='135-13-13'>word</termref>
            </concept>
          </p>
        </foreword>
      </preface>
      <sections>
        <clause id='clause1' inline-header='false' obligation='normative'>
          <title>Clause</title>
          <p id='_'>Terms are defined here</p>
        </clause>
      </sections>
      <bibliography>
        <references id='_' obligation='informative' normative="false">
          <title>Bibliography</title>
          <bibitem id='blah'>
            <formattedref format='application/x-isodoc+xml'>
              <em>Blah</em>
            </formattedref>
            <docidentifier>blah</docidentifier>
          </bibitem>
        </references>
      </bibliography>
      </standard-document>
    OUTPUT
  end

  it "processes the TODO custom admonition" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      TODO: Note1

      [TODO]
      ====
      Note2
      ====

      [TODO]
      Note3
    INPUT
           #{BLANK_HDR}
           <sections><review reviewer="(Unknown)" id="_" date="#{Date.today}T00:00:00Z">
        <p id="_"/>
      </review>
      <review reviewer="(Unknown)" id="_" date="#{Date.today}T00:00:00Z">
        <p id="_">Note2</p>
      </review>
      <review reviewer="(Unknown)" id="_" date="#{Date.today}T00:00:00Z">
        <p id="_">Note3</p>
      </review></sections>
      </standard-document>
    OUTPUT
  end

  it "generates pseudocode examples, with formatting and initial indentation" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      [pseudocode,subsequence="A",number="3",keep-with-next=true,keep-lines-together=true]
      [%unnumbered]
      ====
        *A* +
              [smallcap]#B#

        _C_
      ====
    INPUT
              #{BLANK_HDR}
              <sections>
        <figure id="_"  subsequence='A' class="pseudocode" unnumbered="true" number="3" keep-with-next="true" keep-lines-together="true">
              <p id="_">  <strong>A</strong><br/>
              <smallcap>B</smallcap></p>
      <p id="_">  <em>C</em></p></figure>
      </sections>
      </standard-document>
    OUTPUT
  end

  it "supplies line breaks in pseudocode" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      [pseudocode]
      ====
      A
      B

      D
      E
      ====
    INPUT
              #{BLANK_HDR}
              <sections>
      <figure id='_' class='pseudocode'>
                   <p id='_'>
                     A
                     <br/>
                     B
                   </p>
                   <p id='_'>
                     D
                     <br/>
                     E
                   </p>
                 </figure>
      </sections>
      </standard-document>
    OUTPUT
  end

  it "skips embedded blocks when supplying line breaks in pseudocode" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      [pseudocode]
      ====
      [stem]
      ++++
      bar X' = (1)/(v) sum_(i = 1)^(v) t_(i)
      ++++
      ====
    INPUT
              #{BLANK_HDR}
              <sections>
      <figure id='_' class='pseudocode'>
       <formula id='_'>
         <stem type='MathML'>
           <math xmlns='http://www.w3.org/1998/Math/MathML'>
           <mover accent="true">
                           <mrow>
                             <mi>X</mi>
                           </mrow>
                             <mo>¯</mo>
                         </mover>
                         <mo>′</mo>
                         <mo>=</mo>
                         <mfrac>
                           <mrow>
                             <mn>1</mn>
                           </mrow>
                           <mrow>
                             <mi>v</mi>
                           </mrow>
                         </mfrac>
                         <munderover>
                           <mrow>
                             <mo>∑</mo>
                           </mrow>
                           <mrow>
                             <mrow>
                               <mi>i</mi>
                               <mo>=</mo>
                               <mn>1</mn>
                             </mrow>
                           </mrow>
                           <mrow>
                             <mi>v</mi>
                           </mrow>
                         </munderover>
                         <msub>
                           <mrow>
                             <mi>t</mi>
                           </mrow>
                           <mrow>
                             <mi>i</mi>
                           </mrow>
                         </msub>
           </math>
         </stem>
       </formula>
                 </figure>
      </sections>
      </standard-document>
    OUTPUT
  end

  it "processes the Ruby markups" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      ruby:楽聖少女[がくせいしょうじょ]
    INPUT
           #{BLANK_HDR}
           <sections>
             <p id="_">
             <ruby>楽聖少女<rp>(</rp><rt>がくせいしょうじょ</rt><rp>)</rp></ruby>
           </p>
           </sections>
      </standard-document>
    OUTPUT
  end

  it "processes the footnoteblock macro" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      footnoteblock:[id1]

      [[id1]]
      [NOTE]
      --
      |===
      |a |b

      |c |d
      |===

      * A
      * B
      * C
      --
    INPUT
                  #{BLANK_HDR}
                  <sections>
                    <p id="_">
                    <fn reference='1'>
        <table id='_'>
          <thead>
            <tr>
              <th valign='top' align='left'>a</th>
              <th valign='top' align='left'>b</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td valign='top' align='left'>c</td>
              <td valign='top' align='left'>d</td>
            </tr>
          </tbody>
        </table>
        <ul id='_'>
          <li>
            <p id='_'>A</p>
          </li>
          <li>
            <p id='_'>B</p>
          </li>
          <li>
            <p id='_'>C</p>
          </li>
        </ul>
      </fn>
                  </p>
                  </sections>
             </standard-document>
    OUTPUT
  end

  it "processes the footnoteblock macro with failed reference" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      footnoteblock:[id1]

      [[id2]]
      [NOTE]
      --
      |===
      |a |b

      |c |d
      |===

      * A
      * B
      * C
      --
    INPUT
           #{BLANK_HDR}
       <sections>
          <p id='_'>
            <fn reference='1'>[ERROR]</fn>
          </p>
          <note id='id2'>
            <table id='_'>
              <thead>
                <tr>
                  <th valign='top' align='left'>a</th>
                  <th valign='top' align='left'>b</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td valign='top' align='left'>c</td>
                  <td valign='top' align='left'>d</td>
                </tr>
              </tbody>
            </table>
            <ul id='_'>
              <li>
                <p id='_'>A</p>
              </li>
              <li>
                <p id='_'>B</p>
              </li>
              <li>
                <p id='_'>C</p>
              </li>
            </ul>
          </note>
        </sections>
      </standard-document>
    OUTPUT
  end

  it "processes input form macros" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      [form,id=N0,name=N1,action="/action_page.php"]
      --
      label:fname[First name:] +
      input:text[id=fname,name=fname] +
      label:lname[Last name:] +
      input:text[id=lname,name=lname] +
      label:pwd[Password:] +
      input:password[id=pwd,name=pwd] +
      input:radio[id=male,name=gender,value=male]
      label:male[Male] +
      input:radio[id=female,name=gender,value=female]
      label:female[Female] +
      input:radio[id=other,name=gender,value=other]
      label:other[Other] +
      input:checkbox[id=vehicle1,name=vehicle1,value=Bike,checked=true]
      label:vehicle1[I have a bike] +
      input:checkbox[id=vehicle2,name=vehicle2,value=Car]
      label:vehicle2[I have a car] +
      input:checkbox[id=vehicle3,name=vehicle3,value=Boat]
      label:vehicle3[I have a boat] +
      input:date[id=birthday,name=birthday] +
      label:myfile[Select a file:]
      input:file[id=myfile,name=myfile] +
      label:cars[Select a car:] +
      select:[id=cars,name=cars,value=fiat,size=4,disabled=true,multiple=true]
      option:[Volvo,value=volvo,disabled=true]
      option:[Saab,value=saab]
      option:[Fiat,value=fiat]
      option:[Audi,value=audi]
      textarea:[id=t1,name=message,rows=10,cols=30,value="The cat was playing in the garden."]
      input:button[value="Click Me!"]
      input:button[]
      input:submit[value="Submit"]
      --
    INPUT
        #{BLANK_HDR}
        <sections>
        <form id='_' name='N1' action='/action_page.php'>
        <p id='_'>
          <label for='fname'>First name:</label>
          <br/>
          <input type='text' id='fname' name='fname'/>
          <br/>
          <label for='lname'>Last name:</label>
          <br/>
          <input type='text' id='lname' name='lname'/>
          <br/>
          <label for='pwd'>Password:</label>
          <br/>
          <input type='password' id='pwd' name='pwd'/>
          <br/>
          <input type='radio' id='male' name='gender' value='male'/>
          <label for='male'>Male</label>
          <br/>
          <input type='radio' id='female' name='gender' value='female'/>
          <label for='female'>Female</label>
          <br/>
          <input type='radio' id='other' name='gender' value='other'/>
          <label for='other'>Other</label>
          <br/>
          <input type='checkbox' id='vehicle1' name='vehicle1' value='Bike' checked='true'/>
          <label for='vehicle1'>I have a bike</label>
          <br/>
          <input type='checkbox' id='vehicle2' name='vehicle2' value='Car'/>
          <label for='vehicle2'>I have a car</label>
          <br/>
          <input type='checkbox' id='vehicle3' name='vehicle3' value='Boat'/>
          <label for='vehicle3'>I have a boat</label>
          <br/>
          <input type='date' id='birthday' name='birthday'/>
          <br/>
          <label for='myfile'>Select a file:</label>
          <input type='file' id='myfile' name='myfile'/>
          <br/>
          <label for='cars'>Select a car:</label>
          <br/>
          <select id='cars' name='cars' size='4' disabled='true' multiple='true' value='fiat'>
            <option disabled='true' value='volvo'/>
            <option value='saab'/>
            <option value='fiat'/>
            <option value='audi'/>
          </select>
          <textarea id='t1' name='message' rows='10' cols='30' value='The cat was playing in the garden.'/>
          <input type='button' value='Click Me!'/>
          <input type='button'/>
          <input type='submit' value='Submit'/>
        </p>
      </form>
              </sections>
             </standard-document>
    OUTPUT
  end

  describe "term inline macros" do
    subject(:convert) do
      xmlpp(
        strip_guid(
          Asciidoctor.convert(
            input, *OPTIONS
          )
        )
      )
    end
    let(:input) do
      <<~XML
        #{ASCIIDOC_BLANK_HDR}
        == Terms and Definitions

        === name2

        == Main

        term:[name,name2] is a term
      XML
    end
    let(:output) do
      <<~XML
        #{BLANK_HDR}
        <sections>
          <terms id='_' obligation='normative'>
            <title>Terms and definitions</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id='term-name2'>
              <preferred>name2</preferred>
            </term>
          </terms>
          <clause id='_' inline-header='false' obligation='normative'>
            <title>Main</title>
            <p id='_'>
              <em>name</em>
              (
              <xref target='term-name2'/>
              ) is a term
            </p>
          </clause>
        </sections>
        </standard-document>
      XML
    end

    it "converts macro into the correct xml" do
      expect(convert).to(be_equivalent_to(xmlpp(output)))
    end

    context "default params" do
      let(:input) do
        <<~XML
          #{ASCIIDOC_BLANK_HDR}

          == Terms and Definitions

          === name

          == Main

          term:[name] is a term
        XML
      end
      let(:output) do
        <<~XML
          #{BLANK_HDR}
          <sections>
            <terms id='_' obligation='normative'>
              <title>Terms and definitions</title>
              <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
              <term id='term-name'>
                <preferred>name</preferred>
              </term>
            </terms>
            <clause id='_' inline-header='false' obligation='normative'>
              <title>Main</title>
              <p id='_'>
                <em>name</em>
                (
                <xref target='term-name' />
                ) is a term
              </p>
            </clause>
          </sections>
          </standard-document>
        XML
      end

      it "uses `name` as termref name" do
        expect(convert).to(be_equivalent_to(xmlpp(output)))
      end
    end

    context "multiply exising ids in document" do
      let(:input) do
        <<~XML
          #{ASCIIDOC_BLANK_HDR}

          == Terms and Definitions

          === name
          === name2

          [[term-name]]
          == Main

          paragraph

          [[term-name2]]
          == Second

          term:[name] is a term
          term:[name2] is a term
        XML
      end
      let(:output) do
        <<~XML
          #{BLANK_HDR}
          <sections>
            <terms id='_' obligation='normative'>
              <title>Terms and definitions</title>
              <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
              <term id='term-name-1'>
                 <preferred>name</preferred>
              </term>
              <term id='term-name2-1'>
                <preferred>name2</preferred>
              </term>
            </terms>
            <clause id='term-name' inline-header='false' obligation='normative'>
              <title>Main</title>
              <p id='_'>paragraph</p>
            </clause>
            <clause id='term-name2' inline-header='false' obligation='normative'>
              <title>Second</title>
              <p id='_'>
                <em>name</em>
                (
                <xref target='term-name-1' />
                ) is a term
                <em>name2</em>
                  (
                <xref target='term-name2-1' />
                ) is a term
              </p>
            </clause>
          </sections>
          </standard-document>
        XML
      end

      it "generates unique ids which do not match existing ids" do
        expect(convert).to(be_equivalent_to(xmlpp(output)))
      end
    end

    context "when missing actual ref" do
      let(:input) do
        <<~XML
          #{ASCIIDOC_BLANK_HDR}

          == Terms and Definitions

          === name identity

          [[name-check]]
          === name check

          paragraph

          term:[name check] is a term

          term:[name identity] is a term

          Moreover, term:[missing] is a term
        XML
      end
      let(:output) do
        <<~XML
          #{BLANK_HDR}
            <sections>
              <terms id='_' obligation='normative'>
                <title>Terms and definitions</title>
                <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
                <term id='term-name-identity'>
                  <preferred>name identity</preferred>
                </term>
                <term id='name-check'>
                  <preferred>name check</preferred>
                  <definition>
                    <p id='_'>paragraph</p>
                    <p id='_'>
                      <em>name check</em>
                       (
                      <xref target='name-check'/>
                      ) is a term
                      </p>
                      <p id='_'>
                      <em>name identity</em>
                       (
                      <xref target='term-name-identity'/>
                      ) is a term
                      </p>
                      <p id="_">Moreover, (<strong>term “missing” not resolved</strong>) is a term</p>
                  </definition>
                </term>
              </terms>
            </sections>
          </standard-document>
        XML
      end

      it "generates unique ids which do not match existing ids" do
        expect(convert).to(be_equivalent_to(xmlpp(output)))
      end
    end
  end
end
