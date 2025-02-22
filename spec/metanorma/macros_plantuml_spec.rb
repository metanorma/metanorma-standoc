require "spec_helper"

RSpec.describe Metanorma::Standoc do
  it "processes the PlantUML macro" do
    input = <<~INPUT
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
    output = <<~OUTPUT
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
             </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))
      .gsub(%r{plantuml/plantuml[^./]+\.}, "plantuml/_.")))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes the PlantUML macro with imagesdir" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :imagesdir: spec/assets
      :data-uri-image: false

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
    output = <<~OUTPUT
                #{BLANK_HDR}
                <sections>
        <figure id="_">
        <image src="spec/assets/_.png" id="_" mimetype="image/png" height="auto" width="auto"/>
      </figure>
      </sections>
      </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))
      .gsub(%r{spec/assets/[^./]+\.}, "spec/assets/_.")))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  context "when lutaml_diagram" do
    let(:input) do
      <<~"OUTPUT"
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets
        :data-uri-image: false

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
          </metanorma>
      OUTPUT
    end

    it "processes the lutaml_diagram" do
      expect(
        Xml::C14n.format(
          strip_guid(Asciidoctor.convert(input, *OPTIONS))
                      .gsub(%r{spec/assets/lutaml/[^./]+\.png},
                            "spec/assets/_.png"),
        ),
      ).to(be_equivalent_to(Xml::C14n.format(output)))
    end
  end

  context "when inline macro, path supplied as the second arg" do
    let(:example_file) { fixtures_path("diagram_definitions.lutaml") }
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets
        :data-uri-image: false

        lutaml_diagram::#{example_file}[]

      TEXT
    end
    let(:output) do
      <<~TEXT
        #{BLANK_HDR}
        <sections>
        <figure id="_">
        <image src="spec/assets/_.png" id="_" mimetype="image/png" height="auto" width="auto"/>
        </figure>
        </sections>
        </metanorma>
      TEXT
    end

    it "correctly renders input" do
      expect(
        Xml::C14n.format(
          strip_guid(Asciidoctor.convert(input, *OPTIONS))
          .gsub(%r{spec/assets/lutaml/[^./]+\.png},
                "spec/assets/_.png"),
        ),
      ).to(be_equivalent_to(Xml::C14n.format(output)))
    end
  end

  it "processes the PlantUML macro with PlantUML disabled" do
    mock_plantuml_disabled
    input = <<~INPUT
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
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{PlantUML not installed}).to_stderr

    mock_plantuml_disabled
    input = <<~INPUT
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
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections>
               <sourcecode id="_" lang="plantuml"><body>@startuml
      Alice -&gt; Bob: Authentication Request
      Bob --&gt; Alice: Authentication Response

      Alice -&gt; Bob: Another authentication Request
      Alice &lt;-- Bob: another authentication Response
      @enduml</body></sourcecode>
              </sections>
             </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes the PlantUML macro with localdir unwritable" do
    mock_localdir_unwritable
    input = <<~INPUT
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
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{not writable for PlantUML}).to_stderr

    mock_localdir_unwritable
    input = <<~INPUT
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
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections>
               <sourcecode id="_" lang="plantuml"><body>@startuml
      Alice -&gt; Bob: Authentication Request
      Bob --&gt; Alice: Authentication Response

      Alice -&gt; Bob: Another authentication Request
      Alice &lt;-- Bob: another authentication Response
      @enduml</body></sourcecode>
              </sections>
             </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes the PlantUML macro with mismatched delimiters" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [plantuml]
      ....
      @startuml
      Alice -> Bob: Authentication Request
      Bob --> Alice: Authentication Response

      Alice -> Bob: Another authentication Request
      Alice <-- Bob: another authentication Response
      ....
    INPUT
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{@startuml without matching @enduml in PlantUML!}).to_stderr
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections>
               <sourcecode id="_" lang="plantuml"><body>@startuml
      Alice -&gt; Bob: Authentication Request
      Bob --&gt; Alice: Authentication Response

      Alice -&gt; Bob: Another authentication Request
      Alice &lt;-- Bob: another authentication Response</body></sourcecode>
              </sections>
             </metanorma>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  private

  def mock_plantuml_disabled
    expect(Metanorma::Standoc::PlantUMLBlockMacroBackend)
      .to receive(:plantuml_installed?) do
      raise "PlantUML not installed"
    end
  end

  def mock_localdir_unwritable
    expect(Metanorma::Standoc::Utils).to receive(:localdir) do
      "/"
    end.exactly(2).times
  end

  def mock_localdir_unwritable
    expect(File).to receive(:writable?) do
      false
    end
  end
end
