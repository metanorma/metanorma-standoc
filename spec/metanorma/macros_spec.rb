require "spec_helper"
require "relaton_iso"

RSpec.describe Metanorma::Standoc do
  before do
    # Force to download Relaton index file
    allow_any_instance_of(Relaton::Index::Type).to receive(:actual?)
      .and_return(false)
    allow_any_instance_of(Relaton::Index::FileIO).to receive(:check_file)
      .and_return(nil)
  end

  it "processes the Metanorma::Standoc inline macros" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      preferred:[term0]
      alt:[term1]
      admitted:[term1a]
      deprecated:[term2]
      domain:[term3]
      inherit:[<<ref1>>]
      autonumber:table[3]
      add:[a <<clause>>] del:[B]
      identifier:[a http://example.com]
      span:category[text]
      date:[2012-03-04,%a-%b%s]
      date:[2012-03-04]
      anchor:ABC[*emphasised text*]
      source-id:ABC[*emphasised text*]

      columnbreak::[]

      [bibliography]
      == Bibliography
      * [[[ref1,XYZ 123]]] _Title_
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <preface>
          <foreword id='_' obligation='informative'>
          <title id="_">Foreword</title>
          <preferred><expression><name>term0</name></expression></preferred>
          <admitted><expression><name>term1</name></expression></admitted>
          <admitted><expression><name>term1a</name></expression></admitted>
          <deprecates><expression><name>term2</name></expression></deprecates>
          <domain>term3</domain>
          <inherit>
            <eref type='inline' bibitemid='ref1' citeas='XYZ\\u00a0123'/>
          </inherit>
          <autonumber type='table'>3</autonumber>
          <add>
                      a
                      <xref target='clause'/>
                    </add>
                    <del>B</del>
                    <identifier>a http://example.com</identifier>
                    <span class='category'>text</span>
                    <date format="%a-%b%s" value="2012-03-04"/>
                    <date format="%F" value="2012-03-04"/>
                    <span id="_" anchor="ABC">
                   <strong>emphasised text</strong>
                </span>
                <span id="_" source="ABC">
                   <strong>emphasised text</strong>
                </span>
                    <columnbreak/>
        </foreword>
      </preface>
      <sections> </sections>
      <bibliography>
        <references id="_" obligation='informative' normative="false">
          <title id="_">Bibliography</title>
          <bibitem id="_" anchor="ref1">
            <formattedref format='application/x-isodoc+xml'>
              <em>Title</em>
            </formattedref>
            <docidentifier>XYZ 123</docidentifier>
            <docnumber>123</docnumber>
          </bibitem>
        </references>
      </bibliography>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes the number format macros" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      number:31[]
      number:327428.7432878432992[]
      number:327428.7432878432992[decimal=.]
      number:327428.7432878432992[decimal='.']
      number:327428.7432878432992[decimal="."]
      number:327428.7432878432992[decimal=".",notation=exponential]
      number:327428.7432878432992[decimal=",",notation=exponential]
      number:1[decimal=",",notation=exponential]
      number:1.1[decimal=",",notation=exponential]
      number:1.100[decimal=",",notation=exponential]
      number:10e20[decimal=",",notation=exponential]
      number:1.0e19[decimal=",",notation=exponential]
      number:1.0e-19[decimal=",",notation=exponential]
      number:327428.7432878432992[decimal=",",group=&#x2009;,notation=exponential]
      number:327428.7432878432992[group_digits=3,fraction_group_digits=3,decimal=",",group=&#x2009;,notation=general]
      number:+31[]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <p id="_">
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="notation='basic'">0.31e2</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="notation='basic'">0.3274287432878432992e6</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="decimal='.'">0.3274287432878432992e6</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="decimal='.'">0.3274287432878432992e6</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="decimal='.'">0.3274287432878432992e6</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="decimal='.',notation='exponential'">0.3274287432878432992e6</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="decimal=',',notation='exponential'">0.3274287432878432992e6</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="decimal=',',notation='exponential'">0.1e1</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="decimal=',',notation='exponential'">0.11e1</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="decimal=',',notation='exponential'">0.1100e1</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="decimal=',',notation='exponential'">0.1e22</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="decimal=',',notation='exponential'">0.10e20</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="decimal=',',notation='exponential'">0.10e-18</mn>
               </math>
             </stem>
             <stem type="MathML">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
               <mn data-metanorma-numberformat="decimal=',',group='\\u2009',notation='exponential'">0.3274287432878432992e6</mn>
            </math>
         </stem>
           <stem type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mn data-metanorma-numberformat="group_digits='3',fraction_group_digits='3',decimal=',',group='\\u2009',notation='general'">0.3274287432878432992e6</mn>
                   </math>
           </stem>
           <stem type="MathML">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
               <mn data-metanorma-numberformat="number_sign='plus'">0.31e2</mn>
            </math>
         </stem>
           </p>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processed nested macros" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      admitted:[span:category[term1a\]]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
               <sections>
           <admitted>
             <expression>
               <name>
                 <span class="category">term1a</span>
               </name>
             </expression>
           </admitted>
         </sections>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes the Metanorma::Standoc index macros" do
    input = <<~INPUT
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
    output = <<~OUTPUT
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
                   <bookmark id="_" anchor="id2"/>
                 </p>
                 <p id='_'>
                   Text
                   <bookmark id="_" anchor="id3"/>
                 </p>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes the Metanorma::Standoc variant macros" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == lang:en[English] lang:fr-Latn[Français]

      this lang:en[English] lang:fr-Latn[Français] section is lang:en[silly]  lang:fr[fou]

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
        <clause id="_" inline-header='false' obligation='normative'>
          <title id="_">
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
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes the macro for editorial notes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      EDITOR: Note1

      [EDITOR]
      ====
      Note2
      ====

      [EDITOR]
      Note3
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <sections>
           <admonition id='_' type='editorial'>
             <p id='_'>Note1</p>
           </admonition>
           <admonition id='_' type='editorial'>
             <p id='_'>Note2</p>
           </admonition>
           <admonition id='_' type='editorial'>
             <p id='_'>Note3</p>
           </admonition>
         </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes the TODO custom admonition" do
    mock_uuid_increment
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause 1
      TODO: Note1

      == Clause 2
      [TODO]
      ====
      Note2
      ====

      [appendix]
      == Annex 1
      [TODO]
      Note3
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
          <sections>
             <clause id="_1" inline-header="false" obligation="normative">
                <title id="_2">
                   <bookmark id="_12" anchor="_12"/>
                   Clause 1
                </title>
             </clause>
             <clause id="_4" inline-header="false" obligation="normative">
                <title id="_5">
                   <bookmark id="_13" anchor="_13"/>
                   Clause 2
                </title>
             </clause>
          </sections>
          <annex id="_8" inline-header="false" obligation="normative">
             <title id="_9">
                <bookmark id="_14" anchor="_14"/>
                Annex 1
             </title>
          </annex>
          <review-container>
             <review id="_3" reviewer="(Unknown)" date="#{Date.today}T00:00:00Z" type="todo" from="_12" to="_12">
                <p id="_15">Note1</p>
             </review>
             <review id="_6" reviewer="(Unknown)" date="#{Date.today}T00:00:00Z" type="todo" from="_13" to="_13">
                <p id="_7">Note2</p>
             </review>
             <review id="_10" reviewer="(Unknown)" date="#{Date.today}T00:00:00Z" type="todo" from="_14" to="_14">
                <p id="_11">Note3</p>
             </review>
          </review-container>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "generates pseudocode examples, with formatting and initial indentation" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [pseudocode,subsequence="A",number="3",keep-with-next=true,keep-lines-together=true]
      [%unnumbered]
      ====
        *A* +
              [smallcap]#B#

        _C_
      ====
    INPUT
    output = <<~OUTPUT
              #{BLANK_HDR}
              <sections>
        <figure id="_"  subsequence='A' class="pseudocode" unnumbered="true" number="3" keep-with-next="true" keep-lines-together="true">
              <p id="_">\\u00a0\\u00a0<strong>A</strong><br/>
      \\u00a0\\u00a0\\u00a0\\u00a0\\u00a0\\u00a0\\u00a0\\u00a0<smallcap>B</smallcap></p>
      <p id="_">\\u00a0\\u00a0<em>C</em></p></figure>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "supplies line breaks in pseudocode" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [pseudocode]
      ====
      A
      B

      D
      E
      ====
    INPUT
    output = <<~OUTPUT
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
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "skips embedded blocks when supplying line breaks in pseudocode" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [pseudocode]
      ====
      [stem]
      ++++
      bar X' = (1)/(v) sum_(i = 1)^(v) t_(i)
      ++++
      ====
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                       <sections>
           <figure id="_" class="pseudocode">
             <formula id="_">
                            <stem type="MathML" block="true">
                 <math xmlns="http://www.w3.org/1998/Math/MathML">
                   <mstyle displaystyle="true">
                     <mover>
                       <mi>X</mi>
                       <mo>¯</mo>
                     </mover>
                     <mo>′</mo>
                     <mo>=</mo>
                     <mfrac>
                       <mn>1</mn>
                       <mi>v</mi>
                     </mfrac>
                     <mrow>
                       <munderover>
                         <mo>∑</mo>
                         <mrow>
                           <mi>i</mi>
                           <mo>=</mo>
                           <mn>1</mn>
                         </mrow>
                         <mi>v</mi>
                       </munderover>
                       <msub>
                         <mi>t</mi>
                         <mi>i</mi>
                       </msub>
                     </mrow>
                   </mstyle>
                 </math>
                 <asciimath>bar X' = (1)/(v) sum_(i = 1)^(v) t_(i)</asciimath>
               </stem>
             </formula>
           </figure>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes simple Ruby markup" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      ruby:とうきょう[東京]
      ruby:とうきょう[lang=ja,script=Hira,type=pronunciation,東京]
      ruby:Tōkyō[type=phonetic,script=Latn,東京]
      ruby:ライバル[type=annotation,親友]
      ruby:とう[東] ruby:きょう[京]
      ruby:Tō[script=Latn,東]ruby:kyō[script=Latn,京]
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
           <sections>
             <p id="_">
             <ruby><pronunciation value="とうきょう"/>東京</ruby>
             <ruby><pronunciation value="とうきょう" lang="ja" script="Hira"/>東京</ruby>
             <ruby><pronunciation value="Tōkyō" script="Latn"/>東京</ruby>
             <ruby><annotation value="ライバル"/>親友</ruby>
             <ruby><pronunciation value="とう"/>東</ruby> <ruby><pronunciation value="きょう"/>京</ruby>
             <ruby><pronunciation value="Tō" script="Latn"/>東</ruby><ruby><pronunciation value="kyō" script="Latn"/>京</ruby>
           </p>
           </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes complex Ruby markup" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      ruby:とう[ruby:tou[東\\]] ruby:なん[ruby:nan[南\\]] の方角
      ruby:たつみ[ruby:とう[東\\]{blank}ruby:なん[南\\]]
      ruby:プロテゴ[ruby:まも[護\\]{blank}れ]!
      ruby:プロテゴ[れ{blank}ruby:まも[護\\]]!
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
           <sections>
             <p id="_">
             <ruby><pronunciation value="とう"/><ruby><pronunciation value="tou"/>東</ruby></ruby> <ruby><pronunciation value="なん"/><ruby><pronunciation value="nan"/>南</ruby></ruby> の方角
             <ruby><pronunciation value="たつみ"/><ruby><pronunciation value="とう"/>東</ruby><ruby><pronunciation value="なん"/>南</ruby></ruby>
             <ruby><pronunciation value="プロテゴ"/><ruby><pronunciation value="まも"/>護</ruby>れ</ruby>!
             <ruby><pronunciation value="プロテゴ"/>れ<ruby><pronunciation value="まも"/>護</ruby></ruby>!</p>
           </p>
           </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes the footnoteblock macro" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      footnoteblock:[id1]

      [[id1]]
      [NOTE]
      --
      |===
      |a |b

      |c |d
      |===
      --

      footnoteblock:[id2]. footnoteblock:[id2]

      [[id2]]
      [NOTE]
      --
      * A
      * B
      * C
      --
    INPUT
    output = <<~OUTPUT
                  #{BLANK_HDR}
                  <sections>
                    <p id="_">
                    <fn reference='1'>
        <table id='_'>
          <thead>
            <tr id="_">
              <th id="_" valign='top' align='left'>a</th>
              <th id="_" valign='top' align='left'>b</th>
            </tr>
          </thead>
          <tbody>
            <tr id="_">
              <td id="_" valign='top' align='left'>c</td>
              <td id="_" valign='top' align='left'>d</td>
            </tr>
          </tbody>
        </table>
      </fn>
                  </p>
                  <p id="_"><fn reference="2"><ul id="_"><li><p id="_">A</p></li><li><p id="_">B</p></li><li><p id="_">C</p></li></ul></fn>. <fn reference="2"><ul id="_"><li><p id="_">A</p></li><li><p id="_">B</p></li><li><p id="_">C</p></li></ul></fn></p>
                  </sections>
             </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes the footnoteblock macro with failed reference" do
    input = <<~INPUT
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
    output = <<~OUTPUT
           #{BLANK_HDR}
       <sections>
          <p id='_'>
            <fn reference='1'>[ERROR]</fn>
          <note id="_" anchor="id2">
            <table id='_'>
              <thead>
                <tr id="_">
                  <th id="_" valign='top' align='left'>a</th>
                  <th id="_" valign='top' align='left'>b</th>
                </tr>
              </thead>
              <tbody>
                <tr id="_">
                  <td id="_" valign='top' align='left'>c</td>
                  <td id="_" valign='top' align='left'>d</td>
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
          </p>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes input form macros" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [form,id=N0,name=N1,action="/action_page.php",class="checkboxes"]
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
    output = <<~OUTPUT
        #{BLANK_HDR}
        <sections>
        <form id="_" anchor="N0" name='N1' action='/action_page.php' class="checkboxes">
        <p id='_'>
          <label for='fname'>First name:</label>
          <br/>
          <input type='text' id="_" anchor="fname" name='fname'/>
          <br/>
          <label for='lname'>Last name:</label>
          <br/>
          <input type='text' id="_" anchor="lname" name='lname'/>
          <br/>
          <label for='pwd'>Password:</label>
          <br/>
          <input type='password' id="_" anchor="pwd" name='pwd'/>
          <br/>
          <input type='radio' id="_" anchor="male" name='gender' value='male'/>
          <label for='male'>Male</label>
          <br/>
          <input type='radio' id="_" anchor="female" name='gender' value='female'/>
          <label for='female'>Female</label>
          <br/>
          <input type='radio' id="_" anchor="other" name='gender' value='other'/>
          <label for='other'>Other</label>
          <br/>
          <input type='checkbox' id="_" anchor="vehicle1" name='vehicle1' value='Bike' checked='true'/>
          <label for='vehicle1'>I have a bike</label>
          <br/>
          <input type='checkbox' id="_" anchor="vehicle2" name='vehicle2' value='Car'/>
          <label for='vehicle2'>I have a car</label>
          <br/>
          <input type='checkbox' id="_" anchor="vehicle3" name='vehicle3' value='Boat'/>
          <label for='vehicle3'>I have a boat</label>
          <br/>
          <input type='date' id="_" anchor="birthday" name='birthday'/>
          <br/>
          <label for='myfile'>Select a file:</label>
          <input type='file' id="_" anchor="myfile" name='myfile'/>
          <br/>
          <label for='cars'>Select a car:</label>
          <br/>
          <select id="_" anchor="cars" name='cars' size='4' disabled='true' multiple='true' value='fiat'>
            <option disabled='true' value='volvo'/>
            <option value='saab'/>
            <option value='fiat'/>
            <option value='audi'/>
          </select>
          <textarea id="_" anchor="t1" name='message' rows='10' cols='30' value='The cat was playing in the garden.'/>
          <input type='button' value='Click Me!' id="_"/>
          <input type='button' id="_"/>
          <input type='submit' value='Submit' id="_"/>
        </p>
      </form>
              </sections>
             </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes ToC form macros" do
    mock_uuid_increment
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[clause1]]
      == Clause 1

      [[clause1A]]
      === Clause 1A

      [[clause1Aa]]
      ==== Clause 1Aa

      [[clause1Ab]]
      ==== Clause 1Ab

      [.variant-title,type=toc]
      1Ab Clause

      [[clause1B]]
      === Clause 1B

      [[clause1Ba]]
      ==== Clause 1Ba

      [[clause2]]
      == Clause 2

      And introducing:
      toc:["//clause[@anchor = 'clause1'\\]/clause/title","//clause[@anchor = 'clause1'\\]/clause/clause/title:2"]

      toc:["//clause[@anchor = 'clause1'\\]/clause/title"]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
          <sections>
             <clause id="_1" anchor="clause1" inline-header="false" obligation="normative">
                <title id="_2">Clause 1</title>
                <clause id="_3" anchor="clause1A" inline-header="false" obligation="normative">
                   <title id="_4">Clause 1A</title>
                   <clause id="_5" anchor="clause1Aa" inline-header="false" obligation="normative">
                      <title id="_6">Clause 1Aa</title>
                   </clause>
                   <clause id="_7" anchor="clause1Ab" inline-header="false" obligation="normative">
                      <title id="_8">Clause 1Ab</title>
                      <variant-title id="_9" type="toc">1Ab Clause</variant-title>
                   </clause>
                </clause>
                <clause id="_10" anchor="clause1B" inline-header="false" obligation="normative">
                   <title id="_11">Clause 1B</title>
                   <clause id="_12" anchor="clause1Ba" inline-header="false" obligation="normative">
                      <title id="_13">Clause 1Ba</title>
                   </clause>
                </clause>
             </clause>
             <clause id="_14" anchor="clause2" inline-header="false" obligation="normative">
                <title id="_15">Clause 2</title>
                <p id="_16">And introducing:</p>
                <toc>
                   <ul id="_18">
                      <li>
                         <xref target="_4">
                            <display-text>Clause 1A</display-text>
                         </xref>
                      </li>
                      <li>
                         <ul id="_19">
                            <li>
                               <xref target="_6">
                                  <display-text>Clause 1Aa</display-text>
                               </xref>
                            </li>
                            <li>
                               <xref target="_9">
                                  <display-text>1Ab Clause</display-text>
                               </xref>
                            </li>
                         </ul>
                      </li>
                      <li>
                         <xref target="_11">
                            <display-text>Clause 1B</display-text>
                         </xref>
                      </li>
                      <li>
                         <ul id="_20">
                            <li>
                               <xref target="_13">
                                  <display-text>Clause 1Ba</display-text>
                               </xref>
                            </li>
                         </ul>
                      </li>
                   </ul>
                </toc>
                <toc>
                   <ul id="_21">
                      <li>
                         <xref target="_4">
                            <display-text>Clause 1A</display-text>
                         </xref>
                      </li>
                      <li>
                         <xref target="_11">
                            <display-text>Clause 1B</display-text>
                         </xref>
                      </li>
                   </ul>
                </toc>
             </clause>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes embed macro" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[clause1]]
      == Clause 1

      embed::spec/assets/xref_error.adoc[]
    INPUT
    output = <<~OUTPUT
      <metanorma xmlns='https://www.metanorma.org/ns/standoc' type='semantic' version='#{Metanorma::Standoc::VERSION}' flavor='standoc'>
       <bibdata type='standard'>
         <title language='en' format='text/plain'>Document title</title>
         <language>en</language>
         <script>Latn</script>
         <status>
           <stage>published</stage>
         </status>
         <copyright>
           <from>#{Date.today.year}</from>
         </copyright>
         <ext>
           <doctype>standard</doctype>
            <flavor>standoc</flavor>
         </ext>
         <relation type='derivedFrom'>
           <bibitem>
             <title language='en' format='text/plain'>X</title>
             <language>en</language>
             <script>Latn</script>
             <status>
               <stage>published</stage>
             </status>
             <copyright>
               <from>#{Date.today.year}</from>
             </copyright>
             <ext>
               <doctype>standard</doctype>
            <flavor>standoc</flavor>
             </ext>
           </bibitem>
         </relation>
              </bibdata>
              <sections>
                <clause id="_" anchor="clause1" inline-header='false' obligation='normative'>
                  <title id="_">Clause 1</title>
                </clause>
                <clause id="_" inline-header='false' obligation='normative'>
                  <title id="_">Clause</title>
                  <p id='_'>
                    <xref target='a'><display-text>b</display-text></xref>
                  </p>
                </clause>
              </sections>
      </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(Xml::C14n.format(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes embed macro with overwriting" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[clause1]]
      == Clause

      embed::spec/assets/xref_error.adoc[]
    INPUT
    output = <<~OUTPUT
      <metanorma xmlns='https://www.metanorma.org/ns/standoc' type='semantic' version='#{Metanorma::Standoc::VERSION}' flavor='standoc'>
              <bibdata type='standard'>
                  <title language='en' format='text/plain'>Document title</title>
          <language>en</language>
          <script>Latn</script>
          <status>
            <stage>published</stage>
          </status>
          <copyright>
            <from>#{Date.today.year}</from>
          </copyright>
          <ext>
            <doctype>standard</doctype>
            <flavor>standoc</flavor>
          </ext>
          <relation type='derivedFrom'>
            <bibitem>
              <title language='en' format='text/plain'>X</title>
              <language>en</language>
              <script>Latn</script>
              <status>
                <stage>published</stage>
              </status>
              <copyright>
                <from>#{Date.today.year}</from>
              </copyright>
              <ext>
                <doctype>standard</doctype>
            <flavor>standoc</flavor>
              </ext>
            </bibitem>
          </relation>
              </bibdata>
              <sections>
                <clause id="_" anchor="clause1" inline-header='false' obligation='normative'>
                  <title id="_">Clause</title>
                </clause>
              </sections>
      </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(Xml::C14n.format(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes recursive embed macro with includes, xrefs to embedded documents" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[clause1]]
      == Clause
      <<A>>
      <<A,B>>

      [[A]]
      embed::spec/assets/a1.adoc[]
    INPUT
    output = <<~OUTPUT
       <metanorma xmlns='https://www.metanorma.org/ns/standoc' type='semantic' version='#{Metanorma::Standoc::VERSION}' flavor='standoc'>
          <bibdata type='standard'>
            <title language='en' format='text/plain'>Document title</title>
            <language>en</language>
            <script>Latn</script>
            <status>
              <stage>published</stage>
            </status>
            <copyright>
              <from>#{Date.today.year}</from>
            </copyright>
            <ext>
              <doctype>standard</doctype>
            <flavor>standoc</flavor>
            </ext>
            <relation type='derivedFrom'>
              <bibitem>
                <title language='en' format='text/plain'>X</title>
                <docidentifier primary="true">DOCIDENTIFIER-1</docidentifier>
                <language>en</language>
                <script>Latn</script>
                <status>
                  <stage>published</stage>
                </status>
                <copyright>
                  <from>#{Date.today.year}</from>
                </copyright>
                <ext>
                  <doctype>standard</doctype>
            <flavor>standoc</flavor>
                </ext>
                <relation type='derivedFrom'>
                  <bibitem>
                    <title language='en' format='text/plain'>A2</title>
                    <docidentifier primary="true">DOCIDENTIFIER-2</docidentifier>
                    <language>en</language>
                    <script>Latn</script>
                    <status>
                      <stage>published</stage>
                    </status>
                    <copyright>
                      <from>#{Date.today.year}</from>
                    </copyright>
                    <ext>
                      <doctype>standard</doctype>
            <flavor>standoc</flavor>
                    </ext>
                    <relation type='derivedFrom'>
                       <bibitem>
                         <title language='en' format='text/plain'>A3</title>
                         <language>en</language>
                         <script>Latn</script>
                         <status>
                           <stage>published</stage>
                         </status>
                         <copyright>
                           <from>#{Date.today.year}</from>
                         </copyright>
                         <ext>
                           <doctype>standard</doctype>
            <flavor>standoc</flavor>
                         </ext>
                       </bibitem>
                     </relation>
                     <relation type='derivedFrom'>
                       <bibitem>
                         <title language='en' format='text/plain'>A3a</title>
                         <language>en</language>
                         <script>Latn</script>
                         <status>
                           <stage>published</stage>
                         </status>
                         <copyright>
                           <from>#{Date.today.year}</from>
                         </copyright>
                         <ext>
                           <doctype>standard</doctype>
            <flavor>standoc</flavor>
                         </ext>
                       </bibitem>
                     </relation>
                  </bibitem>
                </relation>
              </bibitem>
            </relation>
          </bibdata>
          <sections>
            <clause id="_" anchor="clause1" inline-header='false' obligation='normative'>
              <title id="_">Clause</title>
                    <p id="_">
         <xref target="A"><display-text>DOCIDENTIFIER-1</display-text></xref>
         <xref target="A"><display-text>B</display-text></xref>
       </p>
            </clause>
            <clause id="_" anchor="A" inline-header='false' obligation='normative'>
              <title id="_">Clause 1</title>
                   <p id="_">
        <xref target="B"><display-text>DOCIDENTIFIER-2</display-text></xref>
      </p>
            </clause>
            <clause id="_" anchor="B" inline-header='false' obligation='normative'>
              <title id="_">Clause 2</title>
              <p id='_'>X</p>
            </clause>
            <clause id="_" inline-header='false' obligation='normative'>
              <title id="_">Clause 3</title>
              <p id='_'>X</p>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title id="_">Clause 4</title>
              <p id="_">X</p>
              <figure id="_">
                <image src="rice_image2.png" id="_" mimetype="image/png" height="auto" width="auto"/>
              </figure>
              <figure id="_">
                <image src="../rice_image1.png" id="_" mimetype="image/png" height="auto" width="auto"/>
              </figure>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title id="_">Clause 3a</title>
              <p id="_">X</p>
              <figure id="_">
                <image src="rice_image1.png" id="_" mimetype="image/png" height="auto" width="auto"/>
              </figure>
              <figure id="_">
                <image src="subdir/rice_image2.png" id="_" mimetype="image/png" height="auto" width="auto"/>
              </figure>
            </clause>
          </sections>
       </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(Xml::C14n.format(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes std-link macro" do
    VCR.use_cassette("std-link", match_requests_on: %i[method uri body]) do
      input = <<~INPUT
        #{ISOBIB_BLANK_HDR}

        [[clause1]]
        == Clause

        std-link:[ISO 131]
        std-link:[iso:std:iso:13485:en,droploc%clause=4,text]
      INPUT
      output = <<~OUTPUT
         #{BLANK_HDR}
                  <sections>
            <clause id="_" anchor="clause1" inline-header='false' obligation='normative'>
              <title id="_">Clause</title>
              <p id='_'>
                <eref type='inline' bibitemid='ISO 131' citeas='ISO\\u00a0131'/>
                <eref type='inline' droploc='true' bibitemid='iso_std_iso_13485_en' citeas='iso:std:iso:13485:en'>
                  <localityStack>
                    <locality type='clause'>
                      <referenceFrom>4</referenceFrom>
                    </locality>
                  </localityStack>
                  <display-text>text</display-text>
                </eref>
              </p>
            </clause>
          </sections>
          <bibliography>
            <references hidden='true' normative='true'>
              <bibitem id="_" type="standard" anchor="ISO 131" hidden="true">
                <fetched/>
                <title type='title-intro' format='text/plain' language='en' script='Latn'>Acoustics</title>
                <title type='title-main' format='text/plain' language='en' script='Latn'>Expression of physical and subjective magnitudes of sound or noise in air</title>
                <title type='main' format='text/plain' language='en' script='Latn'>
                  Acoustics\\u2009—\\u2009Expression of physical and subjective magnitudes of sound
                  or noise in air
                </title>
                <uri type='src'>https://www.iso.org/standard/3944.html</uri>
                <uri type='rss'>https://www.iso.org/contents/data/standard/00/39/3944.detail.rss</uri>
                <docidentifier type='ISO' primary='true'>ISO 131</docidentifier>
                <docidentifier type="iso-reference">ISO 131(E)</docidentifier>
                <docidentifier type="URN">urn:iso:std:iso:131:stage-95.99</docidentifier>
                <docnumber>131</docnumber>
                <contributor>
                  <role type='publisher'/>
                  <organization>
                    <name>International Organization for Standardization</name>
                    <abbreviation>ISO</abbreviation>
                    <uri>www.iso.org</uri>
                  </organization>
                </contributor>
                <edition>1</edition>
                <language>en</language>
                <language>fr</language>
                <script>Latn</script>
                <status>
                  <stage>95</stage>
                  <substage>99</substage>
                </status>
                <copyright>
                  <from>1979</from>
                  <owner>
                    <organization>
                      <name>ISO</name>
                    </organization>
                  </owner>
                </copyright>
                <relation type='obsoletes'>
                  <bibitem type='standard'>
                    <formattedref format='text/plain'>ISO/R 357:1963</formattedref>
                    <docidentifier type='ISO' primary='true'>ISO/R 357:1963</docidentifier>
                  </bibitem>
                </relation>
                <relation type='instanceOf'>
                  <bibitem type='standard'>
                    <fetched/>
                    <title type='title-intro' format='text/plain' language='en' script='Latn'>Acoustics</title>
                    <title type='title-main' format='text/plain' language='en' script='Latn'>Expression of physical and subjective magnitudes of sound or noise in air</title>
                    <title type='main' format='text/plain' language='en' script='Latn'>
                      Acoustics\\u2009—\\u2009Expression of physical and subjective magnitudes of
                      sound or noise in air
                    </title>
                    <uri type='src'>https://www.iso.org/standard/3944.html</uri>
                    <uri type='rss'>https://www.iso.org/contents/data/standard/00/39/3944.detail.rss</uri>
                    <docidentifier type='ISO' primary='true'>ISO 131:1979</docidentifier>
                    <docidentifier type="iso-reference">ISO 131:1979(E)</docidentifier>
                    <docidentifier type="URN">urn:iso:std:iso:131:stage-95.99</docidentifier>
                    <docnumber>131</docnumber>
                    <date type='published'>
                      <on>1979-11</on>
                    </date>
                    <contributor>
                      <role type='publisher'/>
                      <organization>
                        <name>International Organization for Standardization</name>
                        <abbreviation>ISO</abbreviation>
                        <uri>www.iso.org</uri>
                      </organization>
                    </contributor>
                    <edition>1</edition>
                    <language>en</language>
                    <language>fr</language>
                    <script>Latn</script>
                    <status>
                      <stage>95</stage>
                      <substage>99</substage>
                    </status>
                    <copyright>
                      <from>1979</from>
                      <owner>
                        <organization>
                          <name>ISO</name>
                        </organization>
                      </owner>
                    </copyright>
                    <relation type='obsoletes'>
                      <bibitem type='standard'>
                        <formattedref format='text/plain'>ISO/R 357:1963</formattedref>
                        <docidentifier type='ISO' primary='true'>ISO/R 357:1963</docidentifier>
                      </bibitem>
                    </relation>
                    <place>Geneva</place>
                  </bibitem>
                </relation>
                <place>Geneva</place>
              </bibitem>
              <bibitem anchor="iso_std_iso_13485_en" id="_" hidden="true">
                <formattedref format="application/x-isodoc+xml">[NO INFORMATION AVAILABLE]</formattedref>
                <docidentifier type='ISO'>iso:std:iso:13485:en</docidentifier>
                <docnumber>13485:en</docnumber>
              </bibitem>
            </references>
          </bibliography>
        </metanorma>
      OUTPUT
      expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))
                  .gsub(%r{ bibitemid="_[^"]+"}, ' bibitemid="_"')))
        .to be_equivalent_to Xml::C14n.format(output)
    end
  end

  it "preserves ifdefs after preprocessing" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[clause1]]
      == Clause

      ifdef::data-uri-image[]
      A
      endif::[]
    INPUT
    output = <<~OUTPUT
      <sections>
        <clause id="_" anchor="clause1" inline-header="false" obligation="normative">
          <title id="_">Clause</title>
          <p id="_">A</p>
        </clause>
      </sections>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml = xml.at("//xmlns:sections")
    expect(strip_guid(Xml::C14n.format(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes source_include" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[clause1]]
      == Clause

      source_include:spec/fixtures/nested_file_1.yaml[]

      A

      source_include:spec/fixtures/nested_file_1.json[]
    INPUT
    output = <<~OUTPUT
       <metanorma xmlns='https://www.metanorma.org/ns/standoc' type='semantic' version='#{Metanorma::Standoc::VERSION}' flavor='standoc'>
          <bibdata type="standard">
             <title language="en" format="text/plain">Document title</title>
             <language>en</language>
             <script>Latn</script>
             <status>
                <stage>published</stage>
             </status>
             <copyright>
                <from>2025</from>
             </copyright>
             <ext>
                <doctype>standard</doctype>
                <flavor>standoc</flavor>
             </ext>
          </bibdata>
          <metanorma-extension>
             <clause obligation="normative">
                <title id="_">spec/fixtures/nested_file_1.yaml</title>
                <source>---
       name: nested file-main
       description: nested description-main
       one: nested one-main
       two: nested two-main </source>
             </clause>
             <clause obligation="normative">
                <title id="_">spec/fixtures/nested_file_1.json</title>
                <source>{
         "name": "nested file-main",
         "description": "nested description-main",
         "one": "nested one-main",
         "two": "nested two-main"
       } </source>
             </clause>
             <presentation-metadata>
                <name>TOC Heading Levels</name>
                <value>2</value>
             </presentation-metadata>
             <presentation-metadata>
                <name>HTML TOC Heading Levels</name>
                <value>2</value>
             </presentation-metadata>
             <presentation-metadata>
                <name>DOC TOC Heading Levels</name>
                <value>2</value>
             </presentation-metadata>
             <presentation-metadata>
                <name>PDF TOC Heading Levels</name>
                <value>2</value>
             </presentation-metadata>
          </metanorma-extension>
          <sections>
             <clause id="_" anchor="clause1" inline-header="false" obligation="normative">
                <title id="_">Clause</title>
                <p id="_">A</p>
             </clause>
          </sections>
       </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(strip_guid(Xml::C14n.format(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  describe "lutaml_figure macro" do
    let(:example_file) { fixtures_path("test.xmi") }
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        [lutaml_uml_datamodel_description,#{example_file}]
        --
        --

        This is lutaml_figure::[package="Wrapper root package", name="Fig B1 Full model"] figure
      TEXT
    end
    let(:output) do
      '<xref target="figure-EAID_0E029ABF_C35A_49e3_9EEA_FFD4F32780A8">'
    end

    xit "correctly renders input" do
      expect(strip_src(xml_string_content(metanorma_process(input))))
        .to(include(output))
    end
  end

  describe "lutaml_uml_datamodel_description macro" do
    subject(:convert) do
      Xml::C14n.format(
        strip_guid(
          Asciidoctor.convert(
            input, *OPTIONS
          ),
        ),
      )
    end

    let(:example_file) { fixtures_path("test.xmi") }
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        [lutaml_uml_datamodel_description,#{example_file}]
        --
        [.diagram_include_block, base_path="requirements/"]
        .....
        Diagram text
        .....

        [.include_block, package="Another", base_path="spec/fixtures/"]
        .....
        my text
        .....

        [.include_block, base_path="spec/fixtures/"]
        .....
        my text
        .....

        [.before]
        .....
        mine text
        .....

        [.before, package="Another"]
        .....
        text before Another package
        .....

        [.after, package="Another"]
        .....
        text after Another package
        .....

        [.after, package="CityGML"]
        .....
        text after CityGML package
        .....

        [.after]
        .....
        footer text
        .....
        --
      TEXT
    end

    # full testing is done in metanorma-plugin-lutaml
    xit "correctly renders input" do
      expect(convert)
        .to(include("shall be represented as a set of instances of RE_Locale"))
    end
  end
end
