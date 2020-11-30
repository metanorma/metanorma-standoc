require "spec_helper"

RSpec.describe Asciidoctor::Standoc do
  it "processes the Asciidoctor::Standoc inline macros" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      alt:[term1]
      deprecated:[term1]
      domain:[term1]
      inherit:[<<ref1>>]
      autonumber:table[3]

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

  it "processes the Asciidoctor::Standoc variant macros" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
          expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
        expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
        expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
     <mover>
                     <mrow>
                       <mi>X</mi>
                     </mrow>
                     <mrow>
                       <mo>¯</mo>
                     </mrow>
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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

  it "processes the PlantUML macro" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)).gsub(%r{plantuml/plantuml[^./]+\.}, "plantuml/_."))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      [plantuml]
      ....
      @startuml
      Alice -> Bob: Authentication Request
      Bob --> Alice: Authentication Response

      Alice -> Bob: Another authentication Request
      Alice <-- Bob: another authentication Response
      @enduml
      ....

      [plantuml]
      ....
      Alice -> Bob: Authentication Request
      Bob --> Alice: Authentication Response

      Alice -> Bob: Another authentication Request
      Alice <-- Bob: another authentication Response
      ....

      [plantuml]
      ....
      @startuml filename
      Alice -> Bob: Authentication Request
      Bob --> Alice: Authentication Response

      Alice -> Bob: Another authentication Request
      Alice <-- Bob: another authentication Response
      @enduml
      ....
    INPUT
       #{BLANK_HDR}
       <sections><figure id="_">
  <image src="plantuml/_.png" id="_" mimetype="image/png" height="auto" width="auto"/>
</figure>
<figure id="_">
  <image src="plantuml/_.png" id="_" mimetype="image/png" height="auto" width="auto"/>
</figure>
<figure id="_">
  <image src="plantuml/filename.png" id="_" mimetype="image/png" height="auto" width="auto"/>
</figure>
        </sections>

       </standard-document>
    OUTPUT
  end

  it "processes the PlantUML macro with imagesdir" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)).gsub(%r{spec/assets/[^./]+\.}, "spec/assets/_."))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :imagesdir: spec/assets

      [plantuml]
      ....
      @startuml
      Alice -> Bob: Authentication Request
      Bob --> Alice: Authentication Response

      Alice -> Bob: Another authentication Request
      Alice <-- Bob: another authentication Response
      @enduml
      ....
   INPUT
          #{BLANK_HDR}
          <sections>
  <figure id="_">
  <image src="spec/assets/_.png" id="_" mimetype="image/png" height="auto" width="auto"/>
