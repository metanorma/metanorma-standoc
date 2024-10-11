require "spec_helper"
require "relaton_iec"
require "fileutils"

RSpec.describe Metanorma::Standoc do
  before do
    # Force to download Relaton index file
    allow_any_instance_of(Relaton::Index::Type).to receive(:actual?)
      .and_return(false)
    allow_any_instance_of(Relaton::Index::FileIO).to receive(:check_file)
      .and_return(nil)
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
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
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
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
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
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
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
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
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
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
               <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
               <title type="title-part" format="text/plain" language="en" script="Latn">Part 102: Mathematics — General concepts and linear algebra</title>
               <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) — Part 102: Mathematics — General concepts and linear algebra</title>
               <title type="title-main" format="text/plain" language="fr" script="Latn">Vocabulaire Electrotechnique International (IEV)</title>
               <title type="title-part" format="text/plain" language="fr" script="Latn">Partie 102: Mathématiques — Concepts généraux et algèbre linéaire</title>
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
               <abstract format="text/html" language="fr" script="Latn">Cette partie de la CEI 60050 donne la terminologie mathématique générale utilisée dans les domaines de l’électricité, de l’électronique et des télécommunications, ainsi que les concepts fondamentaux d’algèbre linéaire. Elle maintient une distinction nette entre les concepts mathématiques et les concepts physiques, même si certains termes sont employés dans les deux cas. Une autre partie traitera des fonctions.<br/>Elle a le statut de norme horizontale conformément au Guide IEC 108.</abstract>
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
               <title type="title-main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV)</title>
               <title type="title-part" format="text/plain" language="en" script="Latn">Part 103: Mathematics — Functions</title>
               <title type="main" format="text/plain" language="en" script="Latn">International Electrotechnical Vocabulary (IEV) — Part 103: Mathematics — Functions</title>
               <title type="title-main" format="text/plain" language="fr" script="Latn">Vocabulaire Electrotechnique International (IEV)</title>
               <title type="title-part" format="text/plain" language="fr" script="Latn">Partie 103: Mathématiques — Fonctions</title>
               <title type="main" format="text/plain" language="fr" script="Latn">Vocabulaire Electrotechnique International (IEV) — Partie 103: Mathématiques — Fonctions</title>
               <title type="title-intro" format="text/plain" language="es" script="Latn">Versión Oficial En español</title>
               <title type="title-main" format="text/plain" language="es" script="Latn">Vocabulario Electrotécnico Internacional. Parte 103: Matemáticas. Funciones.</title>
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
               <abstract format="text/html" language="en" script="Latn">IEC 60050-103:2009 gives the terminology relative to functions of one or more variables. Together with IEC 60050-102, it covers the mathematical terminology used in the fields of electricity, electronics and telecommunications. It maintains a clear distinction between mathematical concepts and physical concepts, even if some terms are used in both cases. Mathematical symbols are generally in accordance with IEC 60027-1 and ISO 80000-2. This standard cancels and replaces Sections 101-13, 101-14 and 101-15 of International Standard IEC 60050-101:1998.<br/>It has the status of a horizontal standard in accordance with IEC Guide 108.</abstract>
               <abstract format="text/html" language="fr" script="Latn">La CEI 60050-103:2009 donne la terminologie relative aux fonctions d’une ou plusieurs variables. Conjointement avec la CEI 60050-102, elle couvre la terminologie mathématique utilisée dans les domaines de l’électricité, de l’électronique et des télécommunications. Elle maintient une distinction nette entre les concepts mathématiques et les concepts physiques, même si certains termes sont employés dans les deux cas. Les symboles mathématiques sont généralement conformes à la CEI 60027-1 et à l’ISO 80000-2. Cette norme annule et remplace les sections 101-13, 101-14 et 101-15 de la norme internationale CEI 60050-101:1998.<br/>Elle a le statut de norme horizontale conformément au Guide IEC 108.</abstract>
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
      expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
        .to be_equivalent_to Xml::C14n.format(output)
    end
    FileUtils.rm_rf File.expand_path("~/.iev.pstore")
    FileUtils.mv File.expand_path("~/.iev.pstore1"),
                 File.expand_path("~/.iev.pstore"), force: true
    FileUtils.rm_rf File.expand_path("~/.relaton/cache")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"),
                 File.expand_path("~/.relaton/cache"), force: true
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
    expect(Xml::C14n.format(Metanorma::Standoc::Converter.new(nil, *OPTIONS)
      .cleanup(Nokogiri::XML(input)).to_xml))
      .to be_equivalent_to Xml::C14n.format(output)
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
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
            <flavor>standoc</flavor>
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
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
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
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "remove duplicate bibitems" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:--]]] footnote:[The standard is in press] _Standard_
      * [[[iso123,ISO 123:--]]] footnote:[The standard is in press] _Standard_
      * [[[iso123,ISO 123:--]]] footnote:[The standard is in press] _Standard_

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections/>
      <bibliography><references id="_" obligation="informative" normative="true">
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
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  private

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
