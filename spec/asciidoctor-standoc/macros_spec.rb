require "spec_helper"

RSpec.describe Asciidoctor::Standoc do
  it "processes the Asciidoctor::Standoc inline macros" do
    expect(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)).to be_equivalent_to <<~"OUTPUT"
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

  it "processes the PlantUML macro" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
  <image src="plantuml/20.png" id="_" imagetype="PNG" height="auto" width="auto"/>
</figure>
<figure id="_">
  <image src="plantuml/29.png" id="_" imagetype="PNG" height="auto" width="auto"/>
</figure>
<figure id="_">
  <image src="plantuml/filename.png" id="_" imagetype="PNG" height="auto" width="auto"/>
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
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
        </sourcecode>
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
