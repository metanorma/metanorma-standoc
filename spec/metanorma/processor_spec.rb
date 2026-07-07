require "spec_helper"
require "metanorma-core"
require "fileutils"

RSpec.describe Metanorma::Standoc::Processor do
  registry = Metanorma::Registry.instance
  registry.register(Metanorma::Standoc::Processor)
  processor = registry.find_processor(:standoc)

  it "registers against metanorma" do
    expect(processor).not_to be_nil
  end

  it "registers output formats against metanorma" do
    output = <<~OUTPUT
      [[:doc, "doc"], [:html, "html"], [:pdf, "pdf"], [:presentation, "presentation.xml"], [:rxl, "rxl"], [:xml, "xml"]]
    OUTPUT
    expect(processor.output_formats.sort.to_s).to be_equivalent_to output.strip
  end

  it "registers version against metanorma" do
    expect(processor.version.to_s).to match(%r{^Metanorma::Standoc })
    expect(processor.version.to_s).to include("/IsoDoc ")
  end

  it "generates IsoDoc XML from a blank document" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
    INPUT
    output = <<~"OUTPUT"
          #{BLANK_HDR}
      <sections/>
      </iso-standard>
    OUTPUT
    expect(strip_guid(processor.input_to_isodoc(input, "test")))
      .to be_xml_equivalent_to strip_guid(output)
  end

  it "generates HTML from IsoDoc XML" do
    FileUtils.rm_f "test.html"
    processor.output(<<~INPUT, "test.xml", "test.html", :html)
              <iso-standard xmlns="http://riboseinc.com/isoxml">
      <sections>
      <terms id="H" obligation="normative" displayorder="1"><fmt-title>Terms, Definitions, Symbols and Abbreviated Terms</fmt-title>
        <term id="J">
        <fmt-preferred><p>Term2</p></fmt-preferred>
      </term>
       </terms>
       </sections>
       </iso-standard>
    INPUT
    expect(strip_guid(File.read("test.html", encoding: "utf-8")
      .gsub(%r{^.*<main}m, "<main")
      .gsub(%r{</main>.*}m, "</main>")))
      .to be_equivalent_to <<~OUTPUT
           <main class="main-section"><button onclick="topFunction()" id="myBtn" title="Go to top">Top</button><div id="H"><h1><a class="anchor" href="#H"></a><a class="header" href="#H">Terms, Definitions, Symbols and Abbreviated Terms</a></h1>
         <div id="J"><h2 class="TermNum" id="_"><a class="anchor" href="#J"></a><a class="header" href="#J"></a></h2></div>
         <p class="Terms" style="text-align:left;">Term2</p>
        </div></main>
      OUTPUT
  end

  it "generates DOC from IsoDoc XML" do
    FileUtils.rm_f "test.doc"
    processor.output(<<~INPUT, "test.xml", "test.doc", :doc)
              <iso-standard xmlns="http://riboseinc.com/isoxml">
      <sections>
      <terms id="H" obligation="normative" displayorder="1"><fmt-title>Terms, Definitions, Symbols and Abbreviated Terms</fmt-title>
        <term id="J">
        <preferred>Term2</preferred>
      </term>
       </terms>
       </sections>
       </iso-standard>
    INPUT
    expect(File.read("test.doc", encoding: "utf-8"))
      .to include("Terms, Definitions, Symbols and Abbreviated Terms")
  end

  it "generates XML from IsoDoc XML" do
    FileUtils.rm_f "test.xml"
    processor.output(<<~INPUT, "test.xml", "test.xml", :xml)
              <iso-standard xmlns="http://riboseinc.com/isoxml">
      <sections>
      <terms id="H" obligation="normative" displayorder="1"><title id="_">Terms, Definitions, Symbols and Abbreviated Terms</title>
        <term id="J">
        <preferred>Term2</preferred>
      </term>
       </terms>
       </sections>
       </iso-standard>
    INPUT
    expect(File.exist?("test.xml")).to be true
  end

  it "reads scripts into blank HTML document" do
    FileUtils.rm_f "test.html"
    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :no-pdf:
      :scripts: spec/assets/scripts.html
    INPUT
    html = File.read("test.html", encoding: "utf-8")
    expect(html).to match(%r{<script>}i)
  end

  it "uses specified fonts and assets in HTML" do
    FileUtils.rm_f "test.html"
    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:
      :novalid:
      :script: Hans
      :body-font: Zapf Chancery
      :header-font: Comic Sans
      :monospace-font: Andale Mono
      :htmlstylesheet: spec/assets/html.scss
      :htmlstylesheet-override: spec/assets/html-override.css
      :htmlcoverpage: spec/assets/htmlcover.html
      :htmlintropage: spec/assets/htmlintro.html
      :scripts: spec/assets/scripts.html
      :htmltoclevels: 3

      == Level 1

      === Level 2

      ==== Level 3
    INPUT
    html = File.read("test.html", encoding: "utf-8")
    expect(html).to match(%r[pre[^{]+\{[^{]+font-family: Andale Mono;]m)
    expect(html).to match(%r[p[^{]+\{[^{]+font-family: Zapf Chancery;]m)
    expect(html).to match(%r[h1[^{]+\{[^{]+font-family: Comic Sans;]m)
    expect(html).to include("an empty html cover page")
    expect(html).to include("an empty html intro page")
    expect(html).to include("This is > a script")
    expect(html).to include("html-override")
  end

  it "uses specified fonts and assets in Word" do
    FileUtils.rm_f "test.doc"
    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :no-pdf:
      :script: Hans
      :body-font: Zapf Chancery
      :header-font: Comic Sans
      :monospace-font: Andale Mono
      :wordstylesheet: spec/assets/word.scss
      :wordstylesheet-override: spec/assets/word-override.css
      :wordcoverpage: spec/assets/wordcover.html
      :wordintropage: spec/assets/wordintro.html
      :header: spec/assets/header.html
      :doctoclevels: 3

      == Level 1

      === Level 2

      ==== Level 3
    INPUT
    html = File.read("test.doc", encoding: "utf-8")
    expect(html).to match(%r[pre[^{]+\{[^{]+font-family: Andale Mono;]m)
    expect(html).to match(%r[p[^{]+\{[^{]+font-family: Zapf Chancery;]m)
    expect(html).to match(%r[h1[^{]+\{[^{]+font-family: Comic Sans;]m)
    expect(html).to include("an empty word cover page")
    expect(html).to include("an empty word intro page")
    expect(html).to include("word-override")
    expect(html).to include('\o "1-3"')
    expect(html).to include(%[Content-ID: <header.html>
Content-Disposition: inline; filename="header.html"
Content-Transfer-Encoding: base64
Content-Type: text/html; charset="utf-8"

Ci8qIGFuIGVtcHR5IGhlYWRlciAqLwoKU1RBUlQgRE9DIElEOiA6IEVORCBET0MgSUQKCkZJTEVO
QU1FOiB0ZXN0Cgo=
])
  end

  # A document with every attribute that the html/doc/pdf attribute-extraction
  # routines read, so we can assert each routine returns a fully and correctly
  # populated options hash. The converter is initialised from the same node
  # (`conv.init`) so the @toc* / @localdir state matches a real Asciidoctor run.
  ATTRIBUTES_INPUT = <<~INPUT.freeze
    = Document title
    Author
    :docfile: test.adoc
    :nodoc:
    :novalid:
    :no-isobib:
    :script: Hans
    :body-font: BodyFont
    :header-font: HeaderFont
    :monospace-font: MonoFont
    :i18nyaml: i18n.yaml
    :relaton-render-config: relaton-render.yaml
    :scope: myscope
    :html-stylesheet: html.css
    :html-stylesheet-override: html-override.css
    :html-coverpage: html-cover.html
    :html-intropage: html-intro.html
    :scripts: scripts.html
    :scripts-override: scripts-override.html
    :scripts-pdf: scripts-pdf.html
    :data-uri-image: false
    :toclevels-html: 3
    :toclevels-doc: 4
    :toclevels-pdf: 5
    :break-up-urls-in-tables: true
    :suppress-asciimath-dup: true
    :bare: true
    :sectionsplit: true
    :sectionsplit-filename: mysplit
    :base-asset-path: /assets
    :align-cross-elements: left
    :toc-figures: true
    :toc-tables: false
    :toc-recommendations: true
    :toc-examples: false
    :fonts: MyFont
    :font-license-agreement: no-install-fonts
    :localize-number: 3
    :modspec-identifier-base: mybase
    :source-highlighter: rouge
    :word-stylesheet: word.css
    :word-stylesheet-override: word-override.css
    :standard-stylesheet: standard.css
    :header: header.html
    :wordcoverpage: word-cover.html
    :wordintropage: word-intro.html
    :ulstyle: ul-style
    :olstyle: ol-style
    :fonts-manifest: fonts-manifest.yaml
    :pdf-encrypt: true
    :pdf-encryption-length: 128
    :pdf-user-password: userpw
    :pdf-owner-password: ownerpw
    :pdf-allow-copy-content: true
    :pdf-allow-edit-content: true
    :pdf-allow-fill-in-forms: true
    :pdf-allow-assemble-document: true
    :pdf-allow-edit-annotations: true
    :pdf-allow-print: true
    :pdf-allow-print-hq: true
    :pdfkeystore: keystore.p12
    :pdfkeystorepassword: kspw
    :pdf-allow-access-content: true
    :pdf-encrypt-metadata: true
    :pdf-stylesheet: pdf.css
    :pdf-stylesheet-override: pdf-override.css
    :pdf-portfolio: portfolio.yaml

    == Clause

    Text.
  INPUT

  def extract_attributes_setup
    node = Asciidoctor.load(ATTRIBUTES_INPUT, *OPTIONS)
    conv = Metanorma::Standoc::Converter.new(:standoc, *OPTIONS)
    conv.init(node)
    [conv, node]
  end

  it "populates html_extract_attributes from a fully-attributed document" do
    conv, node = extract_attributes_setup
    a = conv.html_extract_attributes(node)
    expect(a[:script]).to eq "Hans"
    expect(a[:bodyfont]).to eq "BodyFont"
    expect(a[:headerfont]).to eq "HeaderFont"
    expect(a[:monospacefont]).to eq "MonoFont"
    expect(a[:i18nyaml]).to end_with "i18n.yaml"
    expect(a[:relatonrenderconfig]).to end_with "relaton-render.yaml"
    expect(a[:scope]).to eq "myscope"
    expect(a[:htmlstylesheet]).to eq "html.css"
    expect(a[:htmlstylesheet_override]).to eq "html-override.css"
    expect(a[:htmlcoverpage]).to eq "html-cover.html"
    expect(a[:htmlintropage]).to eq "html-intro.html"
    expect(a[:scripts]).to eq "scripts.html"
    expect(a[:scripts_override]).to eq "scripts-override.html"
    expect(a[:scripts_pdf]).to eq "scripts-pdf.html"
    expect(a[:datauriimage]).to be false
    expect(a[:htmltoclevels]).to eq "3"
    expect(a[:doctoclevels]).to eq "4"
    expect(a[:pdftoclevels]).to eq "5"
    expect(a[:breakupurlsintables]).to eq "true"
    expect(a[:suppressasciimathdup]).to be true
    expect(a[:bare]).to eq "true"
    expect(a[:sectionsplit]).to eq "true"
    expect(a[:sectionsplit_filename]).to eq "mysplit"
    expect(a[:baseassetpath]).to eq "/assets"
    expect(a[:aligncrosselements]).to eq "left"
    expect(a[:tocfigures]).to be true
    expect(a[:toctables]).to be false
    expect(a[:tocrecommendations]).to be true
    expect(a[:tocexamples]).to be false
    expect(a[:fonts]).to eq "MyFont"
    expect(a[:fontlicenseagreement]).to eq "no-install-fonts"
    expect(a[:localizenumber]).to eq "3"
    expect(a[:modspecidentifierbase]).to eq "mybase"
    expect(a[:sourcehighlighter]).to be true
  end

  it "populates doc_extract_attributes from a fully-attributed document" do
    conv, node = extract_attributes_setup
    d = conv.doc_extract_attributes(node)
    expect(d[:script]).to eq "Hans"
    expect(d[:bodyfont]).to eq "BodyFont"
    expect(d[:headerfont]).to eq "HeaderFont"
    expect(d[:monospacefont]).to eq "MonoFont"
    expect(d[:i18nyaml]).to end_with "i18n.yaml"
    expect(d[:relatonrenderconfig]).to end_with "relaton-render.yaml"
    expect(d[:scope]).to eq "myscope"
    expect(d[:wordstylesheet]).to eq "word.css"
    expect(d[:wordstylesheet_override]).to eq "word-override.css"
    expect(d[:standardstylesheet]).to eq "standard.css"
    expect(d[:header]).to eq "header.html"
    expect(d[:wordcoverpage]).to eq "word-cover.html"
    expect(d[:wordintropage]).to eq "word-intro.html"
    expect(d[:ulstyle]).to eq "ul-style"
    expect(d[:olstyle]).to eq "ol-style"
    expect(d[:htmltoclevels]).to eq "3"
    expect(d[:doctoclevels]).to eq "4"
    expect(d[:pdftoclevels]).to eq "5"
    expect(d[:breakupurlsintables]).to eq "true"
    expect(d[:suppressasciimathdup]).to eq "true"
    expect(d[:bare]).to eq "true"
    expect(d[:baseassetpath]).to eq "/assets"
    expect(d[:aligncrosselements]).to eq "left"
    expect(d[:tocfigures]).to be true
    expect(d[:toctables]).to be false
    expect(d[:tocrecommendations]).to be true
    expect(d[:tocexamples]).to be false
    expect(d[:fonts]).to eq "MyFont"
    expect(d[:fontlicenseagreement]).to eq "no-install-fonts"
    expect(d[:font_manifest]).to eq "fonts-manifest.yaml"
  end

  it "populates pdf_extract_attributes from a fully-attributed document" do
    conv, node = extract_attributes_setup
    p = conv.pdf_extract_attributes(node)
    expect(p[:pdfencrypt]).to eq "true"
    expect(p[:pdfencryptionlength]).to eq "128"
    expect(p[:pdfuserpassword]).to eq "userpw"
    expect(p[:pdfownerpassword]).to eq "ownerpw"
    expect(p[:pdfallowcopycontent]).to eq "true"
    expect(p[:pdfalloweditcontent]).to eq "true"
    expect(p[:pdfallowfillinforms]).to eq "true"
    expect(p[:pdfallowassembledocument]).to eq "true"
    expect(p[:pdfalloweditannotations]).to eq "true"
    expect(p[:pdfallowprint]).to eq "true"
    expect(p[:pdfallowprinthq]).to eq "true"
    expect(p[:pdfkeystore]).to eq "keystore.p12"
    expect(p[:pdfkeystorepassword]).to eq "kspw"
    expect(p[:pdfallowaccesscontent]).to eq "true"
    expect(p[:pdfencryptmetadata]).to eq "true"
    expect(p[:fonts]).to eq "MyFont"
    expect(p[:pdfstylesheet]).to end_with "pdf.css"
    expect(p[:pdfstylesheet_override]).to end_with "pdf-override.css"
    expect(p[:pdfportfolio]).to eq "portfolio.yaml"
    expect(p[:fontlicenseagreement]).to eq "no-install-fonts"
  end
end
