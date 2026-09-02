# frozen_string_literal: true

require "spec_helper"
require "metanorma/document"

RSpec.describe Metanorma::Standoc::Document::Terms::Term do
  it "maps termnote block children and rendering channels" do
    xml = <<~XML
      <term id="_t1">
        <termnote id="_n1" autonum="1">
          <fmt-name><span class="fmt-caption-label">Note 1 to entry</span></fmt-name>
          <fmt-xref-label><span class="fmt-element-name">Note 1</span></fmt-xref-label>
          <p>Note content.</p>
          <ul><li>list item</li></ul>
        </termnote>
      </term>
    XML

    term = described_class.from_xml(xml)
    note = term.note.first

    expect(note).to be_a(Metanorma::Standoc::Document::Terms::TermNote)
    expect(note.id).to eq("_n1")
    expect(note.autonum).to eq("1")
    expect(note.fmt_name)
      .to be_a(Metanorma::Document::Components::Inline::FmtNameElement)
    expect(note.fmt_xref_label.size).to eq(1)
    expect(note.p.first.text).to eq(["Note content."])
    expect(note.ul.size).to eq(1)
  end

  it "maps termexample block children" do
    xml = <<~XML
      <term id="_t1">
        <termexample id="_e1">
          <fmt-name><span>EXAMPLE</span></fmt-name>
          <p>Example content.</p>
        </termexample>
      </term>
    XML

    term = described_class.from_xml(xml)
    example = term.example.first

    expect(example).to be_a(Metanorma::Standoc::Document::Terms::TermExample)
    expect(example.p.first.text).to eq(["Example content."])
    expect(example.fmt_name)
      .to be_a(Metanorma::Document::Components::Inline::FmtNameElement)
  end

  it "exposes deprecates designation content and its rendered form" do
    xml = <<~XML
      <term id="_t1">
        <preferred><expression><name>cargo rice</name></expression></preferred>
        <deprecates id="_d1"><expression><name>cargo rice</name></expression></deprecates>
        <fmt-deprecates><p>DEPRECATED: cargo rice</p></fmt-deprecates>
      </term>
    XML

    term = described_class.from_xml(xml)

    expect(term.deprecates.first.expression.name.first.text)
      .to eq(["cargo rice"])
    expect(term.fmt_deprecates.p.first.text).to eq(["DEPRECATED: cargo rice"])
  end
end
