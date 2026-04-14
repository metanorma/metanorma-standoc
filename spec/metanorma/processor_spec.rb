require "spec_helper"
require "metanorma"
require "fileutils"

RSpec.describe Metanorma::Standoc::Processor do
  registry = Metanorma::Registry.instance
  registry.register(Metanorma::Standoc::Processor)
  processor = registry.find_processor(:standoc)

  it "registers against metanorma" do
    expect(processor).not_to be nil
  end

  it "registers output formats against metanorma" do
    output = <<~OUTPUT
      [[:doc, "doc"], [:html, "html"], [:pdf, "pdf"], [:presentation, "presentation.xml"], [:rxl, "rxl"], [:xml, "xml"]]
    OUTPUT
    expect(processor.output_formats.sort.to_s).to be_equivalent_to output.strip
  end

  it "registers version against metanorma" do
    expect(processor.version.to_s).to match(%r{^Metanorma::Standoc })
    expect(processor.version.to_s).to match(%r{/IsoDoc })
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
      .to match(/Terms, Definitions, Symbols and Abbreviated Terms/)
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
    expect(html).to match(%r[an empty html cover page])
    expect(html).to match(%r[an empty html intro page])
    expect(html).to match(%r[This is > a script])
    expect(html).to match(%r[html-override])
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
    expect(html).to match(%r[an empty word cover page])
    expect(html).to match(%r[an empty word intro page])
    expect(html).to match(%r[word-override])
    expect(html).to include('\o "1-3"')
    expect(html).to include(%[Content-ID: <header.html>
Content-Disposition: inline; filename="header.html"
Content-Transfer-Encoding: base64
Content-Type: text/html; charset="utf-8"

Ci8qIGFuIGVtcHR5IGhlYWRlciAqLwoKU1RBUlQgRE9DIElEOiA6IEVORCBET0MgSUQKCkZJTEVO
QU1FOiB0ZXN0Cgo=
])
  end
end
