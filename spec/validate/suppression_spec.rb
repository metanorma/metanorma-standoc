# frozen_string_literal: true

require "spec_helper"
require "fileutils"

# Declarative validation suppression (metanorma-standoc#1369).
# v1: per-code severity actions, per-code allow/exclude message-text
# patterns, and whole-family rules; the canonical schema is frozen in
# the issue's last comment.
RSpec.describe Metanorma::Standoc::Validate::Suppression::Config do
  let(:config_class) { described_class }
  let(:entry_class) do
    Metanorma::Standoc::Validate::Suppression::RuleEntry
  end

  it "parses the canonical schema: rules keyed by code, family rules" do
    cfg = config_class.from_yaml_string(<<~YAML)
      schema: metanorma-validation-suppression/1
      rules:
        ISO_53:
          severity: off
        STANDOC_48:
          severity: warning
      category_rules:
        category:
          Style:
            severity: off
    YAML
    expect(cfg.schema_version)
      .to eq "metanorma-validation-suppression/1"
    expect(cfg.rules.map { |r| [r.code, r.normalized_severity] })
      .to eq [["ISO_53", "off"], ["STANDOC_48", "warning"]]
    expect(cfg.category_rules)
      .to eq("category" => { "Style" => { "severity" => "off" } })
  end

  it "defaults the schema version when the schema key is absent" do
    cfg = config_class.from_yaml_string("rules:\n  X:\n    severity: off\n")
    expect(cfg.schema_version)
      .to eq "metanorma-validation-suppression/1"
  end

  it "normalizes the YAML-1.1 `off` keyword and case" do
    cfg = config_class.from_yaml_string("rules:\n  X:\n    severity: off\n")
    expect(cfg.rules.first.normalized_severity).to eq "off"
    cfg2 = config_class.from_yaml_string("rules:\n  X:\n    severity: OFF\n")
    expect(cfg2.rules.first.normalized_severity).to eq "off"
  end

  it "rejects an unknown schema version" do
    expect do
      config_class.from_yaml_string("schema: bogus/9\n")
    end.to raise_error ArgumentError,
                       /unsupported validation-suppression schema version/
  end

  it "rejects severities outside the vocabulary, naming the code" do
    expect do
      config_class.from_yaml_string(
        "rules:\n  STANDOC_1:\n    severity: bogus\n",
      )
    end.to raise_error ArgumentError,
                       /invalid severity "bogus" for code STANDOC_1/
  end

  it "parses from a file, naming the path on malformed YAML" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "suppression.yml")
      File.write(path, "rules:\n  STANDOC_48:\n    severity: off\n")
      cfg = config_class.from_yaml(path)
      expect(cfg.code_rule("STANDOC_48").normalized_severity).to eq "off"

      bad = File.join(dir, "bad.yml")
      File.write(bad, "rules:\n  STANDOC_48:\n    severity: nope\n")
      expect { config_class.from_yaml(bad) }
        .to raise_error(ArgumentError,
                        %r{validation suppression config .*bad\.yml})
    end
  end

  describe "#action_for" do
    let(:cfg) do
      config_class.from_yaml_string(<<~YAML)
        rules:
          ISO_53:
            severity: off
          STANDOC_48:
            severity: warning
      YAML
    end

    it "matches codes: off" do
      expect(cfg.action_for(id: "ISO_53"))
        .to eq(action: :off, reason: "suppressed by validation rule (ISO_53)")
    end

    it "matches codes: reclassify with the Log severity level" do
      expect(cfg.action_for(id: "STANDOC_48"))
        .to eq(action: :reclassify, severity: 2,
               reason: "reclassified by validation rule (STANDOC_48: warning)")
    end

    it "returns nil when nothing matches" do
      expect(cfg.action_for(id: "STANDOC_99", category: "Style")).to be_nil
    end

    it "matches category family rules against the log category" do
      fam = config_class.from_yaml_string(<<~YAML)
        category_rules:
          category:
            Style:
              severity: off
      YAML
      expect(fam.action_for(id: "STANDOC_99", category: "Style"))
        .to eq(action: :off,
               reason: "suppressed by validation rule (Style) [category=Style]")
      expect(fam.action_for(id: "STANDOC_99", category: "Relaton")).to be_nil
    end

    it "mn_category and source families are inert without a registry" do
      fam = config_class.from_yaml_string(<<~YAML)
        category_rules:
          mn_category:
            References:
              severity: off
      YAML
      expect(fam.action_for(id: "STANDOC_10", category: "Style")).to be_nil
    end

    it "mn_category and source families match via registry_lookup" do
      fam = config_class.from_yaml_string(<<~YAML)
        category_rules:
          source:
            iso:
              severity: warning
      YAML
      fam.registry_lookup = ->(family, _id) {
        family == "source" ? "iso" : nil
      }
      expect(fam.action_for(id: "STANDOC_10", category: "Anchors"))
        .to eq(action: :reclassify, severity: 2,
               reason: "reclassified by validation rule (iso: warning) " \
                       "[source=iso]")
    end

    it "code rules take precedence over family rules" do
      fam = config_class.from_yaml_string(<<~YAML)
        rules:
          STANDOC_10:
            severity: error
        category_rules:
          category:
            Anchors:
              severity: off
      YAML
      expect(fam.action_for(id: "STANDOC_10", category: "Anchors"))
        .to eq(action: :reclassify, severity: 1,
               reason: "reclassified by validation rule (STANDOC_10: error)")
    end
  end

  describe "per-rule allow and exclude patterns" do
    let(:cfg) do
      config_class.from_yaml_string(<<~'YAML')
        rules:
          STANDOC_7:
            severity: off
            allow:
              - 'value of attribute "align"'
            exclude:
              - 'not allowed here$'
      YAML
    end

    it "parses the pattern lists" do
      expect(Array(cfg.code_rule("STANDOC_7").allow))
        .to eq ['value of attribute "align"']
      expect(Array(cfg.code_rule("STANDOC_7").exclude))
        .to eq ["not allowed here$"]
    end

    it "an allow pattern match yields :allow with the pattern as reason" do
      expect(cfg.action_for(id: "STANDOC_7",
                            message: 'value of attribute "align" is invalid'))
        .to eq(action: :allow,
               reason: 'allowed by config: value of attribute "align"')
    end

    it "allow wins over exclude" do
      expect(cfg.action_for(id: "STANDOC_7",
                            message: 'value of attribute "align" ' \
                                     'not allowed here'))
        .to eq(action: :allow,
               reason: 'allowed by config: value of attribute "align"')
    end

    it "an exclude pattern match yields :exclude" do
      expect(cfg.action_for(id: "STANDOC_7",
                            message: 'element "strike" not allowed here'))
        .to eq(action: :exclude,
               reason: "excluded by config: not allowed here$")
    end

    it "without a content match, the severity action applies" do
      expect(cfg.action_for(id: "STANDOC_7", message: "something else"))
        .to eq(action: :off,
               reason: "suppressed by validation rule (STANDOC_7)")
    end

    it "a severity-only rule ignores the message text" do
      plain = config_class.from_yaml_string(
        "rules:\n  STANDOC_7:\n    severity: off\n",
      )
      expect(plain.action_for(id: "STANDOC_7",
                              message: 'value of attribute "align"'))
        .to eq(action: :off,
               reason: "suppressed by validation rule (STANDOC_7)")
    end

    it "a rule with patterns and no severity is a content-only rule" do
      content = config_class.from_yaml_string(<<~'YAML')
        rules:
          STANDOC_7:
            allow:
              - 'a PDF\b'
      YAML
      expect(content.action_for(id: "STANDOC_7",
                                message: "a PDF is embedded"))
        .to eq(action: :allow, reason: "allowed by config: a PDF\\b")
      expect(content.action_for(id: "STANDOC_7", message: "a horizontal"))
        .to be_nil
    end

    it "rejects an invalid allow pattern, quoting it" do
      yaml = <<~'YAML'
        rules:
          X:
            allow:
              - '[unbalanced('
      YAML
      expect { config_class.from_yaml_string(yaml) }
        .to raise_error(ArgumentError, /invalid allow pattern/)
    end

    it "rejects a rule with no severity and no patterns" do
      expect do
        config_class.from_yaml_string("rules:\n  X: {}\n")
      end.to raise_error(ArgumentError,
                         /rule for code X carries no severity/)
    end

    it "merges allow lists by concatenation across layers" do
      flavor = config_class.from_yaml_string(<<~'YAML')
        rules:
          STANDOC_7:
            severity: warning
            allow:
              - 'align'
      YAML
      document = config_class.from_yaml_string(<<~'YAML')
        rules:
          STANDOC_7:
            severity: off
            allow:
              - 'strike'
      YAML
      merged = flavor.merge(document)
      expect(Array(merged.code_rule("STANDOC_7").allow)).to eq %w(align strike)
      expect(merged.code_rule("STANDOC_7").normalized_severity).to eq "off"
      expect(merged.action_for(id: "STANDOC_7", message: "has strike"))
        .to eq(action: :allow, reason: "allowed by config: strike")
      expect(merged.action_for(id: "STANDOC_7", message: "has align")[:action])
        .to eq :allow
      expect(merged.action_for(id: "STANDOC_7", message: "other")[:action])
        .to eq :off # document severity wins for non-matching text
    end
  end

  describe "#merge (resolution chain)" do
    it "the higher layer overrides per code, lower layers are kept" do
      flavor = config_class.from_yaml_string(<<~YAML)
        rules:
          ISO_53:
            severity: off
          STANDOC_48:
            severity: off
      YAML
      document = config_class.from_yaml_string(<<~YAML)
        rules:
          STANDOC_48:
            severity: info
      YAML
      merged = flavor.merge(document)
      expect(merged.code_rule("ISO_53").normalized_severity).to eq "off"
      expect(merged.code_rule("STANDOC_48").normalized_severity).to eq "info"
      expect(merged.action_for(id: "STANDOC_48")[:severity]).to eq 3
    end

    it "three layers resolve flavor < taste < document" do
      flavor = config_class.from_yaml_string(<<~YAML)
        rules:
          ISO_53:
            severity: off
      YAML
      taste = config_class.from_yaml_string(<<~YAML)
        rules:
          ISO_53:
            severity: info
          ISO_55:
            severity: warning
      YAML
      document = config_class.from_yaml_string(<<~YAML)
        rules:
          ISO_55:
            severity: off
      YAML
      merged = flavor.merge(taste).merge(document)
      expect(merged.code_rule("ISO_53").normalized_severity).to eq "info"
      expect(merged.code_rule("ISO_55").normalized_severity).to eq "off"
    end

    it "merges family rules per name" do
      flavor = config_class.from_yaml_string(<<~YAML)
        category_rules:
          category:
            Style:
              severity: off
            Relaton:
              severity: off
      YAML
      document = config_class.from_yaml_string(<<~YAML)
        category_rules:
          category:
            Style:
              severity: warning
      YAML
      merged = flavor.merge(document)
      expect(merged.action_for(id: "X", category: "Style")[:severity])
        .to eq 2
      expect(merged.action_for(id: "X", category: "Relaton")[:action])
        .to eq :off
    end
  end

  describe "#empty?" do
    it "is empty without rules" do
      expect(config_class.new).to be_empty
      expect(config_class.from_yaml_string("rules: {}")).to be_empty
    end

    it "is not empty with rules" do
      expect(
        config_class.from_yaml_string("rules:\n  X:\n    severity: off\n"),
      ).not_to be_empty
    end
  end
