require 'spec_helper'

# TODO: plantuml figure test
# <figure id='_'>
#   <name>Common models to be used in this standard</name>
#   <image src='models/plantuml2/views/CommonModels.png' id='_' mimetype='image/png' height='auto' width='auto'/>
# </figure>

RSpec.describe Asciidoctor::Standoc::DataModelBlockMacro do
  describe '#process' do
    let(:datamodel_file) { examples_path('datamodel/example.adoc') }
    let(:result_file) { examples_path('datamodel/example.xml') }
    let(:output) do
      [BLANK_HDR, File.read(fixtures_path('macros_datamodel/example.xml'))]
        .join("\n")
    end

    after do
      %w[doc html xml].each do |extention|
        FileUtils.rm_f("example.#{extention}")
      end
    end

    it 'correctly renders input' do
      Asciidoctor.convert_file(datamodel_file,
                               backend: :standoc,
                               safe: :safe,
                               header_footer: true)
      expect(
        xmlpp(strip_guid(File.read(result_file)))
      ).to(be_equivalent_to(xmlpp(output)))
    end
  end
end
