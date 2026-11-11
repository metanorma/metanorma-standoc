# frozen_string_literal: true

require "spec_helper"
require "metanorma/validate/image"

RSpec.describe Metanorma::Standoc::Validate do
  # Integration: the registry's outcomes through the Validate#svg_validate /
  # #png_validate paths — disable, and flavor-dir resolution.
  def build_validator(flavor_dir: nil, profile_attr: nil, png_attr: nil)
    logger = Metanorma::Utils::Log.new
    converter = Struct.new(:log, :files_to_delete).new(logger, [])
    validator = described_class.new(converter)
    validator.instance_variable_set(:@svg_conform_profile, profile_attr)
    validator.instance_variable_set(:@png_conform_profile, png_attr)
    if flavor_dir
      real_base = described_class.new(converter)
                                 .conform_profile_dir(:svg, own: false)
      allow(validator).to receive(:conform_profile_dir).with(:svg, own: false)
        .and_return(real_base)
      allow(validator).to receive(:conform_profile_dir).with(:svg, own: true)
        .and_return(flavor_dir)
    end
    validator
  end

  def corrupt_svg_doc
    Nokogiri::XML(<<~XML)
      <metanorma xmlns="https://www.metanorma.org/ns/standoc">
        <preface/><sections/>
        <metanorma-extension/>
      </metanorma>
    XML
  end

  describe "disable" do
    it "svg: none skips validation entirely, even for corrupt SVG" do
      v = build_validator(profile_attr: "none")
      doc = corrupt_svg_doc
      svg = Nokogiri::XML(<<~SVG).root
        <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"/>
      SVG
      doc.root.add_child(svg)
      expect { v.svg_validate(doc) }.not_to raise_error
      expect(v.svg_conform_profile).to be_nil
    end

    it "png: none skips validation" do
      v = build_validator(png_attr: "off")
      expect(v.png_conform_profile).to eq(:disabled)
    end
  end

  describe "png descriptor translation" do
    # png_conform 0.1.6 (claricle/png_conform#34) takes a definition
    # Hash, a gem profile name, or nil/"none": it reads no consumer
    # profile directories, so owned files load as inline definitions.
    it "loads a profile_file descriptor as an inline definition" do
      Dir.mktmpdir("png_profiles") do |dir|
        file = File.join(dir, "metanorma.yml")
        File.write(file, <<~YML)
          name: "Metanorma baseline"
          required_chunks:
            - IHDR
            - IDAT
            - IEND
          prohibited_chunks: []
        YML
        v = build_validator
        expect(v.png_conform_engine_profile({ profile_file: file }))
          .to eq("name" => "Metanorma baseline",
                 "required_chunks" => %w(IHDR IDAT IEND),
                 "prohibited_chunks" => [])
      end
    end

    it "passes an engine profile name through for gem-side lookup" do
      v = build_validator
      expect(v.png_conform_engine_profile({ engine_profile: "strict" }))
        .to eq("strict")
    end
  end

  describe "flavor-dir resolution" do
    it "resolves a flavor-shipped named profile through svg_validate" do
      Dir.mktmpdir("flavor_profiles") do |dir|
        # A flavor profile forbidding fill: its verdict proves this
        # profile (not the standoc baseline) drove the validation.
        File.write(File.join(dir, "flavor-strict.yml"), <<~YML)
          name: "flavor-strict"
          requirements:
            - id: "forbid_fill"
              type: "ForbiddenContentRequirement"
              description: "The flavor forbids fill attributes"
              forbidden_elements: []
              forbidden_attributes: ["fill"]
        YML
        v = build_validator(flavor_dir: dir, profile_attr: "flavor-strict")
        doc = Nokogiri::XML(<<~XML)
          <metanorma xmlns="https://www.metanorma.org/ns/standoc">
            <preface/><sections/>
          </metanorma>
        XML
        svg = Nokogiri::XML(<<~SVG).root
          <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10" viewBox="0 0 10 10">
            <g fill="blue"><rect width="8" height="8"/></g>
          </svg>
        SVG
        doc.root.add_child(svg)
        # The flavor profile drives the engine: its ForbiddenContent
        # verdict fires on the fill attribute (verified at the engine
        # level — the log surfacing of requirement errors is pending the
        # upstream ValidationIssue violation_type default, see
        # claricle/svg_conform).
        result = SvgConform::Validator.new(mode: :sax)
          .validate(svg.to_xml, profile: v.svg_conform_profile)
        expect(result.valid?).to be(false)
        expect((result.errors || []).map(&:message).join).to match(/fill/i)
      end
    end

    it "keeps the standoc baseline verdict when no flavor dir carries the name" do
      Dir.mktmpdir("empty_flavor") do |dir|
        v = build_validator(flavor_dir: dir, profile_attr: "flavor-strict")
        doc = Nokogiri::XML(<<~XML)
          <metanorma xmlns="https://www.metanorma.org/ns/standoc">
            <preface/><sections/>
          </metanorma>
        XML
        expect { v.svg_validate(doc) }
          .to raise_error(Metanorma::Standoc::ConformProfiles::NotFound,
                          /flavor-strict/)
      end
    end
  end
end
