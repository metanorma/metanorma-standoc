require "spec_helper"
require "relaton_iso"

RSpec.describe Metanorma::Standoc do
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
            <language>en</language>
            <script>Latn</script>
          </bibitem>
        </references>
      </bibliography>
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "processes the Metanorma::Standoc language variant macros" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      A lang:en[Hello]

      A lang:fr[_What_]

      lang:en[Hello]

      lang:en[Hello] lang:fr[Bonjour]

      lang:en[Hello] lang:fr[Bonjour] A

      lang:en[Hello] lang:fr-Latn[Bonjour] lang:de[Guten Tag] lang:eo[Bonan tagon] lang:el[Καλημέρα]

      == lang:en[Hello]

      == lang:en[Hello] lang:fr[Bonjour]

      == lang:en[Hello] lang:fr[Bonjour] http://example.com[]

      == lang:en[English] lang:fr-Latn[Français]

      this lang:en[English] lang:fr-Latn[Français] section is lang:en[silly]  lang:fr[fou]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
          <preface>
             <foreword id="_" obligation="informative">
                <title id="_">Foreword</title>
                <p id="_">
                   A
                   <span lang="en">Hello</span>
                </p>
                <p id="_">
                   A
                   <span lang="fr">
                      <em>What</em>
                   </span>
                </p>
                <p id="_" lang="en">Hello</p>
                <p id="_" lang="en">Hello</p>
                <p id="_" lang="fr">Bonjour</p>
                <p id="_">
                   <span lang="en">Hello</span>
                   <span lang="fr">Bonjour</span>
                   A
                </p>
                <p id="_" lang="en">Hello</p>
                <p id="_" lang="fr" script="Latn">Bonjour</p>
                <p id="_" lang="de">Guten Tag</p>
                <p id="_" lang="eo">Bonan tagon</p>
                <p id="_" lang="el">Καλημέρα</p>
             </foreword>
          </preface>
          <sections>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_" lang="en">Hello</title>
             </clause>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_" lang="en">Hello</title>
                <title id="_" lang="fr">Bonjour</title>
             </clause>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_">
                   <span lang="en">Hello</span>
                   <span lang="fr">Bonjour</span>
                   <link target="http://example.com"/>
                </title>
             </clause>
             <clause id="_" inline-header="false" obligation="normative">
                <title id="_" lang="en">English</title>
                <title id="_" lang="fr" script="Latn">Français</title>
                <p id="_">
                   this
                   <span lang="en">English</span>
                   <span lang="fr" script="Latn">Français</span>
                   section is
                   <span lang="en">silly</span>
                   <span lang="fr">fou</span>
                </p>
             </clause>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "processes hex, octal, and binary number formats" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      number:0xFF[]
      number:0xff[]
      number:0X1A[]
      number:0x1A.8[]
      number:0b1010[]
      number:0B1010[]
      number:0b101.1[]
      number:0o77[]
      number:0O77[]
      number:0o7.4[]
      number:0xFF[decimal=",",notation=exponential]
      number:0b1010[decimal=".",notation=exponential]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
        <p id="_">
          <stem type="MathML">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
              <mn data-metanorma-numberformat="notation='basic'">0.255e3</mn>
            </math>
          </stem>
          <stem type="MathML">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
              <mn data-metanorma-numberformat="notation='basic'">0.255e3</mn>
            </math>
          </stem>
          <stem type="MathML">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
              <mn data-metanorma-numberformat="notation='basic'">0.26e2</mn>
            </math>
          </stem>
          <stem type="MathML">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
              <mn data-metanorma-numberformat="notation='basic'">0.265e2</mn>
            </math>
          </stem>
          <stem type="MathML">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
              <mn data-metanorma-numberformat="notation='basic'">0.1e2</mn>
            </math>
          </stem>
          <stem type="MathML">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
              <mn data-metanorma-numberformat="notation='basic'">0.1e2</mn>
            </math>
          </stem>
          <stem type="MathML">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
              <mn data-metanorma-numberformat="notation='basic'">0.55e1</mn>
            </math>
          </stem>
          <stem type="MathML">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
              <mn data-metanorma-numberformat="notation='basic'">0.63e2</mn>
            </math>
          </stem>
          <stem type="MathML">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
              <mn data-metanorma-numberformat="notation='basic'">0.63e2</mn>
            </math>
          </stem>
          <stem type="MathML">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
              <mn data-metanorma-numberformat="notation='basic'">0.75e1</mn>
            </math>
          </stem>
          <stem type="MathML">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
              <mn data-metanorma-numberformat="decimal=',',notation='exponential'">0.255e3</mn>
            </math>
          </stem>
          <stem type="MathML">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
              <mn data-metanorma-numberformat="decimal='.',notation='exponential'">0.1e2</mn>
            </math>
          </stem>
        </p>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "processes the TODO custom admonition" do
    mock_uuid_increment
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause 1
      TODO: Note1

      ====
      TODO: Note4
      ====

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
                   <bookmark id="_14" anchor="_14"/>
                   Clause 1
                </title>
                <example id="_4">
                   <p id="_18">
                      <bookmark id="_15" anchor="_15"/>
                   </p>
                </example>
             </clause>
             <clause id="_6" inline-header="false" obligation="normative">
                <title id="_7">
                   <bookmark id="_16" anchor="_16"/>
                   Clause 2
                </title>
             </clause>
          </sections>
          <annex id="_10" inline-header="false" obligation="normative">
             <title id="_11">
                <bookmark id="_17" anchor="_17"/>
                Annex 1
             </title>
          </annex>
          <annotation-container>
             <annotation id="_3" reviewer="(Unknown)" type="todo" date="#{Date.today}T00:00:00Z" from="_14" to="_14">
                <p id="_19">Note1</p>
             </annotation>
             <annotation id="_5" reviewer="(Unknown)" type="todo" date="#{Date.today}T00:00:00Z" from="_15" to="_15">
                <p id="_20">Note4</p>
             </annotation>
             <annotation id="_8" reviewer="(Unknown)" type="todo" date="#{Date.today}T00:00:00Z" from="_16" to="_16">
                <p id="_9">Note2</p>
             </annotation>
             <annotation id="_12" reviewer="(Unknown)" type="todo" date="#{Date.today}T00:00:00Z" from="_17" to="_17">
                <p id="_13">Note3</p>
             </annotation>
          </annotation-container>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
             <ruby><ruby-pronunciation value="とうきょう"/>東京</ruby>
             <ruby><ruby-pronunciation value="とうきょう" lang="ja" script="Hira"/>東京</ruby>
             <ruby><ruby-pronunciation value="Tōkyō" script="Latn"/>東京</ruby>
             <ruby><ruby-annotation value="ライバル"/>親友</ruby>
             <ruby><ruby-pronunciation value="とう"/>東</ruby> <ruby><ruby-pronunciation value="きょう"/>京</ruby>
             <ruby><ruby-pronunciation value="Tō" script="Latn"/>東</ruby><ruby><ruby-pronunciation value="kyō" script="Latn"/>京</ruby>
           </p>
           </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
             <ruby><ruby-pronunciation value="とう"/><ruby><ruby-pronunciation value="tou"/>東</ruby></ruby> <ruby><ruby-pronunciation value="なん"/><ruby><ruby-pronunciation value="nan"/>南</ruby></ruby> の方角
             <ruby><ruby-pronunciation value="たつみ"/><ruby><ruby-pronunciation value="とう"/>東</ruby><ruby><ruby-pronunciation value="なん"/>南</ruby></ruby>
             <ruby><ruby-pronunciation value="プロテゴ"/><ruby><ruby-pronunciation value="まも"/>護</ruby>れ</ruby>!
             <ruby><ruby-pronunciation value="プロテゴ"/>れ<ruby><ruby-pronunciation value="まも"/>護</ruby></ruby>!</p>
           </p>
           </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
                    <fn id="_" reference='1'>
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
                  <p id="_"><fn id="_" reference="2"><ul id="_"><li><p id="_">A</p></li><li><p id="_">B</p></li><li><p id="_">C</p></li></ul></fn>. <fn id="_" reference="2"><ul id="_"><li><p id="_">A</p></li><li><p id="_">B</p></li><li><p id="_">C</p></li></ul></fn></p>
                  </sections>
             </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
            <fn id="_" reference='1'>[ERROR]</fn>
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
         <title language='en' type='main'>Document title</title>
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
             <title language='en' type='main'>X</title>
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
    expect(strip_guid(Canon.format_xml(xml.to_xml)))
      .to be_equivalent_to Canon.format_xml(output)
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
                  <title language='en' type='main'>Document title</title>
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
              <title language='en' type='main'>X</title>
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
    expect(strip_guid(Canon.format_xml(xml.to_xml)))
      .to be_equivalent_to Canon.format_xml(output)
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
            <title language='en' type='main'>Document title</title>
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
                <title language='en' type='main'>X</title>
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
                    <title language='en' type='main'>A2</title>
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
                         <title language='en' type='main'>A3</title>
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
                         <title language='en' type='main'>A3a</title>
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
                <image src="rice_image2.png" filename="rice_image2.png" id="_" mimetype="image/png" height="auto" width="auto"/>
              </figure>
              <figure id="_">
                <image src="../rice_image1.png" filename="../rice_image1.png" id="_" mimetype="image/png" height="auto" width="auto"/>
              </figure>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title id="_">Clause 3a</title>
              <p id="_">X</p>
              <figure id="_">
                <image src="rice_image1.png" filename="rice_image1.png" id="_" mimetype="image/png" height="auto" width="auto"/>
              </figure>
              <figure id="_">
                <image src="subdir/rice_image2.png" filename="subdir/rice_image2.png" id="_" mimetype="image/png" height="auto" width="auto"/>
              </figure>
            </clause>
          </sections>
       </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(Canon.format_xml(xml.to_xml)))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "processes asciidoc.log file which reflects all preprocessing, including embeds and includes" do
    FileUtils.rm_rf("spec/examples/test.asciidoc.log.txt")
    system "bundle exec asciidoctor -b standoc -r metanorma-standoc spec/examples/test.adoc"
    expect(File.exist?("spec/examples/test.asciidoc.log.txt")).to be true
    log = File.read("spec/examples/test.asciidoc.log.txt")
    source = File.read("spec/examples/test.adoc")
    expect(log).to be_equivalent_to(source)
    FileUtils.rm_rf("spec/examples/test.asciidoc.log.txt")

    FileUtils.rm_rf("spec/assets/a1.asciidoc.log.txt")
    system "bundle exec asciidoctor -b standoc -r metanorma-standoc spec/assets/a1.adoc"
    expect(File.exist?("spec/assets/a1.asciidoc.log.txt")).to be true
    log = File.read("spec/assets/a1.asciidoc.log.txt")
    expect(log).to be_equivalent_to <<~ADOC
      = X
      A
      :docidentifier: DOCIDENTIFIER-1

      == Clause 1

      <<B>>

      [[B]]
      == Clause 2 [[B]]

      X

      == Clause 3

      X

      == Clause 4

      X

      image::rice_image2.png[]


      image::../rice_image1.png[]

      == Clause 3a

      X

      image::rice_image1.png[]

      image::subdir/rice_image2.png[]

    ADOC
    FileUtils.rm_rf("spec/assets/a1.asciidoc.log.txt")
  end

  it "processes std-link macro" do
    input = <<~INPUT
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR}

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
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))
                .gsub(%r{ bibitemid="_[^"]+"}, ' bibitemid="_"')))
      .to be_equivalent_to Canon.format_xml(output)
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
    expect(strip_guid(Canon.format_xml(xml.to_xml)))
      .to be_equivalent_to Canon.format_xml(output)
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
            <title language="en" type="main">Document title</title>
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
            <semantic-metadata>
         <stage-published>true</stage-published>
      </semantic-metadata>
                  <presentation-metadata>
                <toc-heading-levels>2</toc-heading-levels>
                <html-toc-heading-levels>2</html-toc-heading-levels>
                <doc-toc-heading-levels>2</doc-toc-heading-levels>
                <pdf-toc-heading-levels>2</pdf-toc-heading-levels>
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
    expect(strip_guid(Canon.format_xml(xml.to_xml)))
      .to be_equivalent_to Canon.format_xml(output)
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
      Canon.format_xml(
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
