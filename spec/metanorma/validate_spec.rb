require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Standoc do
  it "generates error file" do
    FileUtils.rm_f "spec/assets/xref_error.err.html"
    Asciidoctor.convert_file "spec/assets/xref_error.adoc",
                             { attributes: { "backend" => "standoc" }, safe: 0,
                               header_footer: true,
                               requires: ["metanorma-standoc"],
                               failure_level: 4, mkdirs: true, to_file: nil }
    expect(File.exist?("spec/assets/xref_error.err.html")).to be true
  end

  it "provides context for log" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :no-pdf:

        [[abc]]
        == Clause 1

        [[abc]]
        == Clause 2
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include "Anchor abc has already been used at line"
    expect(File.read("test.err.html"))
      .to include %(&lt;clause id=&quot;abc&quot; inline-header=&quot;false&quot; obligation=&quot;normative&quot;&gt;)
  end

  it "aborts on embedding a headerless document" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      embed::spec/assets/subdir/a4.adoc[]

    INPUT
    begin
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(RuntimeError)
    rescue SystemExit, RuntimeError
    end
    begin
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to output("Embedding an incomplete document with no header: spec/assets/subdir/a4.adoc").to_stderr
    rescue SystemExit, RuntimeError
    end
  end

  it "aborts on an index cross-reference with too few terms" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      == Clause 1
      index:see[term]

    INPUT
    begin
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include "invalid index \"see\" cross-reference: wrong number of attributes in <code>index:​see[term]</code>"
    expect(File.exist?("test.xml")).to be false
  end

  it "aborts on an index cross-reference with too many terms" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      == Clause 1
      index:see[term,a,b,c,d,e]

    INPUT
    begin
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include "invalid index \"see\" cross-reference: wrong number of attributes in <code>index:​see[term,a,​b,c,d,e]</code>"
    expect(File.exist?("test.xml")).to be false
  end

  it "aborts on embedding a missing document" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      embed::spec/assets/a6.adoc[]

    INPUT
    begin
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(RuntimeError)
    rescue SystemExit, RuntimeError
    end
    begin
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to output("Missing embed file: spec/assets/a5.").to_stderr
    rescue SystemExit, RuntimeError
    end
  end

  it "aborts on malformed URI" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        http://a@x@x@[x]

      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include "Malformed URI: http://​a@x@x@"
    expect(File.exist?("test.xml")).to be false

    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      http://www.詹姆斯.com/[x]

    INPUT
    expect do
      Asciidoctor.convert(input, *OPTIONS)
    end.not_to raise_error
    expect(File.read("test.err.html"))
      .not_to include "Malformed URI: http:"
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
      .to include "Cannot process format pizza for local relaton data source default"
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
      .to include "Cannot process file spec/​assets/fred.​bib for local relaton data source default"
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
      .to include "Cannot find reference xyz for local relaton data source default"
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
      .to include "Reference iso123 is missing a document identifier (docid)"
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
    expect(errf).to include "The following reference is missing an anchor"
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
    expect(errf).not_to include "The following reference is missing an anchor"
  end

  it "warns and aborts if malformed MathML" do
    mock_plurimath_error(2)

    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :stem:

        [stem]
        ++++
        <math><mew>1<mn>3</mn>2</mn></math>
        ++++

        [stem]
        ++++
        sum x
        ++++
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    #     expect(File.read("test.err.html"))
    #       .to include "Invalid MathML"
    #     expect(File.read("test.err.html"))
    #       .to include "<mew>1<mn>3</mn>2</mn>"
    #     expect(File.read("test.err.html"))
    #       .to include "Asciimath original: sum x"
    #     expect(File.read("test.err.html"))
    #       .to include "<mo>∑</mo>"
    expect(File.exist?("test.xml")).to be false
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
    expect(errf).to include "unrecognised key 'surname1' in <code>span:​surname1[Wozn­iak]"
  end

  #   it "warns about malformed LaTeX" do
  #   FileUtils.rm_f "test.err.html"
  #   Asciidoctor.convert(<<~"INPUT", *OPTIONS)
  #   #{VALIDATING_BLANK_HDR}
  #
  #   == Clause 1
  #
  #   latexmath:[\\[ \\text{Odd integer = 51, \\quad \\text{Even integers } = 50 \\]]
  #
  #   === Clause 1.1
  #
  #   Subclause
  #   INPUT
  #   expect(File.read("test.err.html")).to include "latexmlmath failed to process equation"
  #   end

  #   it "warns about reparsing LaTeX" do
  #     FileUtils.rm_f "test.err.html"
  #     expect { Asciidoctor.convert(<<~"INPUT", *OPTIONS) }.to output(/Retrying/).to_stderr
  #   #{VALIDATING_BLANK_HDR}
  #
  #   == Clause 1
  #
  #   [latexmath]
  #   ++++
  #   \\pmatrix{ \\hat{e}_{\\xi} \\cr \\hat{e}_{\\eta}
  #   \\cr \\hat{e}_{\\zeta} } = {\\bf T} \\pmatrix{ \\hat{e}_x \\cr \\hat{e}_y \\cr  \\hat{e}_z },
  #   ++++
  #
  #   === Clause 1.1
  #
  #   Subclause
  #   INPUT
  #   end

  it "warns about hanging paragraphs" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      == Clause 1

      Paragraph

      === Clause 1.1

      Subclause
    INPUT
    expect(File.read("test.err.html")).to include "Hanging paragraph in clause"
  end

  it "warns that video is a skipped node" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      video::video_file.mp4[]
    INPUT
    expect(File.read("test.err.html")).to include "converter missing for video node"
  end

  it "warns that figure does not have title" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      image::spec/examples/rice_images/rice_image1.png[]
    INPUT
    expect(File.read("test.err.html")).to include "Figure should have title"
  end

  it "aborts if callouts do not match annotations" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}
        [source,ruby]
        --
        puts "Hello, world." <1>
        %w{a b c}.each do |x|
          puts x
        end
        --
        <1> This is one callout
        <2> This is another callout
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include "mismatch of callouts (1) and annotations (2)"
    expect(File.exist?("test.xml")).to be false

    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}
        [source,ruby]
        --
        puts "Hello, world." <1>
        %w{a b c}.each do |x|
          puts x
        end <2>
        --
        <1> This is one callout
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include "mismatch of callouts (2) and annotations (1)"
    expect(File.exist?("test.xml")).to be false

    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}
        [source,ruby]
        --
        puts "Hello, world." <1>
        %w{a b c}.each do |x|
          puts x
        end <2>
        --
        <1> This is one callout
        <3> This is another callout
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.not_to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .not_to include "mismatch of callouts"
    # expect(File.exist?("test.xml")).to be true

    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}
        [source,ruby]
        --
        puts "Hello, world." <1>
        %w{a b c}.each do |x|
          puts x
        end <2>
        --
        <1> This is one callout
        <2> This is another callout
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.not_to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .not_to include "mismatch of callouts"
    # expect(File.exist?("test.xml")).to be true

    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}
        [source,ruby]
        --
        puts "Hello, world." <1>
        %w{a b c}.each do |x|
          puts x
        end <2>
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.not_to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .not_to include "mismatch of callouts"
  end

  it "warns that cross-reference to bibliography is not a real reference" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      [.source]
      <<iso123>>
    INPUT
    expect(File.read("test.err.html"))
      .to include "iso123 does not have a corresponding anchor ID in the bibliography"

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
      .not_to include "iso123 does not have a corresponding anchor ID in the bibliography"
  end

  it "warns of Non-reference in bibliography" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      == Normative References
      * I am not a reference
    INPUT
    expect(File.read("test.err.html")).to include "no anchor on reference"
  end

  it "warns that Table should have title" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      |===
      |a |b |c
      |===
    INPUT
    expect(File.read("test.err.html")).to include "Table should have title"
  end

  it "validates document against ISO XML schema" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      [align=mid-air]
      Para
    INPUT
    expect(File.read("test.err.html"))
      .to include 'value of attribute "align" is invalid; must be equal to'
  end

  it "Warning if terms mismatches IEV" do
    FileUtils.rm_f "test.err.html"
    VCR.use_cassette "iev_103-01-02", record: :new_episodes do
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
        .to include 'Term "automation" does not match IEV 103-01-02 "functional"'

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
      expect(File.read("test.err.html")).not_to include "does not match IEV 103-01-02"

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
        .not_to include "does not match IEV 103-01-02"
    end
  end

  it "Abort if non-existent IEV document cited" do
    FileUtils.rm_f "test.err.html"
    begin
      VCR.use_cassette "iev_03-01-02", record: :new_episodes do
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
      end
      expect(File.read("test.err.html"))
        .to include 'The IEV document 60050-03 that has been cited does not exist'
    end
  end

  # it "No warning if attributes on formatted strong or stem extraneous to Metanomra XML" do
  #   expect { Metanorma::Standoc::Converter.new(nil,nil).validate(Nokogiri::XML(<<~INPUT)) }.not_to output('found attribute "close", but no attributes allowed here').to_stderr
  #   <standard-document>
  #   <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mfenced open="(" close=")"><mi>r</mi></mfenced></stem>
  #   </standard-document>
  # INPUT
  # end

  it "warns and aborts if concept attributes are malformed" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        == Symbols and Abbreviated Terms
        [[def]]DEF:: def

        {{<<def>>,term,option="noital"}}
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(RuntimeError)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include 'processing {{&lt;​&lt;def&gt;​&gt;,term,​option=​"noital"}}: error processing ,term,​option=​"noital" as CSV'
    expect(File.exist?("test.xml")).to be false
  end

  it "warns and aborts if concept/xref does not point to term or definition" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        [[abc]]
        == Clause 1
        [[ghi]]A:: B

        == Terms and Definitions

        [[jkl]]
        === Term1

        ==== Term2

        == Symbols and Abbreviated Terms
        [[def]]DEF:: def

        {{<<jkl>>,term1}}
        {{<<abc>>,term}}
        {{<<def>>,term}}
        {{<<ghi>>,term}}
        {{Terms and Definitions}}
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include %(Term reference to <code>Terms-and-Definitions</code> missing: "Terms-and-Definitions" is not defined in document.​ Did you mean to point to a subterm)
    expect(File.read("test.err.html"))
      .to include "Concept term1 is pointing to jkl, which is not a term or symbol. Did you mean to point to a subterm?"
    expect(File.read("test.err.html"))
      .to include "Concept term is pointing to abc, which is not a term or symbol"
    expect(File.read("test.err.html"))
      .not_to include "Concept term is pointing to def, which is not a term or symbol"
    expect(File.read("test.err.html"))
      .to include "Concept term is pointing to ghi, which is not a term or symbol"
    expect(File.exist?("test.xml")).to be false
  end

  it "warns and aborts if related/xref does not point to term or definition" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        [[abc]]
        == Clause 1
        [[ghi]]A:: B

        == Symbols and Abbreviated Terms
        [[def]]DEF:: def

        related:see[<<abc>>,term]
        related:see[<<def>>,term]
        related:see[<<ghi>>,term]
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include "Related term is pointing to abc, which is not a term or symbol"
    expect(File.read("test.err.html"))
      .not_to include "Related term is pointing to def, which is not a term or symbol"
    expect(File.read("test.err.html"))
      .to include "Related term is pointing to ghi, which is not a term or symbol"
    expect(File.exist?("test.xml")).to be false
  end

  it "warns and aborts if id used twice" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        [[abc]]
        == Clause 1

        [[abc]]
        == Clause 2
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include "Anchor abc has already been used at line"
    expect(File.exist?("test.xml")).to be false
  end

  it "warns and aborts if numeric normative reference" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        [bibliography]
        == Normative references
        * [[[A,1]]]
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include "Numeric reference in normative references"
    expect(File.exist?("test.xml")).to be false
  end

  it "does not warn and abort if columns and rows not out of bounds" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        == Clause

        [cols="1,1,1,1"]
        |===
        3.2+| a | a
        | a
        | a | a | a | a
        |===
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.not_to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .not_to include "Table exceeds maximum number of columns defined"
    expect(File.read("test.err.html"))
      .not_to include "Table rows in table are inconsistent: check rowspan"
    expect(File.read("test.err.html"))
      .not_to include "Table rows in table cannot go outside thead: check rowspan"
  end

  it "warns if rowspan goes across thead" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        == Clause

        [cols="1,1,1,1",headerrows=2]
        |===
        3.3+| a | a

        | a
        | a | a | a | a
        |===
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include "Table rows in table cannot go outside thead: check rowspan"
  end

  xit "warns and aborts if columns out of bounds against colgroup" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        [cols="1,1,1,1"]
        |===
        5+| a

        | a 4+| a
        | a | a |a |a
        |===
      INPUT
      expect { Asciidoctor.convert(input, *OPTIONS) }.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include "Table exceeds maximum number of columns defined (4)"
    expect(File.read("test.err.html"))
      .not_to include "Table rows in table are inconsistent: check rowspan"
  end

  xit "warns and aborts if columns out of bounds against cell count per row" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        |===
        2.3+| a | a

        | a | a | a
        | a | a | a
        |===
      INPUT
      expect { Asciidoctor.convert(input, *OPTIONS) }.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include "Table exceeds maximum number of columns defined (3)"
    expect(File.read("test.err.html"))
      .not_to include "Table rows in table are inconsistent: check rowspan"
  end

  it "warns and aborts if rows out of bounds" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        |===
        .4+| a | a | a | a

        | a | a | a
        | a | a | a
        |===
      INPUT
      expect { Asciidoctor.convert(input, *OPTIONS) }.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .not_to include "Table exceeds maximum number of columns defined"
    expect(File.read("test.err.html"))
      .to include "Table rows in table are inconsistent: check rowspan"
  end

  it "err file succesfully created for docfile path" do
    FileUtils.rm_rf "test"
    FileUtils.mkdir_p "test"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      = Document title
      Author
      :docfile: test#{File::ALT_SEPARATOR || File::SEPARATOR}test.adoc
      :nodoc:

      == Clause 1

      Paragraph

      === Clause 1.1

      Subclause
    INPUT

    expect(File.read("test/test.err.html")).to include "Hanging paragraph in clause"
  end

  it "Warning if no block for footnoteblock" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      footnoteblock:[id1]
    INPUT
    expect(File.read("test.err.html"))
      .to include "Could not resolve footnoteblock:[id1]"
  end

  it "Warning if xref/@target does not point to a real identifier" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      <<id1>>
    INPUT
    expect(File.read("test.err.html"))
      .to include "Crossreference target id1 is undefined"
  end

  it "Warns if illegal nessting of assets within assets" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      <<id2>>

      [[id2]]
      [NOTE]
      --
      |===
      |a |b

      |c |d
      |===

      * A
      * B
      * C
      --
    INPUT
    expect(File.read("test.err.html"))
      .to include "There is an instance of table nested within note"
  end

  it "Warns if illegal nesting of assets within assets with crossreferencing" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      <<id2>>

      [NOTE]
      --
      [[id2]]
      |===
      |a |b

      |c |d
      |===

      * A
      * B
      * C
      --
    INPUT
    expect(File.read("test.err.html"))
      .to include "There is a crossreference to an instance of table " \
                  "nested within note"
  end

  it "Warning if metadata deflist not after a designation" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      == Terms and definitions

      === Term 1

      Definition

      [%metadata]
      language:: fr
    INPUT
    expect(File.read("test.err.html"))
      .to include "Metadata definition list does not follow a term designation"
  end

  it "Warning if related term missing" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      == Terms and definitions

      === Term 1

      related:see[xyz]

      Definition

    INPUT
    expect(File.read("test.err.html"))
      .to include "Error: Term reference to <code>xyz</code> missing:"
    expect(File.read("test.err.html"))
      .not_to include "Did you mean to point to a subterm?"

    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      [[xyz]]
      == Terms and definitions

      === Term 1

      related:see[xyz]

      Definition

    INPUT
    expect(File.read("test.err.html"))
      .to include "Error: Term reference to <code>xyz</code> missing:"
    expect(File.read("test.err.html"))
      .to include "Did you mean to point to a subterm?"

    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      == Terms and definitions

      === Term 1

      symbol:[xyz]

      Definition

    INPUT
    expect(File.read("test.err.html"))
      .to include "Symbol reference in <code>symbol​[xyz]</code> missing:"

    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      == Terms and definitions

      === Term 1

      related:see[xyz]
      symbol:[xyz1]

      Definition

      === xyz

      == Symbols and abbreviated terms

      xyz1:: B

    INPUT
    expect(File.read("test.err.html"))
      .not_to include "Error: Term reference to <code>xyz</code> missing:"
    expect(File.read("test.err.html"))
      .not_to include "Symbol reference in <code>symbol[xyz]</code> missing:"
  end

  it "warns if corrupt PNG" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"

    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      == Clause
      image::spec/assets/corrupt.png[]

    INPUT
    Asciidoctor.convert(input, *OPTIONS)
    expect(File.read("test.err.html"))
      .to include "Corrupt PNG image"
    expect(File.exist?("test.xml")).to be true
  end

  it "does not warn if not corrupt PNG" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"

    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      == Clause
      image::spec/assets/correct.png[]

    INPUT

    Asciidoctor.convert(input, *OPTIONS)
    expect(File.read("test.err.html"))
      .not_to include "Corrupt PNG image"
    expect(File.exist?("test.xml")).to be true
  end

  it "warns and aborts if images does not exist" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"

    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :no-pdf:

        == Clause
        image::spec/assets/nonexistent.png[]

      INPUT

      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit
    end

    expect(File.read("test.err.html"))
      .to include "Image not found"
    expect(File.exist?("test.xml")).to be false
  end

  it "warns of explicit style set on ordered list" do
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      == Clause
      [arabic]
      . A
    INPUT
    expect(File.read("test.err.html"))
      .to include "Style override set for ordered list"

    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      == Clause
      . A
    INPUT
    expect(File.read("test.err.html"))
      .not_to include "Style override set for ordered list"
  end

  it "warns if two identical term designations in the same term" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    input = <<~INPUT
      #{VALIDATING_BLANK_HDR}

      == Terms and Definitions

      === Term1

      preferred:[Term1]
    INPUT
    Asciidoctor.convert(input, *OPTIONS)
    expect(File.read("test.err.html"))
      .to include "Removed duplicate designation Term1"
  end

  it "warns if two identical preferred term designations" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        == Terms and Definitions

        === Term1

        === Term1
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.not_to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include "Term Term1 occurs twice as preferred designation"

    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        == Terms and Definitions

        === Term1

        === Term2

        preferred:[Term1]
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.not_to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include "Term Term1 occurs twice as preferred designation"
  end

  private

  def mock_plurimath_error(times)
    expect(Plurimath::Math)
      .to receive(:parse) do
        raise(StandardError)
      end.exactly(times).times
  end
end
