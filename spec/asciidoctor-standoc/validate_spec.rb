require "spec_helper"
require "relaton_iec"
require "fileutils"

RSpec.describe Asciidoctor::Standoc do

  it "warns that video is a skipped node" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/converter missing for video node/).to_stderr
  #{VALIDATING_BLANK_HDR}

  video::video_file.mp4[]
  INPUT
  end

it "warns that figure does not have title" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/Figure should have title/).to_stderr
  #{VALIDATING_BLANK_HDR}

  image::spec/examples/rice_images/rice_image1.png[]
  INPUT
end

it "warns that callouts do not match annotations" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/mismatch of callouts and annotations/).to_stderr
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
end

it "warns that term source is not a real reference" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/iso123 is not a real reference/).to_stderr
  #{VALIDATING_BLANK_HDR}

  [.source]
  <<iso123>>
  INPUT
end

it "warns of Non-reference in bibliography" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/no anchor on reference/).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Normative References
  * I am not a reference
  INPUT
end

it "warns that Table should have title" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Table should have title}).to_stderr
  #{VALIDATING_BLANK_HDR}     

  |===
  |a |b |c
  |===
  INPUT
end

it "validates document against ISO XML schema" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{value of attribute "align" is invalid; must be equal to}).to_stderr
  #{VALIDATING_BLANK_HDR}

  [align=mid-air]
  Para
  INPUT
end

it "Warning if terms mismatches IEV" do
  FileUtils.mv File.expand_path("~/.iev/cache"), File.expand_path("~/.iev.pstore1"), force: true
  FileUtils.rm_f "test_iev/pstore"
  mock_open_uri('103-01-02')
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Term "automation" does not match IEV 103-01-02 "functional"}).to_stderr
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
  FileUtils.mv File.expand_path("~/.iev.pstore1"), File.expand_path("~/.iev/cache"), force: true
end

it "No warning if English term matches IEV" do
  FileUtils.mv File.expand_path("~/.iev/cache"), File.expand_path("~/.iev.pstore1"), force: true
  FileUtils.rm_f "test_iev/cache"
  mock_open_uri('103-01-02')
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.not_to output(%r{does not match IEV 103-01-02}).to_stderr
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
  FileUtils.mv File.expand_path("~/.iev.pstore1"), File.expand_path("~/.iev/cache"), force: true
end

it "No warning if French term matches IEV" do
  FileUtils.mv File.expand_path("~/.iev/cache"), File.expand_path("~/.iev.pstore1"), force: true
  FileUtils.rm_f "test_iev/cache"
  mock_open_uri('103-01-02')
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.not_to output(%r{does not match IEV 103-01-02}).to_stderr
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
  FileUtils.mv File.expand_path("~/.iev.pstore1"), File.expand_path("~/.iev/cache"), force: true
end

end
