require "spec_helper"
require "fileutils"
require "relaton_iso"

RSpec.describe Metanorma::Standoc do
  before do
    # Force to download Relaton index file
    allow_any_instance_of(::Relaton::Index::Type).to receive(:actual?)
      .and_return(false)
    allow_any_instance_of(::Relaton::Index::FileIO).to receive(:check_file)
      .and_return(nil)
  end

  it "aborts on unsupported format in localbib" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :relaton-data-source: file=spec/assets/manual.bib,format=pizza

      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include("Cannot process format pizza for local relaton data source default")
    expect(File.exist?("test.xml")).to be false
  end

  it "aborts on missing file in localbib" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :relaton-data-source: file=spec/assets/fred.bib

      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include("Cannot process file spec/​assets/fred.​bib for local relaton data source default")
    expect(File.exist?("test.xml")).to be false
  end

  it "aborts on missing reference in localbib" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :relaton-data-source: spec/assets/manual.bib

        [bibliography]
        == Bibliography
        * [[[A, local-file(xyz)]]]
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include("Cannot find reference xyz for local relaton data source default")
    expect(File.exist?("test.xml")).to be false
  end

  it "warns about missing fields in asciibib" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      [bibliography]
      == Normative References

      [%bibitem]
      === Standard
      id:: iso123
      type:: standard
      contributor::
        role::: publisher
        organization:::
          name:::: ISO
      contributor::
        role::: author
        person:::
          name::::
      +
      --
      completename::
        language::: en
        content::: Fred
      --
      contributor::
        role::: author
        person:::
        name::::
          completename::::: Jack
    INPUT
    errf = File.read("test.err.html")
    expect(errf)
      .to include("Reference iso123 is missing a document identifier (docid)")
  end

  it "warns about missing fields in asciibib" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      [bibliography]
      == Normative References

      [%bibitem]
      === Standard
      type:: standard
      contributor::
        role::: publisher
        organization:::
          name:::: ISO
    INPUT
    errf = File.read("test.err.html")
    expect(errf).to include("The following reference is missing an anchor")
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      [bibliography]
      == Normative References

      [[x]]
      [%bibitem]
      === Standard
      type:: standard
      contributor::
        role::: publisher
        organization:::
          name:::: ISO
    INPUT
    errf = File.read("test.err.html")
    expect(errf).not_to include("The following reference is missing an anchor")
  end

  it "warns about malformed biblio span" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      [bibliography]
      == Normative References

      * [[[A, B]]], span:surname1[Wozniak]
    INPUT
    errf = File.read("test.err.html")
    expect(errf).to include("unrecognised key 'surname1' in <code>span:​surname1[Wozn­iak]")
  end

  it "warns that cross-reference to bibliography is not a real reference" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      [.source]
      <<iso123>>
    INPUT
    expect(File.read("test.err.html"))
      .to include("iso123 does not have a corresponding anchor ID in the bibliography")

    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      <<iso123>>

      [bibliography]
      == Bibliography

      [%bibitem]
      === RNP: A C library approach to OpenPGP
      id:: RNP
      contributor::
        role::: publisher
        organization:::
          name:::: ISO
    INPUT
    expect(File.read("test.err.html"))
      .not_to include("iso123 does not have a corresponding anchor ID in the bibliography")
  end

  it "warns of Non-reference in bibliography" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      == Normative References
      * I am not a reference
    INPUT
    expect(File.read("test.err.html")).to include("no anchor on reference")
  end

  it "Warning if terms mismatches IEV" do
    FileUtils.rm_f "test.err.html"
    #VCR.use_cassette "iev_103-01-02", record: :new_episodes do
      Asciidoctor.convert(<<~INPUT, *OPTIONS)
        = Document title
        Author
        :docfile: test.adoc
        :no-pdf:

        [bibliography]
        == Normative References
        * [[[iev,IEV]]], _iev_

        == Terms and definitions
        === Automation

        [.source]
        <<iev,clause="103-01-02">>
      INPUT
      expect(File.read("test.err.html"))
        .to include('Term "automation" does not match IEV 103-01-02 "functional"')

      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(<<~INPUT, *OPTIONS)
        = Document title
        Author
        :docfile: test.adoc
        :no-pdf:

        [bibliography]
        == Normative References
        * [[[iev,IEV]]], _iev_

        == Terms and definitions
        === Functional

        [.source]
        <<iev,clause="103-01-02">>
      INPUT
      expect(File.read("test.err.html")).not_to include("does not match IEV 103-01-02")

      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(<<~INPUT, *OPTIONS)
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :language: fr

        [bibliography]
        == Normative References
        * [[[iev,IEV]]], _iev_

        == Terms and definitions
        === Fonctionnelle, f

        [.source]
        <<iev,clause="103-01-02">>
      INPUT
      expect(File.read("test.err.html"))
        .not_to include("does not match IEV 103-01-02")
    #end
  end

  it "Abort if non-existent IEV document cited" do
    FileUtils.rm_f "test.err.html"
    begin
      #VCR.use_cassette "iev_03-01-02", record: :new_episodes do
        Asciidoctor.convert(<<~INPUT, *OPTIONS)
          = Document title
          Author
          :docfile: test.adoc
          :no-pdf:

          [bibliography]
          == Normative References
          * [[[iev,IEV]]], _iev_

          == Terms and definitions
          === Automation

          [.source]
          <<iev,clause="03-01-02">>
        INPUT
        expect do
          Asciidoctor.convert(input, *OPTIONS)
        end.to raise_error(RuntimeError)
      rescue SystemExit, RuntimeError
      #end
      expect(File.read("test.err.html"))
        .to include("The IEV document 60050-03 that has been cited does not exist")
    end
  end

  it "warns and aborts if id used twice in bibliography for distinct docids" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        [bibliography]
        == Bibliography

        * [[[abc,B]]]
        * [[[abc,C]]]
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include("Anchor abc has already been used at line")
    expect(File.exist?("test.xml")).to be false

    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        [bibliography]
        == Bibliography

        * [[[abc,B]]]
        * [[[abc,B]]]
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.not_to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .not_to include("Anchor abc has already been used at line")
  end

  it "warns if numeric normative reference" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      [bibliography]
      == Normative references
      * [[[A,1]]]
    INPUT
    Asciidoctor.convert(input, *OPTIONS)
    expect(File.read("test.err.html"))
      .to include("Numeric reference in normative references")
  end
end
