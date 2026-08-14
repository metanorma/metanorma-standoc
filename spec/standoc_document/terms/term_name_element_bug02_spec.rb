# frozen_string_literal: true

require "spec_helper"
require "metanorma/document"
require "metanorma/standard_document"

RSpec.describe "BUGS.sts 02: TermNameElement preserves <stem> children" do
  def child_classes(element)
    children = []
    element.each_mixed_content do |node|
      children << (node.is_a?(String) ? "String" : node.class)
    end
    children
  end

  it "preserves a stem child inside name" do
    term = Metanorma::Standoc::Document::Terms::Term.from_xml(<<~XML)
      <term xmlns="https://www.metanorma.org/ns/standoc">
        <preferred>
          <expression>
            <name>maximum capacity (<stem block="false" type="MathML">
              <math xmlns="http://www.w3.org/1998/Math/MathML">
                <msub><mi>E</mi><mtext>max</mtext></msub>
              </math>
            </stem>)</name>
          </expression>
        </preferred>
      </term>
    XML
    name = Array(term.preferred).first.expression.name.first
    children = child_classes(name)
    expect(children).to include(Metanorma::Document::Components::Inline::StemInlineElement)
  end

  # NOTE: text-ownership in deeply-nested mixed_content is BUGS.sts 06,
  # a lutaml-model framework bug. Until it lands, the text might be
  # captured at the expression level rather than the name level. We
  # only assert here that text content survives parsing somewhere in
  # the tree.
  it "preserves text content somewhere in the parse tree" do
    term = Metanorma::Standoc::Document::Terms::Term.from_xml(<<~XML)
      <term xmlns="https://www.metanorma.org/ns/standoc">
        <preferred>
          <expression>
            <name>maximum capacity (<stem block="false" type="MathML">
              <math xmlns="http://www.w3.org/1998/Math/MathML">
                <msub><mi>E</mi><mtext>max</mtext></msub>
              </math>
            </stem>)</name>
          </expression>
        </preferred>
      </term>
    XML
    serialized = term.to_xml
    expect(serialized).to include("maximum capacity")
  end

  it "preserves em children inside name" do
    term = Metanorma::Standoc::Document::Terms::Term.from_xml(<<~XML)
      <term xmlns="https://www.metanorma.org/ns/standoc">
        <preferred>
          <expression>
            <name>an <em>emphatic</em> name</name>
          </expression>
        </preferred>
      </term>
    XML
    name = Array(term.preferred).first.expression.name.first
    children = child_classes(name)
    expect(children).to include(Metanorma::Document::Components::Inline::EmRawElement)
  end
end
