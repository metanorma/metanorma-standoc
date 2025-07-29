# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Standoc::Datamodel::DiagramPreprocessor do
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
        %w[doc html xml err].each do |extension|
          path = examples_path("datamodel/common_models_diagram.#{extension}")
          FileUtils.rm_f(path)
          FileUtils.rm_f("common_models_diagram.#{extension}")
        end
        FileUtils.rm_rf("common_models_diagram_htmlimages")
      end

      it "correctly renders input" do
        Asciidoctor.convert_file(datamodel_file,
                                 backend: :standoc,
                                 safe: :safe,
                                 header_footer: true)
        expect(Canon.format_xml(strip_src(strip_guid(File.read(result_file)
          .gsub(/ filename="[^"]+"/, "")))))
          .to(be_equivalent_to(Canon.format_xml(output)))
      end
    end

    context "when complex relations" do
      let(:datamodel_file) { examples_path("datamodel/top_down_diagram.adoc") }
      let(:result_file) { examples_path("datamodel/top_down_diagram.xml") }
      let(:output) do
        [
          BLANK_HDR,
          File.read(fixtures_path("macros_datamodel/top_down_diagram.xml")),
        ].join("\n")
      end

      after do
        %w[doc html xml err].each do |extension|
          path = examples_path("datamodel/top_down_diagram.#{extension}")
          FileUtils.rm_f(path)
          FileUtils.rm_f("top_down_diagram.#{extension}")
        end
        FileUtils.rm_rf(examples_path("datamodel/plantuml"))
        FileUtils.rm_rf("top_down_diagram_htmlimages")
      end

      it "correctly renders input" do
        Asciidoctor.convert_file(datamodel_file,
                                 backend: :standoc,
                                 safe: :safe,
                                 header_footer: true)
        expect(Canon.format_xml(strip_src(strip_guid(File.read(result_file)
          .gsub(/ filename="[^"]+"/, "")))))
          .to(be_equivalent_to(Canon.format_xml(output)))
      end
    end
  end
end