</figure>
</sections>
</standard-document>
OUTPUT
    end

  context 'when lutaml_diagram' do
    let(:input) do
      <<~"OUTPUT"
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        [lutaml_diagram]
        ....
        diagram MyView {
          fontname "Arial"
          title "my diagram"
          class Foo {}
        }
        ....
      OUTPUT
    end
    let(:output) do
      <<~"OUTPUT"
      #{BLANK_HDR}
        <sections>
        <figure id="_">
        <image src="spec/assets/_.png" id="_" mimetype="image/png" height="auto" width="auto"/>
        </figure>
        </sections>
        </standard-document>
      OUTPUT
    end

    it "processes the lutaml_diagram" do
      expect(
        xmlpp(
          strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true))
                      .gsub(%r{".+spec\/assets\/lutaml\/[^.\/]+\.}, %q("spec/assets/_.))))
        .to(be_equivalent_to xmlpp(output))
    end
  end

  context 'when lutaml_uml_attributes_table' do
    let(:example_file) { fixtures_path("diagram_definitions.lutaml") }
    let(:input) do
      <<~"OUTPUT"
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        [lutaml_uml_attributes_table,#{example_file},AttributeProfile]
      OUTPUT
    end
    let(:output) do
      <<~"OUTPUT"
      #{BLANK_HDR}
        <sections>
          <clause id='_' inline-header='false' obligation='normative'>
            <title>AttributeProfile</title>
            <table id='_'>
              <name>AttributeProfile attributes</name>
              <thead>
                <tr>
                  <th valign='top' align='left'>Name</th>
                  <th valign='top' align='left'>Definition</th>
                  <th valign='top' align='left'>Mandatory/ Optional/ Conditional</th>
                  <th valign='top' align='left'>Max Occur</th>
                  <th valign='top' align='left'>Data Type</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td valign='top' align='left'>addressClassProfile</td>
                  <td valign='top' align='left'>TODO: enum ‘s definition</td>
                  <td valign='top' align='left'>O</td>
                  <td valign='top' align='left'>1</td>
                  <td valign='top' align='left'>
                    <tt>CharacterString</tt>
                  </td>
                </tr>
                <tr>
                  <td valign='top' align='left'>imlicistAttributeProfile</td>
                  <td valign='top' align='left'>this is attribute definition with multiply lines</td>
                  <td valign='top' align='left'>O</td>
                  <td valign='top' align='left'>1</td>
                  <td valign='top' align='left'>
                    <tt>CharacterString</tt>
                  </td>
                </tr>
              </tbody>
            </table>
          </clause>
        </sections>
        </standard-document>
      OUTPUT
    end

    it "processes the lutaml_uml_attributes_table macro" do
      expect(
        xmlpp(
          strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true))))
        .to(be_equivalent_to(xmlpp(output)))
    end
  end

  it "processes the PlantUML macro with PlantUML disabled" do
    mock_plantuml_disabled
    expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{PlantUML not installed}).to_stderr
      #{ASCIIDOC_BLANK_HDR}

      [plantuml]
      ....
      @startuml
      Alice -> Bob: Authentication Request
      Bob --> Alice: Authentication Response

      Alice -> Bob: Another authentication Request
      Alice <-- Bob: another authentication Response
      @enduml
      ....
    INPUT

    mock_plantuml_disabled
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      [plantuml]
      ....
      @startuml
      Alice -> Bob: Authentication Request
      Bob --> Alice: Authentication Response

      Alice -> Bob: Another authentication Request
      Alice <-- Bob: another authentication Response
      @enduml
      ....
    INPUT
       #{BLANK_HDR}
       <sections>
         <sourcecode id="_" lang="plantuml">@startuml
Alice -&gt; Bob: Authentication Request
Bob --&gt; Alice: Authentication Response

Alice -&gt; Bob: Another authentication Request
Alice &lt;-- Bob: another authentication Response
@enduml</sourcecode>
        </sections>
       </standard-document>
    OUTPUT
  end

  it "processes the PlantUML macro with localdir unwritable" do
    mock_localdir_unwritable
    expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{not writable for PlantUML}).to_stderr
      #{ASCIIDOC_BLANK_HDR}

      [plantuml]
      ....
      @startuml
      Alice -> Bob: Authentication Request
      Bob --> Alice: Authentication Response

      Alice -> Bob: Another authentication Request
      Alice <-- Bob: another authentication Response
      @enduml
      ....
    INPUT

    mock_localdir_unwritable
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      [plantuml]
      ....
      @startuml
      Alice -> Bob: Authentication Request
      Bob --> Alice: Authentication Response

      Alice -> Bob: Another authentication Request
      Alice <-- Bob: another authentication Response
      @enduml
      ....
    INPUT
       #{BLANK_HDR}
       <sections>
         <sourcecode id="_" lang="plantuml">@startuml
Alice -&gt; Bob: Authentication Request
Bob --&gt; Alice: Authentication Response

Alice -&gt; Bob: Another authentication Request
Alice &lt;-- Bob: another authentication Response
@enduml</sourcecode>
        </sections>
       </standard-document>
    OUTPUT
  end

  private

  def mock_plantuml_disabled
    expect(Asciidoctor::Standoc::PlantUMLBlockMacroBackend).to receive(:plantuml_installed?) do
      raise "PlantUML not installed"
      false
    end
  end

  def mock_localdir_unwritable
    expect(Asciidoctor::Standoc::Utils).to receive(:localdir) do
      "/"
    end.exactly(2).times
  end

  def mock_localdir_unwritable
    expect(File).to receive(:writable?) do
      false
    end
  end
end
