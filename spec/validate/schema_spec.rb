require "spec_helper"

RSpec.describe Metanorma::Standoc do
  describe "schema validation" do
    it "validates a metadata-complete document against the compile schema" do
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :docnumber: 1000
        :copyright-year: 2026
        :publisher: Ribose

        == Clause
        Para
      INPUT

      expect { Asciidoctor.convert(input, *OPTIONS) }
        .to output(/Syntax Valid!/).to_stderr
    end

    it "reports schema violations with line and column in the error log" do
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :docnumber: 1000
        :copyright-year: 2026
        :publisher: Ribose

        == Clause

        === Subclause

        Para
      INPUT
      allow_any_instance_of(Metanorma::Standoc::Validate::Schema)
        .to receive(:schema_validate_errors)
        .and_return([{ line: 1, column: 1, message: "injected violation" }])

      File.delete("test.err.html") if File.exist?("test.err.html")
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html")).to include("injected violation")
    end

    it "aborts cleanly when the schema itself fails to parse" do
      conv = Metanorma::Standoc::Converter.new(:standoc, {})
      validator = Class.new do
        include Metanorma::Standoc::Validate::Schema
        def initialize(conv)
          @conv = conv
        end

        def to_xml(_doc)
          "<doc/>"
        end
      end.new(conv)
      allow(Leptris::XML::RelaxNG).to receive(:parse_file)
        .and_raise(Leptris::XML::Error, "schema parse failed: boom")
      allow(conv).to receive(:clean_abort)

      expect { validator.schema_validate({}, "stub.rng") }
        .not_to raise_error
      expect(conv).to have_received(:clean_abort)
        .with(/Schema validation failed with error/, {})
    end
  end
end
