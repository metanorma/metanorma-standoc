require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.default_cassette_options = {
    clean_outdated_http_interactions: true,
    re_record_interval: 1512000,
    record: :once,
  }
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

Dir[File.expand_path("./support/**/**/*.rb", __dir__)]
  .sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around :each do |example|
    example.run
  rescue SystemExit
    fail "Unexpected exit encountered"
  end
end

OPTIONS = [backend: :standoc, header_footer: true, agree_to_terms: true].freeze

def strip_guid(xml)
  xml.gsub(%r{ id="_[^"]+"}, ' id="_"')
    .gsub(%r{ target="_[^"]+"}, ' target="_"')
end

def strip_src(xml)
  xml.gsub(/\ssrc="[^"]+"/, ' src="_"')
end

def xmlpp(xml)
  s = ""
  f = REXML::Formatters::Pretty.new(2)
  f.compact = true
  f.write(REXML::Document.new(xml
    .gsub(%r{<fetched>[^<]+</fetched>}, "<fetched/>")), s)
  s
end

ASCIIDOC_BLANK_HDR = <<~"HDR".freeze
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :novalid:
  :no-isobib:
  :data-uri-image: false

HDR

DUMBQUOTE_BLANK_HDR = <<~"HDR".freeze
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :novalid:
  :no-isobib:
  :smartquotes: false

HDR

ISOBIB_BLANK_HDR = <<~"HDR".freeze
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :novalid:
  :no-isobib-cache:

HDR

FLUSH_CACHE_ISOBIB_BLANK_HDR = <<~"HDR".freeze
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :novalid:
  :flush-caches:

HDR

CACHED_ISOBIB_BLANK_HDR = <<~"HDR".freeze
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :novalid:

HDR

LOCAL_CACHED_ISOBIB_BLANK_HDR = <<~"HDR".freeze
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :novalid:
  :local-cache:

HDR

LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR = <<~"HDR".freeze
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :novalid:
  :local-cache-only:

HDR

VALIDATING_BLANK_HDR = <<~"HDR".freeze
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :no-isobib:

HDR

NORM_REF_BOILERPLATE = <<~"HDR".freeze
  <p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
HDR

BLANK_HDR = <<~"HDR".freeze
  <?xml version="1.0" encoding="UTF-8"?>
  <standard-document xmlns="https://www.metanorma.org/ns/standoc" version="#{Metanorma::Standoc::VERSION}" type="semantic">
  <bibdata type="standard">
  <title language="en" format="text/plain">Document title</title>
    <language>en</language>
    <script>Latn</script>
    <status><stage>published</stage></status>
    <copyright>
      <from>#{Time.new.year}</from>
    </copyright>
    <ext>
    <doctype>standard</doctype>
    </ext>
  </bibdata>
HDR

BLANK_METANORMA_HDR = <<~"HDR".freeze
  <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
  <?xml version="1.0" encoding="UTF-8"?><html><body>
  <standard-document xmlns="https://www.metanorma.org/ns/standoc" version="#{Metanorma::Standoc::VERSION}" type="semantic">
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

HTML_HDR = <<~HDR.freeze
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
HDR

WORD_HDR = <<~HDR.freeze
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
HDR

def examples_path(path)
  File.join(File.expand_path("./examples", __dir__), path)
end

def fixtures_path(path)
  File.join(File.expand_path("./fixtures", __dir__), path)
end

def stub_fetch_ref(**opts)
  xml = ""

  hit = double("hit")
  expect(hit).to receive(:[]).with("title") do
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

  expect(Isobib::IsoBibliography).to receive(:search)
    .and_wrap_original do |search, *args|
    code = args[0]
    expect(code).to be_instance_of String
    xml = get_xml(search, code, opts)
    hit_pages
  end.at_least :once
end

private

def get_xml(search, code, opts)
  c = code.gsub(%r{[/\s:-]}, "_").sub(%r{_+$}, "").downcase
  file = examples_path("#{[c, opts.keys.join('_')].join '_'}.xml")
  if File.exist? file
    File.read file
  else
    xml = search.call(code)&.first&.first&.to_xml nil, opts
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

def metanorma_process(input)
  Metanorma::Input::Asciidoc
    .new
    .process(input, "test.adoc", :standoc)
end

def xml_string_conent(xml)
  strip_guid(Nokogiri::HTML(xml).to_s)
end
