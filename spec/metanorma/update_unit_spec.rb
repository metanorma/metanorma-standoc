require "spec_helper"
require "tmpdir"

RSpec.describe Metanorma::Standoc do
  include ValidationTestHelpers

  let(:register) do
    <<~YAML
      B-400:
        identifier: S-4 Part B, Section 400
        records:
          - sequence: 2
            edition: 4.10.0
            date: 2026-03-01
            approval: HSSC-17
            reference: CL 12/2026
            summary:
              - language: en
                content: New B-410 on light sectors
              - language: fr
                content: Nouveau B-410 sur les secteurs de feux
            affected_units: [B-410]
          - sequence: 1
            edition: 4.9.0
            date: 2021-03-01
            reference: CL 30/2021
            summary:
              - language: en
                content: Editorial corrections
    YAML
  end

  def with_register(content)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "updates.yaml")
      File.write(path, content)
      yield path
    end
  end

  def clause(xml, anchor)
    Nokogiri::XML(xml).at("//xmlns:clause[@anchor='#{anchor}']")
  end

  it "emits the amendment records of a declared update unit" do
    with_register(register) do |path|
      input = <<~INPUT
        #{ASCIIDOC_BLANK_HDR}
        [#B-400,update-unit=B-400,update-records=#{path}]
        == Section 400

        Text
      INPUT
      c = clause(Asciidoctor.convert(input, *OPTIONS), "B-400")
      unit = c.at("./xmlns:update-unit")
      expect(unit["unit"]).to eq "B-400"
      expect(c.elements.map(&:name)).to eq %w(title update-unit p)
      expect(unit.at("./xmlns:identifier").text)
        .to eq "S-4 Part B, Section 400"
      recs = unit.xpath("./xmlns:amendment-record")
      expect(recs.map { |r| r["sequence"] }).to eq %w(2 1)
      expect(recs.first.at("./xmlns:reference").text).to eq "CL 12/2026"
      expect(recs.first.at("./xmlns:summary[@language='fr']").text)
        .to eq "Nouveau B-410 sur les secteurs de feux"
      expect(recs.first.at("./xmlns:affected-unit").text).to eq "B-410"
      expect(recs.first.at("./xmlns:date").text).to eq "2026-03-01"
    end
  end

  it "reads the register named by the document attribute" do
    with_register(register) do |path|
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR.sub(":nodoc:\n", ":nodoc:\n:update-records: #{path}\n")}
        [#B-400,update-unit=B-400]
        == Section 400

        Text

        [#B-500,update-unit=B-500]
        == Section 500

        Text
      INPUT
      FileUtils.rm_f("test.err.html")
      xml = Asciidoctor.convert(input, *OPTIONS)
      expect(clause(xml, "B-400").xpath(".//xmlns:amendment-record").size)
        .to eq 2
      b500 = clause(xml, "B-500").at("./xmlns:update-unit")
      expect(b500["unit"]).to eq "B-500"
      expect(b500.elements).to be_empty
      expect(File.read("test.err.html")).to include("STANDOC_70")
    end
  end

  it "declares the unit without records when no register is given" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [update-unit=B-400]
      == Section 400

      Text

      == Other

      Text
    INPUT
    xml = Asciidoctor.convert(input, *OPTIONS)
    units = Nokogiri::XML(xml).xpath("//xmlns:update-unit")
    expect(units.map { |u| u["unit"] }).to eq %w(B-400)
  end

  it "aborts on a missing or malformed register" do
    input = <<~INPUT
      #{VALIDATING_BLANK_HDR}
      [update-unit=B-400,update-records=does-not-exist.yaml]
      == Section 400

      Text
    INPUT
    errors = convert_and_expect_abort(input)[:errors]
    expect(errors).to include("STANDOC_71")
    expect(errors).to include("Update records file does-not-exist")
    with_register("- not\n- keyed\n") do |path|
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}
        [update-unit=B-400,update-records=#{path}]
        == Section 400

        Text
      INPUT
      errors = convert_and_expect_abort(input)[:errors]
      expect(errors).to include("STANDOC_72")
      expect(errors).to include("update register must be keyed by unit anchor")
    end
  end

  it "validates update units against the grammar" do
    with_register(register) do |path|
      input = <<~INPUT
        #{VALIDATING_BLANK_HDR}
        [#B-400,update-unit=B-400,update-records=#{path}]
        == Section 400

        Text
      INPUT
      errors = convert_and_capture_errors(input)
      expect(errors).not_to include("update-unit")
      expect(errors).not_to include("amendment-record")
    end
  end

  it "round-trips the update unit through the clause model" do
    with_register(register) do |path|
      input = <<~INPUT
        #{ASCIIDOC_BLANK_HDR}
        [#B-400,update-unit=B-400,update-records=#{path}]
        == Section 400

        Text
      INPUT
      xml = clause(Asciidoctor.convert(input, *OPTIONS), "B-400").to_xml
        .sub(%r{ xmlns="[^"]+"}, "")
      model = Metanorma::Standoc::Document::Sections::ClauseSection
        .from_xml(xml)
      expect(model.update_unit.unit).to eq "B-400"
      expect(model.update_unit.records.map(&:reference))
        .to eq ["CL 30/2021", "CL 12/2026"]
    end
  end
end
