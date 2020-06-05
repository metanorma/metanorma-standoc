require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
end

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "bundler/setup"
require "asciidoctor"
require "metanorma-standoc"
require "rspec/matchers"
require "equivalent-xml"
require "metanorma"
require "metanorma/standoc"
require "rexml/document"
require 'byebug'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def strip_guid(x)
  x.gsub(%r{ id="_[^"]+"}, ' id="_"').gsub(%r{ target="_[^"]+"}, ' target="_"')
end

def strip_src(xml)
  xml.gsub(/\ssrc="[^"]+"/, ' src="_"')
end

def xmlpp(x)
  s = ""
  f = REXML::Formatters::Pretty.new(2)
  f.compact = true
  f.write(REXML::Document.new(x),s)
  s
end

ASCIIDOC_BLANK_HDR = <<~"HDR"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:

HDR

DUMBQUOTE_BLANK_HDR = <<~"HDR"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :smartquotes: false

HDR

ISOBIB_BLANK_HDR = <<~"HDR"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib-cache:

HDR

FLUSH_CACHE_ISOBIB_BLANK_HDR = <<~"HDR"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :flush-caches:

HDR

CACHED_ISOBIB_BLANK_HDR = <<~"HDR"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:

HDR

LOCAL_CACHED_ISOBIB_BLANK_HDR = <<~"HDR"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :local-cache:

HDR

LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR = <<~"HDR"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :local-cache-only:

HDR

VALIDATING_BLANK_HDR = <<~"HDR"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :no-isobib:

HDR

NORM_REF_BOILERPLATE = <<~"HDR"
<p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
HDR

BLANK_HDR = <<~"HDR"
<?xml version="1.0" encoding="UTF-8"?>
<standard-document xmlns="https://www.metanorma.org/ns/standoc">
<bibdata type="standard">
<title language="en" format="text/plain">Document title</title>
  <language>en</language>
  <script>Latn</script>
  <status><stage>published</stage></status>
  <copyright>
    <from>#{Time.new.year}</from>
  </copyright>
  <ext>
  <doctype>article</doctype>
  </ext>
</bibdata>
HDR

HTML_HDR = <<~END
        <html xmlns:epub="http://www.idpf.org/2007/ops">
          <head>
            <title>test</title>
          </head>
          <body lang="EN-US" link="blue" vlink="#954F72">
            <div class="title-section">
              <p>&#160;</p>
            </div>
            <br/>
            <div class="prefatory-section">
              <p>&#160;</p>
            </div>
            <br/>
            <div class="main-section">
END

WORD_HDR = <<~END
       <html xmlns:epub="http://www.idpf.org/2007/ops">
         <head>
           <title>test</title>
         </head>
         <body lang="EN-US" link="blue" vlink="#954F72">
           <div class="WordSection1">
             <p>&#160;</p>
           </div>
           <br clear="all" class="section"/>
           <div class="WordSection2">
             <p>&#160;</p>
           </div>
           <br clear="all" class="section"/>
           <div class="WordSection3">
END

def examples_path(path)
  File.join(File.expand_path('./examples', __dir__), path)
end

def fixtures_path(path)
  File.join(File.expand_path('./fixtures', __dir__), path)
end

def stub_fetch_ref(**opts)
  xml = ""

  hit = double("hit")
  expect(hit).to receive(:"[]").with("title") do
    Nokogiri::XML(xml).at("//docidentifier").content
  end.at_least(:once)

  hit_instance = double("hit_instance")
  expect(hit_instance).to receive(:hit).and_return(hit).at_least(:once)
  expect(hit_instance).to receive(:to_xml) do |builder, opt|
    expect(builder).to be_instance_of Nokogiri::XML::Builder
    expect(opt).to eq opts
    builder << xml
  end.at_least :once

  hit_page = double("hit_page")
  expect(hit_page).to receive(:first).and_return(hit_instance).at_least :once

  hit_pages = double("hit_pages")
  expect(hit_pages).to receive(:first).and_return(hit_page).at_least :once

  expect(Isobib::IsoBibliography).to receive(:search).
    and_wrap_original do |search, *args|
    code = args[0]
    expect(code).to be_instance_of String
    xml = get_xml(search, code, opts)
    hit_pages
  end.at_least :once
end

private

def get_xml(search, code, opts)
  c = code.gsub(%r{[\/\s:-]}, "_").sub(%r{_+$}, "").downcase
  o = opts.keys.join "_"
  file = examples_path("#{[c, o].join '_'}.xml")
  if File.exist? file
    File.read file
  else
    result = search.call(code)
    hit = result&.first&.first
    xml = hit.to_xml nil, opts
    File.write file, xml
    xml
  end
end

def mock_open_uri(code)
  expect(OpenURI).to receive(:open_uri).and_wrap_original do |m, *args|
    # expect(args[0]).to be_instance_of String
    file = examples_path("#{code.tr('-', '_')}.html")
    File.write file, m.call(*args).read unless File.exist? file
    File.read file, encoding: "utf-8"
  end.at_least :once
end

