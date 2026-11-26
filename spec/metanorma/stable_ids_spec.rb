# frozen_string_literal: true

require "spec_helper"
require "fileutils"

# TRThurman, isodoc#861: recompiling the same source must produce the
# same element ids. The anchor-less mint was random per compile: the
# HTML heading ids changed on every run and the TOC links moved with
# them. The mint is now a UUIDv5 over the document identity, the
# element's text, and the occurrence ordinal of that text.
RSpec.describe "deterministic anchor-less ids" do
  before { FileUtils.rm_f "test.doc" }

  let(:input) do
    <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :no-pdf:

      == Scope

      First scope text.

      == Terms

      === widget

      A device.

      === widget

      A second device of the same name, ordinally distinguished.
    INPUT
  end

  def heading_ids
    Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
      .xpath("//*[@id]").map { |n| n["id"] }.select { |i| i =~ /\A_/ }
  end

  it "mints the same ids on every compile" do
    first = heading_ids
    second = heading_ids
    expect(first).to eq(second)
    expect(first).not_to be_empty
  end

  it "distinguishes same-named headings ordinally" do
    ids = heading_ids.grep_v(/UUID|bibitem/).uniq
    expect(ids).to eq(ids.uniq)
  end
end
