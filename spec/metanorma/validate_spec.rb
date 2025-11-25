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

  it "aborts on a missing include file" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      include::spec/subdir/a4.adoc[]

    INPUT
    begin
      expect do
        a = [OPTIONS[0].merge(safe: :unsafe)]
        Asciidoctor.convert(input, *a)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include("Unresolved directive in &lt;​stdin&gt; - include::​spec/​subdir/a4.​adoc[]")
  end

  it "aborts on a missing boilerplate file" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :boilerplate-authority: spec/subdir/a4.adoc

    INPUT
    begin
      expect do
        a = [OPTIONS[0].merge(safe: :unsafe)]
        Asciidoctor.convert(input, *a)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include("Specified boilerplate file does not exist: ./spec/​subdir/a4.​adoc")

    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :boilerplate-authority:#{' '}

    INPUT
    begin
      expect do
        a = [OPTIONS[0].merge(safe: :unsafe)]
        Asciidoctor.convert(input, *a)
      end.not_to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
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

    expect { Asciidoctor.convert(input, *OPTIONS) }.to abort_with_message(
      "Embedding an incomplete document with no header:",
    )
  end

  it "aborts on attaching a non-existent file" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      [bibliography]
      == Bibliography
      * [[[ievterms,attachment:(./hien/spec_helper.rb)]]]

    INPUT
    begin
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include(%(Attachment hien/​spec_helper.​rb does not exist))
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
      .to include("invalid index \"see\" cross-reference: wrong number of attributes in <code>index:​see[term]</code>")
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
      .to include("invalid index \"see\" cross-reference: wrong number of attributes in <code>index:​see[term,a,​b,c,d,e]</code>")
    expect(File.exist?("test.xml")).to be false
  end

  it "aborts on passing through invalid Metanorma XML with no format specification" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"

    # Test case 1: Invalid formula with fred element
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      == Clause

      ++++
      <formula>
      <fred/>
      <stem>
      <asciimath/>
      </stem>
      </formula>
      ++++
    INPUT
    expect { Asciidoctor.convert(input, *OPTIONS) }.to abort_with_message(
      "Invalid passthrough content",
    )

    # Test case 2: Invalid formulae element
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      == Clause

      ++++
      <formulae>
      <fred/>
      <stem>
      <asciimath/>
      </stem>
      </formulae>
      ++++
    INPUT
    expect { Asciidoctor.convert(input, *OPTIONS) }.to abort_with_message(
      "Invalid passthrough content",
    )

    # Test case 3: Valid formula without fred element - should not raise error
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      == Clause

      ++++
      <formula>
      <stem>
      <asciimath/>
      </stem>
      </formula>
      ++++
    INPUT
    expect { Asciidoctor.convert(input, *OPTIONS) }.not_to abort_with_message(
      "Invalid passthrough content",
    )

    # Test case 4: Invalid formula with format=html - should not raise error
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      == Clause

      [format=html]
      ++++
      <formula>
      <fred/>
      <stem>
      <asciimath/>
      </stem>
      </formula>
      ++++
    INPUT
    expect { Asciidoctor.convert(input, *OPTIONS) }.not_to abort_with_message(
      "Invalid passthrough content",
    )

    # Test case 5: Malformed XML - should not raise specific error
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      == Clause

      ++++
      <formula>
      <stem>
      <fred/>
      ++++
    INPUT
    expect { Asciidoctor.convert(input, *OPTIONS) }.not_to abort_with_message(
      "Invalid passthrough content",
    )
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
    #     begin
    #       expect do
    #         Asciidoctor.convert(input, *OPTIONS)
    #       end.to raise_error(RuntimeError)
    #     rescue SystemExit, RuntimeError
    #     end
    #     begin
    #       expect do
    #         Asciidoctor.convert(input, *OPTIONS)
    #       end.to output("Missing embed file: spec/assets/a5.").to_stderr
    #     rescue SystemExit, RuntimeError
    #     end
    expect { Asciidoctor.convert(input, *OPTIONS) }.to abort_with_message(
      "Missing embed file:",
    )
  end

  it "aborts on empty table" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        .Malformed table
        |===

        |===

      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include("Empty table")
    expect(File.exist?("test.xml")).to be false

    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        == metanorma-extension
        .Malformed table
        |===

        |===

      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.not_to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .not_to include("Empty table")
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
      .to include("Malformed URI: http://​a@x@x@")
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
      .not_to include("Malformed URI: http:")
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
    #       .to include("Invalid MathML")
    #     expect(File.read("test.err.html"))
    #       .to include("<mew>1<mn>3</mn>2</mn>")
    #     expect(File.read("test.err.html"))
    #       .to include("Asciimath original: sum x")
    #     expect(File.read("test.err.html"))
    #       .to include("<mo>∑</mo>")
    expect(File.exist?("test.xml")).to be false
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
  #   expect(File.read("test.err.html")).to include("latexmlmath failed to process equation")
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
    expect(File.read("test.err.html")).to include("Hanging paragraph in clause")
  end

  it "warns that video is a skipped node" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      video::video_file.mp4[]
    INPUT
    expect(File.read("test.err.html")).to include("converter missing for video node")
  end

  it "warns that figure does not have title" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      image::spec/examples/rice_images/rice_image1.png[]
    INPUT
    expect(File.read("test.err.html")).to include("Figure should have title")
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
      .to include("mismatch of callouts (1) and annotations (2)")
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
      .to include("mismatch of callouts (2) and annotations (1)")
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
      .not_to include("mismatch of callouts")
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
      .not_to include("mismatch of callouts")

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
      .not_to include("mismatch of callouts")
  end

  it "warns that Table should have title" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      |===
      |a |b |c
      |===
    INPUT
    expect(File.read("test.err.html")).to include("Table should have title")

    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      == metanorma-extension

      |===
      |a |b |c
      |===
    INPUT
    expect(File.read("test.err.html")).not_to include("Table should have title")
  end

  it "validates document against ISO XML schema" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      [align=mid-air]
      Para
    INPUT
    expect(File.read("test.err.html"))
      .to include('value of attribute "align" is invalid; must be equal to')
  end

  context "logging errors" do
    let(:input) do
      <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :no-pdf:
        :no-isobib-cache:

        [[Clause1]]
        == Clause
        [align=mid-air]
        A <<X>>

        [bibliography]
        == Normative References
        * [[[iev,ISO 0a]]], _iev_

      INPUT
    end

    it "provides context for log" do
      FileUtils.rm_f "test.xml"
      FileUtils.rm_f "test.err.html"
      begin
        input1 = <<~INPUT
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
          Asciidoctor.convert(input1, *OPTIONS)
        end.to raise_error(SystemExit)
      rescue SystemExit, RuntimeError
      end
      f = File.read("test.err.html")
      expect(f)
        .to include("ID abc has already been used at line")
      expect(f)
        .to include(%(anchor=&quot;abc&quot;))
    end

    it "logs Relaton and Metanorma errors onto Metanorma log" do
      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(input, *OPTIONS)
      f = File.read("test.err.html")
      expect(f)
        .to include("<code>ISO 0a</code>")
      expect(f)
        .to include("RELATON_3")
      expect(f)
        .to include("Is not recognized as a standards identifier")
      expect(f)
        .to include("STANDOC_38")
      expect(f)
        .to include("Crossreference target X is undefined")
      expect(f)
        .to include("STANDOC_7")
      expect(f)
        .to include("value of attribute \"align\" is invalid")
    end

    it "filters errors in Metanorma log" do
      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(
        input.sub(/:no-isobib-cache:/,
                  ":log-filter-severity: 2\n:no-isobib-cache:"), *OPTIONS
      )
      f = File.read("test.err.html")
      expect(f)
        .not_to include("<code>ISO 0a</code>")
      expect(f)
        .not_to include("RELATON_3")
      expect(f)
        .not_to include("Is not recognized as a standards identifier")
      expect(f)
        .to include("STANDOC_38")
      expect(f)
        .to include("Crossreference target X is undefined")
      expect(f)
        .not_to include("STANDOC_7")
      expect(f)
        .not_to include("value of attribute \"align\" is invalid")

      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(
        input.sub(/:no-isobib-cache:/,
                  ":log-filter-category: Relaton, Anchors \n "\
                  ":no-isobib-cache:"), *OPTIONS
      )
      f = File.read("test.err.html")
      expect(f)
        .not_to include("<code>ISO 0a</code>")
      expect(f)
        .not_to include("RELATON_3")
      expect(f)
        .not_to include("Is not recognized as a standards identifier")
      expect(f)
        .not_to include("STANDOC_38")
      expect(f)
        .not_to include("Crossreference target X is undefined")
      expect(f)
        .to include("STANDOC_7")
      expect(f)
        .to include("value of attribute \"align\" is invalid")

      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(
        input.sub(/:no-isobib-cache:/,
                  ":log-filter-category: Metanorma XML Syntax \n" \
                  ":no-isobib-cache:"), *OPTIONS
      )
      f = File.read("test.err.html")
      expect(f)
        .to include("<code>ISO 0a</code>")
      expect(f)
        .to include("RELATON_3")
      expect(f)
        .to include("Is not recognized as a standards identifier")
      expect(f)
        .to include("STANDOC_38")
      expect(f)
        .to include("Crossreference target X is undefined")
      expect(f)
        .not_to include("STANDOC_7")
      expect(f)
        .not_to include("value of attribute \"align\" is invalid")

      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(
        input.sub(/:no-isobib-cache:/,
                  ":log-filter-error-ids: STANDOC_38, RELATON_3\n" \
                  ":no-isobib-cache:"), *OPTIONS
      )
      f = File.read("test.err.html")
      expect(f)
        .not_to include("<code>ISO 0a</code>")
      expect(f)
        .not_to include("RELATON_3")
      expect(f)
        .not_to include("Is not recognized as a standards identifier")
      expect(f)
        .not_to include("STANDOC_38")
      expect(f)
        .not_to include("Crossreference target X is undefined")
      expect(f)
        .to include("STANDOC_7")
      expect(f)
        .to include("value of attribute \"align\" is invalid")
    end

    it "filters errors by location in Metanorma log" do
      FileUtils.rm_f "test.err.html"
      l = ":log-filter-error-loc: "
      Asciidoctor.convert(
        input.sub(/:no-isobib-cache:/,
                  l + '{ "from": "Clause3" }'), *OPTIONS
      )
      f = File.read("test.err.html")
      expect(f).to include("STANDOC_38")

      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(
        input.sub(/:no-isobib-cache:/,
                  l + '{ "from": "Clause1" }'), *OPTIONS
      )
      f = File.read("test.err.html")
      expect(f).not_to include("STANDOC_38")

      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(
        input.sub(/:no-isobib-cache:/,
                  l + '{ "from": "Clause1", "error_ids": ["STANDOC_39"] }'), *OPTIONS
      )
      f = File.read("test.err.html")
      expect(f).to include("STANDOC_38")

      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(
        input.sub(/:no-isobib-cache:/,
                  l + '{ "from": "Clause1", "error_ids": ["STANDOC_39", "STANDOC_38"] }'), *OPTIONS
      )
      f = File.read("test.err.html")
      expect(f).not_to include ("STANDOC_38")

      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(
        input.sub(/:no-isobib-cache:/,
                  l + '[{ "from": "Clause1", "error_ids": ["STANDOC_39", "STANDOC_38"] }, { "from": "Clause3" }]'), *OPTIONS
      )
      f = File.read("test.err.html")
      expect(f).not_to include ("STANDOC_38")
    end

    it "filters errors by location in Metanorma log using annotations" do
      FileUtils.rm_f "test.err.html"
      annotation = <<~ANNOTATION

        [from="Clause3",type="ignore-log"]
        ****
        ERRORS
        ****
      ANNOTATION
      xml = Asciidoctor.convert(
        input + annotation.sub("ignore-log", "ignore-me"), *OPTIONS
      )
      expect(xml).to include("</annotation>")

      FileUtils.rm_f "test.err.html"
      xml = Asciidoctor.convert(
        input + annotation.sub("ERRORS", ""), *OPTIONS
      )
      expect(xml).not_to include("</annotation>")
      f = File.read("test.err.html")
      expect(f).to include("STANDOC_38")

      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(
        input + annotation.sub("Clause3", "Clause1").sub("ERRORS", ""), *OPTIONS
      )
      f = File.read("test.err.html")
      expect(f).not_to include("STANDOC_38")

      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(
        input + annotation.sub("Clause3", "Clause1")
        .sub("ERRORS", "STANDOC_39"), *OPTIONS
      )
      f = File.read("test.err.html")
      expect(f).to include("STANDOC_38")

      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(
        input + annotation.sub("Clause3", "Clause1")
        .sub("ERRORS", "STANDOC_39, STANDOC_38"), *OPTIONS
      )
      f = File.read("test.err.html")
      expect(f).not_to include ("STANDOC_38")

      FileUtils.rm_f "test.err.html"
      Asciidoctor.convert(
        input + annotation.sub("Clause3", "Clause1")
        .sub("ERRORS", "STANDOC_39, STANDOC_38") +
        annotation.sub("Clause3", "Clause1").sub("ERRORS", ""), *OPTIONS
      )
      f = File.read("test.err.html")
      expect(f).not_to include ("STANDOC_38")
    end
  end

  it "warns and aborts if concept attributes are malformed" do
    FileUtils.rm_f  "test.xml"
    FileUtils.rm_f  "test.err.html"
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
      end.to raise_error (RuntimeError)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include ('processing {{&lt;​&lt;def&gt;​&gt;,term,​option=​"noital"}}: error processing ,term,​option=​"noital" as CSV')
    expect(File.exist?("test.xml")).to be false
  end

  it "warns and aborts if concept/xref does not point to term or definition" do
    FileUtils.rm_f  "test.xml"
    FileUtils.rm_f  "test.err.html"
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
      .to include(%(Term reference to <code>Terms-and-Definitions</code> missing: "Terms-and-Definitions" is not defined in document))
    expect(File.read("test.err.html"))
      .to include ("Concept term1 is pointing to jkl, which is not a term or symbol. Did you mean to point to a subterm?")
    expect(File.read("test.err.html"))
      .to include ("Concept term is pointing to abc, which is not a term or symbol")
    expect(File.read("test.err.html"))
      .not_to include ("Concept term is pointing to def, which is not a term or symbol")
    expect(File.read("test.err.html"))
      .to include ("Concept term is pointing to ghi, which is not a term or symbol")
    expect(File.exist?("test.xml")).to be false
  end

  it "warns and aborts if related/xref does not point to term or definition" do
    FileUtils.rm_f  "test.xml"
    FileUtils.rm_f  "test.err.html"
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
      .to include ("Related term is pointing to abc, which is not a term or symbol")
    expect(File.read("test.err.html"))
      .not_to include ("Related term is pointing to def, which is not a term or symbol")
    expect(File.read("test.err.html"))
      .to include ("Related term is pointing to ghi, which is not a term or symbol")
    expect(File.exist?("test.xml")).to be false
  end

  it "warns and aborts if a designation appears in a non-term clause" do
    FileUtils.rm_f  "test.xml"
    FileUtils.rm_f  "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        [[abc]]
        == Clause 1

        preferred:[ABC]

        alt:[DE&F]

        == Clause 2

        [[ghi]]
        === Clause 3

        deprecated:[GHI]
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include ("Clause not recognised as a term clause, but contains designation markup")
    expect(File.read("test.err.html"))
      .to include ("ABC, DE&amp;F")
    expect(File.read("test.err.html"))
      .to include ("GHI")
    expect(File.exist?("test.xml")).to be false
  end

  it "warns and aborts if id used twice" do
    FileUtils.rm_f  "test.xml"
    FileUtils.rm_f  "test.err.html"
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
      .to include("ID abc has already been used at line")
    expect(File.exist?("test.xml")).to be false
  end

  it "does not warn and abort if columns and rows not out of bounds" do
    FileUtils.rm_f  "test.xml"
    FileUtils.rm_f  "test.err.html"
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
        |===#{' '}
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.not_to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .not_to include ("Table exceeds maximum number of columns defined")
    expect(File.read("test.err.html"))
      .not_to include ("Table rows in table are inconsistent: check rowspan")
    expect(File.read("test.err.html"))
      .not_to include ("Table rows in table cannot go outside thead: check rowspan"
                      )
  end

  it "warns if rowspan goes across thead" do
    FileUtils.rm_f  "test.xml"
    FileUtils.rm_f  "test.err.html"
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
      .to include ("Table rows in table cannot go outside thead: check rowspan")

    FileUtils.rm_f  "test.xml"
    FileUtils.rm_f  "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        == metanorma-extension

        [cols="1,1,1,1",headerrows=2]
        |===
        3.3+| a | a

        | a
        | a | a | a | a
        |===#{' '}
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.not_to raise_error(SystemExit)
    rescue SystemExit
    end
  end

  xit "warns and aborts if columns out of bounds against colgroup" do
    FileUtils.rm_f  "test.xml"
    FileUtils.rm_f  "test.err.html"
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
        |===#{' '}
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include ("Table exceeds maximum number of columns defined (4)")
    expect(File.read("test.err.html"))
      .not_to include ("Table rows in table are inconsistent: check rowspan"
                      )
  end

  xit "warns and aborts if columns out of bounds against cell count per row" do
    FileUtils.rm_f  "test.xml"
    FileUtils.rm_f  "test.err.html"
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
        |===#{' '}
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include ("Table exceeds maximum number of columns defined (3)")
    expect(File.read("test.err.html"))
      .not_to include ("Table rows in table are inconsistent: check rowspan"
                      )
  end

  it "warns and aborts if rows out of bounds" do
    FileUtils.rm_f  "test.xml"
    FileUtils.rm_f  "test.err.html"
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
        |===#{' '}
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .not_to include ("Table exceeds maximum number of columns defined")
    expect(File.read("test.err.html"))
      .to include("Table rows in table are inconsistent: check rowspan")
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

    expect(File.read("test/test.err.html"))
      .to include("Hanging paragraph in clause")
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
      .to include("Could not resolve footnoteblock:[id1]")
  end

  it "aborts if illegal connective is used between cross-references" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      [[id1]]
      == Clause

      A

      [[id2]]
      == Clause

      <<id1;through!id2>>

    INPUT
    begin
      expect do
        a = [OPTIONS[0].merge(safe: :unsafe)]
        Asciidoctor.convert(input, *a)
      end.to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(File.read("test.err.html"))
      .to include("Illegal cross-reference connective: through")
  end

  it "Warning if xref/@target, xref/location/@target, index/@to does not point to a real anchor" do
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      <<id1>>
      <<id1;to!id2>>
      index-range:id3[(((A)))]
    INPUT
    expect(File.read("test.err.html"))
      .to include("Crossreference target id1 is undefined")
    expect(File.read("test.err.html"))
      .to include("Crossreference target id2 is undefined")
    expect(File.read("test.err.html"))
      .to include("Crossreference target id3 is undefined")
  end

  it "Warns if illegal nesting of assets within assets" do
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
      .to include("There is an instance of table nested within note")
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
      .to include("There is a crossreference to an instance of table " \
                  "nested within note")
  end

  it "Warns if illegal nesting of assets within assets with crossreferencing across a range" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      <<id1;to!id3>>

      [[id1]]
      [NOTE]
      --
      [[id2]]
      |===
      |a |b

      |c |d
      |===

      [[id3]]
      * A
      * B
      * C
      --
    INPUT
    expect(File.read("test.err.html"))
      .to include("There is a crossreference to an instance of table " \
                  "nested within note")
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
      .to include("Metadata definition list does not follow a term designation")
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
      .to include("Error: Term reference to <code>xyz</code> missing:")
    expect(File.read("test.err.html"))
      .not_to include("Did you mean to point to a subterm?")

    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      [[xyz]]
      == Terms and definitions

      === Term 1

      related:see[xyz]

      Definition

    INPUT
    expect(File.read("test.err.html"))
      .to include("Error: Term reference to <code>xyz</code> missing:")
    expect(File.read("test.err.html"))
      .to include("Did you mean to point to a subterm?")

    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      == Terms and definitions

      === Term 1

      symbol:[xyz]

      Definition

    INPUT
    expect(File.read("test.err.html"))
      .to include("Symbol reference in <code>symbol​[xyz]</code> missing:")

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
      .not_to include("Error: Term reference to <code>xyz</code> missing:")
    expect(File.read("test.err.html"))
      .not_to include("Symbol reference in <code>symbol[xyz]</code> missing:")
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
      .to include("Corrupt PNG image")
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
      .not_to include("Corrupt PNG image")
    expect(File.exist?("test.xml")).to be true
  end

  it "validates SVG in svgmap context" do
    FileUtils.cp "spec/fixtures/action_schemaexpg1.svg",
                 "action_schemaexpg1.svg"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      [svgmap%unnumbered,number=8,subsequence=A,keep-with-next=true,keep-lines-together=true]
      ====
      * <<ref1,Computer>>; http://www.example.com
      ====
    INPUT
    Asciidoctor.convert(input, *OPTIONS)
    expect(File.read("test.err.html"))
      .not_to include("Corrupt SVG image detected")
    expect(File.read("test.err.html"))
      .not_to include("SVG image warning")
    expect(File.exist?("test.xml")).to be true

    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      [[ref1]]
      .SVG title
      [.svgmap]
      ====
      image::action_schemaexpg1.svg[]

      * <<ref1,Computer>>; mn://action_schema
      * http://www.example.com[Phone]; http://www.example.com
      ====
    INPUT
    Asciidoctor.convert(input, *OPTIONS)
    expect(File.read("test.err.html"))
      .not_to include("Corrupt SVG image detected")
    expect(File.read("test.err.html"))
      .not_to include("SVG image warning")
    expect(File.read("test.err.html"))
      .not_to include("SVG unresolved internal reference")
    expect(File.exist?("test.xml")).to be true

    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      [[ref2]]
      [svgmap%unnumbered,number=8,subsequence=A,keep-with-next=true,keep-lines-together=true]
      ====
      [alt=Workmap]
      image::action_schemaexpg1.svg[]

      * <<ref1,Computer>>; mn://action_schema
      * http://www.example.com[Phone]; mn://basic_attribute_schema
      * <<express:action_schema:action_schema.basic,Coffee>>; mn://support_resource_schema
      ====
    INPUT
    Asciidoctor.convert(input, *OPTIONS)
    expect(File.read("test.err.html"))
      .not_to include("Corrupt SVG image detected")
    expect(File.read("test.err.html"))
      .not_to include("SVG image warning")
    expect(File.read("test.err.html"))
      .to include("SVG unresolved internal reference") # ref1
    expect(File.exist?("test.xml")).to be true
  end

  it "validates SVG by profile" do
    FileUtils.rm_rf "test.xml"
    FileUtils.cp "spec/fixtures/IETF-test.svg",
                 "IETF-test.svg"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      [[ref1]]
      .SVG title
      image::IETF-test.svg[]
    INPUT
    Asciidoctor.convert(input, *OPTIONS)
    expect(File.read("test.err.html"))
      .not_to include("Corrupt SVG image detected")

    FileUtils.rm_rf "test.xml"
    Asciidoctor.convert(
      input.sub(":no-pdf:",
                ":svg-conform-profile: metanorma\n:no-pdf:"), *OPTIONS
    )
    expect(File.read("test.err.html"))
      .not_to include("Corrupt SVG image detected")

    FileUtils.rm_rf "test.xml"
    Asciidoctor.convert(
      input.sub(":no-pdf:",
                ":svg-conform-profile: svg_1_2_rfc\n:no-pdf:"), *OPTIONS
    )
    expect(File.read("test.err.html"))
      .to include("Corrupt SVG image detected")

    FileUtils.rm_rf "test.xml"
    Asciidoctor.convert(
      input.sub(":no-pdf:",
                ":svg-conform-profile: :svg_1_2_rfc\n:no-pdf:"), *OPTIONS
    )
    expect(File.read("test.err.html"))
      .to include("Corrupt SVG image detected")
  end

  it "repairs SVG error" do
    FileUtils.rm_rf "test.xml"
    FileUtils.cp "spec/fixtures/missing_viewbox.svg",
                 "missing_viewbox.svg"
    expect(File.read("missing_viewbox.svg"))
      .not_to include("viewBox=")
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      [[ref1]]
      .SVG title
      image::missing_viewbox.svg[]
    INPUT
    Asciidoctor.convert(input, *OPTIONS)
    expect(File.read("test.err.html"))
      .to include("Corrupt SVG image detected")
    expect(File.read("test.err.html"))
      .to include("error found")
    expect(File.read("test.err.html"))
      .to include("fix attempted")
    expect(File.read("test.err.html"))
      .not_to include("could not be fixed")
    expect(File.read("test.err.html"))
      .not_to include("SVG image warning")
    expect(File.exist?("test.xml")).to be true
    expect(File.read("test.xml")).to include("viewBox=")
  end

  it "fails to repair SVG error" do
    FileUtils.rm_rf "test.xml"
    FileUtils.cp "spec/fixtures/gibberish.svg",
                 "gibberish.svg"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:

      [[ref1]]
      .SVG title
      image::gibberish.svg[]
    INPUT
    Asciidoctor.convert(input, *OPTIONS)

    expect(File.read("test.err.html"))
      .to include("Corrupt SVG image detected")
    expect(File.read("test.err.html"))
      .to include("error found")
    expect(File.read("test.err.html"))
      .to include("fix attempted")
    expect(File.read("test.err.html"))
      .to include("could not be fixed")
    expect(File.read("test.err.html"))
      .not_to include("SVG image warning")
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
      .to include("Image not found")
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
      .to include("Style override set for ordered list")

    Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{VALIDATING_BLANK_HDR}

      == Clause
      . A
    INPUT
    expect(File.read("test.err.html"))
      .not_to include("Style override set for ordered list")
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
      .to include("Removed duplicate designation Term1")
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

        [[a]]
        === Term1

        [[b]]
        === Term1
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.not_to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include("Term Term1 occurs twice as preferred designation: a, b")

    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        == Terms and Definitions

        [[a]]
        === Term1

        [[b]]
        === Term2

        preferred:[Term1]
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.not_to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include("Term Term1 occurs twice as preferred designation: a, b")
  end

  it "warns if image is too big for Data URI encoding" do
    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        == Clause

        image::spec/assets/Sample-jpg-image-15mb.jpeg[]
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include("Image too large for Data URI encoding")

    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :data-uri-image: false

        == Clause

        image::spec/assets/Sample-jpg-image-15mb.jpeg[]
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.not_to raise_error(SystemExit)
    rescue SystemExit
    end

    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :data-uri-maxsize: 25000000

        == Clause

        image::spec/assets/Sample-jpg-image-15mb.jpeg[]
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.not_to raise_error(SystemExit)
    rescue SystemExit
    end

    FileUtils.rm_f "test.xml"
    FileUtils.rm_f "test.err.html"
    begin
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :data-uri-maxsize: 5000000

        == Clause

        image::spec/assets/Sample-jpg-image-15mb.jpeg[]
      INPUT
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to raise_error(SystemExit)
    rescue SystemExit
    end
    expect(File.read("test.err.html"))
      .to include("Image too large for Data URI encoding")
  end

  context "warns of empty elements: " do
    it "notes" do
      FileUtils.rm_f "test.xml"
      FileUtils.rm_f "test.err.html"
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        .Caption
        [NOTE]
        --

        --
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .to include(%(note is empty))

      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        [[a]]
        [NOTE]
        --
        <<a>>
        --
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .not_to include(%(note is empty))
    end

    it "examples" do
      FileUtils.rm_f "test.xml"
      FileUtils.rm_f "test.err.html"
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        .Caption
        ====

        ====
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .to include(%(example is empty))

      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        ====
        A
        ====
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .not_to include(%(example is empty))
    end

    it "admonitions" do
      FileUtils.rm_f "test.xml"
      FileUtils.rm_f "test.err.html"
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        .Caption
        [WARNING]
        --

        --
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .to include(%(admonition is empty))

      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        [WARNING]
        --
        A
        --
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .not_to include(%(admonition is empty))
    end

    it "figures" do
      FileUtils.rm_f "test.xml"
      FileUtils.rm_f "test.err.html"
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        .Caption
        [figure]
        ====

        ====
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .to include(%(figure is empty))

      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        [figure]
        ====
        image::spec/examples/rice_images/rice_image3_1.png[]
        ====
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .not_to include(%(figure is empty))
    end

    it "quotes" do
      FileUtils.rm_f "test.xml"
      FileUtils.rm_f "test.err.html"
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        .Caption
        ____

        ____
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .to include(%(quote is empty))

      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        ____
        A
        ____
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .not_to include(%(quote is empty))
    end

    it "literals" do
      FileUtils.rm_f "test.xml"
      FileUtils.rm_f "test.err.html"
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        .Caption
        ....

        ....
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .to include(%(pre is empty))

      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        ....
        A
        ....
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .not_to include(%(pre is empty))
    end

    it "sourcecodes" do
      FileUtils.rm_f "test.xml"
      FileUtils.rm_f "test.err.html"
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        .Caption
        [source,ruby]
        ----

        ----
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .to include(%(sourcecode is empty))

      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        [source]
        ----
        &nbsp;
        ----
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .not_to include(%(sourcecode is empty))
    end

    it "formulas" do
      FileUtils.rm_f "test.xml"
      FileUtils.rm_f "test.err.html"
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        .Caption
        [stem]
        ++++

        ++++
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .to include(%(formula is empty))

      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}

        [stem]
        ++++
        1
        ++++
      INPUT
      Asciidoctor.convert(input, *OPTIONS)
      expect(File.read("test.err.html"))
        .not_to include(%(formula is empty))
    end
  end

  private

  def mock_plurimath_error(times)
    expect(Plurimath::Math)
      .to receive(:parse) do
        raise(StandardError)
      end.exactly(times).times
  end
end
