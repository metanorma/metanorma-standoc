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
    expect(processor.output_formats.sort.to_s).to be_equivalent_to <<~OUTPUT
      [[:doc, "doc"], [:html, "html"], [:pdf, "pdf"], [:presentation, "presentation.xml"], [:rxl, "rxl"], [:xml, "xml"]]
    OUTPUT
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
    expect(Xml::C14n.format(strip_guid(processor.input_to_isodoc(input, "test"))))
      .to be_equivalent_to Xml::C14n.format(strip_guid(output))
  end

  it "generates HTML from IsoDoc XML" do
    FileUtils.rm_f "test.html"
    processor.output(<<~INPUT, "test.xml", "test.html", :html)
              <iso-standard xmlns="http://riboseinc.com/isoxml">
      <sections>
      <terms id="H" obligation="normative" displayorder="1"><title>Terms, Definitions, Symbols and Abbreviated Terms</title>
        <term id="J">
        <preferred>Term2</preferred>
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

  it "generates HTML from IsoDoc XML" do
    FileUtils.rm_f "test.doc"
    processor.output(<<~INPUT, "test.xml", "test.doc", :doc)
              <iso-standard xmlns="http://riboseinc.com/isoxml">
      <sections>
      <terms id="H" obligation="normative" displayorder="1"><title>Terms, Definitions, Symbols and Abbreviated Terms</title>
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
      <terms id="H" obligation="normative" displayorder="1"><title>Terms, Definitions, Symbols and Abbreviated Terms</title>
        <term id="J">
        <preferred>Term2</preferred>
      </term>
       </terms>
       </sections>
       </iso-standard>
    INPUT
    expect(File.exist?("test.xml")).to be true
  end
end
