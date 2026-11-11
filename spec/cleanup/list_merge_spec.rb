# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Standoc::Cleanup do
  def new_cleanup
    conv = Metanorma::Standoc::Converter.new(:standoc, *OPTIONS)
    conv.init(Asciidoctor::Document.new("", OPTIONS[0].dup))
    described_class.new(conv)
  end

  def merge_xml(xml)
    doc = Nokogiri::XML(xml)
    new_cleanup.merge_adjacent_lists(doc)
    doc
  end

  def ols(doc)
    doc.xpath("//*[local-name()='ol' or local-name()='ul']").map do |l|
      [l.name, l["type"], l["start"], l["id"],
       l.xpath(".//*[local-name()='li']").map(&:text)]
    end
  end

  # The Peter Wyatt report: a // comment flanked by blank lines between
  # bullets ended the list; the fragments tripped the clause list checks
  # and restarted numbering in the render.
  it "merges a list split by a blank-line-flanked comment" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:

      == Clause 1

      Intro sentence:

      . first

      // a comment between bullets

      . second
    INPUT

    doc = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(doc.xpath("//*[local-name()='ol']").size).to eq(1)
    items = doc.xpath("//*[local-name()='ol']//*[local-name()='li']")
      .map { |li| li.text.strip }
    expect(items).to eq(%w(first second))
  end

  it "merges adjacent ordered lists into one" do
    doc = merge_xml(<<~XML)
      <metanorma>
        <sections>
          <clause><p>intro:</p>
            <ol><li>one</li><li>two</li></ol>
            <ol><li>three</li></ol>
          </clause>
        </sections>
      </metanorma>
    XML
    expect(ols(doc)).to eq([["ol", nil, nil, nil, %w(one two three)]])
  end

  it "merges a three-way split into one list" do
    doc = merge_xml(<<~XML)
      <metanorma>
        <sections>
          <clause>
            <ol><li>one</li></ol>
            <ol><li>two</li></ol>
            <ol><li>three</li></ol>
          </clause>
        </sections>
      </metanorma>
    XML
    expect(ols(doc)).to eq([["ol", nil, nil, nil, %w(one two three)]])
  end

  it "merges adjacent unordered lists into one" do
    doc = merge_xml(<<~XML)
      <metanorma>
        <sections>
          <clause>
            <ul><li>one</li></ul>
            <ul><li>two</li></ul>
          </clause>
        </sections>
      </metanorma>
    XML
    expect(ols(doc)).to eq([["ul", nil, nil, nil, %w(one two)]])
  end

  it "keeps ordered lists of different types apart" do
    doc = merge_xml(<<~XML)
      <metanorma>
        <sections>
          <clause>
            <ol type="arabic"><li>one</li></ol>
            <ol type="loweralpha"><li>a</li></ol>
          </clause>
        </sections>
      </metanorma>
    XML
    expect(doc.xpath("//*[local-name()='ol']").size).to eq(2)
  end

  it "keeps explicitly restarted lists apart" do
    doc = merge_xml(<<~XML)
      <metanorma>
        <sections>
          <clause>
            <ol><li>one</li></ol>
            <ol start="5"><li>five</li></ol>
          </clause>
        </sections>
      </metanorma>
    XML
    expect(doc.xpath("//*[local-name()='ol']").size).to eq(2)
  end

  it "keeps user-anchored second lists apart" do
    doc = merge_xml(<<~XML)
      <metanorma>
        <sections>
          <clause>
            <ol><li>one</li></ol>
            <ol id="user_anchor"><li>two</li></ol>
          </clause>
        </sections>
      </metanorma>
    XML
    expect(doc.xpath("//*[local-name()='ol']").size).to eq(2)
  end

  it "merges fragments whose ids are generated" do
    doc = merge_xml(<<~XML)
      <metanorma>
        <sections>
          <clause>
            <ol><li>one</li></ol>
            <ol id="_8f2a"><li>two</li></ol>
          </clause>
        </sections>
      </metanorma>
    XML
    expect(ols(doc)).to eq([["ol", nil, nil, nil, %w(one two)]])
  end

  it "keeps ordered and unordered lists apart" do
    doc = merge_xml(<<~XML)
      <metanorma>
        <sections>
          <clause>
            <ol><li>one</li></ol>
            <ul><li>two</li></ul>
          </clause>
        </sections>
      </metanorma>
    XML
    expect(doc.xpath("//*[local-name()='ol']").size).to eq(1)
    expect(doc.xpath("//*[local-name()='ul']").size).to eq(1)
  end

  it "keeps lists separated by a block apart" do
    doc = merge_xml(<<~XML)
      <metanorma>
        <sections>
          <clause>
            <ol><li>one</li></ol>
            <p>between</p>
            <ol><li>two</li></ol>
          </clause>
        </sections>
      </metanorma>
    XML
    expect(doc.xpath("//*[local-name()='ol']").size).to eq(2)
  end
end
