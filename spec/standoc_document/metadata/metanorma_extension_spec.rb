# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe "StandardDocument metadata classes" do
  describe Metanorma::Standoc::Document::Metadata::MetanormaExtension do
    let(:full_xml) do
      "<metanorma-extension>" \
        "<semantic-metadata><stage-published>true</stage-published></semantic-metadata>" \
        "<presentation-metadata><document-scheme>2013</document-scheme>" \
        "<toc-heading-levels>2</toc-heading-levels></presentation-metadata>" \
        '<UnitsML xmlns="https://schema.unitsml.org/unitsml/1.0">' \
        '<UnitSet><Unit dimensionURL="#NISTd1" id="U_mm" semx-id="U_mm">' \
        '<UnitSystem name="SI" type="SI_base" lang="en-US"/>' \
        "<UnitName lang=\"en\">mm</UnitName>" \
        '<UnitSymbol type="HTML">mm</UnitSymbol>' \
        "</Unit></UnitSet></UnitsML>" \
        "<source-highlighter-css>sourcecode table td { padding: 5px; }\n" \
        "</source-highlighter-css></metanorma-extension>"
    end

    it "parses all four child kinds", :aggregate_failures do
      ext = described_class.from_xml(full_xml)
      expect(ext.semantic_metadata.stage_published).to eq("true")
      expect(ext.presentation_metadata.document_scheme).to eq("2013")
      expect(ext.unitsml.unit_set.unit.first.semx_id).to eq("U_mm")
      expect(ext.source_highlighter_css).to eq("sourcecode table td { padding: 5px; }\n")
    end

    it "round-trips the full extension" do
      expect(described_class.from_xml(full_xml).to_xml).to be_equivalent_to(full_xml)
    end

    it "round-trips an extension without UnitsML" do
      xml = "<metanorma-extension>" \
            "<semantic-metadata><stage-published>false</stage-published></semantic-metadata>" \
            "<presentation-metadata><document-scheme>current</document-scheme></presentation-metadata>" \
            "<source-highlighter-css>css</source-highlighter-css>" \
            "</metanorma-extension>"
      expect(described_class.from_xml(xml).to_xml).to be_equivalent_to(xml)
    end
  end

  describe Metanorma::Standoc::Document::Metadata::PresentationMetadata do
    it "parses the current typed children", :aggregate_failures do
      xml = "<presentation-metadata><document-scheme>2013</document-scheme>" \
            "<toc-heading-levels>2</toc-heading-levels>" \
            "<html-toc-heading-levels>2</html-toc-heading-levels>" \
            "<doc-toc-heading-levels>3</doc-toc-heading-levels>" \
            "<pdf-toc-heading-levels>3</pdf-toc-heading-levels></presentation-metadata>"
      pm = described_class.from_xml(xml)
      expect(pm.document_scheme).to eq("2013")
      expect(pm.toc_heading_levels).to eq("2")
      expect(pm.html_toc_heading_levels).to eq("2")
      expect(pm.doc_toc_heading_levels).to eq("3")
      expect(pm.pdf_toc_heading_levels).to eq("3")
    end

    it "round-trips the current form with html-details-open" do
      xml = "<presentation-metadata><document-scheme>2013</document-scheme>" \
            "<toc-heading-levels>2</toc-heading-levels>" \
            "<html-toc-heading-levels>2</html-toc-heading-levels>" \
            "<doc-toc-heading-levels>3</doc-toc-heading-levels>" \
            "<pdf-toc-heading-levels>3</pdf-toc-heading-levels>" \
            "<html-details-open>true</html-details-open></presentation-metadata>"
      expect(described_class.from_xml(xml).to_xml).to be_equivalent_to(xml)
    end

    it "parses the legacy name/value serialization", :aggregate_failures do
      xml = "<presentation-metadata><name>TOC Heading Levels</name>" \
            "<value>2</value></presentation-metadata>"
      pm = described_class.from_xml(xml)
      expect(pm.name).to eq("TOC Heading Levels")
      expect(pm.value).to eq("2")
    end

    it "round-trips the legacy name/value serialization" do
      xml = "<presentation-metadata><name>TOC Heading Levels</name>" \
            "<value>2</value></presentation-metadata>"
      expect(described_class.from_xml(xml).to_xml).to be_equivalent_to(xml)
    end

    it "parses doctype-alias and repeated fonts (OIML shape)", :aggregate_failures do
      xml = "<presentation-metadata>" \
            "<doctype-alias>international-recommendation</doctype-alias>" \
            "<document-scheme>2013</document-scheme>" \
            "<toc-heading-levels>2</toc-heading-levels>" \
            "<fonts>Futura PT Book</fonts><fonts>Futura PT Demi</fonts>" \
            "<fonts>Futura PT Light</fonts></presentation-metadata>"
      pm = described_class.from_xml(xml)
      expect(pm.doctype_alias).to eq("international-recommendation")
      expect(pm.fonts).to eq(["Futura PT Book", "Futura PT Demi", "Futura PT Light"])
    end

    it "round-trips the OGC color family" do
      xml = "<presentation-metadata><document-scheme>2026</document-scheme>" \
            "<color-admonition-caution>rgb(79, 129, 189)</color-admonition-caution>" \
            "<color-admonition-editor>rgb(79, 129, 189)</color-admonition-editor>" \
            "<color-admonition-important>rgb(79, 129, 189)</color-admonition-important>" \
            "<color-admonition-note>rgb(79, 129, 189)</color-admonition-note>" \
            "<color-admonition-safety-precaution>rgb(79, 129, 189)</color-admonition-safety-precaution>" \
            "<color-admonition-tip>rgb(79, 129, 189)</color-admonition-tip>" \
            "<color-admonition-todo>rgb(79, 129, 189)</color-admonition-todo>" \
            "<color-admonition-warning>rgb(79, 129, 189)</color-admonition-warning>" \
            "<color-background-definition-description>rgb(242, 251, 255)</color-background-definition-description>" \
            "<color-background-definition-term>rgb(215, 243, 255)</color-background-definition-term>" \
            "<color-background-page>rgb(33, 55, 92)</color-background-page>" \
            "<color-background-table-header>rgb(33, 55, 92)</color-background-table-header>" \
            "<color-background-table-row-even>rgb(252, 246, 222)</color-background-table-row-even>" \
            "<color-background-table-row-odd>rgb(254, 252, 245)</color-background-table-row-odd>" \
            "<color-background-term-admitted-label>rgb(223, 236, 249)</color-background-term-admitted-label>" \
            "<color-background-term-deprecated-label>rgb(237, 237, 238)</color-background-term-deprecated-label>" \
            "<color-background-term-preferred-label>rgb(249, 235, 187)</color-background-term-preferred-label>" \
            "<color-background-text-label-legacy>rgb(33, 60, 107)</color-background-text-label-legacy>" \
            "<color-secondary-shade-1>rgb(0, 177, 255)</color-secondary-shade-1>" \
            "<color-secondary-shade-2>rgb(0, 177, 255)</color-secondary-shade-2>" \
            "<color-text>rgb(88, 89, 91)</color-text>" \
            "<color-text-title>rgb(33, 55, 92)</color-text-title>" \
            "<toc-heading-levels>2</toc-heading-levels>" \
            "<html-toc-heading-levels>2</html-toc-heading-levels>" \
            "<doc-toc-heading-levels>2</doc-toc-heading-levels>" \
            "<pdf-toc-heading-levels>2</pdf-toc-heading-levels></presentation-metadata>"
      expect(described_class.from_xml(xml).to_xml).to be_equivalent_to(xml)
    end
  end

  describe Metanorma::Standoc::Document::Metadata::SemanticMetadata do
    it "parses stage-published" do
      xml = "<semantic-metadata><stage-published>true</stage-published></semantic-metadata>"
      expect(described_class.from_xml(xml).stage_published).to eq("true")
    end

    it "round-trips" do
      xml = "<semantic-metadata><stage-published>false</stage-published></semantic-metadata>"
      expect(described_class.from_xml(xml).to_xml).to be_equivalent_to(xml)
    end
  end
end
