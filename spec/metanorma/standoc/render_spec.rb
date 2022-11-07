require "metanorma"
require "spec_helper"

RSpec.describe "TestRender" do
  describe ".pdf_extract_attributes" do
    it "extracts the font manifest when present" do
      pdf_option_node = PdfOptionNode.new
      pdf_options = TestRender.pdf_extract_attributes(pdf_option_node)

      expect(pdf_options[:mn2pdf][:font_manifest]).to eq(
        pdf_option_node.attr("fonts-manifest"),
      )
    end

    it "does not inlcude the mn2pdf node when not present" do
      pdf_option_node = PdfOptionNode.new
      pdf_option_node.options["fonts-manifest"] = nil

      pdf_options = TestRender.pdf_extract_attributes(pdf_option_node)

      expect(pdf_options.fetch(:mn2pdf, nil)).to be_nil
    end
  end
end

class TestRender
  extend Metanorma::Standoc::Base
end

class PdfOptionNode
  attr_reader :options

  def initialize(options = {})
    @options = options
    @options["fonts-manifest"] = "./tmp/fake-fontist-file"
  end

  def attr(key)
    options.fetch(key, nil)
  end
end
