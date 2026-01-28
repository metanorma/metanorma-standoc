require "spec_helper"

RSpec.describe Metanorma::Standoc do
  it "does NOT apply character substitutions in monospaced text" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      Normal text with "smart quotes" and -- em-dash

      `Monospaced with "smart quotes" and -- em-dash`

      _a``part-wordwith--em``dash_
    INPUT

    result = Asciidoctor.convert(input, *OPTIONS)

    expect(result).to match(/Normal text with [\u201c\u201d]smart quotes[\u201c\u201d] and.*\u2014.*em-dash/)
    expect(result).to include('<tt>Monospaced with "smart quotes" and -- em-dash</tt>')
    expect(result).to include("<em>a<tt>part-wordwith--em</tt>dash</em>")
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

      *a``D__E__F``b* should have italic B
    INPUT

    result = Asciidoctor.convert(input, *OPTIONS)
    expect(result).to include("<tt>A<em>B</em>C</tt>")
    expect(result).to include("<strong>a<tt>D<em>E</em>F</tt>b</strong>")
  end

  it "does not double-process existing pass macros in monospace" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      `text with pass:[content] macro`

      a``another{blank}pass-format:metanorma[more content]-macro``b
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
      `code with number:[1]`
      an-``inline{blank}[bracketed inline content]``
    INPUT

    result = Asciidoctor.convert(input, *OPTIONS)
    # Brackets should be preserved in monospace text
    expect(result).to include("[bracketed content]")
    expect(result).to include("number:[1]")
    expect(result).to include("[bracketed inline content]")
  end
end
