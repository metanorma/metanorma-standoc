require "spec_helper"

RSpec.describe Asciidoctor::Standoc do
  it "processes the Asciidoctor::Standoc inline macros" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      alt:[term1]
      deprecated:[term1]
      domain:[term1]
      inherit:[<<ref1>>]

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
  </foreword>
</preface>
<sections> </sections>
<bibliography>
  <references id='_' obligation='informative'>
    <title>Bibliography</title>
    <bibitem id='ref1'>
      <formattedref format='application/x-isodoc+xml'>
        <em>Title</em>
      </formattedref>
      <docidentifier>XYZ 123</docidentifier>
    </bibitem>
  </references>
</bibliography>
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
          <locality type='clause'>
            <referenceFrom>3.1</referenceFrom>
          </locality>
        </eref>
      </concept>
      <concept>
        <eref>
          <locality type='clause'>
            <referenceFrom>3.1</referenceFrom>
          </locality>
          word
        </eref>
      </concept>
      <concept term='term'>
        <eref>
          <locality type='clause'>
            <referenceFrom>3.1</referenceFrom>
          </locality>
          word
        </eref>
      </concept>
      <concept>
        <eref>
          <locality type='clause'>
            <referenceFrom>3.1</referenceFrom>
          </locality>
          <locality type='figure'>
            <referenceFrom>a</referenceFrom>
          </locality>
        </eref>
      </concept>
      <concept>
        <eref>
          <locality type='clause'>
            <referenceFrom>3.1</referenceFrom>
          </locality>
          <locality type='figure'>
            <referenceFrom>a</referenceFrom>
          </locality>
          word
        </eref>
      </concept>
      <concept term='term'>
        <eref>
          <locality type='clause'>
            <referenceFrom>3.1</referenceFrom>
          </locality>
          <locality type='figure'>
            <referenceFrom>a</referenceFrom>
          </locality>
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
  <references id='_' obligation='informative'>
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

        [pseudocode]
        ====
          *A* +
                [smallcap]#B#

          _C_
        ====
        INPUT
        #{BLANK_HDR}
        <sections>
  <figure id="_" class="pseudocode"><p id="_">  <strong>A</strong><br/>
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
