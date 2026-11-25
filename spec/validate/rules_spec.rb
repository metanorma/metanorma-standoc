require "spec_helper"

RSpec.describe Metanorma::Standoc::Validate::Rules do
  let(:rules) { described_class }
  let(:header) { "schema: metanorma-validation-rules/1\n" }
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

  def parse(body, registry: rules::CheckRegistry.default)
    rules::RuleSet.parse(header + body, registry: registry)
  end

  def rule_yaml(extra)
    "rules:\n  - {id: r.one, code: TEST_1, context: //a, #{extra}}\n"
  end

  describe "STANDOC_39 parity with the Ruby implementation" do
    let(:shipped) do
      File.join(Metanorma::Standoc::Validate.instance_method(:validate)
        .source_location.first.then { |f| File.dirname(f) },
                "rules", "standoc.yaml")
    end
    let(:doc) do
      Nokogiri::XML(<<~XML)
        <doc>
          <note/><note><p>full</p></note><note><name>only name</name></note>
          <example> </example><admonition/><figure><image src="a"/></figure>
          <quote/><pre>x</pre>
          <sourcecode><name>n</name><body/></sourcecode>
          <sourcecode><body>code</body></sourcecode><sourcecode/>
          <formula><stem/></formula><formula><stem>x</stem></formula><formula/>
          <ol><li/><li>second</li></ol><ol><li>first</li></ol><ol/>
          <ul><li/></ul><dl><dt/><dd>d</dd></dl><dl><dt>t</dt></dl>
        </doc>
      XML
    end

    it "reports identical codes, nodes, params and order" do
      validator.all_empty_block_validate(doc)
      legacy = log.entries
      expect(legacy).not_to be_empty

      set = rules::RuleSet.load_file(shipped)
      declarative = rules::Engine.new(set, validator: validator)
        .findings(doc, modes: %w(shadow))
        .select { |f| f.code == "STANDOC_39" }
        .map { |f| [f.code, f.node.path, f.params] }
      expect(declarative).to eq legacy
    end

    it "does not run shadow rules as enforced rules" do
      set = rules::RuleSet.load_file(shipped)
      rules::Engine.new(set, validator: validator, log: log).run(doc)
      expect(log.entries).to be_empty
    end
  end

  describe "validator integration" do
    let(:doc) { Nokogiri::XML("<doc><a kind='bad'/></doc>") }

    it "has no rule set by default" do
      expect(validator.validation_rule_set).to be_nil
      expect(validator.declarative_rules_validate(doc)).to be_nil
      expect(log.entries).to be_empty
    end

    it "logs enforced findings through the log with the rule's code" do
      set = parse(rule_yaml("check: attribute_in, args: {attribute: kind, " \
                            "values: [good]}, params: [{attribute: kind}]"))
      allow(validator).to receive(:validation_rule_set).and_return(set)
      validator.declarative_rules_validate(doc)
      expect(log.entries).to eq [["TEST_1", "/doc/a", ["bad"]]]
    end
  end

  describe "rule file safety" do
    it "rejects YAML object tags" do
      expect { rules::RuleSet.parse("--- !ruby/object:Object {}\n") }
        .to raise_error(Psych::Exception)
    end

    it "rejects a check that is not registered" do
      expect { parse(rule_yaml("check: system")) }
        .to raise_error(rules::RuleError, /unknown check/)
    end

    it "rejects severity and citation on a rule" do
      %w(severity citation).each do |key|
        expect { parse(rule_yaml("check: empty_block, #{key}: x")) }
          .to raise_error(rules::RuleError, /log registry/)
      end
    end

    it "rejects unknown keys, bad XPath and non-node XPath" do
      expect { parse(rule_yaml("check: empty_block, eval: x")) }
        .to raise_error(rules::RuleError, /unknown keys/)
      expect { parse("rules:\n  - {id: a, code: T_1, context: '//[', check: empty_block}\n") }
        .to raise_error(rules::RuleError, /invalid context/)
      expect { parse("rules:\n  - {id: a, code: T_1, context: 'count(//a)', check: empty_block}\n") }
        .to raise_error(rules::RuleError, /must select nodes/)
    end

    it "rejects unquoted YAML booleans as attribute values" do
      expect do
        parse(rule_yaml("check: attribute_in, args: {attribute: a, values: [no]}"))
      end.to raise_error(rules::RuleError, /list of strings/)
    end

    it "rejects an unsupported schema version" do
      expect { rules::RuleSet.parse("schema: other/1\nrules: []\n") }
        .to raise_error(rules::RuleError, /unsupported schema/)
    end

    it "keeps the default registry immutable" do
      expect { rules::CheckRegistry.default.register("x") { true } }
        .to raise_error(FrozenError)
    end
  end

  describe "registered code-backed prose checks" do
    it "runs a flavor check and reports it as code-backed on export" do
      registry = rules::CheckRegistry.default.dup
      registry.register("no_shall") { |node, _, _| node.text.include?("shall") }
      set = parse(rule_yaml("check: no_shall"), registry: registry)
      doc = Nokogiri::XML("<doc><a>you shall</a><a>you may</a></doc>")

      found = rules::Engine.new(set).findings(doc)
      expect(found.map { |f| f.node.path }).to eq ["/doc/a[1]"]
      expect(rules::Schematron.export(set).code_backed).to eq ["r.one"]
    end
  end

  describe "layered rule sets" do
    let(:base) do
      parse("rules:\n" \
            "  - {id: a, code: T_1, context: //a, check: empty_block}\n" \
            "  - {id: b, code: T_2, context: //b, check: empty_block}\n")
    end

    it "replaces in place, appends and disables" do
      higher = parse("disable: [b]\nrules:\n" \
                     "  - {id: a, code: T_9, context: //a, check: empty_block}\n" \
                     "  - {id: c, code: T_3, context: //c, check: empty_block}\n")
      merged = base.merge(higher)
      expect(merged.rules.map { |r| [r.id, r.code] })
        .to eq [["a", "T_9"], ["c", "T_3"]]
    end

    it "fails when disabling an unknown rule" do
      expect { base.merge(parse("disable: [typo]\nrules: []\n")) }
        .to raise_error(rules::RuleError, /typo/)
    end
  end

  describe "Schematron export" do
    let(:set) do
      parse(<<~YAML)
        rules:
          - {id: req, code: T_1, context: //s, target: ./title, check: required}
          - {id: forb, code: T_2, context: //s, target: ./bad, check: forbidden}
          - {id: attr, code: T_3, context: //s, check: attribute_in, args: {attribute: type, values: [x, "it's"]}}
          - {id: block, code: T_4, context: //s, check: empty_block}
      YAML
    end
    let(:doc) do
      Nokogiri::XML(<<~XML)
        <doc><s type="x"><title>t</title></s><s type="it's"><bad/></s>
        <s type="y"><title>t</title><bad/></s><s/></doc>
      XML
    end

    it "gives each rule its own pattern and lists code-backed rules" do
      export = rules::Schematron.export(set)
      xml = Nokogiri::XML(export.xml)
      ns = { "s" => rules::Schematron::NS }
      expect(xml.xpath("//s:pattern", ns).size).to eq 3
      expect(xml.xpath("//s:assert/@id", ns).map(&:value))
        .to eq %w(req forb attr)
      expect(export.code_backed).to eq ["block"]
    end

    it "exports assertions that agree with the engine on every node" do
      set.rules.first(3).each do |rule|
        test = rules::Schematron.test_for(rule)
        by_xpath = doc.xpath(rule.context).reject do |n|
          n.xpath("boolean(#{test})")
        end.map(&:path)
        single = rules::RuleSet.new([rule])
        by_engine = rules::Engine.new(single).findings(doc).map do |f|
          f.node.ancestors("s").first&.path || f.node.path
        end
        expect(by_engine).to eq(by_xpath), rule.id
      end
    end
  end

  describe "xpath_assert check and Schematron evaluation" do
    let(:set) do
      parse(<<~YAML)
        rules:
          - {id: has-text, code: T_1, context: //s, check: xpath_assert, args: {test: "string-length(normalize-space(.)) > 0"}}
          - {id: title-short, code: T_2, context: //s, target: ./title, check: xpath_assert, args: {test: "string-length(.) < 5"}}
      YAML
    end
    let(:doc) do
      Nokogiri::XML(<<~XML)
        <doc><s><title>ok</title></s><s><title>far too long</title></s>
        <s/><s><p>x</p></s></doc>
      XML
    end

    it "agrees with the engine when the export is run as Schematron" do
      export = rules::Schematron.export(set)
      expect(export.code_backed).to be_empty
      by_schematron = rules::Schematron.evaluate(export.xml, doc)
        .map { |f| [f.id, f.node.path] }
      by_engine = rules::Engine.new(set).findings(doc).map do |f|
        [f.rule_id, (f.node.name == "s" ? f.node : f.node.parent).path]
      end
      expect(by_engine).to eq by_schematron
      expect(by_engine.map(&:first)).to eq %w(has-text title-short)
    end

    it "fires only the first matching rule of a pattern, and reports" do
      xml = <<~SCH
        <schema xmlns="#{rules::Schematron::NS}"><pattern>
          <rule context="//s[@a]"><assert id="a" test="false()">a</assert></rule>
          <rule context="//s"><assert id="b" test="false()">b</assert>
          <report id="c" test="true()">c</report></rule>
        </pattern></schema>
      SCH
      found = rules::Schematron.evaluate(
        xml, Nokogiri::XML('<d><s a="1"/><s/></d>')
      )
      expect(found.map(&:id)).to eq %w(a b c)
    end

    it "rejects a malformed test or a missing one" do
      expect do
        parse("rules:\n  - {id: x, code: T_1, context: //s, check: xpath_assert, args: {test: \"((\"}}\n")
      end.to raise_error(rules::RuleError, /invalid test XPath/)
      expect do
        parse("rules:\n  - {id: x, code: T_1, context: //s, check: xpath_assert}\n")
      end.to raise_error(rules::RuleError, /missing args test/)
    end

    it "accepts namespace prefixes declared by the rule file" do
      set = parse(<<~YAML)
        namespaces: {m: "urn:m"}
        rules:
          - {id: ns, code: T_1, context: //m:s, check: xpath_assert, args: {test: "m:t"}}
      YAML
      d = Nokogiri::XML('<d xmlns:m="urn:m"><m:s><m:t/></m:s><m:s/></d>')
      expect(rules::Engine.new(set).findings(d).size).to eq 1
      expect(rules::Schematron.evaluate(rules::Schematron.export(set).xml, d).size).to eq 1
    end

    it "exposes the export through the validator" do
      validator = Class.new { include Metanorma::Standoc::Validate::Rules::DeclarativeValidation }.new
      expect(validator.validation_schematron).to be_nil
    end
  end
end
