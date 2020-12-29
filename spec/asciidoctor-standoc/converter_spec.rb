require "spec_helper"

RSpec.describe Asciidoctor::Standoc do
  it "flavor_name is standoc" do
    converter = Asciidoctor::Standoc::Converter.new(nil, backend: :standoc)
    expect(converter.flavor_name).to eql(:standoc)
  end

  it "install TNR font (cold-run)" do
    converter = Asciidoctor::Standoc::Converter.new(nil, backend: :standoc)

    font_manifest = {
      "Times New Roman" => nil,
    }

    VCR.turned_off do
      WebMock.allow_net_connect!
      converter.install_fonts_safe(font_manifest, true, false)
    end
  end
end
