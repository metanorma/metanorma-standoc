# frozen_string_literal: true

require "spec_helper"

# Pair iteration and in-document lookup checks (metanorma-standoc#1381).
# Parity examples run the legacy method and the shadow rules for its code on
# the same input and require identical codes, nodes and params.
RSpec.describe Metanorma::Standoc::Validate::Rules, "pair and lookup checks" do
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
    expect(legacy).not_to be_empty
    expect(declarative(doc, code).sort).to eq legacy.sort
    legacy
  end

  def load_set(yaml)
    rules::RuleSet.parse(yaml)
  end

  let(:nested_doc) do
    Nokogiri::XML(<<~XML)
      <doc>
      <example id="e1" anchor="e1"><note id="n1" anchor="n1"/>
        <figure id="f1" anchor="f1"><figure id="f2" anchor="f2"/></figure></example>
      <table id="t1" anchor="t1"><example id="x2" anchor="x2"/><note id="n5"/></table>
      <termnote id="tn" anchor="tn"><note id="n2" anchor="n2"/></termnote>
      <note id="n3" anchor="n3"><note id="n4" anchor="n4"/></note>
      <p><xref to="f1"/><xref target="f1"/><eref bibitemid="n2"/>
        <citation bibitemid="n4"/><xref target="x2"/><xref target="f2"/></p>
      </doc>
    XML
  end

  it "STANDOC_34 nested assets, excluding figure in figure and example in table" do
    validator.nested_asset_validate(nested_doc)
    legacy = expect_parity(nested_doc, "STANDOC_34")
    expect(legacy.map(&:last)).to include(%w(figure example), %w(note termnote),
                                          %w(note note))
    expect(legacy.map(&:last)).not_to include(%w(figure figure))
    expect(legacy.map(&:last)).not_to include(%w(example table))
  end

  it "STANDOC_35 references to nested assets, last reference winning" do
    validator.repeat_id_validate(nested_doc.root)
    validator.xref_validate_exists(nested_doc)
    validator.nested_asset_validate(nested_doc)
    legacy = expect_parity(nested_doc, "STANDOC_35")
    expect(legacy.map { |e| e[1] }).to include("/doc/p/xref[2]", "/doc/p/eref",
                                                "/doc/p/citation")
    expect(legacy.map { |e| e[1] }).not_to include("/doc/p/xref[1]")
  end

  it "STANDOC_38 undefined cross-reference targets" do
    doc = Nokogiri::XML(<<~XML)
      <doc><clause id="a" anchor="a"/><clause id="b"/>
      <p><xref target="a"/><xref target="gone"/><xref target="b"/>
      <xref to="nowhere"/><eref bibitemid="a"/><eref bibitemid="zz"/>
      <callout target="a"/><label for="q"/><xref/></p></doc>
    XML
    validator.repeat_id_validate(doc.root)
    validator.xref_validate_exists(doc)
    legacy = expect_parity(doc, "STANDOC_38")
    expect(legacy.size).to eq 5
  end

  describe "rule loading" do
    def rule(check, args)
      <<~YAML
        schema: metanorma-validation-rules/1
        rules:
          - {id: r.x, code: T_1, context: //note, check: #{check}, args: #{args}}
      YAML
    end

    it "rejects invalid nested arguments" do
      expect { load_set(rule("nested", "{}")) }.to raise_error(/missing args inner/)
      expect { load_set(rule("nested", "{inner: [a b]}")) }
        .to raise_error(/element names/)
      expect { load_set(rule("nested", "{inner: [a], except: [oops]}")) }
        .to raise_error(/outer\/inner/)
      expect { load_set(rule("nested", "{inner: [a], referenced_by: []}")) }
        .to raise_error(/non-empty list/)
      expect { load_set(rule("nested", "{inner: [a], referenced_by: ['//(']}")) }
        .to raise_error(/referenced_by/)
    end

    it "rejects invalid reference_exists arguments" do
      expect { load_set(rule("reference_exists", "{attribute: a}")) }
        .to raise_error(/missing args known/)
      expect { load_set(rule("reference_exists", "{attribute: '1x', known: //a}")) }
        .to raise_error(/invalid attribute/)
      expect { load_set(rule("reference_exists", "{attribute: a, known: '//('}")) }
        .to raise_error(/known/)
    end

    it "allows related params only on pair checks" do
      yaml = <<~YAML
        schema: metanorma-validation-rules/1
        rules:
          - {id: r.x, code: T_1, context: //note, check: required, target: ./a, params: [{related: name}]}
      YAML
      expect { load_set(yaml) }.to raise_error(/invalid param/)
    end
  end

  describe "Schematron export" do
    let(:set) do
      load_set(<<~YAML)
        schema: metanorma-validation-rules/1
        rules:
          - id: r.nested
            code: T_1
            context: //example | //figure
            check: nested
            args: {inner: [example, figure], except: [figure/figure]}
          - id: r.ref
            code: T_2
            context: //xref[@target]
            check: reference_exists
            args: {attribute: target, known: "//*[@id]/@anchor"}
      YAML
    end
    let(:doc) do
      Nokogiri::XML(<<~XML)
        <doc><example><figure/></example><figure><figure/></figure>
        <figure><example/></figure><clause id="c" anchor="c"/>
        <xref target="c"/><xref target="d"/><xref/></doc>
      XML
    end

    it "exports both checks as portable rules" do
      export = rules::Schematron.export(set)
      expect(export.code_backed).to be_empty
      expect(export.xml).to include("not(.//example or not(self::figure) and .//figure)")
    end

    it "exports the shipped pair and lookup rules and flags the same outer nodes" do
      mine = shipped_set.rules.select do |r|
        %w(STANDOC_34 STANDOC_35 STANDOC_38).include?(r.code)
      end
      export = rules::Schematron.export(rules::RuleSet.new(mine))
      expect(export.code_backed).to be_empty
      failed = rules::Schematron.evaluate(export.xml, nested_doc)
        .select { |f| f.id.start_with?("standoc.style.nested-asset", "standoc.style.nested-note") }
      by_engine = rules::Engine.new(shipped_set, validator: validator).findings(nested_doc, modes: %w(shadow))
        .select { |f| %w(STANDOC_34 STANDOC_35).include?(f.code) }
      outers = by_engine.map { |f| f.node.ancestors.map(&:path) }.flatten.uniq
      expect(failed).not_to be_empty
      expect(failed.map { |f| f.node.path }.uniq - outers).to be_empty
    end

    it "agrees with the engine on the offending nodes" do
      by_schematron = rules::Schematron.evaluate(rules::Schematron.export(set).xml, doc)
      expect(by_schematron.map { |f| [f.id, f.node.path] }.sort).to eq [
        ["r.nested", "/doc/example"], ["r.nested", "/doc/figure[2]"],
        ["r.ref", "/doc/xref[2]"]
      ]
      by_engine = rules::Engine.new(set).findings(doc)
      expect(by_engine.map { |f| [f.rule_id, f.node.path] }.uniq.sort).to eq [
        ["r.nested", "/doc/example/figure"], ["r.nested", "/doc/figure[2]/example"],
        ["r.ref", "/doc/xref[2]"]
      ]
    end
  end
end
