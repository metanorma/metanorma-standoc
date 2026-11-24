# frozen_string_literal: true

require_relative "../spec_helper"

# metanorma-ietf#296 item 7: clause-level <pre> was unmapped at parse,
# so literal blocks (ASCII art, preformatted text) never reached the
# flavor transformers
RSpec.describe "literal block mapping on clauses" do
  it "parses clause <pre> into literal_blocks" do
    xml = <<~XML
      <clause id="_c1">
        <title>Diagram</title>
        <pre id="_pre1" alt="ascii art">+------+
      | box  |
      +------+</pre>
      </clause>
    XML

    clause = Metanorma::Standoc::Document::Sections::ClauseSection.from_xml(xml)

    expect(clause.literal_blocks.length).to eq(1)
    pre = clause.literal_blocks.first
    expect(pre.id).to eq("_pre1")
    expect(pre.alt).to eq("ascii art")
    expect(pre.content).to include("| box  |")
  end

  it "keeps <pre> in document order with sibling blocks" do
    xml = <<~XML
      <clause id="_c1">
        <title>Mixed</title>
        <p>before</p>
        <pre>lit</pre>
        <p>after</p>
      </clause>
    XML

    clause = Metanorma::Standoc::Document::Sections::ClauseSection.from_xml(xml)

    classes = clause.blocks.map(&:class)
    expect(classes).to eq([
      Metanorma::Document::Components::Paragraphs::ParagraphBlock,
      Metanorma::Document::Components::AncillaryBlocks::LiteralBlock,
      Metanorma::Document::Components::Paragraphs::ParagraphBlock,
    ])
  end
end
