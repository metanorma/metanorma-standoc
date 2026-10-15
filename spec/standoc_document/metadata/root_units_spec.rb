# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Metanorma::Standoc::Document::Metadata::Unitsml::RootUnits do
  [
    ["an omitted power", '<EnumeratedRootUnit unit="bel" prefix="d"/>', nil, nil],
    ["an integer power",
     '<EnumeratedRootUnit unit="bel" prefix="d" powerNumerator="1"/>', 1, nil],
    ["a zero power",
     '<EnumeratedRootUnit unit="bel" prefix="d" powerNumerator="0"/>', 0, nil],
    ["an explicit denominator of one",
     '<EnumeratedRootUnit unit="bel" prefix="d" ' \
     'powerNumerator="2" powerDenominator="1"/>', 2, 1],
    ["a positive fraction",
     '<EnumeratedRootUnit unit="bel" prefix="d" ' \
     'powerNumerator="1" powerDenominator="2"/>', 1, 2],
    ["a negative fraction",
     '<EnumeratedRootUnit unit="bel" prefix="d" ' \
     'powerNumerator="-2" powerDenominator="3"/>', -2, 3],
  ].each do |name, root_xml, numerator, denominator|
    it "preserves #{name} in a nested root unit", :aggregate_failures do
      xml = '<RootUnits xmlns="https://schema.unitsml.org/unitsml/1.0">' \
            "#{root_xml}</RootUnits>"
      model = described_class.from_xml(xml)
      root_unit = model.enumerated_root_unit.first
      expect(root_unit.unit).to eq("bel")
      expect(root_unit.prefix).to eq("d")
      expect(root_unit.power_numerator).to eq(numerator)
      expect(root_unit.power_denominator).to eq(denominator)
      expect(model.to_xml).to be_equivalent_to(xml)
    end
  end
end
