# frozen_string_literal: true

require "spec_helper"

# Cell-grid and term-state checks (metanorma-standoc#1381). Parity examples
# run the legacy method and the shadow rules for its code on the same input
# and require identical codes, nodes and params.
RSpec.describe Metanorma::Standoc::Validate::Rules, "grid and term checks" do
  let(:rules) { described_class }
  let(:log) do
    Class.new do
      attr_reader :entries

      def initialize
        @entries = []
      end

      def add(code, node, params: [])
        @entries << [code, node.path, params]
      end
    end.new
  end
  let(:validator) do
    Metanorma::Standoc::Validate
      .new(Metanorma::Standoc::Converter.new("standoc", {})).tap do |v|
      v.instance_variable_set(:@log, log)
    end
  end
  let(:shipped) do
    File.join(File.dirname(Metanorma::Standoc::Validate.instance_method(:validate)
      .source_location.first), "rules", "standoc.yaml")
  end
  let(:shipped_set) { rules::RuleSet.load_file(shipped) }

  def declarative(doc, code)
    rules::Engine.new(shipped_set, validator: validator)
      .findings(doc, modes: %w(shadow))
      .select { |f| f.code == code }
      .map { |f| [f.code, f.node.path, f.params] }
  end

  def expect_parity(doc, code)
    legacy = log.entries.select { |e| e.first == code }
    expect(declarative(doc, code).sort).to eq legacy.sort
    legacy
  end

  def load_set(yaml)
    rules::RuleSet.parse(yaml)
  end

  describe "tables" do
    let(:doc) do
      Nokogiri::XML(<<~XML)
        <doc>
        <table id="ok"><colgroup><col/><col/></colgroup>
          <tbody><tr><td/><td/></tr><tr><td/><td/></tr></tbody></table>
        <table id="wide"><colgroup><col/><col/></colgroup>
          <tbody><tr><td/><td/><td/><td id="over"/></tr><tr><td colspan="2"/></tr></tbody></table>
        <table id="ragged"><tbody><tr><td/><td/></tr><tr><td colspan="1"/></tr></tbody></table>
        <table id="rowspan"><thead><tr><th rowspan="2"/><th/></tr></thead>
          <tbody><tr><td/></tr></tbody></table>
        <table id="direct"><tr><td colspan="2"/><td/></tr><tr><td/><td/><td/><td/></tr></table>
        <metanorma-extension><table id="skipped"><colgroup><col/></colgroup>
          <tbody><tr><td/><td/></tr></tbody></table></metanorma-extension>
        </doc>
      XML
    end

    before { validator.table_validate(doc) }

    it "STANDOC_5 cells beyond the column count" do
      legacy = expect_parity(doc, "STANDOC_5")
      expect(legacy.map(&:last)).to include([2])
      expect(legacy.map(&:last).flatten.uniq).to eq [2]
      expect(legacy.map { |e| e[1] }).to include("/doc/table[2]/tbody/tr[1]/td[4]")
    end

    it "STANDOC_4 inconsistent rows, and rowspans leaving their section" do
      legacy = expect_parity(doc, "STANDOC_4")
      expect(legacy.map(&:last)).to include(["are inconsistent"],
                                            ["cannot go outside thead"])
      expect(legacy.map { |e| e[1] }).not_to include("/doc/metanorma-extension/table")
    end
  end

  describe "terms" do
    let(:doc) do
      Nokogiri::XML(<<~XML)
        <doc>
        <terms anchor="ts"><term anchor="t1"><domain>chem</domain>
          <preferred><expression><name>salt<index><primary>salt</primary></index></name></expression></preferred></term>
        <term anchor="t2"><domain>chem</domain><preferred><expression><name>salt</name></expression></preferred></term>
        <term anchor="t3"><preferred><expression><name>salt</name></expression></preferred></term>
        <term anchor="t4"><preferred><expression><name>salt</name></expression></preferred></term>
        <term anchor="t5"><preferred><expression><name>unique</name></expression></preferred>
          <admitted><expression><name>salt</name></expression></admitted></term></terms>
        <clause id="c1" anchor="c1"><title>Stray</title>
          <preferred><expression><name>caf&#233; &amp; co</name></expression></preferred>
          <deprecates><expression><name>old</name></expression></deprecates></clause>
        <annex id="a1" anchor="a1"><admitted><expression><name>x</name></expression></admitted></annex>
        </doc>
      XML
    end

    it "STANDOC_24 repeated preferred designations" do
      validator.preferred_validate(doc)
      legacy = expect_parity(doc, "STANDOC_24")
      expect(legacy.map(&:last)).to contain_exactly(["<chem> salt", "t1, t2"],
                                                    ["salt", "t3, t4"])
    end

    it "STANDOC_25 designations outside terms clauses" do
      validator.termsect_validate(doc)
      legacy = expect_parity(doc, "STANDOC_25")
      expect(legacy.size).to eq 2
      expect(legacy.map(&:last).flatten.join).to include("&#xe9;")
    end
  end

  describe "rule loading" do
    def rule(check, args, extra = "")
      <<~YAML
        schema: metanorma-validation-rules/1
        rules:
          - {id: r.x, code: T_1, context: //table, check: #{check}, args: #{args}#{extra}}
      YAML
    end

    it "rejects invalid cell_grid arguments" do
      expect { load_set(rule("cell_grid", "{}")) }.to raise_error(/missing args report/)
      expect { load_set(rule("cell_grid", "{report: nope}")) }
        .to raise_error(/report must be/)
      expect { load_set(rule("cell_grid", "{report: row_mismatch, section: tr}")) }
        .to raise_error(/section must be/)
      expect { load_set(rule("cell_grid", "{report: column_overflow}")) }
        .to raise_error(/columns must be/)
    end

    it "rejects invalid term check arguments" do
      expect { load_set(rule("duplicate_designation", "{terms: '//(', designation: ./a}")) }
        .to raise_error(/terms/)
      expect { load_set(rule("duplicate_designation", "{terms: //term, designation: ./a, prefix: '//('}")) }
        .to raise_error(/prefix/)
      expect { load_set(rule("designation_outside_terms", "{designations: //a, containers: []}")) }
        .to raise_error(/containers/)
    end

    it "allows value params only on checks that compute values" do
      expect { load_set(rule("required", "{}", ", target: ./a, params: [{value: x}]")) }
        .to raise_error(/invalid param/)
    end

    it "reports these checks as code-backed on Schematron export" do
      mine = shipped_set.rules.select do |r|
        r.check.name.match?(/cell_grid|designation/)
      end
      export = rules::Schematron.export(rules::RuleSet.new(mine))
      expect(export.xml).not_to include("standoc.term")
      expect(export.code_backed).to include("standoc.table.column-overflow.colgroup",
                                            "standoc.term.preferred-duplicate")
    end
  end
end
