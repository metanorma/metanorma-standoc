# frozen_string_literal: true

require "spec_helper"
require "metanorma/standoc/conform_profiles"
require "tmpdir"

RSpec.describe Metanorma::Standoc::ConformProfiles::Registry do
  let(:standoc_dir) { File.join(tmpdir, "standoc_svg_conform_profile") }
  let(:flavor_dir) { File.join(tmpdir, "bsi_svg_conform_profile") }
  let(:registry) do
    described_class.new(type: :svg, standoc_dir: standoc_dir,
                        flavor_dir: flavor_dir)
  end

  around do |example|
    @tmpdir = Dir.mktmpdir("conform_profiles_spec")
    FileUtils.mkdir_p([standoc_dir, flavor_dir])
    File.write(File.join(standoc_dir, "metanorma.yml"), "engine: svg\n")
    File.write(File.join(standoc_dir, "metanorma-strict.yml"), "engine: svg\n")
    File.write(File.join(flavor_dir, "bsi-strict.yml"), "engine: svg\n")
    example.run
    FileUtils.rm_rf(@tmpdir)
  end

  let(:tmpdir) { @tmpdir }

  it "resolves the unset value to the owned metanorma baseline" do
    expect(registry.resolve(nil)).to eq([:file,
                                         File.join(standoc_dir, "metanorma.yml")])
    expect(registry.resolve("metanorma")).to eq(
      [:file, File.join(standoc_dir, "metanorma.yml")],
    )
  end

  it "lets the flavor dir shadow the standoc default" do
    File.write(File.join(flavor_dir, "metanorma.yml"), "engine: svg\n")
    expect(registry.resolve(nil)).to eq([:file,
                                         File.join(flavor_dir, "metanorma.yml")])
  end

  it "resolves bare names within the flavor and standoc namespaces" do
    expect(registry.resolve("bsi-strict"))
      .to eq([:file, File.join(flavor_dir, "bsi-strict.yml")])
    expect(registry.resolve("metanorma-strict"))
      .to eq([:file, File.join(standoc_dir, "metanorma-strict.yml")])
  end

  it "reserves none/off/disabled for disabling validation" do
    %w(none off disabled NONE).each do |v|
      expect(registry.resolve(v)).to eq([:disabled])
    end
  end

  it "reaches the engine namespace only through the type prefix" do
    kind, name = registry.resolve("svg:svg_1_2_rfc")
    expect(kind).to eq(:engine)
    expect(name).to eq("svg_1_2_rfc")
  end

  it "does not let the colliding metanorma name fall back to the engine" do
    # "metanorma" is reserved for the owned baseline: with the baseline
    # present it resolves to it, never to a svg_conform gem profile.
    expect(registry.resolve("metanorma")).to eq(
      [:file, File.join(standoc_dir, "metanorma.yml")],
    )
  end

  it "loads direct paths" do
    path = File.join(tmpdir, "custom.yml")
    File.write(path, "engine: svg\n")
    expect(registry.resolve(path)).to eq([:file, path])
    expect(registry.resolve("#{tmpdir}/custom.yml"))
      .to eq([:file, "#{tmpdir}/custom.yml"])
  end

  it "fails loudly on unknown names, listing what exists" do
    expect { registry.resolve("nonexistent") }
      .to raise_error(Metanorma::Standoc::ConformProfiles::NotFound, /bsi-strict/)
  end

  it "fails loudly when the baseline is missing everywhere" do
    File.delete(File.join(standoc_dir, "metanorma.yml"))
    expect { registry.resolve(nil) }
      .to raise_error(Metanorma::Standoc::ConformProfiles::NotFound, /baseline is missing/)
  end
end

RSpec.describe "the owned metanorma SVG baseline" do
  let(:baseline_path) do
    File.expand_path("../../lib/metanorma/standoc/svg_conform_profile/metanorma.yml",
                     __dir__)
  end

  # claricle/svg_conform#128: markers are how metanorma diagrams draw
  # arrowheads; the profile listed the marker element but none of the
  # marker presentation attributes on the shape elements, so every
  # marker-end="url(#...)" failed while the same marker in a style
  # attribute passed.
  it "accepts marker presentation attributes on shape elements" do
    require "svg_conform"
    profile = SvgConform::Profile.load_from_file(baseline_path)
    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" version="1.2" baseProfile="tiny" width="40" height="12" viewBox="0 0 40 12">
        <defs>
          <marker id="a" markerWidth="4" markerHeight="4" refX="2" refY="2" orient="auto">
            <path d="M0,0 L4,2 L0,4"/>
          </marker>
        </defs>
        <path d="M2,6 H38" marker-end="url(#a)" marker-start="url(#a)"/>
        <line x1="2" y1="3" x2="38" y2="3" marker-end="url(#a)"/>
        <polyline points="2,9 20,9 38,9" marker-end="url(#a)"/>
        <polygon points="2,11 20,11 38,11" marker-end="url(#a)"/>
      </svg>
    SVG
    result = SvgConform::Validator.new(profile: profile).validate(svg)
    expect(result.valid?).to be(true), result.errors.map(&:message).join("; ")
  end

  it "still rejects marker attributes where SVG does not define them" do
    require "svg_conform"
    profile = SvgConform::Profile.load_from_file(baseline_path)
    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" version="1.2" baseProfile="tiny" width="40" height="12" viewBox="0 0 40 12">
        <rect x="2" y="2" width="36" height="8" marker-end="url(#a)"/>
      </svg>
    SVG
    result = SvgConform::Validator.new(profile: profile).validate(svg)
    expect(result.valid?).to be(false)
    expect(result.errors.map(&:message).join).to include("marker-end")
  end
end
