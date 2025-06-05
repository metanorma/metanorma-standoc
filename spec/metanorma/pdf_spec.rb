require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Standoc do
  it "uses specified attributes in PDF" do
    FileUtils.rm_f "test.pdf"

    # Create a mock for IsoDoc::Standoc::PdfConvert
    pdf_converter = double("PdfConvert")

    # Mock the convert method to avoid actual PDF generation
    allow(pdf_converter).to receive(:convert)

    rootdir = File.expand_path(
      File.join(
        File.dirname(__FILE__), "..", ".."
      ),
    )

    # Mock the PdfConvert class constructor to return our mock and capture the attributes
    expect(IsoDoc::Standoc::PdfConvert).to receive(:new) do |attrs|
      # Verify that the attributes were correctly extracted and passed
      expect(attrs[:pdfencrypt]).to eq "true"
      expect(attrs[:pdfencryptionlength]).to eq "128"
      expect(attrs[:pdfuserpassword]).to eq "user-pass"
      expect(attrs[:pdfownerpassword]).to eq "owner-pass"
      expect(attrs[:pdfallowcopycontent]).to eq "true"
      expect(attrs[:pdfalloweditcontent]).to eq "true"
      expect(attrs[:pdfallowfillinforms]).to eq "true"
      expect(attrs[:pdfallowassembledocument]).to eq "true"
      expect(attrs[:pdfalloweditannotations]).to eq "true"
      expect(attrs[:pdfallowprint]).to eq "true"
      expect(attrs[:pdfallowprinthq]).to eq "true"
      expect(attrs[:pdfencryptmetadata]).to eq "true"
      expect(attrs[:pdfallowaccesscontent]).to eq "true"
      expect(attrs[:fonts]).to eq "Zapf Chancery"
      expect(attrs[:pdfstylesheet]).to eq File.join(rootdir, "spec/assets/pdf.scss")
      expect(attrs[:pdfstylesheet_override]).to eq File.join(rootdir, "spec/assets/pdf-override.css")
      expect(attrs[:fontlicenseagreement]).to eq "true"

      # Return the mock converter
      pdf_converter
    end

    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :script: Hans
      :body-font: Zapf Chancery
      :fonts: Zapf Chancery
      :header-font: Comic Sans
      :monospace-font: Andale Mono
      :pdf-stylesheet: spec/assets/pdf.scss
      :pdf-stylesheet-override: spec/assets/pdf-override.css
      :pdf-encrypt: true
      :pdf-encryption-length: 128
      :pdf-user-password: user-pass
      :pdf-owner-password: owner-pass
      :pdf-allow-copy-content: true
      :pdf-allow-edit-content: true
      :pdf-allow-fill-in-forms: true
      :pdf-allow-assemble-document: true
      :pdf-allow-edit-annotations: true
      :pdf-allow-print: true
      :pdf-allow-print-hq: true
      :pdf-allow-access-content: true
      :pdf-encrypt-metadata: true
      :font-license-agreement: true

      == Level 1

      === Level 2

      ==== Level 3
    INPUT
  end
end
