require "spec_helper"

RSpec.describe Metanorma::Standoc do
  it "does NOT apply character substitutions in monospaced text" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      Normal text with "smart quotes" and -- em-dash

      `Monospaced with "smart quotes" and -- em-dash`
    INPUT

    result = Asciidoctor.convert(input, *OPTIONS)

    # Check that normal text has smart quotes (curly quotes) and em-dash
    # Use Unicode for curly quotes and em-dash in the regex
    expect(result).to match(/Normal text with [\u201c\u201d]smart quotes[\u201c\u201d] and.*\u2014.*em-dash/)

    # Check that monospaced text preserves straight quotes and double dashes
    expect(result).to include('<tt>Monospaced with "smart quotes" and -- em-dash</tt>')
  end

  it "protects monospaced text with multiple special characters" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      Code with `multiple--dashes` and `"quotes"` and `test...ellipsis`
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
        <p id="_">Code with <tt>multiple--dashes</tt> and <tt>"quotes"</tt> and <tt>test...ellipsis</tt></p>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "allows quotes substitution in monospaced text" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      `A__B__C` should have italic B
    INPUT

    result = Asciidoctor.convert(input, *OPTIONS)
    # Verify __B__ becomes <em>B</em> inside <tt>
    expect(result).to include("<tt>A<em>B</em>C</tt>")
  end

  it "does not double-process existing pass macros in monospace" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      `text with pass:[content] macro`
    INPUT

    result = Asciidoctor.convert(input, *OPTIONS)
    # Should handle gracefully without errors
    expect(result).to be_a(String)
    expect(result).to include("<tt>")
  end

  it "handles brackets in monospace for inline macros" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      `code with [bracketed content]`
    INPUT

    result = Asciidoctor.convert(input, *OPTIONS)
    # Brackets should be preserved in monospace text
    expect(result).to include("[bracketed content]")
  end
end
