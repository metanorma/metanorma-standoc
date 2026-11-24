require "spec_helper"

RSpec.describe "section visibility metadata" do
  [Metanorma::Standoc::Document::Sections::ClauseSection,
   Metanorma::Standoc::Document::Sections::AnnexSection].each do |model|
    [true, false, nil].each do |value|
      it "round-trips #{value.inspect} through #{model.name}" do
        section = model.new(hidden: value)
        xml = section.to_xml
        expect(section.hidden).to eq(value)
        expect(Nokogiri::XML(xml).root["hidden"]).to eq(value.nil? ? nil : value.to_s)
        expect(model.from_xml(xml).hidden).to eq(value)
      end
    end
  end
end
