require "spec_helper"

RSpec.describe Asciidoctor::Standoc do
  it "flavor_name is standoc" do
    converter = Asciidoctor::Standoc::Converter.new(nil, backend: :standoc)
    expect(converter.flavor_name).to eql(:standoc)
  end
end
