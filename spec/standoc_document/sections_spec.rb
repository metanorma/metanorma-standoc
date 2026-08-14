# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "StandardDocument section models" do
  describe Metanorma::Standoc::Document::Sections::ClauseSection do
    it "parses a clause with blocks" do
      xml = <<~XML
        <clause id="_c1" type="scope" obligation="normative">
          <title>Scope</title>
          <p id="_p1">This is the scope paragraph.</p>
          <table id="_t1"><thead><tr><th>Header</th></tr></thead><tbody><tr><td>Cell</td></tr></tbody></table>
          <figure id="_f1"><name>Figure 1</name></figure>
        </clause>
      XML

      clause = described_class.from_xml(xml)

      expect(clause.id).to eq("_c1")
      expect(clause.type).to eq("scope")
      expect(clause.obligation).to eq("normative")
      expect(clause.paragraphs.length).to eq(1)
      expect(clause.tables.length).to eq(1)
      expect(clause.figures.length).to eq(1)
    end

    it "parses nested clauses recursively" do
      xml = <<~XML
        <clause id="_c1">
          <title>Clause 1</title>
          <p>Top-level paragraph</p>
          <clause id="_c1_1">
            <title>Clause 1.1</title>
            <p>Nested paragraph</p>
          </clause>
        </clause>
      XML

      clause = described_class.from_xml(xml)

      expect(clause.id).to eq("_c1")
      expect(clause.clause.length).to eq(1)
      expect(clause.clause.first.id).to eq("_c1_1")
      expect(clause.clause.first.paragraphs.length).to eq(1)
    end

    it "parses terms and definitions inside a clause" do
      xml = <<~XML
        <clause id="_c1">
          <title>Terms</title>
          <terms id="_terms1">
            <title>Terms and definitions</title>
            <term id="_t1">
              <preferred><expression><name>term name</name></expression></preferred>
            </term>
          </terms>
          <definitions id="_defs1">
            <title>Symbols</title>
          </definitions>
        </clause>
      XML

      clause = described_class.from_xml(xml)

      expect(clause.terms.length).to eq(1)
      expect(clause.definitions.length).to eq(1)
    end
  end

  describe Metanorma::Standoc::Document::Sections::Sections do
    it "parses sections with mixed content types" do
      xml = <<~XML
        <sections>
          <clause id="_scope"><title>Scope</title><p>Scope text</p></clause>
          <terms id="_terms"><title>Terms</title><term id="_t1"><preferred><expression><name>term</name></expression></preferred></term></terms>
          <definitions id="_defs"><title>Symbols</title><dl><dt>A</dt><dd><p>Alpha</p></dd></dl></definitions>
          <floating-title depth="2">Note</floating-title>
          <references normative="true" id="_normrefs"><title>Normative References</title></references>
        </sections>
      XML

      sections = described_class.from_xml(xml)

      expect(sections.clause.length).to eq(1)
      expect(sections.terms.length).to eq(1)
      expect(sections.definitions.length).to eq(1)
      expect(sections.floating_title.length).to eq(1)
      expect(sections.references.length).to eq(1)
    end
  end

  describe Metanorma::Standoc::Document::Sections::Preface do
    it "parses a preface with abstract and foreword" do
      xml = <<~XML
        <preface>
          <abstract id="_abs"><title>Abstract</title><p>Abstract text</p></abstract>
          <foreword id="_fw"><title>Foreword</title><p>Foreword text</p></foreword>
          <introduction id="_intro"><title>Introduction</title><p>Intro text</p></introduction>
        </preface>
      XML

      preface = described_class.from_xml(xml)

      expect(preface.abstract).not_to be_nil
      expect(preface.foreword).not_to be_nil
      expect(preface.introduction).not_to be_nil
    end

    it "parses generic clause content in preface" do
      xml = <<~XML
        <preface>
          <abstract id="_abs"><title>Abstract</title><p>Text</p></abstract>
          <clause id="_misc"><title>Dedication</title><p>Dedication text</p></clause>
        </preface>
      XML

      preface = described_class.from_xml(xml)

      expect(preface.content.length).to eq(1)
    end
  end

  describe Metanorma::Standoc::Document::Sections::AnnexSection do
    it "parses an annex with blocks and sub-clauses" do
      xml = <<~XML
        <annex id="_a1" obligation="informative">
          <title>Annex A</title>
          <p>Annex content</p>
          <clause id="_a1_1">
            <title>A.1</title>
            <p>Subclause content</p>
          </clause>
        </annex>
      XML

      annex = described_class.from_xml(xml)

      expect(annex.id).to eq("_a1")
      expect(annex.obligation).to eq("informative")
      expect(annex.paragraphs.length).to eq(1)
      expect(annex.clause.length).to eq(1)
    end

    it "parses an annex with recursive sub-annexes" do
      xml = <<~XML
        <annex id="_a1" obligation="normative">
          <title>Annex B</title>
          <clause id="_b1">
            <title>B.1</title>
            <p>Content</p>
            <clause id="_b1_1"><title>B.1.1</title><p>Deep nested</p></clause>
          </clause>
        </annex>
      XML

      annex = described_class.from_xml(xml)

      expect(annex.clause.first.clause.length).to eq(1)
    end
  end

  describe Metanorma::Standoc::Document::Sections::ContentSection do
    it "parses a content section with blocks and subsections" do
      xml = <<~XML
        <clause id="_cs1">
          <title>Introduction</title>
          <p>Some text</p>
          <clause id="_cs1_1">
            <title>Background</title>
            <p>Background text</p>
          </clause>
        </clause>
      XML

      section = described_class.from_xml(xml)

      expect(section.paragraphs.length).to eq(1)
      expect(section.subsection.length).to eq(1)
    end
  end

  describe Metanorma::Standoc::Document::Sections::DefinitionSection do
    it "parses a definition section with definition lists" do
      xml = <<~XML
        <definitions id="_defs" type="symbols">
          <title>Symbols and abbreviated terms</title>
          <dl>
            <dt>A</dt>
            <dd><p>Alpha</p></dd>
            <dt>B</dt>
            <dd><p>Bravo</p></dd>
          </dl>
        </definitions>
      XML

      defs = described_class.from_xml(xml)

      expect(defs.id).to eq("_defs")
      expect(defs.type).to eq("symbols")
      expect(defs.definition_lists.length).to eq(1)
    end
  end

  describe Metanorma::Standoc::Document::Sections::TermsSection do
    it "parses a terms section with term entries" do
      xml = <<~XML
        <terms id="_terms">
          <title>Terms and definitions</title>
          <p>For the purposes of this document, the following terms apply.</p>
          <term id="_t1">
            <preferred><expression><name>example term</name></expression></preferred>
          </term>
        </terms>
      XML

      terms = described_class.from_xml(xml)

      expect(terms.id).to eq("_terms")
      expect(terms.paragraphs.length).to eq(1)
      expect(terms.terms.length).to eq(1)
    end
  end

  describe Metanorma::Standoc::Document::Sections::BibliographySection do
    it "references ClauseSection, not IsoClauseSection" do
      described_class.new
      expect(described_class.attributes.keys).to include(:references, :clause)
    end

    it "parses a bibliography with references" do
      xml = <<~XML
        <bibliography>
          <references normative="true"><title>Normative References</title></references>
          <references normative="false"><title>Bibliography</title></references>
        </bibliography>
      XML

      bib = described_class.from_xml(xml)

      expect(bib.references.length).to eq(2)
      expect(bib.references.first.normative).to be(true)
      expect(bib.references.last.normative).to be(false)
    end
  end
