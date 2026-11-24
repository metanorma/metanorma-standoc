# frozen_string_literal: true

require "spec_helper"

# Shadow YAML rules versus the Ruby validations they mirror
# (metanorma-standoc#1381). Each example runs the legacy method and the rules
# for its code on the same input and requires identical findings.
RSpec.describe Metanorma::Standoc::Validate::Rules, "migrated validations" do
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

  def declarative(doc, code)
    set = rules::RuleSet.load_file(shipped)
    rules::Engine.new(set, validator: validator).findings(doc, modes: %w(shadow))
      .select { |f| f.code == code }
      .map { |f| [f.code, f.node.path, f.params] }
  end

  def expect_parity(doc, code)
    legacy = log.entries.select { |e| e.first == code }
    expect(legacy).not_to be_empty
    expect(declarative(doc, code).sort).to eq legacy.sort
  end

  it "STANDOC_2 empty tables" do
    doc = Nokogiri::XML(<<~XML)
      <doc><table><tr><td/></table><table/><table><name>x</name></table>
      <metanorma-extension><table/></metanorma-extension></doc>
    XML
    validator.empty_table_validate(doc)
    expect_parity(doc, "STANDOC_2")
    expect(log.entries.size).to eq 2
  end

  it "STANDOC_47 and STANDOC_62 sourcecode callouts" do
    doc = Nokogiri::XML(<<~XML)
      <doc>
      <sourcecode><body>a<callout>1</callout></body></sourcecode>
      <sourcecode><body>a<callout>1</callout><callout>2</callout></body>
        <callout-annotation>x</callout-annotation></sourcecode>
      <sourcecode><body>a<callout>1</callout></body>
        <callout-annotation>x</callout-annotation></sourcecode>
      <sourcecode><body>a</body><callout-annotation>x</callout-annotation></sourcecode>
      <sourcecode><body>plain</body></sourcecode>
      </doc>
    XML
    validator.sourcecode_style(doc.root)
    expect_parity(doc, "STANDOC_62")
    expect_parity(doc, "STANDOC_47")
    expect(log.entries.map(&:first).sort)
      .to eq %w(STANDOC_47 STANDOC_47 STANDOC_62)
  end

  it "STANDOC_48 hanging paragraphs and missing asset titles" do
    doc = Nokogiri::XML(<<~XML)
      <doc>
      <clause><title>t</title><clause/></clause>
      <clause><title>t</title><p>hang</p><clause/></clause>
      <annex><p>no subclause</p></annex>
      <foreword><clause/><note/></foreword>
      <figure><image src="a"/></figure><figure><name>n</name><image src="b"/></figure>
      <figure><pre>no image</pre></figure>
      <table><tr><td/></tr></table><table><name>n</name><tr><td/></tr></table>
      <sourcecode><table><tr><td/></tr></table></sourcecode>
      <metanorma-extension><figure><image src="c"/></figure><table/></metanorma-extension>
      </doc>
    XML
    validator.hanging_para_style(doc.root)
    validator.asset_style(doc.root)
    expect_parity(doc, "STANDOC_48")
    expect(log.entries.size).to eq 4
  end

  it "STANDOC_49 numeric docidentifiers in normative references" do
    doc = Nokogiri::XML(<<~XML)
      <doc>
      <references normative="true">
      <bibitem><docidentifier type="metanorma">[1]</docidentifier></bibitem>
      <bibitem><docidentifier type="metanorma">[12]</docidentifier></bibitem>
      <bibitem><docidentifier type="metanorma">[]</docidentifier></bibitem>
      <bibitem><docidentifier type="metanorma">[A1]</docidentifier></bibitem>
      <bibitem><docidentifier type="metanorma">ISO 1</docidentifier></bibitem>
      <bibitem><docidentifier type="ISO">[2]</docidentifier></bibitem>
      <bibitem><docidentifier type="ISO">x</docidentifier>
        <docidentifier type="metanorma">[3]</docidentifier></bibitem>
      </references>
      <references normative="false">
      <bibitem><docidentifier type="metanorma">[4]</docidentifier></bibitem>
      </references></doc>
    XML
    validator.norm_ref_validate(doc)
    expect_parity(doc, "STANDOC_49")
    expect(log.entries.size).to eq 3
  end

  it "rejects an invalid count param" do
    yaml = "schema: metanorma-validation-rules/1\nrules:\n  - {id: r.one, " \
           "code: TEST_1, context: //a, check: required, target: ./b, " \
           "params: [{count: '(('}]}\n"
    expect { rules::RuleSet.parse(yaml, registry: rules::CheckRegistry.default) }
      .to raise_error(rules::RuleError, /invalid param/)
  end
end
