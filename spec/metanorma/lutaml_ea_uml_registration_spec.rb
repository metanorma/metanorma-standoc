# frozen_string_literal: true

require "spec_helper"

# The [lutaml_ea_uml] preprocessor ships with metanorma-plugin-lutaml and
# reads EA models DIRECTLY (.qea/.xmi/.lur, Ea::Qea / Ea.to_uml — no XMI
# intermediate). Standoc registers it so every flavor exposes the macro.
RSpec.describe "lutaml_ea_uml preprocessor registration" do
  it "intercepts the lutaml_ea_uml block instead of passing it through" do
    input = <<~SRC
      = Document title
      Author
      :docnumber: 1
      :doctype: standard
      :language: en

      [lutaml_ea_uml,nonexistent.qea]
      ----
      {% for k in context.classes %}{{ k.name }}{% endfor %}
      ----
    SRC

    # With the registration, the preprocessor attempts to load the model
    # file and errors out naming it; without, the liquid template survives
    # verbatim as literal document text.
    expect do
      Asciidoctor.convert(input, backend: :standoc)
    end.to raise_error(/nonexistent\.qea/)
  end
end
