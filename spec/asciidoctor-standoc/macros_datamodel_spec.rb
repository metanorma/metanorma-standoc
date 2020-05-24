require 'spec_helper'

RSpec.describe Asciidoctor::Standoc::DataModelBlockMacro do
  describe '#process' do
    context 'when simple models without relations' do
      let(:datamodel_file) { examples_path('datamodel/common_models.adoc') }
      let(:result_file) { examples_path('datamodel/common_models.xml') }
      let(:output) do
        [BLANK_HDR, File.read(fixtures_path('macros_datamodel/common_models.xml'))]
          .join("\n")
      end

      after do
        %w[doc html xml err].each do |extention|
          FileUtils.rm_f(examples_path("datamodel/common_models.#{extention}"))
          FileUtils.rm_f("common_models.#{extention}")
        end
        FileUtils.rm_rf('common_models_htmlimages')
      end

      it 'correctly renders input' do
        Asciidoctor.convert_file(datamodel_file,
                                backend: :standoc,
                                safe: :safe,
                                header_footer: true)
        expect do
          xmlpp(strip_guid(File.read(result_file)))
        end.to_not raise_error
      end
    end

    context 'when complex relations' do
      let(:datamodel_file) { examples_path('datamodel/top_down.adoc') }
      let(:result_file) { examples_path('datamodel/top_down.xml') }
      let(:output) do
        [BLANK_HDR, File.read(fixtures_path('macros_datamodel/top_down.xml'))]
          .join("\n")
      end

      after do
        %w[doc html xml err].each do |extention|
          FileUtils.rm_f(examples_path("datamodel/top_down.#{extention}"))
          FileUtils.rm_f("top_down.#{extention}")
        end
        FileUtils.rm_rf(examples_path('datamodel/plantuml'))
        FileUtils.rm_rf('top_down_htmlimages')
      end

      it 'correctly renders input' do
        Asciidoctor.convert_file(datamodel_file,
                                backend: :standoc,
                                safe: :safe,
                                header_footer: true)
        expect do
          xmlpp(strip_guid(File.read(result_file)))
        end.to_not raise_error
      end
    end
  end
end
