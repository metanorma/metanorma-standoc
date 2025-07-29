# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Standoc::Datamodel::AttributesTablePreprocessor do
  describe "#process" do
    context "when simple models without relations" do
      let(:datamodel_file) do
        examples_path("datamodel/address_class_profile.adoc")
      end
      let(:result_file) do
        examples_path("datamodel/address_class_profile.xml")
      end
      let(:output) do
        [
          BLANK_HDR,
          File.read(fixtures_path("macros_datamodel/address_class_profile.xml")),
        ]
          .join
      end

      after do
        %w[doc html xml err].each do |extension|
          path = examples_path("datamodel/address_class_profile.#{extension}")
          FileUtils.rm_f(path)
          FileUtils.rm_f("address_class_profile.#{extension}")
        end
      end

      it "correctly renders input" do
        Asciidoctor.convert_file(datamodel_file,
                                 backend: :standoc,
                                 safe: :safe,
                                 header_footer: true)
        expect(strip_guid(Canon.format_xml(File.read(result_file))))
          .to(be_equivalent_to(Canon.format_xml(output)))
      end
    end

    context "when complex relations" do
      let(:datamodel_file) do
        examples_path("datamodel/address_component_profile.adoc")
      end
      let(:result_file) do
        examples_path("datamodel/address_component_profile.xml")
      end
      let(:output) do
        path = fixtures_path("macros_datamodel/address_component_profile.xml")
        [
          BLANK_HDR,
          File.read(path),
        ]
          .join("\n")
      end

      after do
        %w[doc html xml err].each do |extension|
          path = examples_path(
            "datamodel/address_component_profile.#{extension}",
          )
          FileUtils.rm_f(path)
          FileUtils.rm_f("address_component_profile.#{extension}")
        end
      end

      it "correctly renders input" do
        Asciidoctor.convert_file(datamodel_file,
                                 backend: :standoc,
                                 safe: :safe,
                                 header_footer: true)
        expect(strip_guid(Canon.format_xml(File.read(result_file))))
          .to(be_equivalent_to(Canon.format_xml(output)))
      end
    end

    context "when missing definition" do
      let(:datamodel_file) do
        examples_path("datamodel/blank_definition_profile.adoc")
      end
      let(:result_file) do
        examples_path("datamodel/blank_definition_profile.xml")
      end
      let(:output) do
        path = fixtures_path("macros_datamodel/blank_definition_profile.xml")
        [
          BLANK_HDR,
          File.read(path),
        ].join("\n")
      end

      after do
        %w[doc html xml err].each do |extension|
          path = examples_path(
            "datamodel/blank_definition_profile.#{extension}",
          )
          FileUtils.rm_f(path)
          FileUtils.rm_f("blank_definition_profile.#{extension}")
        end
      end

      it "correctly renders input" do
        Asciidoctor.convert_file(datamodel_file,
                                 backend: :standoc,
                                 safe: :safe,
                                 header_footer: true)
        expect(strip_guid(Canon.format_xml(File.read(result_file))))
          .to(be_equivalent_to(Canon.format_xml(output)))
      end
    end
  end
end
