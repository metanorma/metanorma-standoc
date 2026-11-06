require "spec_helper"

RSpec.describe "multi-line link macros" do
  # A hard break inside link-macro text carries PDF-tagging semantics
  # (ISO 32000-2 clause 14.8.4.7.3 errata): the break must survive into
  # the semantic XML as a <br/> between two link segments with the same
  # target, and the link text must not leak as literal bracket content.
  # The anchor consumes the break itself and emits one link per
  # segment (metanorma-pdfa#102).
  it "preserves link text across a hard break in an auto-link macro" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      Some more text with a https://pdfa.org[auto-link macro that +
      breaks over a line] hopefully.
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
      <p id="_">Some more text with a <link target="https://pdfa.org">auto-link macro that</link><br/>
      <link target="https://pdfa.org">breaks over a line</link> hopefully.</p>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

  it "preserves link text across a hard break in an explicit link macro" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      Yet more text a link:https://pdfa.org[explicit link macro that +
      breaks over a line] hopefully.
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
      <p id="_">Yet more text a <link target="https://pdfa.org">explicit link macro that</link><br/>
      <link target="https://pdfa.org">breaks over a line</link> hopefully.</p>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

  it "leaves single-line links untouched" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      This is some text with 2 separate URL https://pdfa.org[links that] +
      https://pdfa.org[breaks over a line] hopefully.
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
      <p id="_">This is some text with 2 separate URL <link target="https://pdfa.org">links that</link><br/>
      <link target="https://pdfa.org">breaks over a line</link> hopefully.</p>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end
end
