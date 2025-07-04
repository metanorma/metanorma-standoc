require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Standoc do
  it "processes a blank document" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
    INPUT
    output = <<~OUTPUT
          #{BLANK_HDR}
      <sections/>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to strip_guid(Xml::C14n.format(output))
  end

  it "converts a blank document" do
    FileUtils.rm_f "test.doc"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
    INPUT
    output = <<~OUTPUT
          #{BLANK_HDR}
      <sections/>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to strip_guid(Xml::C14n.format(output))
    expect(File.exist?("test.doc")).to be true
    expect(File.exist?("test.pdf")).to be true
    expect(File.exist?("htmlstyle.css")).to be false
  end
end