end

RSpec.describe "StandardDocument shared modules" do
  describe Metanorma::Standoc::Document::BlockAttributes do
    it "adds block collection attributes when included" do
      klass = Class.new(Lutaml::Model::Serializable) do
        include Metanorma::Standoc::Document::BlockAttributes
      end

      attrs = klass.attributes.keys
      expect(attrs).to include(:paragraphs, :tables, :figures, :formulas,
                               :examples, :notes, :admonitions,
                               :sourcecode_blocks, :quote_blocks, :definition_lists)
    end
  end

  describe Metanorma::Standoc::Document::RootAttributes do
    it "adds common root attributes when included" do
      klass = Class.new(Lutaml::Model::Serializable) do
        include Metanorma::Standoc::Document::RootAttributes
      end

      attrs = klass.attributes.keys
      expect(attrs).to include(:version, :type, :schema_version, :flavor,
                               :bibliography, :boilerplate, :metanorma_extension,
                               :autonum, :fmt_xref_label)
    end
  end

  describe Metanorma::Standoc::Document::BlockXmlMapping do
    it "adds block element mappings via ClauseSection parsing" do
      clause_xml = <<~XML
        <clause id="_test">
          <p>Paragraph</p>
          <table id="_t"><thead><tr><th>H</th></tr></thead><tbody><tr><td>D</td></tr></tbody></table>
          <figure id="_f"><name>Fig</name></figure>
          <formula id="_fm"><stem type="MathML"><math></math></stem></formula>
          <note id="_n"><p>Note text</p></note>
        </clause>
      XML

      clause = Metanorma::Standoc::Document::Sections::ClauseSection.from_xml(clause_xml)

      expect(clause.paragraphs.length).to eq(1)
      expect(clause.tables.length).to eq(1)
      expect(clause.figures.length).to eq(1)
      expect(clause.formulas.length).to eq(1)
      expect(clause.notes.length).to eq(1)
    end
  end
end
