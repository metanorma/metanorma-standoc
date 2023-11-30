require "spec_helper"
require "relaton_iec"
require "fileutils"

RSpec.describe Metanorma::Standoc do
  it "applies smartquotes by default" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == "Quotation" A's

      '24:00:00'.

      _emphasis_ *strong* `monospace` "double quote" 'single quote'
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                    <sections>
        <clause id="_" inline-header="false" obligation="normative">
        <title>“Quotation” A’s</title>
        <p id='_'>‘24:00:00’.</p>
        <p id='_'>
       <em>emphasis</em>
       <strong>strong</strong>
       <tt>monospace</tt>
        “double quote” ‘single quote’
       </p>
      </clause>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "applies smartquotes when requested" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :smartquotes: true

      == "Quotation" A's
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
        <clause id="_" inline-header="false" obligation="normative">
        <title>“Quotation” A’s</title>
      </clause>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "does not apply smartquotes when requested not to" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :smartquotes: false

      == "Quotation" A's

      `"quote" A's`
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
        <clause id="_" inline-header="false" obligation="normative">
        <title>"Quotation" A's</title>
      <p id="_">
        <tt>"quote" A's</tt>
      </p>
      </clause>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "does not apply smartquotes to sourcecode, tt, pre, pseudocode" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :smartquotes: true

      == "Quotation" A's

      "Quotation" A's

      `"quote" A's`

      [source]
      ----
      "quote" A's
      ----

      [pseudocode]
      ====
      "quote" A's
      ====

    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
                      <clause id="_" inline-header="false" obligation="normative"><title>“Quotation” A’s</title><p id="_">“Quotation” A’s</p>
      <p id="_">
        <tt>"quote" A’s</tt>
      </p>
      <sourcecode id="_">"quote" A's</sourcecode>
      <figure id='_' class='pseudocode'>
        <p id='_'>"quote" A's</p>
      </figure>
      </clause>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "handles < > &amp; in Asciidoctor correctly" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == {blank}

      <&amp;>
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
               <clause id="_" inline-header="false" obligation="normative">
      <p id="_">&lt;&amp;&gt;</p>
             </clause>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "ignores tags when applying smartquotes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      "*word*",

      "link:http://example.com[]",

      "((ppt))",

      "((ppm))", "((ppt))"

      "((ppm))"&#xa0;

      "stem:[3]".
      footnote:[The mole]

      ....
      ((ppm))",
      ....
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                     <sections>
           <p id="_">“<strong>word</strong>”,</p>
           <p id="_">“<link target="http://example.com"/>”,</p>
           <p id="_">“ppt”,<index><primary>ppt</primary></index></p>
           <p id="_">“ppm”,<index><primary>ppm</primary></index> “ppt”<index><primary>ppt</primary></index></p>
           <p id="_">“ppm<index><primary>ppm</primary></index>” </p>
           <p id="_">“<stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><mn>3</mn></mstyle></math><asciimath>3</asciimath></stem>”.<fn reference="1"><p id="_">The mole</p></fn></p>
           <figure id="_">
             <pre id="_">((ppm))",</pre>
           </figure>
         </sections>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "removes empty text elements" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == {blank}
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections>
        <clause id="_" inline-header="false" obligation="normative">

      </clause>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "converts xrefs to references into erefs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      <<iso216>>
      <<iso216,droploc%capital%>>

      [bibliography]
      == Normative References
      * [[[iso216,ISO 216:2001]]], _Reference_
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <preface><foreword id="_" obligation="informative">
        <title>Foreword</title>
        <p id="_">
        <eref type="inline" bibitemid="iso216" citeas="ISO&#xa0;216:2001"/>
        <eref type='inline' case='capital' droploc='true' bibitemid='iso216' citeas='ISO&#xa0;216:2001'/>
      </p>
      </foreword></preface><sections>
      </sections>
      </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:bibliography")&.remove
    expect(xmlpp(strip_guid(xml.to_xml)))
      .to be_equivalent_to xmlpp(output)
  end

  it "extracts localities from erefs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      <<iso216,whole,clause=3,example=9-11,locality:prelude="33 a",locality:entirety:the reference,xyz>>
      <<iso216,whole,clause=3,example=9-11,locality:prelude=33,locality:entirety="the reference";whole,clause=3,example=9-11,locality:prelude=33,locality:URL:the reference,xyz>>
      <<iso216,_whole_>>
      <<iso216,a _whole_ flagon>>
      <<iso216,whole,clause=3,a _whole_ flagon>>
      <<iso216,droploc%capital%whole,clause=3,a _whole_ flagon>>

      [bibliography]
      == Normative References
      * [[[iso216,ISO 216]]], _Reference_
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
            <preface><foreword id="_" obligation="informative">
              <title>Foreword</title>
              <p id="_">
              <eref type="inline" bibitemid="iso216" citeas="ISO&#xa0;216">
              <localityStack>
              <locality type="whole"/><locality type="clause"><referenceFrom>3</referenceFrom></locality><locality type="example"><referenceFrom>9</referenceFrom><referenceTo>11</referenceTo></locality><locality type="locality:prelude"><referenceFrom>33 a</referenceFrom></locality><locality type="locality:entirety"/>
              </localityStack>
              the reference,xyz</eref>
       <eref type='inline' bibitemid='iso216' citeas='ISO&#xa0;216'>
         <localityStack connective="and">
           <locality type='whole'/>
           <locality type='clause'>
             <referenceFrom>3</referenceFrom>
           </locality>
           <locality type='example'>
             <referenceFrom>9</referenceFrom>
             <referenceTo>11</referenceTo>
           </locality>
           <locality type='locality:prelude'>
             <referenceFrom>33</referenceFrom>
           </locality>
           <locality type='locality:entirety'>
           <referenceFrom>the reference</referenceFrom>
           </locality>
         </localityStack>
         <localityStack connective="and">
           <locality type='whole'/>
           <locality type='clause'>
             <referenceFrom>3</referenceFrom>
           </locality>
           <locality type='example'>
             <referenceFrom>9</referenceFrom>
             <referenceTo>11</referenceTo>
           </locality>
           <locality type='locality:prelude'>
             <referenceFrom>33</referenceFrom>
           </locality>
           <locality type='locality:URL'/>
         </localityStack>
         the reference,xyz
       </eref>
      <eref type='inline' bibitemid='iso216' citeas='ISO&#xa0;216'>
        <em>whole</em>
      </eref>
      <eref type='inline' bibitemid='iso216' citeas='ISO&#xa0;216'>
        a
        <em>whole</em>
         flagon
      </eref>
      <eref type='inline' bibitemid='iso216' citeas='ISO&#xa0;216'>
        <localityStack>
          <locality type='whole'/>
          <locality type='clause'>
            <referenceFrom>3</referenceFrom>
          </locality>
        </localityStack>
        a
        <em>whole</em>
         flagon
      </eref>
      <eref type='inline' case='capital' droploc='true' bibitemid='iso216' citeas='ISO&#xa0;216'>
        <localityStack>
          <locality type='whole'/>
          <locality type='clause'>
            <referenceFrom>3</referenceFrom>
          </locality>
        </localityStack>
        a
        <em>whole</em>
         flagon
      </eref>
              </p>
            </foreword></preface><sections>
            </sections>
            </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:bibliography")&.remove
    expect(xmlpp(strip_guid(xml.to_xml)))
      .to be_equivalent_to xmlpp(output)
  end

  it "strips type from xrefs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      <<iso216>>

      [bibliography]
      == Clause
      * [[[iso216,ISO 216]]], _Reference_
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <preface>
      <foreword id="_" obligation="informative">
        <title>Foreword</title>
        <p id="_">
        <eref type="inline" bibitemid="iso216" citeas="ISO&#xa0;216"/>
      </p>
      </foreword></preface><sections>
      </sections>
      </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:bibliography")&.remove
    expect(xmlpp(strip_guid(xml.to_xml)))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes erefstack" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      <<from!iso216;to!iso216>>

      [bibliography]
      == Clause
      * [[[iso216,ISO 216]]], _Reference_
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <preface>
           <foreword id='_' obligation='informative'>
             <title>Foreword</title>
             <p id='_'>
               <erefstack>
                 <eref connective='from' bibitemid='iso216' citeas='ISO&#xa0;216' type='inline'/>
                 <eref connective='to' bibitemid='iso216' citeas='ISO&#xa0;216' type='inline'/>
               </erefstack>
             </p>
           </foreword>
         </preface>
         <sections> </sections>
       </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:bibliography")&.remove
    expect(xmlpp(strip_guid(xml.to_xml)))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes localities in term sources" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      Definition 0

      [.source]
      <<ISO2191,section=1>>
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
      <sections>
        <terms id="_" obligation="normative">
        <title>Terms and definitions</title>
        <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
        <term id="term-Term1">
        <preferred><expression><name>Term1</name></expression></preferred>
        <definition><verbal-definition><p id='_'>Definition 0</p></verbal-definition></definition>
        <termsource status="identical" type="authoritative">
        <origin bibitemid="ISO2191" type="inline" citeas="">
        <localityStack>
       <locality type="section"><referenceFrom>1</referenceFrom></locality>
       </localityStack>
       </origin>
      </termsource>
      </term>
      </terms>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "numbers bibliographic notes and footnotes sequentially" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      footnote:[Footnote]

      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:--]]] footnote:[The standard is in press] _Standard_

      == Clause
      footnote:[Footnote2]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <preface><foreword id="_" obligation="informative">
        <title>Foreword</title>
        <p id="_"><fn reference="1">
        <p id="_">Footnote</p>
      </fn>
      </p>
      </foreword></preface><sections>

      <clause id="_" inline-header="false" obligation="normative">
        <title>Clause</title>
        <p id="_"><fn reference="2">
        <p id="_">Footnote2</p>
      </fn>
      </p>
      </clause></sections><bibliography><references id="_" obligation="informative" normative="true">
        <title>Normative references</title>
        #{NORM_REF_BOILERPLATE}
        <bibitem id="iso123" type="standard">
         <title format="text/plain">Standard</title>
         <docidentifier>ISO 123:—</docidentifier>
         <docnumber>123</docnumber>
         <date type="published">
           <on>–</on>
         </date>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>ISO</name>
           </organization>
         </contributor>
         <note format="text/plain" type="Unpublished-Status">The standard is in press</note>
       </bibitem>
      </references>
      </bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "separates IEV citations by top-level clause" do
    FileUtils.rm_rf File.expand_path("~/.relaton-bib.pstore1")
    FileUtils.mv File.expand_path("~/.relaton/cache"),
                 File.expand_path("~/.relaton-bib.pstore1"), force: true
    FileUtils.rm_rf File.expand_path("~/.iev.pstore1")
    FileUtils.mv File.expand_path("~/.iev.pstore"),
                 File.expand_path("~/.iev.pstore1"), force: true
    FileUtils.rm_rf "relaton/cache"
    FileUtils.rm_rf "test.iev.pstore"
    # mock_iev
    VCR.use_cassette("separates_iev_citations_by_top_level_clause",
                     record: :new_episodes,
                     match_requests_on: %i[method uri body]) do
      input = <<~INPUT
        #{CACHED_ISOBIB_BLANK_HDR}

        [bibliography]
        == Normative References
        * [[[iev,IEV]]], _iev_

        == Terms and definitions
        === Automation1

        Definition 1

        [.source]
        <<iev,clause="103-01-02">>

        === Automation2

        Definition 2

        [.source]
        <<iev,clause="102-01-02">>

        === Automation3

        Definition 3

        [.source]
        <<iev,clause="103-01-02">>
      INPUT
      output = <<~OUTPUT
           #{BLANK_HDR}
           <sections>
         <terms id="_" obligation="normative"><title>Terms and definitions</title>
          <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
          <term id="term-Automation1">
           <preferred><expression><name>Automation1</name></expression></preferred>
           <definition><verbal-definition><p id='_'>Definition 1</p></verbal-definition></definition>
           <termsource status="identical" type="authoritative">
           <origin bibitemid="IEC60050-103" type="inline" citeas="IEC&#xa0;60050-103:2009">
           <localityStack>
         <locality type="clause"><referenceFrom>103-01-02</referenceFrom></locality>
           </localityStack>
         </origin>
         </termsource>
         </term>
         <term id="term-Automation2">
           <preferred><expression><name>Automation2</name></expression></preferred>
           <definition><verbal-definition><p id='_'>Definition 2</p></verbal-definition></definition>
           <termsource status="identical" type="authoritative">
           <origin bibitemid="IEC60050-102" type="inline" citeas="IEC&#xa0;60050-102:2007">
           <localityStack>
         <locality type="clause"><referenceFrom>102-01-02</referenceFrom></locality>
           </localityStack>
         </origin>
         </termsource>
         </term>
         <term id="term-Automation3">
           <preferred><expression><name>Automation3</name></expression></preferred>
           <definition><verbal-definition><p id='_'>Definition 3</p></verbal-definition></definition>
           <termsource status="identical" type="authoritative">
           <origin bibitemid="IEC60050-103" type="inline" citeas="IEC&#xa0;60050-103:2009">
           <localityStack>
         <locality type="clause"><referenceFrom>103-01-02</referenceFrom></locality>
           </localityStack>
         </origin>
         </termsource>
         </term></terms></sections><bibliography><references id="_" obligation="informative" normative="true">
           <title>Normative references</title>
         #{NORM_REF_BOILERPLATE}
                      <bibitem id="IEC60050-102" type="standard">
                <fetched/>
                <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) — Part 102: Mathematics — General concepts and linear algebra</title>
                <title type="main" format="text/plain" language="fr" script="Latn">Vocabulaire Electrotechnique International (IEV) — Partie 102: Mathématiques — Concepts généraux et algèbre linéaire</title>
                <uri type="src">https://webstore.iec.ch/publication/160</uri>
                <uri type="obp">https://webstore.iec.ch/preview/info_iec60050-102{ed1.0}b.pdf</uri>
                <docidentifier type="IEC" primary="true">IEC 60050-102:2007</docidentifier>
                <docidentifier type="URN">urn:iec:std:iec:60050-102:2007-08:::</docidentifier>
                <date type="published">
                  <on>2007-08-27</on>
                </date>
                <contributor>
                  <role type="publisher"/>
                  <organization>
                    <name>International Electrotechnical Commission</name>
                    <abbreviation>IEC</abbreviation>
                    <uri>www.iec.ch</uri>
                  </organization>
                </contributor>
                <edition>1</edition>
                <language>en</language>
                <language>fr</language>
                <script>Latn</script>
                <abstract format="text/html" language="en" script="Latn">This part of IEC 60050 gives the general mathematical terminology used in the fields of electricity, electronics and telecommunications, together with basic concepts in linear algebra. It maintains a clear distinction between mathematical concepts and physical concepts, even if some terms are used in both cases. Another part will deal with functions.<br/>It has the status of a horizontal standard in accordance with IEC Guide 108.</abstract>
                <abstract format="text/html" language="fr" script="Latn">Cette partie de la CEI 60050 donne la terminologie mathématique générale utilisée dans les domaines de l’électricité, de l’électronique et des télécommunications, ainsi que les concepts fondamentaux d’algèbre linéaire. Elle maintient une distinction nette entre les concepts mathématiques et les concepts physiques, même si certains termes sont employés dans les deux cas. Une autre partie traitera des fonctions.<br/>Elle a le statut de norme horizontale conformément au  Guide IEC 108.</abstract>
                <status>
                  <stage>PUBLISHED</stage>
                </status>
                <copyright>
                  <from>2007</from>
                  <owner>
                    <organization>
                      <name>International Electrotechnical Commission</name>
                      <abbreviation>IEC</abbreviation>
                      <uri>www.iec.ch</uri>
                    </organization>
                  </owner>
                </copyright>
                <place>Geneva</place>
              </bibitem>
              <bibitem id="IEC60050-103" type="standard">
                <fetched/>
                <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) — Part 103: Mathematics — Functions</title>
                <title type="main" format="text/plain" language="fr" script="Latn">Vocabulaire Electrotechnique International (IEV) — Partie 103: Mathématiques — Fonctions</title>
                <title type="main" format="text/plain" language="es" script="Latn">Versión Oficial En español — Vocabulario Electrotécnico Internacional. Parte 103: Matemáticas. Funciones.</title>
                <uri type="src">https://webstore.iec.ch/publication/161</uri>
                <uri type="obp">https://webstore.iec.ch/preview/info_iec60050-103{ed1.0}b.pdf</uri>
                <docidentifier type="IEC" primary="true">IEC 60050-103:2009</docidentifier>
                <docidentifier type="URN">urn:iec:std:iec:60050-103:2009-12:::</docidentifier>
                <date type="published">
                  <on>2009-12-14</on>
                </date>
                <contributor>
                  <role type="publisher"/>
                  <organization>
                    <name>International Electrotechnical Commission</name>
                    <abbreviation>IEC</abbreviation>
                    <uri>www.iec.ch</uri>
                  </organization>
                </contributor>
                <edition>1</edition>
                <language>en</language>
                <language>fr</language>
                <language>es</language>
                <script>Latn</script>
                <abstract format="text/html" language="en" script="Latn">IEC 60050-103:2009 gives the terminology relative to functions of one or more variables. Together with IEC 60050-102, it covers the mathematical terminology used in the fields of electricity, electronics and telecommunications. It maintains a clear distinction between mathematical concepts and physical concepts, even if some terms are used in both cases. Mathematical symbols are generally in accordance with IEC 60027-1 and ISO 80000-2. This standard cancels and replaces Sections 101-13, 101-14 and 101-15 of International Standard IEC 60050-101:1998.<br/>It has the status of a horizontal standard in accordance with  IEC Guide 108.</abstract>
                <abstract format="text/html" language="fr" script="Latn">La CEI 60050-103:2009 donne la terminologie relative aux fonctions d’une ou plusieurs variables. Conjointement avec la CEI 60050-102, elle couvre la terminologie mathématique utilisée dans les domaines de l’électricité, de l’électronique et des télécommunications. Elle maintient une distinction nette entre les concepts mathématiques et les concepts physiques, même si certains termes sont employés dans les deux cas. Les symboles mathématiques sont généralement conformes à la CEI 60027-1 et à l’ISO 80000-2. Cette norme annule et remplace les sections 101-13, 101-14 et 101-15 de la norme internationale CEI 60050-101:1998.<br/>Elle a le statut de norme horizontale conformément au  Guide IEC 108.</abstract>
                <status>
                  <stage>PUBLISHED</stage>
                </status>
                <copyright>
                  <from>2009</from>
                  <owner>
                    <organization>
                      <name>International Electrotechnical Commission</name>
                      <abbreviation>IEC</abbreviation>
                      <uri>www.iec.ch</uri>
                    </organization>
                  </owner>
                </copyright>
                <place>Geneva</place>
              </bibitem>
            </references>
          </bibliography>
        </standard-document>
      OUTPUT
      expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
        .to be_equivalent_to xmlpp(output)
    end
    FileUtils.rm_rf File.expand_path("~/.iev.pstore")
    FileUtils.mv File.expand_path("~/.iev.pstore1"),
                 File.expand_path("~/.iev.pstore"), force: true
    FileUtils.rm_rf File.expand_path("~/.relaton/cache")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"),
                 File.expand_path("~/.relaton/cache"), force: true
  end

  it "counts footnotes with link-only content as separate footnotes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      footnote:[http://www.example.com]

      footnote:[http://www.example.com]

      footnote:[http://www.example1.com]
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections><p id="_"><fn reference="1">
        <p id="_">
          <link target="http://www.example.com"/>
        </p>
      </fn>
      </p>
      <p id="_"><fn reference="1">
        <p id="_">
          <link target="http://www.example.com"/>
        </p>
      </fn>
      </p>
      <p id="_"><fn reference="2">
        <p id="_">
          <link target="http://www.example1.com"/>
        </p>
      </fn>
      </p></sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "retains AsciiMath on request" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :mn-keep-asciimath:

      stem:[1/r]
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections>
        <p id="_">
        <stem type="AsciiMath" block="false">1/r</stem>
      </p>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "converts AsciiMath to MathML by default" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:

      stem:[1/r]
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
                     <sections>
          <p id="_">
            <stem type="MathML" block="false">
              <math xmlns="http://www.w3.org/1998/Math/MathML">
                <mstyle displaystyle="false">
                  <mfrac>
                    <mn>1</mn>
                    <mi>r</mi>
                  </mfrac>
                </mstyle>
              </math>
              <asciimath>1/r</asciimath>
            </stem>
          </p>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "cleans up text MathML" do
    input = <<~INPUT
      #{BLANK_HDR.sub(/<standard-document [^>]+>/, '<standard-document>')}
      <sections>
      <stem type="MathML">&lt;math xmlns="http://www.w3.org/1998/Math/MathML"&gt;&lt;mfrac&gt;&lt;mn&gt;1&lt;/mn&gt;&lt;mi&gt;r&lt;/mi&gt;&lt;/mfrac&gt;&lt;/math&gt;</stem>
      </sections>
      </standard-document>
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR.sub(/<standard-document [^>]+>/, '<standard-document>')}
      <sections>
      <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mfrac><mn>1</mn><mi>r</mi></mfrac></math></stem>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(Metanorma::Standoc::Converter.new(nil, *OPTIONS)
      .cleanup(Nokogiri::XML(input)).to_xml))
      .to be_equivalent_to xmlpp(output)
  end

  it "cleans up nested mathvariant instances" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      stem:[sf "unitsml(cd)"]
    INPUT
    output = <<~OUTPUT
          <sections>
        <p id="_">
          <stem type="MathML" block="false">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
              <mstyle displaystyle="false">
                <mstyle mathvariant="sans-serif">
                  <mrow xref="U_NISTu7">
                    <mi mathvariant="sans-serif">cd</mi>
                  </mrow>
                </mstyle>
              </mstyle>
            </math>
            <asciimath>sf "unitsml(cd)"</asciimath>
          </stem>
        </p>
      </sections>
    OUTPUT
    expect(xmlpp(strip_guid(Nokogiri::XML(
      Asciidoctor.convert(input, *OPTIONS),
    ).at("//xmlns:sections").to_xml)))
      .to be_equivalent_to xmlpp(output)
  end

  it "removes nested bibitem IDs" do
    input = <<~INPUT
      #{BLANK_HDR}
      <bibliography>
        <references normative="true"><title>Normative</title>
        <bibitem id="A">
          <relation type="includes">
            <bibitem id="B"/>
          </relation>
        </bibitem>
      </bibliography>
      </standard-document>
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <bibliography>
        <references normative="true"><title>Normative</title>
        <bibitem id="A">
          <relation type="includes">
            <bibitem id="B"/>
          </relation>
        </bibitem>
      </references>
      </bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(Metanorma::Standoc::Converter.new(nil, *OPTIONS)
      .cleanup(Nokogiri::XML(input)).to_xml))
      .to be_equivalent_to xmlpp(output)
  end

  it "renumbers numeric references in Bibliography sequentially" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause
      <<iso123>>
      <<iso124>>

      [bibliography]
      == Bibliography

      * [[[iso124,ISO 124]]] _Standard 124_
      * [[[iso123,1]]] _Standard 123_
    INPUT
    output = <<~OUTPUT
          #{BLANK_HDR}
      <sections><clause id="_" inline-header="false" obligation="normative">
        <title>Clause</title>
        <p id="_"><eref type="inline" bibitemid="iso123" citeas="[2]"/>
      <eref type="inline" bibitemid="iso124" citeas="ISO&#xa0;124"/></p>
      </clause>
      </sections><bibliography><references id="_" obligation="informative" normative="false">
        <title>Bibliography</title>
        <bibitem id="iso124" type="standard">
        <title format="text/plain">Standard 124</title>
        <docidentifier>ISO 124</docidentifier>
        <docnumber>124</docnumber>
        <contributor>
          <role type="publisher"/>
          <organization>
            <name>ISO</name>
          </organization>
        </contributor>
      </bibitem>
        <bibitem id="iso123">
        <formattedref format="application/x-isodoc+xml">
          <em>Standard 123</em>
        </formattedref>
        <docidentifier type="metanorma">[2]</docidentifier>
      </bibitem>
      </references></bibliography>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "renumbers numeric references in Bibliography subclauses sequentially" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause
      <<iso123>>
      <<iso124>>
      <<iso125>>
      <<iso126>>

      [bibliography]
      == Bibliography

      [bibliography]
      === Clause 1
      * [[[iso124,ISO 124]]] _Standard 124_
      * [[[iso123,1]]] _Standard 123_

      [bibliography]
      === {blank}
      * [[[iso125,ISO 125]]] _Standard 124_
      * [[[iso126,1]]] _Standard 123_

      [bibliography]
      == Bibliography Redux

      [bibliography]
      === Clause 1
      * [[[iso127,ISO 124]]] _Standard 124_
      * [[[iso128,1]]] _Standard 123_

    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
        <sections><clause id="_" inline-header="false" obligation="normative">
             <title>Clause</title>
             <p id="_"><eref type="inline" bibitemid="iso123" citeas="[2]"/>
           <eref type="inline" bibitemid="iso124" citeas="ISO&#xa0;124"/>
           <eref type="inline" bibitemid="iso125" citeas="ISO&#xa0;125"/>
           <eref type="inline" bibitemid="iso126" citeas="[4]"/></p>
           </clause>
           </sections><bibliography><clause id="_" obligation="informative"><title>Bibliography</title><references id="_" obligation="informative" normative="false">
             <title>Clause 1</title>
             <bibitem id="iso124" type="standard">
             <title format="text/plain">Standard 124</title>
             <docidentifier>ISO 124</docidentifier>
             <docnumber>124</docnumber>
             <contributor>
               <role type="publisher"/>
               <organization>
                 <name>ISO</name>
               </organization>
             </contributor>
           </bibitem>
             <bibitem id="iso123">
             <formattedref format="application/x-isodoc+xml">
               <em>Standard 123</em>
             </formattedref>
             <docidentifier type="metanorma">[2]</docidentifier>
           </bibitem>
           </references>
           <references id="_" obligation="informative" normative="false">
             <bibitem id="iso125" type="standard">
             <title format="text/plain">Standard 124</title>
             <docidentifier>ISO 125</docidentifier>
             <docnumber>125</docnumber>
             <contributor>
               <role type="publisher"/>
               <organization>
                 <name>ISO</name>
               </organization>
             </contributor>
           </bibitem>
             <bibitem id="iso126">
             <formattedref format="application/x-isodoc+xml">
               <em>Standard 123</em>
             </formattedref>
             <docidentifier type="metanorma">[4]</docidentifier>
           </bibitem>
        </references>
      </clause>
      <clause id='_' obligation='informative'>
        <title>Bibliography Redux</title>
        <references id='_' normative='false' obligation='informative'>
          <title>Clause 1</title>
          <bibitem id='iso127' type='standard'>
            <title format='text/plain'>Standard 124</title>
            <docidentifier>ISO 124</docidentifier>
            <docnumber>124</docnumber>
            <contributor>
              <role type='publisher'/>
              <organization>
                <name>ISO</name>
              </organization>
            </contributor>
          </bibitem>
          <bibitem id='iso128'>
            <formattedref format='application/x-isodoc+xml'>
              <em>Standard 123</em>
            </formattedref>
            <docidentifier type='metanorma'>[6]</docidentifier>
          </bibitem>
           </references></clause></bibliography>
           </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "removes bibdata bibitem IDs" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :translated-from: IEC 60050-102

      [bibliography]
      == Normative References

    INPUT
    output = <<~OUTPUT
          <?xml version='1.0' encoding='UTF-8'?>
      <standard-document xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}">
        <bibdata type='standard'>
          <title language='en' format='text/plain'>Document title</title>
          <language>en</language>
          <script>Latn</script>
          <status>
            <stage>published</stage>
          </status>
          <copyright>
            <from>#{Date.today.year}</from>
          </copyright>
          <relation type='translatedFrom'>
            <bibitem>
              <title>--</title>
              <docidentifier>IEC 60050-102</docidentifier>
            </bibitem>
          </relation>
          <ext>
            <doctype>standard</doctype>
          </ext>
        </bibdata>
        <sections> </sections>
        <bibliography>
          <references id='_' obligation='informative' normative="true">
            <title>Normative references</title>
            <p id="_">There are no normative references in this document.</p>
          </references>
        </bibliography>
      </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(xmlpp(strip_guid(xml.to_xml)))
      .to be_equivalent_to xmlpp(output)
  end

  it "imports boilerplate file in XML" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :docstage: 10
      :boilerplate-authority: spec/assets/boilerplate.xml
      :publisher: Fred
      :pub-address: 10 Jack St + \\
      Antarctica

      == Clause 1

    INPUT
    output = <<~OUTPUT
          <standard-document xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}">
        <bibdata type='standard'>
          <title language='en' format='text/plain'>Document title</title>
                     <contributor>
             <role type="author"/>
             <organization>
               <name>Fred</name>
             </organization>
           </contributor>
           <contributor>
             <role type="publisher"/>
             <organization>
               <name>Fred</name>
               <address>
                 <formattedAddress>10 Jack St<br/>Antarctica</formattedAddress>
               </address>
             </organization>
           </contributor>
          <language>en</language>
          <script>Latn</script>
          <status>
            <stage>10</stage>
          </status>
          <copyright>
            <from>#{Date.today.year}</from>
                  <owner>
        <organization>
          <name>Fred</name>
          <address>
            <formattedAddress>10 Jack St<br/>Antarctica</formattedAddress>
          </address>
        </organization>
      </owner>
          </copyright>
          <ext>
            <doctype>standard</doctype>
          </ext>
        </bibdata>
        <boilerplate>
          <text>10</text>
          <text>10 Jack St<br/>Antarctica</text>
        </boilerplate>
        <sections>
          <clause id='_' inline-header='false' obligation='normative'>
            <title>Clause 1</title>
          </clause>
        </sections>
      </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(xmlpp(strip_guid(xml.to_xml)))
      .to be_equivalent_to xmlpp(output)
  end

  it "imports boilerplate file in ADOC" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :docstage: 10
      :boilerplate-authority: spec/assets/boilerplate.adoc
      :publisher: Fred
      :pub-address: 10 Jack St + \\
      Antarctica

      == Clause 1

    INPUT
    output = <<~OUTPUT
      <standard-document xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}">
                   <boilerplate>
           <copyright-statement>
             <clause id="B" inline-header="false" obligation="normative">
               <p id="_">A</p>
             </clause>
           </copyright-statement>
           <license-statement>
             <clause id="_" inline-header="false" obligation="normative">
               <title>clause 1</title>
             </clause>
             <clause id="_" inline-header="false" obligation="normative">
               <title>clause 2</title>
             </clause>
           </license-statement>
           <feedback-statement>
             <p id="_">10 Jack St<br/>Antarctica</p>
           </feedback-statement>
           <clause id="_" inline-header="false" obligation="normative">
             <title>Random Title</title>
             <clause id="_" inline-header="false" obligation="normative">
               <title>feedback-statement</title>
             </clause>
           </clause>
         </boilerplate>
         <sections>
           <clause id="_" inline-header="false" obligation="normative">
             <title>Clause 1</title>
           </clause>
         </sections>
       </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    xml.at("//xmlns:bibdata")&.remove
    expect(xmlpp(strip_guid(xml.to_xml)))
      .to be_equivalent_to xmlpp(output)
  end

  it "sorts symbols lists #1" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[L]]
      == Symbols and abbreviated terms

      α:: Definition 1
      Xa:: Definition 2
      x_1_:: Definition 3
      x_m_:: Definition 4
      x:: Definition 5
      stem:[n]:: Definition 6
      m:: Definition 7
      2d:: Definition 8
    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
        <sections>
          <definitions id='L' obligation="normative">
            <title>Symbols and abbreviated terms</title>
            <dl id='_'>
            <dt id="symbol-m">m</dt>
      <dd>
        <p id='_'>Definition 7</p>
      </dd>
      <dt id="symbol-n">
        <stem type='MathML' block="false">
          <math xmlns='http://www.w3.org/1998/Math/MathML'>
          <mstyle displaystyle="false">
            <mi>n</mi>
            </mstyle>
          </math>
           <asciimath>n</asciimath>
        </stem>
      </dt>
      <dd>
        <p id='_'>Definition 6</p>
      </dd>
                   <dt id='symbol-Xa'>Xa</dt>
              <dd>
                <p id='_'>Definition 2</p>
              </dd>
              <dt id="symbol-x">x</dt>
              <dd>
                <p id='_'>Definition 5</p>
              </dd>
              <dt  id='symbol-x_m_'>x_m_</dt>
              <dd>
                <p id='_'>Definition 4</p>
              </dd>
              <dt id='symbol-x_1_'>x_1_</dt>
              <dd>
                <p id='_'>Definition 3</p>
              </dd>
              <dt id="symbol-_2d">2d</dt>
            <dd>
              <p id="_">Definition 8</p>
            </dd>
              <dt  id='symbol-__x3b1_'>α</dt>
              <dd>
                <p id='_'>Definition 1</p>
              </dd>
            </dl>
          </definitions>
        </sections>
      </standard-document>
    OUTPUT
    doc = Asciidoctor.convert(input, *OPTIONS)
    expect(xmlpp(strip_guid(doc)))
      .to be_equivalent_to xmlpp(output)
    sym = Nokogiri::XML(doc).xpath("//xmlns:dt").to_xml
    expect(sym).to be_equivalent_to <<~OUTPUT
          <dt id="symbol-m">m</dt><dt id="symbol-n">
        <stem type="MathML" block="false">
          <math xmlns="http://www.w3.org/1998/Math/MathML">
        <mstyle displaystyle="false">
          <mi>n</mi>
        </mstyle>
      </math>
          <asciimath>n</asciimath>
        </stem>
      </dt><dt id="symbol-Xa">Xa</dt><dt id="symbol-x">x</dt><dt id="symbol-x_m_">x_m_</dt><dt id="symbol-x_1_">x_1_</dt><dt id="symbol-_2d">2d</dt><dt id="symbol-__x3b1_">α</dt>
    OUTPUT
  end

  it "sorts symbols lists #2" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[L]]
      == Symbols and abbreviated terms

      stem:[alpha]:: Definition 1
      xa:: Definition 2
      stem:[x_1]:: Definition 3
      stem:[x_m]:: Definition 4
      x:: Definition 5
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                <sections>
            <definitions id="L" obligation="normative">
              <title>Symbols and abbreviated terms</title>
              <dl id="_">
                <dt id="symbol-x">x</dt>
                <dd>
                  <p id="_">Definition 5</p>
                </dd>
                <dt id="symbol-x_m">
                  <stem type="MathML" block="false">
                    <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="false">
                        <msub>
                          <mi>x</mi>
                          <mi>m</mi>
                        </msub>
                      </mstyle>
                    </math>
                    <asciimath>x_m</asciimath>
                  </stem>
                </dt>
                <dd>
                  <p id="_">Definition 4</p>
                </dd>
                <dt id="symbol-x_1">
                  <stem type="MathML" block="false">
                    <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="false">
                        <msub>
                          <mi>x</mi>
                          <mn>1</mn>
                        </msub>
                      </mstyle>
                    </math>
                    <asciimath>x_1</asciimath>
                  </stem>
                </dt>
                <dd>
                  <p id="_">Definition 3</p>
                </dd>
                <dt id="symbol-xa">xa</dt>
                <dd>
                  <p id="_">Definition 2</p>
                </dd>
                <dt id="symbol-__x3b1_">
                  <stem type="MathML" block="false">
                    <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="false">
                        <mi>α</mi>
                      </mstyle>
                    </math>
                    <asciimath>alpha</asciimath>
                  </stem>
                </dt>
                <dd>
                  <p id="_">Definition 1</p>
                </dd>
              </dl>
            </definitions>
          </sections>
        </standard-document>
    OUTPUT
    doc = Asciidoctor.convert(input, *OPTIONS)
    expect(xmlpp(strip_guid(doc)))
      .to be_equivalent_to xmlpp(output)
    sym = Nokogiri::XML(doc).xpath("//xmlns:dt").to_xml
    expect(sym).to be_equivalent_to <<~OUTPUT
          <dt id="symbol-x">x</dt><dt id="symbol-x_m">
        <stem type="MathML" block="false">
          <math xmlns="http://www.w3.org/1998/Math/MathML">
        <mstyle displaystyle="false">
          <msub>
            <mi>x</mi>
            <mi>m</mi>
          </msub>
        </mstyle>
      </math>
          <asciimath>x_m</asciimath>
        </stem>
      </dt><dt id="symbol-x_1">
        <stem type="MathML" block="false">
          <math xmlns="http://www.w3.org/1998/Math/MathML">
        <mstyle displaystyle="false">
          <msub>
            <mi>x</mi>
            <mn>1</mn>
          </msub>
        </mstyle>
      </math>
          <asciimath>x_1</asciimath>
        </stem>
      </dt><dt id="symbol-xa">xa</dt><dt id="symbol-__x3b1_">
        <stem type="MathML" block="false">
          <math xmlns="http://www.w3.org/1998/Math/MathML">
        <mstyle displaystyle="false">
          <mi>α</mi>
        </mstyle>
      </math>
          <asciimath>alpha</asciimath>
        </stem>
      </dt>
    OUTPUT
  end

  it "fixes illegal anchors" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [[a:b]]
      == A
      <</:ab>>
      <<:>>
      <<1>>
      <<1:>>
      <<1#b>>
      <<:a#b:>>
      <</%ab>>
      <<1!>>
      <<Löwe>>

      [[Löwe]]
      .See <<Löwner2016>>
      ----
      ABC
      ----

      [bibliography]
      == Bibliography
      * [[[Löwner2016,Löwner et al. 2016]]], Löwner, M.-O., Gröger, G., Benner, J., Biljecki, F., Nagel, C., 2016: *Proposal for a new LOD and multi-representation concept for CityGML*. In: Proceedings of the 11th 3D Geoinfo Conference 2016, ISPRS Annals of the Photogrammetry, Remote Sensing and Spatial Information Sciences, Vol. IV-2/W1, 3–12. https://doi.org/10.5194/isprs-annals-IV-2-W1-3-2016
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                 <sections>
           <clause id='a_b' inline-header='false' obligation='normative'>
             <title>A</title>
             <eref bibitemid='__ab' citeas=''/>
             <xref target='_'/>
             <xref target='_1'/>
             <xref target='_1_'/>
             <xref target='1#b'/>
             <xref target='_a#b_'/>
             <xref target='__ab'/>
             <xref target='_1_'/>
             <xref target='L__xf6_we'/>
             <sourcecode id='L__xf6_we'>
               <name>
                 See
                 <eref type='inline' bibitemid='L__xf6_wner2016' citeas='Löwner&#xa0;et&#xa0;al.&#xa0;2016'/>
               </name>
               ABC
             </sourcecode>
           </clause>
         </sections>
         <bibliography>
           <references id='_bibliography' normative='false' obligation='informative'>
             <title>Bibliography</title>
             <bibitem id='L__xf6_wner2016'>
               <formattedref format='application/x-isodoc+xml'>
                 L&#246;wner, M.-O., Gr&#246;ger, G., Benner, J., Biljecki, F., Nagel,
                 C., 2016:
                 <strong>Proposal for a new LOD and multi-representation concept for CityGML</strong>
                 . In: Proceedings of the 11th 3D Geoinfo Conference 2016, ISPRS Annals
                 of the Photogrammetry, Remote Sensing and Spatial Information
                 Sciences, Vol. IV-2/W1, 3&#8211;12.
                 <link target='https://doi.org/10.5194/isprs-annals-IV-2-W1-3-2016'/>
               </formattedref>
               <docidentifier>L&#246;wner et al. 2016</docidentifier>
               <docnumber>2016</docnumber>
             </bibitem>
           </references>
           <references hidden='true' normative='false'>
             <bibitem id='__ab' type='internal'>
               <docidentifier type='repository'>//ab</docidentifier>
             </bibitem>
           </references>
         </bibliography>
       </standard-document>
    OUTPUT
    expect(xmlpp(Asciidoctor.convert(input, *OPTIONS)
      .gsub(/<p id="_[^"]+">/, "").gsub("</p>", "")))
      .to be_equivalent_to(xmlpp(output))
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{normalised identifier in <clause id="a_b" inline-header="false" obligation="normative"/> from a:b})
      .to_stderr
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{normalised identifier in <eref bibitemid="__ab" citeas=""/> from /_ab})
      .to_stderr
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{normalised identifier in <xref target="_"/> from :})
      .to_stderr
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{normalised identifier in <xref target="_1"/> from 1})
      .to_stderr
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{normalised identifier in <xref target="_1_"/> from 1:})
      .to_stderr
    expect { Asciidoctor.convert(input, *OPTIONS) }
      .to output(%r{normalised identifier in <xref target="_a#b_"/> from :a#b:})
      .to_stderr
  end

  it "moves title footnotes to bibdata" do
    input = <<~INPUT
      = Document title footnote:[ABC] footnote:[DEF]
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:

    INPUT
    output = <<~OUTPUT
      <standard-document xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}">
               <bibdata type='standard'>
                 <title language='en' format='text/plain'>Document title</title>
                 <note type='title-footnote'>
                   <p>ABC</p>
                 </note>
                 <note type='title-footnote'>
                   <p>DEF</p>
                 </note>
                 <language>en</language>
                 <script>Latn</script>
                 <status>
                   <stage>published</stage>
                 </status>
                 <copyright>
                   <from>#{Time.now.year}</from>
                 </copyright>
                 <ext>
                   <doctype>standard</doctype>
                 </ext>
               </bibdata>
               <sections> </sections>
               </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(xmlpp(strip_guid(xml.to_xml)))
      .to be_equivalent_to xmlpp(output)
  end

  it "converts UnitsML to MathML" do
    input = <<~INPUT
      = Document title
      Author
      :stem:

      [stem]
      ++++
      <math xmlns='http://www.w3.org/1998/Math/MathML'>
        <mrow>
        <mn>7</mn>
        <mtext>unitsml(m*kg^-2)</mtext>
        <mo>+</mo>
        <mn>8</mn>
        <mtext>unitsml(m*kg^-3)</mtext>
        </mrow>
      </math>
      ++++
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR.sub('<metanorma-extension>', <<~EXT
        <metanorma-extension>
             <UnitsML xmlns='https://schema.unitsml.org/unitsml/1.0'>
               <UnitSet>
                 <Unit xml:id='U_m.kg-2' dimensionURL='#D_LM-2'>
                   <UnitSystem name='SI' type='SI_derived' xml:lang='en-US'/>
                   <UnitName xml:lang='en'>m*kg^-2</UnitName>
                   <UnitSymbol type='HTML'>
                     m&#160;kg
                     <sup>&#8722;2</sup>
                   </UnitSymbol>
                   <UnitSymbol type='MathML'>
                     <math xmlns='http://www.w3.org/1998/Math/MathML'>
                       <mrow>
                         <mi mathvariant='normal'>m</mi>
                         <mo rspace='thickmathspace'>&#8290;</mo>
                         <msup>
                           <mrow>
                             <mi mathvariant='normal'>kg</mi>
                           </mrow>
                           <mrow>
                             <mo>&#8722;</mo>
                             <mn>2</mn>
                           </mrow>
                         </msup>
                       </mrow>
                     </math>
                   </UnitSymbol>
                   <RootUnits>
                     <EnumeratedRootUnit unit='meter'/>
                     <EnumeratedRootUnit unit='gram' prefix='k' powerNumerator='-2'/>
                   </RootUnits>
                 </Unit>
                 <Unit xml:id="U_m.kg-3" dimensionURL="#D_LM-3">
                 <UnitSystem name="SI" type="SI_derived" xml:lang="en-US"/>
                 <UnitName xml:lang="en">m*kg^-3</UnitName>
                 <UnitSymbol type="HTML">m kg<sup>−3</sup></UnitSymbol>
                 <UnitSymbol type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                     <mrow>
                       <mi mathvariant="normal">m</mi>
                       <mo rspace="thickmathspace">⁢</mo>
                       <msup>
                         <mrow>
                           <mi mathvariant="normal">kg</mi>
                         </mrow>
                         <mrow>
                           <mo>−</mo>
                           <mn>3</mn>
                         </mrow>
                       </msup>
                     </mrow>
                   </math>
                 </UnitSymbol>
                 <RootUnits>
                   <EnumeratedRootUnit unit="meter"/>
                   <EnumeratedRootUnit unit="gram" prefix="k" powerNumerator="-3"/>
                 </RootUnits>
               </Unit>
             </UnitSet>
               <DimensionSet>
                 <Dimension xml:id='D_LM-2'>
                   <Length symbol='L' powerNumerator='1'/>
                   <Mass symbol='M' powerNumerator='-2'/>
                 </Dimension>
                 <Dimension xml:id="D_LM-3">
                 <Length symbol="L" powerNumerator="1"/>
                 <Mass symbol="M" powerNumerator="-3"/>
               </Dimension>
               </DimensionSet>
               <PrefixSet>
                 <Prefix prefixBase='10' prefixPower='3' xml:id='NISTp10_3'>
                   <PrefixName xml:lang='en'>kilo</PrefixName>
                   <PrefixSymbol type='ASCII'>k</PrefixSymbol>
                   <PrefixSymbol type='unicode'>k</PrefixSymbol>
                   <PrefixSymbol type='LaTeX'>k</PrefixSymbol>
                   <PrefixSymbol type='HTML'>k</PrefixSymbol>
                 </Prefix>
               </PrefixSet>
             </UnitsML>
      EXT
      )}
         <sections>
           <formula id='_'>
             <stem type='MathML' block="true">
               <math xmlns='http://www.w3.org/1998/Math/MathML'>
                 <mrow>
                   <mn>7</mn>
                   <mo rspace='thickmathspace'>&#8290;</mo>
                   <mrow xref='U_m.kg-2'>
                     <mi mathvariant='normal'>m</mi>
                     <mo rspace='thickmathspace'>&#8290;</mo>
                     <msup>
                       <mrow>
                         <mi mathvariant='normal'>kg</mi>
                       </mrow>
                       <mrow>
                         <mo>&#8722;</mo>
                         <mn>2</mn>
                       </mrow>
                     </msup>
                   </mrow>
                   <mo>+</mo>
                   <mn>8</mn>
                   <mo rspace='thickmathspace'>&#8290;</mo>
                   <mrow xref='U_m.kg-3'>
                     <mi mathvariant='normal'>m</mi>
                     <mo rspace='thickmathspace'>&#8290;</mo>
                     <msup>
                       <mrow>
                         <mi mathvariant='normal'>kg</mi>
                       </mrow>
                       <mrow>
                         <mo>&#8722;</mo>
                         <mn>3</mn>
                       </mrow>
                     </msup>
                   </mrow>
                 </mrow>
               </math>
             </stem>
           </formula>
         </sections>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "customises italicisation of MathML" do
    input = <<~INPUT
      = Document title
      Author
      :stem:

      [stem]
      ++++
      <math xmlns='http://www.w3.org/1998/Math/MathML'>
        <mi>A</mi>
        <mo>+</mo>
        <mi>a</mi>
        <mo>+</mo>
        <mi>Α</mi>
        <mo>+</mo>
        <mi>α</mi>
        <mo>+</mo>
        <mi>AB</mi>
        <mstyle mathvariant="italic">
        <mrow>
        <mi>Α</mi>
        </mrow>
        </mstyle>
      </math>
      ++++
    INPUT

    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(<<~"OUTPUT")
        #{BLANK_HDR}
                 <sections>
            <formula id="_">
              <stem type="MathML" block="true"><math xmlns="http://www.w3.org/1998/Math/MathML">
          <mi>A</mi><mo>+</mo><mi>a</mi><mo>+</mo><mi>Α</mi><mo>+</mo><mi>α</mi><mo>+</mo><mi>AB</mi><mstyle mathvariant="italic"><mrow><mi>Α</mi></mrow></mstyle></stem>
            </formula>
          </sections>
        </standard-document>
      OUTPUT
    mock_mathml_italicise({ uppergreek: false, upperroman: true,
                            lowergreek: true, lowerroman: true })
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(<<~"OUTPUT")
        #{BLANK_HDR}
          <sections>
            <formula id='_'>
              <stem type='MathML' block="true">
                <math xmlns='http://www.w3.org/1998/Math/MathML'>
                  <mi>A</mi>
                  <mo>+</mo>
                  <mi>a</mi>
                  <mo>+</mo>
                  <mi mathvariant="normal">Α</mi>
                  <mo>+</mo>
                  <mi>α</mi>
                  <mo>+</mo>
                  <mi>AB</mi>
                  <mstyle mathvariant='italic'>
          <mrow>
            <mi>Α</mi>
          </mrow>
        </mstyle>
                </math>
              </stem>
            </formula>
          </sections>
        </standard-document>
      OUTPUT
    mock_mathml_italicise({ uppergreek: true, upperroman: false,
                            lowergreek: true, lowerroman: true })
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(<<~"OUTPUT")
        #{BLANK_HDR}
          <sections>
            <formula id='_'>
              <stem type='MathML' block="true">
                <math xmlns='http://www.w3.org/1998/Math/MathML'>
                  <mi mathvariant="normal">A</mi>
                  <mo>+</mo>
                  <mi>a</mi>
                  <mo>+</mo>
                  <mi>Α</mi>
                  <mo>+</mo>
                  <mi>α</mi>
                  <mo>+</mo>
                  <mi>AB</mi>
                  <mstyle mathvariant='italic'>
          <mrow>
            <mi>Α</mi>
          </mrow>
        </mstyle>
                </math>
              </stem>
            </formula>
          </sections>
        </standard-document>
      OUTPUT
    mock_mathml_italicise({ uppergreek: true, upperroman: true,
                            lowergreek: false, lowerroman: true })
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(<<~"OUTPUT")
        #{BLANK_HDR}
          <sections>
            <formula id='_'>
              <stem type='MathML' block="true">
                <math xmlns='http://www.w3.org/1998/Math/MathML'>
                  <mi>A</mi>
                  <mo>+</mo>
                  <mi>a</mi>
                  <mo>+</mo>
                  <mi>Α</mi>
                  <mo>+</mo>
                  <mi mathvariant="normal">α</mi>
                  <mo>+</mo>
                  <mi>AB</mi>
                  <mstyle mathvariant='italic'>
          <mrow>
            <mi>Α</mi>
          </mrow>
        </mstyle>
                </math>
              </stem>
            </formula>
          </sections>
        </standard-document>
      OUTPUT
    mock_mathml_italicise({ uppergreek: true, upperroman: true,
                            lowergreek: true, lowerroman: false })
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(<<~"OUTPUT")
        #{BLANK_HDR}
          <sections>
            <formula id='_'>
              <stem type='MathML' block="true">
                <math xmlns='http://www.w3.org/1998/Math/MathML'>
                  <mi>A</mi>
                  <mo>+</mo>
                  <mi mathvariant="normal">a</mi>
                  <mo>+</mo>
                  <mi>Α</mi>
                  <mo>+</mo>
                  <mi>α</mi>
                  <mo>+</mo>
                  <mi>AB</mi>
                  <mstyle mathvariant='italic'>
          <mrow>
            <mi>Α</mi>
          </mrow>
        </mstyle>
                </math>
              </stem>
            </formula>
          </sections>
        </standard-document>
      OUTPUT
    mock_mathml_italicise({ uppergreek: true, upperroman: true,
                            lowergreek: true, lowerroman: true })
  end

  it "process express_ref macro with existing bibliography" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Clause

      <<uml:A:A.B.C,C>>
      <<uml:A>>
      <<express-schema:action:action.AA,AA>>
      <<express-schema:action:action.AB>>

      [[action]]
      [type="express-schema"]
      == Action

      [[action.AA]]
      === AA

      [bibliography]
      == Bibliography
      * [[[D,E]]] F
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
       <sections>
           <clause id='_' inline-header='false' obligation='normative'>
             <title>Clause</title>
             <p id='_'>
               <eref bibitemid='uml_A' citeas="">
               <localityStack>
                 <locality type='anchor'><referenceFrom>A.B.C</referenceFrom></locality>
               </localityStack>
                 C
               </eref>
               <eref bibitemid='uml_A' citeas=""/>
               <xref target='action.AA'>AA</xref>
               <xref target='action'>** Missing target action.AB</xref>
             </p>
           </clause>
           <clause id='action' type='express-schema' inline-header='false' obligation='normative'>
             <title>Action</title>
             <clause id='action.AA' inline-header='false' obligation='normative'>
             <title>AA</title>
              </clause>
           </clause>
         </sections>
         <bibliography>
           <references id='_' normative='false' obligation='informative'>
             <title>Bibliography</title>
             <bibitem id='D'>
               <formattedref format='application/x-isodoc+xml'>F</formattedref>
               <docidentifier>E</docidentifier>
             </bibitem>
           </references>
           <references hidden='true' normative='false'>
             <bibitem id='uml_A' type='internal'>
               <docidentifier type='repository'>uml/A</docidentifier>
             </bibitem>
           </references>
         </bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "process express_ref macro with no existing bibliography" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [[B]]
      [type="express-schema"]
      == Clause

      [[B1]]
      NOTE: X

      <<express-schema:A:A.B.C,C>>
      <<express-schema:A>>
      <<express-schema:B>>
      <<express-schema:B1>>
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections>
             <clause id='B' type='express-schema' inline-header='false' obligation='normative'>
                   <title>Clause</title>
                   <note id='B1'>
                     <p id='_'>X</p>
                   </note>
                   <p id='_'>
                     <eref bibitemid='express-schema_A' citeas=''>
                       <localityStack>
                         <locality type='anchor'>
                           <referenceFrom>A.B.C</referenceFrom>
                         </locality>
                       </localityStack>
                       C
                     </eref>
                     <eref bibitemid='express-schema_A' citeas=''/>
                     <xref target='B'/>
                     <xref target='B1'/>
                   </p>
                 </clause>
               </sections>
               <bibliography>
                 <references hidden='true' normative='false'>
                   <bibitem id='express-schema_A' type='internal'>
                     <docidentifier type='repository'>express-schema/A</docidentifier>
                   </bibitem>
                 </references>
               </bibliography>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "creates content-based GUIDs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      .Foreword
      Foreword

      [NOTE,beforeclauses=true]
      ====
      Note which is very important <<a>>
      ====

      == Introduction
      Introduction

      == Scope
      Scope statement

      [IMPORTANT,beforeclauses=true]
      ====
      Notice which is very important
      ====
    INPUT
    output = <<~OUTPUT
        #{BLANK_HDR}
        <preface>
          <note id='_2cfe95f6-7ad6-aa57-8207-6f7d7928aa8e'>
            <p id='_76d95913-a379-c60f-5144-1f09655cafa6'>
              Note which is very important
              <xref target='a'/>
            </p>
          </note>
          <foreword id='_96b556cb-657c-985b-351b-ed70d8bd6fdd' obligation='informative'>
            <title>Foreword</title>
            <p id='_d2f825bf-3e18-6143-8777-34e59928d48c'>Foreword</p>
          </foreword>
          <introduction id='_introduction' obligation='informative'>
            <title>Introduction</title>
            <p id='_272021ab-1bfa-78ae-e860-ed770e36f3d2'>Introduction</p>
          </introduction>
        </preface>
        <sections>
          <admonition id='_6abb9105-854c-e79c-c351-73a56d6ca81f' type='important'>
            <p id='_69ec375e-c992-5be3-76dd-a2311f9bb6cc'>Notice which is very important</p>
          </admonition>
          <clause id='_scope' type='scope' inline-header='false' obligation='normative'>
            <title>Scope</title>
            <p id='_fdcef9f1-c898-da99-eff6-f3e6abde7799'>Scope statement</p>
          </clause>
        </sections>
      </standard-document>
    OUTPUT
    input1 = xmlpp(Asciidoctor.convert(input, *OPTIONS))
    expect(xmlpp(input1))
      .to be_equivalent_to xmlpp(output)
  end

  it "aliases anchors" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Misc-Container

      [[_misccontainer_anchor_aliases]]
      |===
      | id1 | http://www.example.com | %2
      |===

      [[id1]]
      == Clause 1

      <<id1>>
      <<id1,style=id%>>
      xref:http://www.example.com[]
      xref:http://www.example.com[style=id%]

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR.sub('<metanorma-extension>', <<~EXT
        <metanorma-extension>
          <table id='_'>
            <tbody>
              <tr>
                <td valign='top' align='left'>id1</td>
                <td valign='top' align='left'>
                  <link target='http://www.example.com'/>
                </td>
                <td valign='top' align='left'>%2</td>
              </tr>
            </tbody>
          </table>
      EXT
      )}
         <sections>
           <clause id='id1' inline-header='false' obligation='normative'>
             <title>Clause 1</title>
             <p id='_'>
               <xref target='id1'/>
               <xref target='id1' style='id'/>
               <xref target='id1' type='inline'/>
               <xref target='id1' type='inline' style="id">http://www.example.com</xref>
             </p>
           </clause>
         </sections>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "removes redundant bookmarks" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [appendix]
      == Annex [[bookmark]]

    INPUT
    output = <<~OUTPUT
      <annex id="bookmark" inline-header="false" obligation="normative">
        <title>Annex</title>
      </annex>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(xmlpp(strip_guid(ret.at("//xmlns:annex").to_xml)))
      .to be_equivalent_to(xmlpp(output))

    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [appendix]
      [[annex]]
      == Annex [[bookmark]]

    INPUT
    output = <<~OUTPUT
      <annex id="annex" inline-header="false" obligation="normative">
        <title>Annex <bookmark id="bookmark"/></title>
      </annex>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(xmlpp(strip_guid(ret.at("//xmlns:annex").to_xml)))
      .to be_equivalent_to(xmlpp(output))
  end

  it "cleans up links" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause

      http://user:pass@www.example.com/a%20<a>%3cb%3e[x]
      mailto:copyright@iso.org[x]

    INPUT
    output = <<~OUTPUT
      <clause id="_" inline-header="false" obligation="normative">
        <title>Clause</title>
        <p id="_">
        <link target="http://user:pass@www.example.com/a%20&lt;a&gt;%3cb%3e">x</link>
        <link target="mailto:copyright@iso.org">x</link>
        </p>
      </clause>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(xmlpp(strip_guid(ret.at("//xmlns:clause").to_xml)))
      .to be_equivalent_to(xmlpp(output))
  end

  it "do not apply substitutions to links" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause

      \\http://www.example.com/...abc

      http://www.example.com/...abc

      <http://www.example.com/...abc>

      a http://www.example.com/...abc

      http://www.example.com/...abc[]

      http://www.example.com/...abc[x]

      ++http://www.example.com++

      https://isotc.iso.org/livelink/livelink/fetch/-15620806/15620808/15623592/15768654/TMB_resolutions_-_2012_%28Resolution_1-148%29.pdf?nodeid=15768229&vernum=-2

      https://isotc.iso.org/livelink/livelink/fetch/-15620806/15620808/15623592/15768654/TMB_resolutions_-_2012_%28Resolution_1-148%29.pdf?nodeid=15768229&vernum=-2[TMB Resolution 8/2012]

      link:http://www...com[]

      <link:http://www...com[]>

      a link:http://www...com[]

      link:++http://www...com++[]

      ++++
      <a xmlns="http://www.example.com"/>
      ++++

      pass:q[http://www.example.com]
      And pass:[http://www.example.com] and pass:a,q[http://www.example.com]

      [sourcecode,filename="http://www.example.com"]
      ----
      A
      http://www.example.com/...abc2[]
      ----

      ----
      http://www.example.com/...def[]
      ----

      --
      http://www.example.com/...ghi[]
      --

      [example]
      ----
      http://www.example.com/...jkl[]
      ----

      ====
      http://www.example.com/...mno[]
      ====

      [example]
      ====
      http://www.example.com/...prq[]
      ====

    INPUT
    output = <<~OUTPUT
      <clause id="_" inline-header="false" obligation="normative">
         <title>Clause</title>
         <p id="_">http://www.example.com/…​abc</p>
         <p id="_">
           <link target="http://www.example.com/...abc"/>
         </p>
         <p id="_">&lt;<link target="http://www.example.com/...abc"/>&gt;</p>
         <p id="_">a <link target="http://www.example.com/...abc"/></p>
         <p id="_">
           <link target="http://www.example.com/...abc"/>
         </p>
         <p id="_">
           <link target="http://www.example.com/...abc">x</link>
         </p>
         <p id="_">http://www.example.com</p>
         <p id="_">
           <link target="https://isotc.iso.org/livelink/livelink/fetch/-15620806/15620808/15623592/15768654/TMB_resolutions_-_2012_%28Resolution_1-148%29.pdf?nodeid=15768229&amp;vernum=-2"/>
         </p>
         <p id="_">
           <link target="https://isotc.iso.org/livelink/livelink/fetch/-15620806/15620808/15623592/15768654/TMB_resolutions_-_2012_%28Resolution_1-148%29.pdf?nodeid=15768229&amp;vernum=-2">TMB Resolution 8/2012</link>
         </p>
         <p id="_">
           <link target="http://www...com"/>
         </p>
         <p id="_">&lt;<link target="http://www...com"/>&gt;</p>
         <p id="_">a <link target="http://www...com"/></p>
         <p id="_">
           <link target="http://www...com"/>
         </p>
         <a xmlns="http://www.example.com"/>
         <p id="_">http://www.example.com
         And http://www.example.com and http://www.example.com</p>
         <sourcecode id="_" filename="http://www.example.com">A
       http://www.example.com/...abc2[]</sourcecode>
         <sourcecode id="_">http://www.example.com/...def[]</sourcecode>
         <p id="_">
           <link target="http://www.example.com/...ghi"/>
         </p>
         <sourcecode id="_">http://www.example.com/...jkl[]</sourcecode>
         <example id="_">
           <p id="_">
             <link target="http://www.example.com/...mno"/>
           </p>
         </example>
         <example id="_">
           <p id="_">
             <link target="http://www.example.com/...prq"/>
           </p>
         </example>
       </clause>
       </clause>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(xmlpp(strip_guid(ret.at("//xmlns:clause").to_xml)))
      .to be_equivalent_to(xmlpp(output))
  end

  private

  def mock_mathml_italicise(string)
    allow_any_instance_of(Metanorma::Standoc::Cleanup)
      .to receive(:mathml_mi_italics).and_return(string)
  end

  def mock_iev
    expect(Iecbib::IecBibliography).to receive(:get).with("IEV", nil, {}) do
      IsoBibItem::XMLParser.from_xml(<<~OUTPUT)
        <bibitem type="standard" id="IEC60050:2001">
           <title format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary</title>
           <docidentifier>IEC 60050:2011</docidentifier>
           <date type="published">
             <on>2007</on>
           </date>
           <contributor>
             <role type="publisher"/>
             <organization>
               <name>International Electrotechnical Commission</name>
               <abbreviation>IEC</abbreviation>
               <uri>www.iec.ch</uri>
             </organization>
           </contributor>
           <language>en</language>
           <language>fr</language>
           <script>Latn</script>
           <status>
             <stage>60</stage>
           </status>
           <copyright>
             <from>2018</from>
             <owner>
               <organization>
                 <name>International Electrotechnical Commission</name>
                 <abbreviation>IEC</abbreviation>
                 <uri>www.iec.ch</uri>
               </organization>
             </owner>
           </copyright>
         </bibitem>
      OUTPUT
    end.at_least :once
  end
end
