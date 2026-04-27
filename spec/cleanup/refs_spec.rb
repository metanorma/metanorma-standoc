require "spec_helper"
require "relaton/iec"
require "fileutils"

RSpec.describe Metanorma::Standoc do
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
        <title id="_">Foreword</title>
        <p id="_">
        <eref type="inline" bibitemid="iso216" citeas="ISO\\u00a0216:2001"/>
        <eref type='inline' case='capital' droploc='true' bibitemid='iso216' citeas='ISO\\u00a0216:2001'/>
      </p>
      </foreword></preface><sections>
      </sections>
      </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:bibliography")&.remove
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
  end

  it "add default eref and origin style" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR.sub(':nodoc:', ":nodoc:\n:erefstyle: short\n:originstyle: full\n:xrefstyle: basic")}
      <<iso216>>
      <<A>>

      [.source]
      <<iso216,section=1>>

      [[A]]
      [bibliography]
      == Normative References
      * [[[iso216,ISO 216:2001]]], _Reference_
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <preface>
             <foreword id="_" obligation="informative">
                <title id="_">Foreword</title>
                <p id="_">
                   <eref type="inline" bibitemid="iso216" citeas="ISO\\u00a0216:2001" style="short"/>
                   <xref target="A" style="basic"/>
                </p>
                <source status="identical" type="authoritative">
                   <origin bibitemid="iso216" type="inline" style="full" citeas="ISO\\u00a0216:2001">
                      <localityStack>
                         <locality type="section">
                            <referenceFrom>1</referenceFrom>
                         </locality>
                      </localityStack>
                   </origin>
                </source>
             </foreword>
          </preface>
          <sections>

       </sections>
       </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:bibliography")&.remove
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
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
              <title id="_">Foreword</title>
              <p id="_">
              <eref type="inline" bibitemid="iso216" citeas="ISO\\u00a0216">
              <localityStack>
              <locality type="whole"/><locality type="clause"><referenceFrom>3</referenceFrom></locality><locality type="example"><referenceFrom>9</referenceFrom><referenceTo>11</referenceTo></locality><locality type="locality:prelude"><referenceFrom>33 a</referenceFrom></locality><locality type="locality:entirety"/>
              </localityStack>
              <display-text>the reference,xyz</display-text></eref>
       <eref type='inline' bibitemid='iso216' citeas='ISO\\u00a0216'>
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
         <display-text>the reference,xyz</display-text>
       </eref>
      <eref type='inline' bibitemid='iso216' citeas='ISO\\u00a0216'>
        <display-text><em>whole</em></display-text>
      </eref>
      <eref type='inline' bibitemid='iso216' citeas='ISO\\u00a0216'>
        <display-text>a
        <em>whole</em>
         flagon
         </display-text>
      </eref>
      <eref type='inline' bibitemid='iso216' citeas='ISO\\u00a0216'>
        <localityStack>
          <locality type='whole'/>
          <locality type='clause'>
            <referenceFrom>3</referenceFrom>
          </locality>
        </localityStack>
        <display-text>
        a
        <em>whole</em>
         flagon
         </display-text>
      </eref>
      <eref type='inline' case='capital' droploc='true' bibitemid='iso216' citeas='ISO\\u00a0216'>
        <localityStack>
          <locality type='whole'/>
          <locality type='clause'>
            <referenceFrom>3</referenceFrom>
          </locality>
        </localityStack>
        <display-text>a
        <em>whole</em>
         flagon</display-text>
      </eref>
              </p>
            </foreword></preface><sections>
            </sections>
            </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:bibliography")&.remove
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
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
        <title id="_">Foreword</title>
        <p id="_">
        <eref type="inline" bibitemid="iso216" citeas="ISO\\u00a0216"/>
      </p>
      </foreword></preface><sections>
      </sections>
      </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:bibliography")&.remove
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
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
             <title id="_">Foreword</title>
             <p id='_'>
               <erefstack>
                 <eref connective='from' bibitemid='iso216' citeas='ISO\\u00a0216' type='inline'/>
                 <eref connective='to' bibitemid='iso216' citeas='ISO\\u00a0216' type='inline'/>
               </erefstack>
             </p>
           </foreword>
         </preface>
         <sections> </sections>
       </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:bibliography")&.remove
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
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
        <title id="_">Terms and definitions</title>
        <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
        <term id="_" anchor="term-Term1">
        <preferred><expression><name>Term1</name></expression></preferred>
        <definition id="_"><verbal-definition id="_"><p id='_'>Definition 0</p></verbal-definition></definition>
        <source status="identical" type="authoritative">
        <origin bibitemid="ISO2191" type="inline" citeas="">
        <localityStack>
       <locality type="section"><referenceFrom>1</referenceFrom></locality>
       </localityStack>
       </origin>
      </source>
      </term>
      </terms>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
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
    # VCR.use_cassette("separates_iev_citations_by_top_level_clause",
    # record: :new_episodes,
    # match_requests_on: %i[method uri body]) do
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
        <terms id="_" obligation="normative"><title id="_">Terms and definitions</title>
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
         <term id="_" anchor="term-Automation1">
          <preferred><expression><name>Automation1</name></expression></preferred>
          <definition id="_"><verbal-definition id="_"><p id='_'>Definition 1</p></verbal-definition></definition>
          <source status="identical" type="authoritative">
          <origin bibitemid="IEC60050-103" type="inline" citeas="IEC\\u00a060050-103:2009">
          <localityStack>
        <locality type="clause"><referenceFrom>103-01-02</referenceFrom></locality>
          </localityStack>
        </origin>
        </source>
        </term>
        <term id="_" anchor="term-Automation2">
          <preferred><expression><name>Automation2</name></expression></preferred>
          <definition id="_"><verbal-definition id="_"><p id='_'>Definition 2</p></verbal-definition></definition>
          <source status="identical" type="authoritative">
          <origin bibitemid="IEC60050-102" type="inline" citeas="IEC\\u00a060050-102:2007">
          <localityStack>
        <locality type="clause"><referenceFrom>102-01-02</referenceFrom></locality>
          </localityStack>
        </origin>
        </source>
        </term>
        <term id="_" anchor="term-Automation3">
          <preferred><expression><name>Automation3</name></expression></preferred>
          <definition id="_"><verbal-definition id="_"><p id='_'>Definition 3</p></verbal-definition></definition>
          <source status="identical" type="authoritative">
          <origin bibitemid="IEC60050-103" type="inline" citeas="IEC\\u00a060050-103:2009">
          <localityStack>
        <locality type="clause"><referenceFrom>103-01-02</referenceFrom></locality>
          </localityStack>
        </origin>
        </source>
        </term></terms></sections><bibliography><references id="_" obligation="informative" normative="true">
          <title id="_">Normative references</title>
        #{NORM_REF_BOILERPLATE}
                <bibitem id="_" anchor="IEC60050-102" type="standard">
                   <fetched/>
                   <title language="en" script="Latn" type="title-main">International Electrotechnical Vocabulary (IEV)</title>
                   <title language="en" script="Latn" type="title-part">Part 102: Mathematics\\u2009—\\u2009General concepts and linear algebra</title>
                   <title language="en" script="Latn" type="main">International Electrotechnical Vocabulary (IEV)\\u2009—\\u2009Part 102: Mathematics\\u2009—\\u2009General concepts and linear algebra</title>
                   <title language="fr" script="Latn" type="title-main">Vocabulaire Electrotechnique International (IEV)</title>
                   <title language="fr" script="Latn" type="title-part">Partie 102: Mathématiques\\u2009—\\u2009Concepts généraux et algèbre linéaire</title>
                   <title language="fr" script="Latn" type="main">Vocabulaire Electrotechnique International (IEV)\\u2009—\\u2009Partie 102: Mathématiques\\u2009—\\u2009Concepts généraux et algèbre linéaire</title>
                   <uri type="src">https://webstore.iec.ch/publication/160</uri>
                   <uri type="obp">https://webstore.iec.ch/preview/info_iec60050-102{ed1.0}b.pdf</uri>
                   <docidentifier type="IEC" primary="true">IEC 60050-102:2007</docidentifier>
                   <docidentifier type="URN">urn:iec:std:iec:60050-102:2007:::</docidentifier>
                   <date type="published">
                      <on>2007-08-27</on>
                   </date>
                   <contributor>
                      <role type="publisher"/>
                      <organization>
                         <name language="en" script="Latn">International Electrotechnical Commission</name>
                         <abbreviation language="en" script="Latn">IEC</abbreviation>
                         <uri type="org">www.iec.ch</uri>
                      </organization>
                   </contributor>
                   <contributor>
                      <role type="author">
                         <description>committee</description>
                      </role>
                      <organization>
                         <name language="en" script="Latn">International Electrotechnical Commission</name>
                         <subdivision type="technical-committee">
                            <name language="en" script="Latn">TC 1</name>
                            <identifier>1</identifier>
                         </subdivision>
                         <abbreviation language="en" script="Latn">IEC</abbreviation>
                      </organization>
                   </contributor>
                   <edition>1</edition>
                   <language>en</language>
                   <language>fr</language>
                   <script>Latn</script>
                   <abstract language="en" script="Latn">
                      This part of IEC 60050 gives the general mathematical terminology used in the fields of electricity, electronics and telecommunications, together with basic concepts in linear algebra. It maintains a clear distinction between mathematical concepts and physical concepts, even if some terms are used in both cases. Another part will deal with functions.
                      <br/>
                      It has the status of a horizontal standard in accordance with IEC Guide 108.
                   </abstract>
                   <abstract language="fr" script="Latn">
                      Cette partie de la CEI 60050 donne la terminologie mathématique générale utilisée dans les domaines de l’électricité, de l’électronique et des télécommunications, ainsi que les concepts fondamentaux d’algèbre linéaire. Elle maintient une distinction nette entre les concepts mathématiques et les concepts physiques, même si certains termes sont employés dans les deux cas. Une autre partie traitera des fonctions.
                      <br/>
                      Elle a le statut de norme horizontale conformément au Guide IEC 108.
                   </abstract>
                   <status>
                      <stage>PUBLISHED</stage>
                   </status>
                   <copyright>
                      <from>2007</from>
                      <owner>
                         <organization>
                            <name language="en" script="Latn">International Electrotechnical Commission</name>
                            <abbreviation language="en" script="Latn">IEC</abbreviation>
                            <uri type="org">www.iec.ch</uri>
                         </organization>
                      </owner>
                   </copyright>
                   <place>
                      <city>Geneva</city>
                   </place>
                </bibitem>
                <bibitem id="_" anchor="IEC60050-103" type="standard">
                   <fetched/>
                   <title language="en" script="Latn" type="title-main">International Electrotechnical Vocabulary (IEV)</title>
                   <title language="en" script="Latn" type="title-part">Part 103: Mathematics\\u2009—\\u2009Functions</title>
                   <title language="en" script="Latn" type="main">International Electrotechnical Vocabulary (IEV)\\u2009—\\u2009Part 103: Mathematics\\u2009—\\u2009Functions</title>
                   <title language="fr" script="Latn" type="title-main">Vocabulaire Electrotechnique International (IEV)</title>
                   <title language="fr" script="Latn" type="title-part">Partie 103: Mathématiques\\u2009—\\u2009Fonctions</title>
                   <title language="fr" script="Latn" type="main">Vocabulaire Electrotechnique International (IEV)\\u2009—\\u2009Partie 103: Mathématiques\\u2009—\\u2009Fonctions</title>
                   <title language="es" script="Latn" type="title-intro">Versión Oficial En español</title>
                   <title language="es" script="Latn" type="title-main">Vocabulario Electrotécnico Internacional. Parte 103: Matemáticas. Funciones.</title>
                   <title language="es" script="Latn" type="main">Versión Oficial En español\\u2009—\\u2009Vocabulario Electrotécnico Internacional. Parte 103: Matemáticas. Funciones.</title>
                   <uri type="src">https://webstore.iec.ch/publication/161</uri>
                   <uri type="obp">https://webstore.iec.ch/preview/info_iec60050-103{ed1.0}b.pdf</uri>
                   <docidentifier type="IEC" primary="true">IEC 60050-103:2009</docidentifier>
                   <docidentifier type="URN">urn:iec:std:iec:60050-103:2009:::</docidentifier>
                   <date type="published">
                      <on>2009-12-14</on>
                   </date>
                   <contributor>
                      <role type="publisher"/>
                      <organization>
                         <name language="en" script="Latn">International Electrotechnical Commission</name>
                         <abbreviation language="en" script="Latn">IEC</abbreviation>
                         <uri type="org">www.iec.ch</uri>
                      </organization>
                   </contributor>
                   <contributor>
                      <role type="author">
                         <description>committee</description>
                      </role>
                      <organization>
                         <name language="en" script="Latn">International Electrotechnical Commission</name>
                         <subdivision type="technical-committee">
                            <name language="en" script="Latn">TC 1</name>
                            <identifier>1</identifier>
                         </subdivision>
                         <abbreviation language="en" script="Latn">IEC</abbreviation>
                      </organization>
                   </contributor>
                   <edition>1</edition>
                   <language>en</language>
                   <language>fr</language>
                   <language>es</language>
                   <script>Latn</script>
                   <abstract language="en" script="Latn">
                      IEC 60050-103:2009 gives the terminology relative to functions of one or more variables. Together with IEC 60050-102, it covers the mathematical terminology used in the fields of electricity, electronics and telecommunications. It maintains a clear distinction between mathematical concepts and physical concepts, even if some terms are used in both cases. Mathematical symbols are generally in accordance with IEC 60027-1 and ISO 80000-2. This standard cancels and replaces Sections 101-13, 101-14 and 101-15 of International Standard IEC 60050-101:1998.
                      <br/>
                      It has the status of a horizontal standard in accordance with IEC Guide 108.
                   </abstract>
                   <abstract language="fr" script="Latn">
                      La CEI 60050-103:2009 donne la terminologie relative aux fonctions d’une ou plusieurs variables. Conjointement avec la CEI 60050-102, elle couvre la terminologie mathématique utilisée dans les domaines de l’électricité, de l’électronique et des télécommunications. Elle maintient une distinction nette entre les concepts mathématiques et les concepts physiques, même si certains termes sont employés dans les deux cas. Les symboles mathématiques sont généralement conformes à la CEI 60027-1 et à l’ISO 80000-2. Cette norme annule et remplace les sections 101-13, 101-14 et 101-15 de la norme internationale CEI 60050-101:1998.
                      <br/>
                      Elle a le statut de norme horizontale conformément au Guide IEC 108.
                   </abstract>
                   <status>
                      <stage>PUBLISHED</stage>
                   </status>
                   <copyright>
                      <from>2009</from>
                      <owner>
                         <organization>
                            <name language="en" script="Latn">International Electrotechnical Commission</name>
                            <abbreviation language="en" script="Latn">IEC</abbreviation>
                            <uri type="org">www.iec.ch</uri>
                         </organization>
                      </owner>
                   </copyright>
                   <place>
                      <city>Geneva</city>
                   </place>
                </bibitem>
             </references>
          </bibliography>
       </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
    FileUtils.rm_rf File.expand_path("~/.iev.pstore")
    FileUtils.mv File.expand_path("~/.iev.pstore1"),
                 File.expand_path("~/.iev.pstore"), force: true
    FileUtils.rm_rf File.expand_path("~/.relaton/cache")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"),
                 File.expand_path("~/.relaton/cache"), force: true
  end

  it "removes nested bibitem IDs" do
    input = <<~INPUT
      #{BLANK_HDR.sub(/ xmlns="[^"]+"/, '')}
      <bibliography>
        <references normative="true"><title id="_">Normative</title>
        <bibitem id="_" anchor="A">
          <relation type="includes">
            <bibitem id="_" anchor="B"/>
          </relation>
        </bibitem>
      </bibliography>
      </metanorma>
    INPUT
    output = <<~OUTPUT
      <bibliography>
         <references normative="true" obligation="informative">
            <title id="_">Normative references</title>
            <p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
            <bibitem id="_" anchor="A">
         <language>en</language>
         <script>Latn</script>
               <relation type="includes">
                  <bibitem/>
               </relation>
            </bibitem>
         </references>
      </bibliography>
    OUTPUT
    c = Metanorma::Standoc::Converter.new("standoc", *OPTIONS)
    c.init(Metanorma::Standoc::EmptyAttr.new)
    xml = Metanorma::Standoc::Cleanup.new(c).cleanup(Nokogiri::XML(input)).to_xml
    xml = Nokogiri::XML(xml).at("//bibliography")
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
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
        <title id="_">Clause</title>
        <p id="_"><eref type="inline" bibitemid="iso123" citeas="[2]"/>
      <eref type="inline" bibitemid="iso124" citeas="ISO\\u00a0124"/></p>
      </clause>
      </sections><bibliography><references id="_" obligation="informative" normative="false">
        <title id="_">Bibliography</title>
        <bibitem id="_" anchor="iso124" type="standard">
        <title format="text/plain">Standard 124</title>
        <docidentifier>ISO 124</docidentifier>
        <docnumber>124</docnumber>
        <contributor>
          <role type="publisher"/>
          <organization>
            <name>ISO</name>
          </organization>
        </contributor>
        <language>en</language>
        <script>Latn</script>
      </bibitem>
        <bibitem id="_" anchor="iso123">
        <formattedref format="application/x-isodoc+xml">
          <em>Standard 123</em>
        </formattedref>
        <docidentifier type="metanorma">[2]</docidentifier>
        <language>en</language>
        <script>Latn</script>
      </bibitem>
      </references></bibliography>
             </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
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
             <title id="_">Clause</title>
             <p id="_"><eref type="inline" bibitemid="iso123" citeas="[2]"/>
           <eref type="inline" bibitemid="iso124" citeas="ISO\\u00a0124"/>
           <eref type="inline" bibitemid="iso125" citeas="ISO\\u00a0125"/>
           <eref type="inline" bibitemid="iso126" citeas="[4]"/></p>
           </clause>
           </sections><bibliography><clause id="_" obligation="informative"><title id="_">Bibliography</title>
            <references id="_" obligation="informative" normative="false">
             <title id="_">Clause 1</title>
             <bibitem id="_" anchor="iso124" type="standard">
             <title format="text/plain">Standard 124</title>
             <docidentifier>ISO 124</docidentifier>
             <docnumber>124</docnumber>
             <contributor>
               <role type="publisher"/>
               <organization>
                 <name>ISO</name>
               </organization>
             </contributor>
             <language>en</language>
             <script>Latn</script>
           </bibitem>
             <bibitem id="_" anchor="iso123">
             <formattedref format="application/x-isodoc+xml">
               <em>Standard 123</em>
             </formattedref>
             <docidentifier type="metanorma">[2]</docidentifier>
             <language>en</language>
             <script>Latn</script>
           </bibitem>
           </references>
           <references id="_" obligation="informative" normative="false">
             <bibitem id="_" anchor="iso125" type="standard">
             <title format="text/plain">Standard 124</title>
             <docidentifier>ISO 125</docidentifier>
             <docnumber>125</docnumber>
             <contributor>
               <role type="publisher"/>
               <organization>
                 <name>ISO</name>
               </organization>
             </contributor>
             <language>en</language>
             <script>Latn</script>
           </bibitem>
             <bibitem id="_" anchor="iso126">
             <formattedref format="application/x-isodoc+xml">
               <em>Standard 123</em>
             </formattedref>
             <docidentifier type="metanorma">[4]</docidentifier>
             <language>en</language>
             <script>Latn</script>
           </bibitem>
        </references>
      </clause>
      <clause id="_" obligation='informative'>
        <title id="_">Bibliography Redux</title>
        <references id="_" normative='false' obligation='informative'>
          <title id="_">Clause 1</title>
          <bibitem id="_" anchor="iso127" type='standard'>
            <title format='text/plain'>Standard 124</title>
            <docidentifier>ISO 124</docidentifier>
            <docnumber>124</docnumber>
            <contributor>
              <role type='publisher'/>
              <organization>
                <name>ISO</name>
              </organization>
            </contributor>
            <language>en</language>
            <script>Latn</script>
          </bibitem>
          <bibitem id="_" anchor="iso128">
            <formattedref format='application/x-isodoc+xml'>
              <em>Standard 123</em>
            </formattedref>
            <docidentifier type='metanorma'>[6]</docidentifier>
            <language>en</language>
            <script>Latn</script>
          </bibitem>
           </references></clause></bibliography>
           </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
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
      <metanorma xmlns='https://www.metanorma.org/ns/standoc'  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
        <bibdata type='standard'>
          <title language='en' type='main'>Document title</title>
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
          <references id="_" obligation='informative' normative="true">
            <title id="_">Normative references</title>
            <p id="_">There are no normative references in this document.</p>
          </references>
        </bibliography>
      </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
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
           <clause id="_" inline-header='false' obligation='normative'>
             <title id="_">Clause</title>
             <p id='_'>
               <eref bibitemid='uml_A' citeas="">
               <localityStack>
                 <locality type='anchor'><referenceFrom>A.B.C</referenceFrom></locality>
               </localityStack>
                 <display-text>C</display-text>
               </eref>
               <eref bibitemid='uml_A' citeas=""/>
               <xref target='action.AA'><display-text>AA</display-text></xref>
               <xref target='action'><display-text>** Missing target action.AB</display-text></xref>
             </p>
           </clause>
           <clause id="_" anchor="action" type='express-schema' inline-header='false' obligation='normative'>
             <title id="_">Action</title>
             <clause id="_" anchor="action.AA" inline-header='false' obligation='normative'>
             <title id="_">AA</title>
              </clause>
           </clause>
         </sections>
         <bibliography>
           <references id="_" normative='false' obligation='informative'>
             <title id="_">Bibliography</title>
             <bibitem id="_" anchor="D">
               <formattedref format='application/x-isodoc+xml'>F</formattedref>
               <docidentifier>E</docidentifier>
               <language>en</language>
               <script>Latn</script>
             </bibitem>
           </references>
           <references hidden='true' normative='false'>
             <bibitem id="_" anchor="uml_A" type='internal'>
               <docidentifier type='repository'>uml/A</docidentifier>
             </bibitem>
           </references>
         </bibliography>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
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
             <clause id="_" anchor="B" type='express-schema' inline-header='false' obligation='normative'>
                   <title id="_">Clause</title>
                   <note id="_" anchor="B1">
                     <p id='_'>X</p>
                   </note>
                   <p id='_'>
                     <eref bibitemid='express-schema_A' citeas=''>
                       <localityStack>
                         <locality type='anchor'>
                           <referenceFrom>A.B.C</referenceFrom>
                         </locality>
                       </localityStack>
                       <display-text>C</display-text>
                     </eref>
                     <eref bibitemid='express-schema_A' citeas=''/>
                     <xref target='B'/>
                     <xref target='B1'/>
                   </p>
                 </clause>
               </sections>
               <bibliography>
                 <references hidden='true' normative='false'>
                   <bibitem id="_" anchor="express-schema_A" type='internal'>
                     <docidentifier type='repository'>express-schema/A</docidentifier>
                   </bibitem>
                 </references>
               </bibliography>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
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
        <title id="_">Foreword</title>
        <p id="_"><fn id="_" reference="1">
        <p id="_">Footnote</p>
      </fn>
      </p>
      </foreword></preface><sections>

      <clause id="_" inline-header="false" obligation="normative">
        <title id="_">Clause</title>
        <p id="_"><fn id="_" reference="2">
        <p id="_">Footnote2</p>
      </fn>
      </p>
      </clause></sections><bibliography><references id="_" obligation="informative" normative="true">
        <title id="_">Normative references</title>
        #{NORM_REF_BOILERPLATE}
        <bibitem id="_" anchor="iso123" type="standard">
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
         <language>en</language>
         <script>Latn</script>
       </bibitem>
      </references>
      </bibliography>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
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
        <title id="_">Normative references</title>
        #{NORM_REF_BOILERPLATE}
        <bibitem id="_" anchor="iso123" type="standard">
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
            <language>en</language>
            <script>Latn</script>
       </bibitem>
      </references>
      </bibliography>
      </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

    it "processes attachments" do
    attachment =
      if RUBY_PLATFORM.include?("mingw") || RUBY_PLATFORM.include?("mswin")
        <<~OUTPUT
          DQpwIHsNCiAgZm9udC1mYW1
          pbHk6ICRib2R5Zm9udDsNCn0NCg0KaDEgew0KICBmb250LWZhbWlseTogJGh
          lYWRlcmZvbnQ7DQp9DQoNCnByZSB7DQogIGZvbnQtZmFtaWx5OiAkbW9ub3N
          wYWNlZm9udDsNCn0NCg0K
        OUTPUT
      else
        <<~OUTPUT
          CnAgewogIGZvbnQtZmFtaWx
          5OiAkYm9keWZvbnQ7Cn0KCmgxIHsKICBmb250LWZhbWlseTogJGhlYWRlcmZ
          vbnQ7Cn0KCnByZSB7CiAgZm9udC1mYW1pbHk6ICRtb25vc3BhY2Vmb250Owp
          9Cgo=
        OUTPUT
      end
    input = File.read("spec/assets/attach.adoc")
      .gsub("iso.xml", "spec/assets/iso.xml")
      .gsub("html.scss", "spec/assets/html.scss")
    output = <<~OUTPUT
      <metanorma xmlns="https://www.metanorma.org/ns/standoc" type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
         <bibdata type="standard">
           <title language="en" type="main">Document title</title>
           <language>en</language>
           <script>Latn</script>
           <status>
             <stage>published</stage>
           </status>
           <copyright>
             <from>#{Date.today.year}</from>
           </copyright>
           <ext>
             <doctype>standard</doctype>
            <flavor>standoc</flavor>
           </ext>
         </bibdata>
                  <metanorma-extension>
             <attachment name="_attach_attachments/iso.xml">data:application/octet-stream;base64,ICAgIC...</attachment>
             <attachment name="_attach_attachments/iso.xml_">data:application/octet-stream;base64,ICAgIC...</attachment>
             <attachment name="_attach_attachments/html.scss">data:application/octet-stream;base64,#{attachment}</attachment>
      <semantic-metadata>
         <stage-published>true</stage-published>
      </semantic-metadata>
             <presentation-metadata>
                <toc-heading-levels>2</toc-heading-levels>
                <html-toc-heading-levels>2</html-toc-heading-levels>
                <doc-toc-heading-levels>2</doc-toc-heading-levels>
                <pdf-toc-heading-levels>2</pdf-toc-heading-levels>
             </presentation-metadata>
          </metanorma-extension>
           <sections>
              <clause id="_" inline-header="false" obligation="normative">
                 <title id="_">Clause</title>
                 <p id="_">
                    <eref type="inline" bibitemid="iso123" citeas="[spec/assets/iso.xml]"/>
                 </p>
              </clause>
           </sections>
           <bibliography>
              <references id="_" normative="true" obligation="informative">
                 <title id="_">Normative references</title>
                 <p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
                 <bibitem anchor="iso123" id="_" hidden="true">
                    <formattedref format="application/x-isodoc+xml">[NO INFORMATION AVAILABLE]</formattedref>
                    <uri type="attachment">_attach_attachments/iso.xml</uri>
                    <uri type="citation">_attach_attachments/iso.xml</uri>
                    <docidentifier type="metanorma">[spec/assets/iso.xml]</docidentifier>
                    <language>en</language>
                    <script>Latn</script>
                 </bibitem>
                 <bibitem anchor="iso124" id="_" hidden="true">
                    <formattedref format="application/x-isodoc+xml">[NO INFORMATION AVAILABLE]</formattedref>
                    <uri type="attachment">_attach_attachments/iso.xml_</uri>
                    <uri type="citation">_attach_attachments/iso.xml_</uri>
                    <docidentifier type="metanorma">[spec/assets/iso.xml]</docidentifier>
                    <language>en</language>
                    <script>Latn</script>
                 </bibitem>
                 <bibitem anchor="iso125" id="_" hidden="true">
                    <formattedref format="application/x-isodoc+xml">[NO INFORMATION AVAILABLE]</formattedref>
                    <uri type="attachment">_attach_attachments/html.scss</uri>
                    <uri type="citation">_attach_attachments/html.scss</uri>
                    <docidentifier type="metanorma">[spec/assets/html.scss]</docidentifier>
                    <language>en</language>
                    <script>Latn</script>
                 </bibitem>
              </references>
           </bibliography>
        </metanorma>
    OUTPUT

    # Windows/Unix differences in XML encoding: remove body of Data URI
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)
      .gsub(/iso.xml_[a-f0-9-]+/, "iso.xml_")
      .gsub(/ICAgIC[^<]+/, "ICAgIC...")))
      .to be_xml_equivalent_to output

    input.sub!(":docfile:", ":data-uri-attachment: false\n:docfile:")
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)
      .gsub(/iso.xml_[a-f0-9-]+/, "iso.xml_")
      .gsub(/ICAgIC[^<]+/, "ICAgIC...")))
      .to be_xml_equivalent_to output
      .gsub(%r{<attachment .+?</attachment>}m, "")
      .gsub("_attach_attachments", "spec/assets")
      .gsub("iso.xml_", "iso.xml")

    FileUtils.rm_rf "spec/assets/attach.xml"
    system "bundle exec asciidoctor -b standoc -r metanorma-standoc spec/assets/attach.adoc"
    expect(strip_guid(File.read("spec/assets/attach.xml")
      .gsub(/iso.xml_[a-f0-9-]+/, "iso.xml_")
      .gsub(/ICAgIC[^<]+/, "ICAgIC...")))
      .to be_xml_equivalent_to output
      .gsub("spec/assets/iso.xml", "iso.xml")
      .gsub("spec/assets/html.scss", "html.scss")

    mock_absolute_localdir(4)
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)
      .gsub(/iso.xml_[a-f0-9-]+/, "iso.xml_")
      .gsub(/ICAgIC[^<]+/, "ICAgIC...")))
      .to be_xml_equivalent_to output
      .gsub(%r{<attachment .+?</attachment>}m, "")
      .gsub("_attach_attachments", "spec/assets")
      .gsub("iso.xml_", "iso.xml")
  end

      it "sorts bibliography" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Bibliography

      * [[[iso123,2]]] _Standard2_
      * [[[iso124,(B)]]] _Standard3_
      * [[[iso125,1]]] _Standard1_
      * [[[iso126,usrlabel=A1]]] _Standard_
      * [[[iso127,(4)XYZ 123:1066 (all parts)]]] _Standard0_
    INPUT
    output0 = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
             </sections>
             <bibliography><references id="_" obligation="informative" normative="false">
               <title id="_">Bibliography</title><bibitem id="_" anchor="iso123">
               <formattedref format="application/x-isodoc+xml">
                 <em>Standard2</em>
               </formattedref>
               <docidentifier type="metanorma">[1]</docidentifier>
               <language>en</language>
               <script>Latn</script>
             </bibitem><bibitem id="_" anchor="iso124">
               <formattedref format="application/x-isodoc+xml">
                 <em>Standard3</em>
               </formattedref>
               <docidentifier type="metanorma">[B]</docidentifier>
               <language>en</language>
               <script>Latn</script>
             </bibitem><bibitem id="_" anchor="iso125">
               <formattedref format="application/x-isodoc+xml">
                 <em>Standard1</em>
               </formattedref>
               <docidentifier type="metanorma">[3]</docidentifier>
               <language>en</language>
               <script>Latn</script>
             </bibitem><bibitem id="_" anchor="iso126">
               <formattedref format="application/x-isodoc+xml">
                 <em>Standard</em>
               </formattedref>
               <docidentifier type="metanorma">[A1]</docidentifier>
               <language>en</language>
               <script>Latn</script>
             </bibitem>
      <bibitem id="_" anchor="iso127">
        <formattedref format='application/x-isodoc+xml'>
          <em>Standard0</em>
        </formattedref>
        <docidentifier type='metanorma'>[5]</docidentifier>
        <docidentifier>XYZ 123:1066 (all parts)</docidentifier>
        <docnumber>123:1066 (all parts)</docnumber>
        <language>en</language>
        <script>Latn</script>
      </bibitem>
             </references>
             </bibliography>
             </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output0

   mock_sort_biblio
    output1 = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
             </sections>
             <bibliography><references id="_" obligation="informative" normative="false">
               <title id="_">Bibliography</title><bibitem anchor="iso126" id="_">
               <formattedref format="application/x-isodoc+xml">
                 <em>Standard</em>
               </formattedref>
               <docidentifier type="metanorma">[A1]</docidentifier>
               <language>en</language>
               <script>Latn</script>
             </bibitem>
      <bibitem anchor="iso127" id="_">
        <formattedref format='application/x-isodoc+xml'>
          <em>Standard0</em>
        </formattedref>
        <docidentifier type='metanorma'>[2]</docidentifier>
        <docidentifier>XYZ 123:1066 (all parts)</docidentifier>
        <docnumber>123:1066 (all parts)</docnumber>
        <language>en</language>
        <script>Latn</script>
      </bibitem>
      <bibitem anchor="iso125" id="_">
               <formattedref format="application/x-isodoc+xml">
                 <em>Standard1</em>
               </formattedref>
               <docidentifier type="metanorma">[3]</docidentifier>
               <language>en</language>
               <script>Latn</script>
             </bibitem><bibitem anchor="iso123" id="_">
               <formattedref format="application/x-isodoc+xml">
                 <em>Standard2</em>
               </formattedref>
               <docidentifier type="metanorma">[4]</docidentifier>
               <language>en</language>
               <script>Latn</script>
             </bibitem><bibitem anchor="iso124" id="_">
               <formattedref format="application/x-isodoc+xml">
                 <em>Standard3</em>
               </formattedref>
               <docidentifier type="metanorma">[B]</docidentifier>
               <language>en</language>
               <script>Latn</script>
             </bibitem>
             </references>
             </bibliography>
             </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output1

    expect(strip_guid(Asciidoctor
      .convert(input.sub(":nodoc:",
                         ":nodoc:\n:sort-biblio: false"), *OPTIONS)))
      .to be_xml_equivalent_to output0
  end

      it "sorts references with their notes in Bibliography" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Bibliography

      This is extraneous information

      * [[[iso216,ISO 216]]], _Reference_

      NOTE: ABC

      NOTE: DEF

      This is further extraneous information

      NOTE: GHI

      * [[[iso216,ISO 215]]], _Reference_

      NOTE: JKL

      This is also extraneous information
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections> </sections>
         <bibliography>
           <references id="_" obligation='informative' normative="false">
             <title id="_">Bibliography</title>
             <p id='_'>This is extraneous information</p>
             <bibitem id="_" anchor="iso216" type='standard'>
               <title format='text/plain'>Reference</title>
               <docidentifier>ISO 216</docidentifier>
               <docnumber>216</docnumber>
               <contributor>
                 <role type='publisher'/>
                 <organization>
                   <name>ISO</name>
                 </organization>
               </contributor>
               <language>en</language>
               <script>Latn</script>
             </bibitem>
             <note id='_'>
               <p id='_'>ABC</p>
             </note>
             <note id='_'>
               <p id='_'>DEF</p>
             </note>
             <bibitem id="_" anchor="iso216" type='standard'>
               <title format='text/plain'>Reference</title>
               <docidentifier>ISO 215</docidentifier>
               <docnumber>215</docnumber>
               <contributor>
                 <role type='publisher'/>
                 <organization>
                   <name>ISO</name>
                 </organization>
               </contributor>
               <language>en</language>
               <script>Latn</script>
             </bibitem>
             <note id='_'>
               <p id='_'>JKL</p>
             </note>
             <p id='_'>
               This is further extraneous information
               <note id='_'>
                 <p id='_'>GHI</p>
               </note>
             </p>
             <p id='_'>This is also extraneous information</p>
           </references>
         </bibliography>
       </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

  private

    def mock_absolute_localdir(times)
    expect(Metanorma::Utils).to receive(:localdir)
      .exactly(times).times.with(anything)
      .and_return(File.expand_path(FileUtils.pwd))
  end

  def mock_iev
    expect(Iecbib::IecBibliography).to receive(:get).with("IEV", nil, {}) do
      IsoBibItem::XMLParser.from_xml(<<~OUTPUT)
        <bibitem type="standard" id="_" anchor="IEC60050:2001">
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

    def mock_sort_biblio
    expect_any_instance_of(Metanorma::Standoc::Cleanup).to receive(:sort_biblio) do |_instance, bib|
      bib.sort do |a, b|
        a_title = a.at("./title")&.text || a.at("./formattedref")&.text || ""
        b_title = b.at("./title")&.text || b.at("./formattedref")&.text || ""
        a_title <=> b_title
      end
    end
  end
end
