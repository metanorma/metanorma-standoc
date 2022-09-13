# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Standoc::Datamodel::DiagramPreprocessor do
  it "processes the PlantUML macro" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :no-isobib:

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
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))
      .gsub(%r{plantuml/plantuml[^./]+\.}, "plantuml/_.")))
      .to be_equivalent_to xmlpp(output)
  end

  describe "#process" do
    context "when simple models without relations" do
      let(:datamodel_file) do
        examples_path("datamodel/common_models_diagram.adoc")
      end
      let(:result_file) do
        examples_path("datamodel/common_models_diagram.xml")
      end
      let(:output) do
        [
          BLANK_HDR,
          File.read(
            fixtures_path("macros_datamodel/common_models_diagram.xml"),
          ),
        ].join
      end

      after do
        %w[doc html xml err].each do |extention|
          path = examples_path("datamodel/common_models_diagram.#{extention}")
          FileUtils.rm_f(path)
          FileUtils.rm_f("common_models_diagram.#{extention}")
        end
        FileUtils.rm_rf("common_models_diagram_htmlimages")
      end

      it "correctly renders input" do
        Asciidoctor.convert_file(datamodel_file,
                                 backend: :standoc,
                                 safe: :safe,
                                 header_footer: true)
        expect(xmlpp(strip_src(strip_guid(File.read(result_file)))))
          .to(be_equivalent_to(xmlpp(output)))
      end
    end

  end
end
