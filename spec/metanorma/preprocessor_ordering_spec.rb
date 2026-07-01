require "spec_helper"

# Regression guard for preprocessor ORDERING.
#
# metanorma's monospace safeguard (MonospaceProtectPreprocessor) must run
# AFTER the content-injecting preprocessors (yaml2text / json2text /
# data2text / lutaml*), so that monospace inside their *injected* content is
# protected from Asciidoctor character substitution exactly like
# hand-authored monospace. The relative timing of these preprocessors is
# load-bearing: if the guard is registered before the injectors, injected
# `->` becomes `→`, `--` becomes an em dash, and a `\->` escape is
# consumed -- see metanorma/iso-10303#208.
#
# These examples fail loudly if that ordering ever regresses.
RSpec.describe "preprocessor ordering: monospace safeguard covers injected content" do
  around do |example|
    File.write("ordering_spec.yaml", { "sym" => "->" }.to_yaml)
    example.run
    FileUtils.rm_rf("ordering_spec.yaml")
  end

  let(:input) do
    <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:

      handauthored:: arrow `->` dash `--` ellipsis `...`

      [yaml2text,ordering_spec.yaml,ctx]
      ----
      injected:: arrow `->` dash `--` ellipsis `...` interp `{ctx.sym}`
      ----
    INPUT
  end

  let(:output) do
    Asciidoctor.convert(input, backend: :standoc, header_footer: true)
  end

  it "safeguards monospace injected by yaml2text like hand-authored monospace" do
    # hand-authored monospace is the baseline: always literal
    expect(output).to include("<tt>-&gt;</tt>")

    # the guarantee: injected monospace is safeguarded identically, so the
    # literal monospace `->` appears BOTH hand-authored and injected (and the
    # interpolated {ctx.sym} == "->" makes a third). If the guard ran before
    # yaml2text, the injected ones would be substituted and this count drops.
    expect(output.scan("<tt>-&gt;</tt>").size).to be >= 3

    # no character substitution leaked out of any monospace span
    expect(output).not_to include("→") # -> right arrow
    expect(output).not_to include("&#8594;") # -> right arrow (entity)
    expect(output).not_to include("—") # -- em dash
    expect(output).not_to include("…") # ... ellipsis
  end
end
