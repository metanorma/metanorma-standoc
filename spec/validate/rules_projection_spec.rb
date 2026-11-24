require "spec_helper"

RSpec.describe Metanorma::Standoc::Validate::Rules do
  let(:rules) { described_class }
  let(:namespace) { "https://www.metanorma.org/ns/standoc" }
  let(:set) do
    rules::RuleSet.parse(<<~YAML)
      schema: metanorma-validation-rules/1
      namespaces: {m: #{namespace}}
      rules:
        - id: document.title
          code: TEST_1
          context: /m:metanorma
          target: ./m:sections/m:clause/m:title
          check: required
    YAML
  end

  it "evaluates a real Document model without dropping namespaces or identity" do
    model = Metanorma::Standoc::Document::Root.from_xml(<<~XML)
      <metanorma xmlns="#{namespace}" type="semantic" flavor="standoc">
        <sections><clause id="c1"><p id="p1">Body</p></clause></sections>
      </metanorma>
    XML
    projection = rules::DocumentProjection.for(model)
    expect(projection.source_model).to equal model
    expect(projection.xml.root.namespace.href).to eq namespace
    expect(projection.xml.at_xpath("//m:p", "m" => namespace).text).to eq "Body"
    findings = rules::Engine.new(set).findings(projection)
    expect(findings.map(&:code)).to eq ["TEST_1"]
    expect(findings.first.node).to equal projection.xml.root
    expect(findings.first.source_model).to equal model
  end

  it "preserves existing XML node identity for log/suppression consumers" do
    doc = Nokogiri::XML("<metanorma xmlns='#{namespace}'><sections/></metanorma>")
    expect(rules::Engine.new(set).findings(doc).first.node).to equal doc.root
  end

  it "recognizes a real model with the required title" do
    model = Metanorma::Standoc::Document::Root.from_xml(<<~XML)
      <metanorma xmlns="#{namespace}" type="semantic" flavor="standoc">
        <sections><clause id="c1"><title>Scope</title><p id="p1">Body</p></clause></sections>
      </metanorma>
    XML
    expect(rules::Engine.new(set).findings(model)).to be_empty
  end

  it "rejects arbitrary objects even if they expose to_xml" do
    impostor = Object.new
    def impostor.to_xml = "<metanorma/>"
    expect { rules::Engine.new(set).findings(impostor) }
      .to raise_error(rules::RuleError, /Document root/)
  end

  it "exports namespace bindings that retain the runtime assertion meaning" do
    export = rules::Schematron.export(set)
    doc = Nokogiri::XML(export.xml)
    ns = { "s" => rules::Schematron::NS }
    expect(doc.at_xpath("//s:ns[@prefix='m']", ns)["uri"]).to eq namespace
    assertion = doc.at_xpath("//s:assert", ns)
    expect(assertion["test"]).to eq "./m:sections/m:clause/m:title"
    xml = Nokogiri::XML("<metanorma xmlns='#{namespace}'><sections/></metanorma>")
    expect(xml.root.xpath("boolean(#{assertion['test']})", set.namespaces)).to be false
  end

  it "rejects namespace rebinding across layered rule sets" do
    other = rules::RuleSet.parse(<<~YAML)
      schema: metanorma-validation-rules/1
      namespaces: {m: urn:other}
      rules: []
    YAML
    expect { set.merge(other) }.to raise_error(rules::RuleError, /conflicting namespace/)
  end

  it "honors disable on a standalone set and rejects unknown disabled ids" do
    disabled = rules::RuleSet.new(set.rules, disabled: ["document.title"])
    xml = Nokogiri::XML("<metanorma xmlns='#{namespace}'/>")
    expect(rules::Engine.new(disabled).findings(xml)).to be_empty
    unknown = rules::RuleSet.new([], disabled: ["misspelled.rule"])
    expect { rules::Engine.new(unknown) }.to raise_error(rules::RuleError, /unknown rules/)
  end

  it "rejects invalid namespace maps and undeclared XPath prefixes" do
    expect do
      rules::RuleSet.parse("schema: metanorma-validation-rules/1\nnamespaces: []\nrules: []")
    end.to raise_error(rules::RuleError, /namespaces must be a map/)
    expect do
      rules::RuleSet.parse(<<~YAML)
        schema: metanorma-validation-rules/1
        rules:
          - {id: r.one, code: TEST_1, context: //missing:p, target: ./title, check: required}
      YAML
    end.to raise_error(rules::RuleError, /invalid context XPath/)
  end

  it "rejects valid XPath selections that are not portable XSLT match patterns" do
    nonportable = rules::RuleSet.parse(<<~YAML)
      schema: metanorma-validation-rules/1
      rules:
        - {id: r.one, code: TEST_1, context: '(//p)[1]', target: ./title, check: required}
    YAML
    expect { rules::Schematron.export(nonportable) }
      .to raise_error(rules::RuleError, /nonportable Schematron context/)
  end
end
