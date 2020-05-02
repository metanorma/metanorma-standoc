require "spec_helper"
require "relaton_iec"
require "fileutils"

RSpec.describe Asciidoctor::Standoc do
  it "warns about malformed LaTeX" do
  FileUtils.rm_f "test.err"
  Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) 
  #{VALIDATING_BLANK_HDR}

  == Clause 1

  latexmath:[\\begin{}]

  === Clause 1.1

  Subclause
  INPUT
  expect(File.read("test.err")).to include "latexmlmath failed to process equation"
  end

  it "warns about reparsing LaTeX" do
    FileUtils.rm_f "test.err"
    expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/Retrying/).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Clause 1

  [latexmath]
  ++++
  \\pmatrix{ \\hat{e}_{\\xi} \\cr \\hat{e}_{\\eta}
  \\cr \\hat{e}_{\\zeta} } = {\\bf T} \\pmatrix{ \\hat{e}_x \\cr \\hat{e}_y \\cr  \\hat{e}_z },
  ++++

  === Clause 1.1

  Subclause
  INPUT
  end

  it "warns about hanging paragraphs" do
  FileUtils.rm_f "test.err"
  Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) 
  #{VALIDATING_BLANK_HDR}

  == Clause 1

  Paragraph

  === Clause 1.1

  Subclause
  INPUT
  expect(File.read("test.err")).to include "Hanging paragraph in clause"
  end

  it "warns that video is a skipped node" do
  FileUtils.rm_f "test.err"
  Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) 
  #{VALIDATING_BLANK_HDR}

  video::video_file.mp4[]
  INPUT
  expect(File.read("test.err")).to include "converter missing for video node"
  end

it "warns that figure does not have title" do
  FileUtils.rm_f "test.err"
  Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) 
  #{VALIDATING_BLANK_HDR}

  image::spec/examples/rice_images/rice_image1.png[]
  INPUT
  expect(File.read("test.err")).to include "Figure should have title"
end

it "warns that callouts do not match annotations" do
  FileUtils.rm_f "test.err"
  Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
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
  expect(File.read("test.err")).to include "mismatch of callouts and annotations"
end

it "warns that term source is not a real reference" do
  FileUtils.rm_f "test.err"
  Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) 
  #{VALIDATING_BLANK_HDR}

  [.source]
  <<iso123>>
  INPUT
  expect(File.read("test.err")).to include "iso123 does not have a corresponding anchor ID in the bibliography"
end

it "warns of Non-reference in bibliography" do
  FileUtils.rm_f "test.err"
  Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) 
  #{VALIDATING_BLANK_HDR}

  == Normative References
  * I am not a reference
  INPUT
  expect(File.read("test.err")).to include "no anchor on reference"
end

it "warns that Table should have title" do
  FileUtils.rm_f "test.err"
  Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) 
  #{VALIDATING_BLANK_HDR}     

  |===
  |a |b |c
  |===
  INPUT
  expect(File.read("test.err")).to include "Table should have title"
end

it "validates document against ISO XML schema" do
  FileUtils.rm_f "test.err"
  Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) 
  #{VALIDATING_BLANK_HDR}

  [align=mid-air]
  Para
  INPUT
  expect(File.read("test.err")).to include 'value of attribute "align" is invalid; must be equal to'
end

it "Warning if terms mismatches IEV" do
  FileUtils.rm_f "test.err"
  FileUtils.mv File.expand_path("~/.iev/cache"), File.expand_path("~/.iev.pstore1"), force: true
  FileUtils.rm_f "test_iev/pstore"
  mock_open_uri('103-01-02')
  Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) 
  = Document title
  Author
  :docfile: test.adoc
  
  [bibliography]
  == Normative References
  * [[[iev,IEV]]], _iev_

  == Terms and definitions
  === Automation

  [.source]
  <<iev,clause="103-01-02">>
  INPUT
  expect(File.read("test.err")).to include 'Term "automation" does not match IEV 103-01-02 "functional"'
  FileUtils.mv File.expand_path("~/.iev.pstore1"), File.expand_path("~/.iev/cache"), force: true
end

it "No warning if English term matches IEV" do
  FileUtils.rm_f "test.err"
  FileUtils.mv File.expand_path("~/.iev/cache"), File.expand_path("~/.iev.pstore1"), force: true
  FileUtils.rm_f "test_iev/cache"
  mock_open_uri('103-01-02')
  Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) 
  = Document title
  Author
  :docfile: test.adoc

  [bibliography]
  == Normative References
  * [[[iev,IEV]]], _iev_

  == Terms and definitions
  === Functional

  [.source]
  <<iev,clause="103-01-02">>
  INPUT
  expect(File.read("test.err")).not_to include "does not match IEV 103-01-02"
  FileUtils.mv File.expand_path("~/.iev.pstore1"), File.expand_path("~/.iev/cache"), force: true
end

it "No warning if French term matches IEV" do
  FileUtils.rm_f "test.err"
  FileUtils.mv File.expand_path("~/.iev/cache"), File.expand_path("~/.iev.pstore1"), force: true
  FileUtils.rm_f "test_iev/cache"
  mock_open_uri('103-01-02')
  Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) 
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
  expect(File.read("test.err")).not_to include "does not match IEV 103-01-02"
  FileUtils.mv File.expand_path("~/.iev.pstore1"), File.expand_path("~/.iev/cache"), force: true
end

=begin
it "No warning if attributes on formatted strong or stem extraneous to Metanomra XML" do
  expect { Asciidoctor::Standoc::Converter.new(nil,nil).validate(Nokogiri::XML(<<~INPUT)) }.not_to output('found attribute "close", but no attributes allowed here').to_stderr
  <standard-document>
  <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mfenced open="(" close=")"><mi>r</mi></mfenced></stem>
  </standard-document>
INPUT
end
=end

it "warns if id used twice" do
  FileUtils.rm_f "test.err"
  Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:

  [[abc]]
  == Clause 1

  [[abc]]
  == Clause 2
  INPUT
  expect(File.read("test.err")).to include "Anchor abc has already been used at line"
end

it "err file succesfully created for docfile path" do
  FileUtils.rm_rf "test"
  FileUtils.mkdir_p "test"
  Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
  = Document title
  Author
  :docfile: test#{File::ALT_SEPARATOR || File::SEPARATOR}test.adoc
  :nodoc:

  [[abc]]
  == Clause 1

  [[abc]]
  == Clause 2
  INPUT
  expect(File.read("test/test.err")).to include "Anchor abc has already been used at line"
end

end
