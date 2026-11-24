# frozen_string_literal: true

require "spec_helper"

# text_pattern check (metanorma-standoc#1381): prose matching with stem
# exclusion and a language gate, and ISO style rules written against it.
RSpec.describe Metanorma::Standoc::Validate::Rules, "text_pattern" do
  let(:rules) { described_class }
  let(:fixture) do
    File.join(__dir__, "..", "fixtures", "iso_style_text_patterns.yaml")
  end
  let(:iso_set) { rules::RuleSet.load_file(fixture) }

  def doc(body, lang: nil)
    bib = lang ? "<bibdata><language>#{lang}</language></bibdata>" : ""
    Nokogiri::XML("<doc>#{bib}<sections>#{body}</sections></doc>")
  end

  def messages(set, xml, code = nil)
    rules::Engine.new(set).findings(xml)
      .select { |f| code.nil? || f.code == code }.map(&:params)
  end

  def one_rule(args, extra = {})
    rules::RuleSet.parse(<<~YAML)
      schema: metanorma-validation-rules/1
      rules:
        - {id: t.one, code: TST_1, context: //p, check: text_pattern, args: #{args.to_json}, params: [{value: message}]#{extra.to_json[1..-2].then { |s| s.empty? ? '' : ", #{s}" }}}
    YAML
  end

  describe "loading" do
    {
      "neither pattern nor words" => {},
      "both" => { "pattern" => "a", "words" => ["b"] },
      "bad regexp" => { "pattern" => "(" },
      "bad flags" => { "pattern" => "a", "flags" => "g" },
      "bad report" => { "pattern" => "a", "report" => "all" },
      "empty words" => { "words" => [] },
      "bad exclude" => { "pattern" => "a", "exclude" => ["a b"] },
      "bad language" => { "pattern" => "a", "language" => "en" },
      "unknown arg" => { "pattern" => "a", "colour" => "red" },
    }.each do |label, args|
      it "rejects #{label}" do
        expect { one_rule(args) }.to raise_error(rules::RuleError)
      end
    end

    it "has no Schematron mapping and is reported as code-backed" do
      set = one_rule("pattern" => "a")
      expect(rules::Schematron.export(set).code_backed).to eq ["t.one"]
    end
  end

  describe "matching" do
    it "reports each distinct match once, using capture groups" do
      set = one_rule("pattern" => "\\b(foo|bar)\\w*", "message" => "bad '%s'")
      xml = doc("<p>foo and barn and foo</p><p>fine</p>")
      expect(messages(set, xml)).to eq [["bad 'foo'"], ["bad 'bar'"]]
    end

    it "matches word lists on whole words, with flags" do
      set = one_rule("words" => ["don't", "it's"], "flags" => "i")
      xml = doc("<p>Don't do IT'S</p><p>it'sx</p>")
      expect(messages(set, xml)).to eq [["Don't"], ["IT'S"]]
    end

    it "reports once" do
      set = one_rule("pattern" => "x", "report" => "once", "message" => "has x")
      expect(messages(set, doc("<p>xx x</p>"))).to eq [["has x"]]
    end

    it "excludes stem content, and other named elements on request" do
      set = one_rule("pattern" => "MSSs")
      xml = doc("<p>formula <stem><asciimath>MSSs</asciimath></stem></p>")
      expect(messages(set, xml)).to be_empty
      xml = doc("<p>use <tt>MSSs</tt></p>")
      expect(messages(set, xml)).to eq [["MSSs"]]
      set = one_rule("pattern" => "MSSs", "exclude" => ["tt"])
      expect(messages(set, xml)).to be_empty
    end
  end

  describe "language gate" do
    let(:set) { one_rule("pattern" => "\\d,\\d", "language" => ["fr"]) }
    let(:body) { "<p>0,5 mm</p>" }

    it "runs for a listed language and its regional variants" do
      expect(messages(set, doc(body, lang: "fr"))).to eq [["0,5"]]
      expect(messages(set, doc(body, lang: "fr-FR"))).to eq [["0,5"]]
    end

    it "is silent for other languages and for a document with none (en)" do
      expect(messages(set, doc(body, lang: "en"))).to be_empty
      expect(messages(set, doc(body))).to be_empty
    end
  end

  describe "ISO style rules as declarative fixtures" do
    it "ISO_64 flags the doubled-s plural once, case-sensitively" do
      xml = doc("<p>The MSSs and MSSs.</p><p>the msss</p><p>MSS</p>")
      expect(messages(iso_set, xml, "ISO_64")).to eq(
        [["style: 'MSSs' (abbreviated terms are invariant — 'MSS' is not pluralized)"]],
      )
    end

    it "ISO_62 flags wrong articles in both directions, not in stem" do
      xml = doc("<p>A hour and an user, an hour, a user. " \
                "<stem><asciimath>a hour</asciimath></stem></p>")
      expect(messages(iso_set, xml, "ISO_62")).to eq(
        [["wrong article 'A hour' (use 'an' before a vowel sound)"],
         ["wrong article 'an user' (use 'a' before a consonant sound)"]],
      )
    end

    it "ISO_143 is gated on the document language" do
      xml = ->(lang) { doc("<p>0,01 mm</p>", lang: lang) }
      expect(messages(iso_set, xml.call("de"), "ISO_143"))
        .to eq [["decimal comma '0,01'"]]
      expect(messages(iso_set, xml.call("en"), "ISO_143")).to be_empty
    end
  end
end
