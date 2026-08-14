# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe "StandardDocument metadata classes" do
  describe Metanorma::Standoc::Document::Metadata::Unitsml::UnitsmlRoot do
    let(:unitsml_xml) do
      '<UnitsML xmlns="https://schema.unitsml.org/unitsml/1.0">' \
        "<UnitSet>" \
        '<Unit dimensionURL="#NISTd1" id="U_mm" semx-id="U_mm">' \
        '<UnitSystem name="SI" type="SI_base" lang="en-US"/>' \
        '<UnitName lang="en">mm</UnitName>' \
        '<UnitSymbol type="HTML">mm</UnitSymbol>' \
        '<UnitSymbol type="MathMl">' \
        '<math xmlns="http://www.w3.org/1998/Math/MathML">' \
        '<mi mathvariant="normal">mm</mi></math></UnitSymbol>' \
        "<RootUnits>" \
        '<EnumeratedRootUnit unit="metre" prefix="m"/>' \
        "</RootUnits></Unit></UnitSet>" \
        "<QuantitySet>" \
        '<Quantity id="NISTq2" quantityType="base" dimensionURL="#NISTd2" semx-id="NISTq2">' \
        '<QuantityName lang="en-US">mass</QuantityName></Quantity></QuantitySet>' \
        "<DimensionSet>" \
        '<Dimension id="NISTd1" semx-id="NISTd1">' \
        '<Length symbol="L" powerNumerator="1"/></Dimension></DimensionSet>' \
        "<PrefixSet>" \
        '<Prefix prefixBase="10" prefixPower="-3" id="NISTp10_-3" semx-id="NISTp10_-3">' \
        '<PrefixName lang="en">milli</PrefixName>' \
        '<PrefixSymbol type="ASCII">m</PrefixSymbol></Prefix></PrefixSet>' \
        "</UnitsML>"
    end

    it "parses all four child sets", :aggregate_failures do
      root = described_class.from_xml(unitsml_xml)
      expect(root.unit_set.unit.length).to eq(1)
      expect(root.quantity_set.quantity.length).to eq(1)
      expect(root.dimension_set.dimension.length).to eq(1)
      expect(root.prefix_set.prefix.length).to eq(1)
    end

    it "round-trips the full tree (semx-id, lang, MathML symbol, default namespace)" do
      expect(described_class.from_xml(unitsml_xml).to_xml)
        .to be_equivalent_to(unitsml_xml)
    end

    it "serializes with the default (unprefixed) UnitsML namespace" do
      expect(described_class.from_xml(unitsml_xml).to_xml)
        .to include('<UnitsML xmlns="https://schema.unitsml.org/unitsml/1.0">')
    end

    describe "Unit" do
      let(:unit) { described_class.from_xml(unitsml_xml).unit_set.unit.first }

      it "parses dimensionURL, id and semx-id", :aggregate_failures do
        expect(unit.dimension_url).to eq("#NISTd1")
        expect(unit.id).to eq("U_mm")
        expect(unit.semx_id).to eq("U_mm")
      end

      it "parses UnitSystem, UnitName, UnitSymbol and RootUnits", :aggregate_failures do
        expect(unit.unit_system.name).to eq("SI")
        expect(unit.unit_system.type).to eq("SI_base")
        expect(unit.unit_system.lang).to eq("en-US")
        expect(unit.unit_name.text).to eq("mm")
        expect(unit.unit_symbol.map(&:type)).to eq(%w[HTML MathMl])
        expect(unit.root_units.enumerated_root_unit.first.unit).to eq("metre")
        expect(unit.root_units.enumerated_root_unit.first.prefix).to eq("m")
      end
    end
  end

  describe Metanorma::Standoc::Document::Metadata::Unitsml::UnitSymbol do
    it "parses an HTML symbol with inline sup markup as mixed content", :aggregate_failures do
      xml = '<UnitSymbol xmlns="https://schema.unitsml.org/unitsml/1.0" ' \
            'type="HTML">nmol mol <sup>−1</sup></UnitSymbol>'
      sym = described_class.from_xml(xml)
      expect(sym.text).to eq(["nmol mol "])
      expect(sym.sup.first.text).to eq(["−1"])
    end

    it "round-trips an HTML symbol with inline sup markup" do
      xml = '<UnitSymbol xmlns="https://schema.unitsml.org/unitsml/1.0" ' \
            'type="HTML">nmol mol <sup>−1</sup></UnitSymbol>'
      expect(described_class.from_xml(xml).to_xml).to be_equivalent_to(xml)
    end

    it "round-trips a MathMl symbol with its MathML content" do
      xml = '<UnitSymbol xmlns="https://schema.unitsml.org/unitsml/1.0" ' \
            'type="MathMl"><math xmlns="http://www.w3.org/1998/Math/MathML">' \
            '<mi mathvariant="normal">mm</mi></math></UnitSymbol>'
      expect(described_class.from_xml(xml).to_xml).to be_equivalent_to(xml)
    end
  end

  describe Metanorma::Standoc::Document::Metadata::Unitsml::Dimension do
    # Brief example: AmountOfSubstance before ThermodynamicTemperature.
    # Parsing is order-independent; serialization normalizes to schema
    # order (ThermodynamicTemperature before AmountOfSubstance), which is
    # what every spec fixture uses.
    it "parses all six base-quantity children", :aggregate_failures do
      xml = '<Dimension id="NISTd1" semx-id="NISTd1">' \
            '<Length symbol="L" powerNumerator="1"/>' \
            '<Mass symbol="M" powerNumerator="1"/>' \
            '<Time symbol="T" powerNumerator="-2"/>' \
            '<ElectricCurrent symbol="I" powerNumerator="-1"/>' \
            '<AmountOfSubstance symbol="N" powerNumerator="0"/>' \
            '<ThermodynamicTemperature symbol="Theta" powerNumerator="1"/>' \
            "</Dimension>"
      dim = described_class.from_xml(xml)
      expect(dim.semx_id).to eq("NISTd1")
      expect(dim.length.symbol).to eq("L")
      expect(dim.mass.symbol).to eq("M")
      expect(dim.time.power_numerator).to eq(-2)
      expect(dim.electric_current.power_numerator).to eq(-1)
      expect(dim.amount_of_substance.power_numerator).to eq(0)
      expect(dim.thermodynamic_temperature.symbol).to eq("Theta")
    end

    it "serializes every base-quantity child back out" do
      xml = '<Dimension id="NISTd1" semx-id="NISTd1">' \
            '<Length symbol="L" powerNumerator="1"/>' \
            '<Mass symbol="M" powerNumerator="1"/>' \
            '<Time symbol="T" powerNumerator="-2"/>' \
            '<ElectricCurrent symbol="I" powerNumerator="-1"/>' \
            '<AmountOfSubstance symbol="N" powerNumerator="0"/>' \
            '<ThermodynamicTemperature symbol="Theta" powerNumerator="1"/>' \
            "</Dimension>"
      out = described_class.from_xml(xml).to_xml
      expect(out).to include("Length", "Mass", "Time", "ElectricCurrent",
                             "AmountOfSubstance", "ThermodynamicTemperature")
    end

    it "round-trips children in schema order" do
      xml = '<Dimension xmlns="https://schema.unitsml.org/unitsml/1.0" ' \
            'id="NISTd9" semx-id="NISTd9">' \
            '<Length symbol="L" powerNumerator="1"/>' \
            '<Mass symbol="M" powerNumerator="1"/>' \
            '<Time symbol="T" powerNumerator="-2"/>' \
            '<ElectricCurrent symbol="I" powerNumerator="-1"/>' \
            '<ThermodynamicTemperature symbol="Theta" powerNumerator="1"/>' \
            '<AmountOfSubstance symbol="N" powerNumerator="0"/>' \
            "</Dimension>"
      expect(described_class.from_xml(xml).to_xml).to be_equivalent_to(xml)
    end
  end

  describe Metanorma::Standoc::Document::Metadata::Unitsml::Prefix do
    it "parses attributes and children", :aggregate_failures do
      xml = '<Prefix prefixBase="10" prefixPower="-3" id="NISTp10_-3" semx-id="NISTp10_-3">' \
            '<PrefixName lang="en">milli</PrefixName>' \
            '<PrefixSymbol type="ASCII">m</PrefixSymbol></Prefix>'
      prefix = described_class.from_xml(xml)
      expect(prefix.prefix_base).to eq(10)
      expect(prefix.prefix_power).to eq(-3)
      expect(prefix.semx_id).to eq("NISTp10_-3")
      expect(prefix.prefix_name.text).to eq("milli")
      expect(prefix.prefix_symbol.first.type).to eq("ASCII")
    end

    it "round-trips a prefix with multiple symbols" do
      xml = '<Prefix xmlns="https://schema.unitsml.org/unitsml/1.0" ' \
            'prefixBase="10" prefixPower="3" id="NISTp10_3" semx-id="NISTp10_3">' \
            '<PrefixName lang="en">kilo</PrefixName>' \
            '<PrefixSymbol type="ASCII">k</PrefixSymbol>' \
            '<PrefixSymbol type="unicode">k</PrefixSymbol>' \
            '<PrefixSymbol type="LaTeX">k</PrefixSymbol>' \
            '<PrefixSymbol type="HTML">k</PrefixSymbol></Prefix>'
      expect(described_class.from_xml(xml).to_xml).to be_equivalent_to(xml)
    end
  end

  describe Metanorma::Standoc::Document::Metadata::Unitsml::Quantity do
    it "parses attributes and repeated QuantityName", :aggregate_failures do
      xml = '<Quantity id="NISTq3" quantityType="base" dimensionURL="#NISTd3" semx-id="NISTq3">' \
            '<QuantityName lang="en-US">time</QuantityName>' \
            '<QuantityName lang="en-US">duration</QuantityName></Quantity>'
      quantity = described_class.from_xml(xml)
      expect(quantity.quantity_type).to eq("base")
      expect(quantity.dimension_url).to eq("#NISTd3")
      expect(quantity.semx_id).to eq("NISTq3")
      expect(quantity.quantity_name.map(&:text)).to eq(%w[time duration])
      expect(quantity.quantity_name.first.lang).to eq("en-US")
    end

    it "round-trips" do
      xml = '<Quantity xmlns="https://schema.unitsml.org/unitsml/1.0" ' \
            'id="NISTq2" quantityType="base" dimensionURL="#NISTd2" semx-id="NISTq2">' \
            '<QuantityName lang="en-US">mass</QuantityName></Quantity>'
      expect(described_class.from_xml(xml).to_xml).to be_equivalent_to(xml)
    end
  end
end