end

RSpec.describe "validation suppression wiring" do
  # header ending at the last attribute line, so per-test attributes
  # interpolate into the document header (a blank line would close it)
  SUPPR_HDR = <<~HDR.freeze
    = Document title
    Author
    :docfile: test.adoc
    :nodoc:
    :no-isobib:
  HDR

  let(:log) { Metanorma::Utils::Log.new }
  let(:options) { OPTIONS[0].merge(log: log) }

  def convert(input, opts = options)
    Asciidoctor.convert(input, opts)
  end

  # The Peter acceptance test (metanorma-standoc#1369): one attribute
  # silences a rule; the dropped entries are recorded with a reason.
  it ":validation-off: silences STANDOC_48 end to end" do
    input = <<~INPUT
      #{SUPPR_HDR}:validation-off: STANDOC_48

      image::spec/examples/rice_images/rice_image1.png[]
    INPUT
    convert(input)

    expect(log.messages.map { |e| e[:error_id] })
      .not_to include("STANDOC_48")
    expect(log.messages.map { |e| e[:error] })
      .not_to include(a_string_including("Figure should have title"))
    expect(log.suppressed?).to be true
    suppressed = log.suppressed_messages.select do |e|
      e[:error_id] == "STANDOC_48"
    end
    expect(suppressed).not_to be_empty
    expect(suppressed.first[:suppressed_by])
      .to eq "suppressed by validation rule (STANDOC_48)"
    expect(suppressed.first[:original_severity]).to eq 2
    expect(suppressed.first[:error]).to include("Figure should have title")
  end

  it ":validation-config: file rules silence the named codes" do
    Dir.mktmpdir do |dir|
      cfg = File.join(dir, "suppress.yml")
      File.write(cfg, "rules:\n  STANDOC_48:\n    severity: off\n")
      input = <<~INPUT
        #{SUPPR_HDR}:validation-config: #{cfg}

        image::spec/examples/rice_images/rice_image1.png[]
      INPUT
      convert(input)

      expect(log.messages.map { |e| e[:error_id] })
        .not_to include("STANDOC_48")
      expect(log.suppressed_messages.map { |e| e[:error_id] })
        .to include("STANDOC_48")
    end
  end

  # Peter acceptance test, content-matching variant: an a-or-an-style
  # waiver narrows to the matching message text, while genuine
  # violations under the same code still flag.
  it "allow patterns silence only matching entries; others still flag" do
    Dir.mktmpdir do |dir|
      cfg = File.join(dir, "suppress.yml")
      File.write(cfg, <<~'YAML')
        rules:
          STANDOC_7:
            allow:
              - 'value of attribute "align"'
      YAML
      input = <<~INPUT
        #{SUPPR_HDR}:validation-config: #{cfg}

        [[Clause1]]
        == Clause

        [align=mid-air]
        Aligned paragraph.

        [type=weird]
        Styled paragraph.
      INPUT
      convert(input)

      allowed = log.suppressed_messages.select do |e|
        e[:error_id] == "STANDOC_7"
      end
      expect(allowed).not_to be_empty
      expect(allowed.map { |e| e[:error] })
        .to all(include('value of attribute "align"'))
      expect(allowed.first[:suppressed_by])
        .to eq 'allowed by config: value of attribute "align"'

      flagged = log.messages.select { |e| e[:error_id] == "STANDOC_7" }
      expect(flagged).not_to be_empty
      expect(flagged.map { |e| e[:error] })
        .not_to include(a_string_including('attribute "align"'))
      expect(flagged.map { |e| e[:error] })
        .to include(a_string_including("not allowed here"))
    end
  end

  it "the effective-config dump counts allow patterns" do
    Dir.mktmpdir do |dir|
      cfg = File.join(dir, "suppress.yml")
      File.write(cfg, <<~'YAML')
        rules:
          STANDOC_7:
            severity: warning
            allow:
              - 'align'
              - 'strike'
      YAML
      input = <<~INPUT
        #{SUPPR_HDR}:validation-config: #{cfg}

        Paragraph.
      INPUT
      convert(input)

      dump = log.messages.find { |e| e[:error_id] == "STANDOC_68" }
      expect(dump).not_to be_nil
      expect(dump[:error])
        .to include("code rules: 1 (off: 0, reclassified: 1)")
      expect(dump[:error]).to include("allow patterns: 2")
      expect(dump[:error]).to include(cfg)
    end
  end

  it ":validation-warning: reclassifies the code in the active log" do
    input = <<~INPUT
      #{SUPPR_HDR}:validation-warning: STANDOC_38

      [[X]]
      == Clause 1

      See <<UNDEFINED_REF>>.
    INPUT
    convert(input)

    entry = log.messages.find { |e| e[:error_id] == "STANDOC_38" }
    expect(entry).not_to be_nil
    expect(entry[:severity]).to eq 2 # reclassified from serious to warning
    expect(log.suppressed_messages).to be_empty
  end

  it "a reclassified severity-0 code no longer aborts" do
    Dir.mktmpdir do |dir|
      cfg = File.join(dir, "suppress.yml")
      File.write(cfg, "rules:\n  STANDOC_47:\n    severity: warning\n")
      input = <<~INPUT
        #{SUPPR_HDR}:validation-config: #{cfg}

        [source,ruby]
        --
        puts "Hello, world." <1>
        %w{a b c}.each do |x|
          puts x
        end <2>
        --
        <1> This is one callout
      INPUT
      # Without the rule this document aborts on STANDOC_47; with the
      # reclassification it completes, carrying the warning severity.
      expect { convert(input) }.not_to raise_error
      entry = log.messages.find { |e| e[:error_id] == "STANDOC_47" }
      expect(entry[:severity]).to eq 2
      expect(log.abort_messages).to be_empty
    end
  end

  it "dumps the effective configuration as one Suppression entry" do
    input = <<~INPUT
      #{SUPPR_HDR}:validation-off: STANDOC_48, ISO_53
      :validation-warning: STANDOC_38

      Paragraph.
    INPUT
    convert(input)

    dumps = log.messages.select { |e| e[:error_id] == "STANDOC_68" }
    expect(dumps.size).to eq 1
    expect(dumps.first[:error])
      .to include("code rules: 3 (off: 2, reclassified: 1)")
    expect(dumps.first[:error])
      .to include(":validation-off:/:validation-warning:")
    # the dump entry itself is info severity and never aborts
    expect(dumps.first[:severity]).to eq 3
  end

  it "documents without suppression attributes get no suppression" do
    input = <<~INPUT
      #{SUPPR_HDR}

      image::spec/examples/rice_images/rice_image1.png[]
    INPUT
    FileUtils.rm_f("test.err.html")
    convert(input)

    expect(log.suppression).to be_nil
    expect(log.messages.map { |e| e[:error_id] }).to include("STANDOC_48")
    expect(log.suppressed_messages).to be_empty
    expect(log.messages.map { |e| e[:error_id] })
      .not_to include("STANDOC_68")
  end

  it "a malformed validation config raises naming the document layer" do
    Dir.mktmpdir do |dir|
      bad = File.join(dir, "bad.yml")
      File.write(bad, "schema: not-a-version/8\n")
      input = <<~INPUT
        #{SUPPR_HDR}:validation-config: #{bad}

        Paragraph.
      INPUT
      expect { convert(input) }
        .to raise_error(ArgumentError,
                        /invalid validation suppression config \(document layer\)/)
    end
  end

  it "the err.html omits validation-off'd entries" do
    FileUtils.rm_f("test.err.html")
    input = <<~INPUT
      #{SUPPR_HDR}:validation-off: STANDOC_48

      image::spec/examples/rice_images/rice_image1.png[]
    INPUT
    Asciidoctor.convert(input, OPTIONS[0])
    expect(File).to exist("test.err.html")
    expect(File.read("test.err.html"))
      .not_to include("Figure should have title")
  ensure
    FileUtils.rm_f("test.err.html")
  end

  it "legacy log-filter-* behavior is unchanged" do
    # The legacy attributes keep flowing through the untouched
    # suppress_log machinery (see validate_spec's log-filter specs for
    # the full behavioral matrix).
    input = <<~INPUT
      #{SUPPR_HDR}:log-filter-error-ids: STANDOC_48

      image::spec/examples/rice_images/rice_image1.png[]
    INPUT
    FileUtils.rm_f("test.err.html")
    Asciidoctor.convert(input, OPTIONS[0])
    expect(File).to exist("test.err.html")
    expect(File.read("test.err.html"))
      .not_to include("Figure should have title")
  ensure
    FileUtils.rm_f("test.err.html")
  end
end
