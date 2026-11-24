# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

# Document-state, file and option checks (metanorma-standoc#1381). Parity
# examples run the legacy method and the shadow rules for its code on the
# same input and require identical codes, nodes and params.
RSpec.describe Metanorma::Standoc::Validate::Rules, "document state checks" do
  let(:rules) { described_class }
  let(:log) do
    Class.new do
      attr_reader :entries

      def initialize
        @entries = []
      end

      def add(code, node, params: [], **)
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

  describe "STANDOC_23 concept cross-references" do
    let(:doc) do
      Nokogiri::XML(<<~XML)
        <doc>
        <terms id="i-ts" anchor="ts"><term id="i-t1" anchor="t1"><preferred><expression><name>salt</name></expression></preferred></term></terms>
        <definitions id="i-d"><dl><dt id="i-s1" anchor="s1">x</dt><dd/></dl></definitions>
        <clause id="i-c" anchor="c"><title>c</title>
        <p><concept><refterm>good</refterm><renderterm>good</renderterm><xref target="t1"/></concept>
        <concept><refterm>sym</refterm><xref target="s1"/></concept>
        <concept><refterm>bad</refterm><xref target="c"/></concept>
        <concept><refterm>sub</refterm><xref target="ts"/></concept>
        <concept><refterm>idref</refterm><xref target="i-c"/></concept>
        <concept><refterm>missing</refterm><xref target="nowhere"/></concept></p>
        <related type="see"><preferred><expression><name>other</name></expression></preferred><xref target="c"/></related>
        <related type="see"><preferred><expression><name>fine</name></expression></preferred><xref target="t1"/></related></clause>
        </doc>
      XML
    end

    before do
      validator.repeat_id_validate(doc.root)
      validator.concept_validate(doc, "concept", "refterm")
      validator.concept_validate(doc, "related", "preferred//name")
    end

    it "matches the legacy messages" do
      legacy = expect_parity(doc, "STANDOC_23")
      msgs = legacy.map { |e| e.last.first }
      expect(msgs.size).to eq 5
      expect(msgs).to include("Concept bad is pointing to c, which is not a term or symbol\n")
      expect(msgs).to include("Concept sub is pointing to ts, which is not " \
                              "a term or symbol. Did you mean to point to a subterm?")
      expect(msgs).to include("Concept idref is pointing to c, which is not a term or symbol\n")
      expect(msgs).to include("Related other is pointing to c, which is not a term or symbol\n")
    end
  end

  describe "STANDOC_44 and STANDOC_46 images" do
    let(:dir) { Dir.mktmpdir }
    let(:doc) do
      File.write(File.join(dir, "here.png"), "x")
      Nokogiri::XML(<<~XML)
        <doc>
        <figure id="f1"><image src="here.png" mimetype="image/png"/></figure>
        <figure id="f2"><image src="gone.png" mimetype="image/png"/></figure>
        <figure id="f3"><image src="http://example.com/a.png"/></figure>
        <figure id="f4"><image src="data:image/png;base64,AAAAAAAAAAAAAAAAAAAA"/></figure>
        <p id="p1"><altmedia src="missing.mp4"/></p>
        </doc>
      XML
    end

    before { validator.instance_variable_set(:@localdir, "#{dir}/") }
    after { FileUtils.remove_entry(dir) }

    it "STANDOC_44 files that do not exist" do
      Dir.chdir(dir) do
        validator.image_exists(doc)
        legacy = expect_parity(doc, "STANDOC_44")
        expect(legacy.map(&:last)).to contain_exactly(["gone.png"], ["missing.mp4"])
      end
    end

    it "STANDOC_46 images too large for data URIs" do
      validator.instance_variable_set(:@dataurimaxsize, 20)
      validator.image_toobig(doc)
      legacy = expect_parity(doc, "STANDOC_46")
      expect(legacy.size).to eq 2
    end

    it "STANDOC_46 is disabled by a zero limit" do
      validator.instance_variable_set(:@dataurimaxsize, 0)
      validator.image_toobig(doc)
      expect(expect_parity(doc, "STANDOC_46")).to be_empty
    end
  end

  describe "STANDOC_36 repeated identifiers" do
    let(:doc) do
      Nokogiri::XML(<<~XML)
        <doc>
        <clause id="a" anchor="x"/>
        <clause id="b" anchor="y"/>
        <clause id="a" anchor="z"/>
        <clause id="c" anchor="y"/>
        <clause id="c" anchor="y"/>
        <clause anchor="x"/>
        </doc>
      XML
    end

    it "matches the legacy findings, with first-occurrence line numbers" do
      validator.repeat_id_validate(doc.root)
      legacy = expect_parity(doc, "STANDOC_36")
      expect(legacy.map(&:last)).to include(["a", 2], ["y", 3], ["c", 5])
      expect(legacy.size).to eq 4
    end
  end

  describe "rule loading" do
    def rule(check, args)
      <<~YAML
        schema: metanorma-validation-rules/1
        rules:
          - {id: r.x, code: T_1, context: //x, check: #{check}, args: #{args}}
      YAML
    end

    it "rejects invalid arguments" do
      expect { load_set(rule("value_too_long", "{attribute: src, limit: other}")) }
        .to raise_error(/limit must be/)
      expect { load_set(rule("value_too_long", "{attribute: 1x, limit: dataurimaxsize}")) }
        .to raise_error(/invalid attribute/)
      expect { load_set(rule("duplicate_value", "{nodes: '//(', attribute: id}")) }
        .to raise_error(/nodes/)
      expect { load_set(rule("file_missing", "{attribute: 'a b'}")) }
        .to raise_error(/invalid attribute/)
      expect { load_set(rule("concept_reference", "{known: //a, label: '', refterm: ., subterm: //b}")) }
        .to raise_error(/label/)
      expect { load_set(rule("concept_reference", "{known: //a, label: L, refterm: '//(', subterm: //b}")) }
        .to raise_error(/refterm/)
    end

    it "needs a validator for option-based checks" do
      set = load_set(rule("value_too_long", "{attribute: src, limit: dataurimaxsize}"))
      doc = Nokogiri::XML("<doc><x src='a'/></doc>")
      expect { rules::Engine.new(set).findings(doc) }.to raise_error(rules::RuleError, /validator/)
    end

    it "reports these checks as code-backed on Schematron export" do
      mine = shipped_set.rules.select do |r|
        r.check.name.match?(/concept_reference|file_missing|value_too_long|duplicate_value/)
      end
      export = rules::Schematron.export(rules::RuleSet.new(mine))
      expect(export.code_backed).to include("standoc.concept.xref-not-term",
                                            "standoc.image.file-missing",
                                            "standoc.image.too-large",
                                            "standoc.id.repeated")
    end
  end
end
