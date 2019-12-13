require "spec_helper"

RSpec.describe Asciidoctor::Standoc do
  it "processes the Asciidoctor::Standoc inline macros" do
    expect(xmlpp(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      alt:[term1]
      deprecated:[term1]
      domain:[term1]
    INPUT
            #{BLANK_HDR}
       <sections>
         <admitted>term1</admitted>
       <deprecates>term1</deprecates>
       <domain>term1</domain>
       </sections>
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
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)).gsub(%r{plantuml/[^.]{36}\.}, "plantuml/_."))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)).gsub(%r{spec/assets/[^.]+\.}, "spec/assets/_."))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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

  private

  def mock_plantuml_disabled
    expect(Asciidoctor::Standoc::PlantUMLBlockMacroBackend).to receive(:plantuml_installed?) do
      false
    end
  end
end
