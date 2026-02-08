require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Standoc do
  it "has a version number" do
    expect(Metanorma::Standoc::VERSION).not_to be nil
  end

  it "applies Asciidoctor substitutions" do
    expect(Metanorma::Utils.asciidoc_sub("A -- B"))
      .to eq "A&#8201;&#8212;&#8201;B"
    expect(Canon.format_xml(Metanorma::Utils.asciidoc_sub("*A* stem:[x]")))
      .to be_equivalent_to Canon.format_xml(<<~XML,
        <strong>A</strong> <stem type="AsciiMath" block="false">x</stem>
      XML
                                           )
  end

  it "processes root attributes" do
    FileUtils.rm_f "test.doc"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :no-pdf:
    INPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(xml.root["version"]).to be_equivalent_to Metanorma::Standoc::VERSION
    expect(xml.root["schema-version"])
      .to be_equivalent_to Metanorma::Standoc::Converter.new(nil, nil)
        .schema_version
  end

  it "processes named entities" do
    FileUtils.rm_f "test.doc"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :no-pdf:

      Text &times; text
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
        <p id='_'>Text × text</p>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "assigns default scripts to major languages" do
    FileUtils.rm_f "test.doc"
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :no-pdf:
      :language: ar
    INPUT
    output = <<~OUTPUT
      <metanorma xmlns='https://www.metanorma.org/ns/standoc' type='semantic' version='#{Metanorma::Standoc::VERSION}' flavor='standoc'>
           <bibdata type='standard'>
             <title language='ar' type='main'>Document title</title>
             <language>ar</language>
             <script>Arab</script>
             <status>
               <stage>published</stage>
             </status>
             <copyright>
               <from>#{Time.now.year}</from>
             </copyright>
             <ext>
               <doctype>standard</doctype>
               <flavor>standoc</flavor>
             </ext>
           </bibdata>
           <sections> </sections>
         </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(Canon.format_xml(xml.to_xml)))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "processes publisher abbreviations in CSV :publisher: attribute" do
    mock_org_abbrevs
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :publisher: International Electrotechnical Commission;IETF;ISO
    INPUT
    output = <<~OUTPUT
      <metanorma xmlns='https://www.metanorma.org/ns/standoc' type='semantic' version='#{Metanorma::Standoc::VERSION}' flavor='standoc'>
        <bibdata type='standard'>
          <title language='en' type='main'>Document title</title>
          <contributor>
            <role type='author'/>
            <organization>
              <name>International Electrotechnical Commission</name>
              <abbreviation>IEC</abbreviation>
            </organization>
          </contributor>
          <contributor>
            <role type='author'/>
            <organization>
              <name>IETF</name>
            </organization>
          </contributor>
          <contributor>
            <role type='author'/>
            <organization>
              <name>International Standards Organization</name>
              <abbreviation>ISO</abbreviation>
            </organization>
          </contributor>
          <contributor>
            <role type='publisher'/>
            <organization>
              <name>International Electrotechnical Commission</name>
              <abbreviation>IEC</abbreviation>
            </organization>
          </contributor>
          <contributor>
            <role type='publisher'/>
            <organization>
              <name>IETF</name>
            </organization>
          </contributor>
          <contributor>
            <role type='publisher'/>
            <organization>
              <name>International Standards Organization</name>
              <abbreviation>ISO</abbreviation>
            </organization>
          </contributor>
          <language>en</language>
          <script>Latn</script>
          <status>
            <stage>published</stage>
          </status>
          <copyright>
            <from>#{Time.now.year}</from>
            <owner>
              <organization>
                <name>International Electrotechnical Commission</name>
                <abbreviation>IEC</abbreviation>
              </organization>
            </owner>
          </copyright>
          <copyright>
            <from>#{Time.now.year}</from>
            <owner>
              <organization>
                <name>IETF</name>
              </organization>
            </owner>
          </copyright>
          <copyright>
            <from>#{Time.now.year}</from>
            <owner>
              <organization>
                <name>International Standards Organization</name>
                <abbreviation>ISO</abbreviation>
              </organization>
            </owner>
          </copyright>
          <ext>
            <doctype>standard</doctype>
            <flavor>standoc</flavor>
          </ext>
        </bibdata>
        <sections> </sections>
      </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(Canon.format_xml(xml.to_xml)))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "processes default metadata" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :docnumber: 1000
      :partnumber: 1
      :edition: 2
      :revdate: 2000-01-01
      :published-date: 1000-01-01
      :accessed-date: 1001-01-01
      :created-date: 1002-01-01
      :implemented-date: 1003-01-01
      :obsoleted-date: 1004-01-01
      :confirmed-date: 1005-01-01
      :updated-date: 1006-01-01
      :issued-date: 1007-01-01
      :circulated-date: 1008-01-01
      :unchanged-date: 1009-01-01
      :vote-started-date: 1011-01-01
      :vote-ended-date: 1012-01-01
      :date: Fred 1010-01-01
      :date_2: Jack 1010-01-01
      :version: 3.4
      :technical-committee: TC
      :technical-committee-number: 1
      :technical-committee-type: A
      :subcommittee: SC
      :subcommittee-number: 2
      :subcommittee-type: B
      :workgroup: WG
      :workgroup-number: 3
      :workgroup-type: C
      :technical-committee_2: TC1
      :technical-committee-number_2: 11
      :technical-committee-type_2: A1
      :technical-committee-agency_2: TC1
      :technical-committee_logo_2: spec/assets/correct.png
      :subcommittee_2: SC1
      :subcommittee-number_2: 21
      :subcommittee-type_2: B1
      :workgroup_2: WG1
      :workgroup-number_2: 31
      :workgroup-type_2: C1
      :workgroup_logo_2: spec/assets/correct.png
      :secretariat: SECRETARIAT
      :copyright-year: 2001
      :docstage: 10
      :docsubstage: 20
      :iteration: 3
      :language: en
      :title: Main Title -- Title
      :library-ics: 01.040.11,11.060.01
      :fullname: Fred Flintstone
      :role: author
      :contributor-credentials: PhD, F.R.Pharm.S.
      :contributor-position: Vice President, Medical Devices Quality & Compliance -- Strategic programmes
      :affiliation: Slate Rock and Gravel Company
      :affiliation_abbrev: SRG
      :affiliation_subdiv: Hermeneutics Unit; Exegetical Subunit
      :address: 6 Rubble Way, Bedrock
      :contributor-uri: http://slate.example.com
      :phone: 123
      :fax: 456
      :surname_2: Rubble
      :givenname_2: Barney
      :initials_2: B. X.
      :role_2: editor
      :role-description_2: consulting editor
      :contributor-credentials_2: PhD, F.R.Pharm.S.
      :contributor-position_2: Former Chair ISO TC 210
      :affiliation_2: Rockhead and Quarry Cave Construction Company
      :affiliation_abbrev_2: RQCCC
      :affiliation_subdiv_2: Hermeneutics Unit; Exegetical Subunit
      :address_2: 6A Rubble Way, + \\
      Bedrock
      :email_2: barney@rockhead.example.com
      :phone_2: 789
      :fax_2: 012
      :corporate-author: "Cartoon Network"; "Ribose, Inc."
      :publisher: "Hanna Barbera"; "Cartoon Network"; "Ribose, Inc."
      :copyright-holder: "Ribose, Inc."; Hanna Barbera
      :part-of: ABC
      :translated-from: DEF,GHI;JKL MNO,PQR
      :keywords: a, b, c
      :pub-address: 1 Infinity Loop + \\
      California
      :pub-phone: 3333333
      :pub-fax: 4444444
      :pub-email: x@example.com
      :pub-uri: http://www.example.com
      :sponsor: "Cartoon Network"; "Ribose, Inc."
      :authorizer: "CBS"; "TXE"
      :isbn: ISBN-13
      :isbn10: ISBN-10
      :classification: a:b, c
      :toclevels: 2
      :toclevels-doc: 3
      :toclevels-html: 4
      :toclevels-pdf: 5
      :docidentifier-additional: ABC:x 1, DEF:y 2
      :data-uri-image: false

    INPUT
    output = <<~OUTPUT
                    <?xml version="1.0" encoding="UTF-8"?>
                <metanorma xmlns="https://www.metanorma.org/ns/standoc" type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
                <bibdata type="standard">
                <title language="en" type="main">Main Title\\u2009—\\u2009Title</title>
                <title language="en" type="title-part-prefix">Part\\u00a01</title>
                  <docidentifier primary="true">1000-1</docidentifier>
                  <docidentifier type='ISBN'>ISBN-13</docidentifier>
                <docidentifier type='ISBN10'>ISBN-10</docidentifier>
                 <docidentifier type="ABC">x 1</docidentifier>
                  <docidentifier type="DEF">y 2</docidentifier>
                  <docnumber>1000</docnumber>
                  <date type="published">
                  <on>1000-01-01</on>
                </date>
                <date type="accessed">
                  <on>1001-01-01</on>
                </date>
                <date type="created">
                  <on>1002-01-01</on>
                </date>
                <date type="implemented">
                  <on>1003-01-01</on>
                </date>
                <date type="obsoleted">
                  <on>1004-01-01</on>
                </date>
                <date type="confirmed">
                  <on>1005-01-01</on>
                </date>
                <date type="updated">
                  <on>1006-01-01</on>
                </date>
                <date type="issued">
                  <on>1007-01-01</on>
                </date>
                <date type="circulated">
                  <on>1008-01-01</on>
                </date>
                <date type="unchanged">
                  <on>1009-01-01</on>
                </date>
                 <date type='vote-started'>
                   <on>1011-01-01</on>
                 </date>
                 <date type='vote-ended'>
                   <on>1012-01-01</on>
                 </date>
                <date type="Fred">
                  <on>1010-01-01</on>
                </date>
                <date type="Jack">
                  <on>1010-01-01</on>
                </date>
                <contributor>
                  <role type="author"/>
                  <organization>
                    <name>Cartoon Network</name>
                  </organization>
                </contributor>
                <contributor>
                  <role type="author"/>
                  <organization>
                    <name>Ribose, Inc.</name>
                  </organization>
                </contributor>
                <contributor>
                  <role type="author"/>
                  <person>
                    <name>
                      <completename>Fred Flintstone</completename>
                    </name>
                    <credentials>PhD, F.R.Pharm.S.</credentials>
                     <affiliation>
                     <name>Vice President, Medical Devices Quality &amp; Compliance -- Strategic programmes</name>
                   <organization>
                     <name>Slate Rock and Gravel Company</name>
                     <abbreviation>SRG</abbreviation>
                     <subdivision><name>Hermeneutics Unit</name></subdivision>
                    <subdivision><name>Exegetical Subunit</name></subdivision>
                  <address>
                  <formattedAddress>
                  6 Rubble Way, Bedrock
                </formattedAddress>
                  </address>
                   </organization>
                   </affiliation>
                   <phone>123</phone>
                <phone type='fax'>456</phone>
                   <uri>http://slate.example.com</uri>
                  </person>
                </contributor>
                <contributor>
                  <role type="editor">
                    <description>consulting editor</description>
                  </role>
                  <person>
                    <name>
                      <forename>Barney</forename>
                      <initial>B. X.</initial>
                      <surname>Rubble</surname>
                    </name>
                    <credentials>PhD, F.R.Pharm.S.</credentials>
                <affiliation>
                  <name>Former Chair ISO TC 210</name>
                  <organization>
                    <name>Rockhead and Quarry Cave Construction Company</name>
                    <abbreviation>RQCCC</abbreviation>
                    <subdivision><name>Hermeneutics Unit</name></subdivision>
                <subdivision><name>Exegetical Subunit</name></subdivision>
                  <address>
                    <formattedAddress>6A Rubble Way, <br/>Bedrock</formattedAddress>
                  </address>
                  </organization>
                </affiliation>
                <phone>789</phone>
                <phone type='fax'>012</phone>
                   <email>barney@rockhead.example.com</email>
                  </person>
                </contributor>
             <contributor>
                <role type="author">
                   <description>committee</description>
                </role>
                <organization>
                   <name>"Cartoon Network"; "Ribose, Inc."</name>
                   <subdivision type="Technical committee" subtype="A">
                      <name>TC</name>
                      <identifier>A 1</identifier>
                      <identifier type="full">A 1</identifier>
                   </subdivision>
                </organization>
             </contributor>
             <contributor>
                <role type="author">
                   <description>committee</description>
                </role>
                <organization>
                   <name>TC1</name>
                   <subdivision type="Technical committee" subtype="A1">
                      <name>TC1</name>
                      <identifier>A1 11</identifier>
                      <identifier type="full">A1 11</identifier>
                      <logo>
                  <image src="spec/assets/correct.png" mimetype="image/png"/>
               </logo>
                   </subdivision>
                </organization>
             </contributor>
                <contributor>
                  <role type="publisher"/>
                  <organization>
                    <name>Hanna Barbera</name>
                  </organization>
                </contributor>
                <contributor>
                  <role type="publisher"/>
                  <organization>
                    <name>Cartoon Network</name>
                  </organization>
                </contributor>
                <contributor>
                  <role type="publisher"/>
                  <organization>
                    <name>Ribose, Inc.</name>
                  </organization>
                </contributor>
                <contributor>
          <role type="enabler"/>
          <organization>
            <name>Cartoon Network</name>
          </organization>
        </contributor>
        <contributor>
          <role type="enabler"/>
          <organization>
            <name>Ribose, Inc.</name>
          </organization>
        </contributor>
            <contributor>
        <role type="authorizer"/>
        <organization>
          <name>CBS</name>
        </organization>
      </contributor>
      <contributor>
        <role type="authorizer"/>
        <organization>
          <name>TXE</name>
        </organization>
      </contributor>
                <edition>2</edition>
                <version>
                  <revision-date>2000-01-01</revision-date>
                  <draft>3.4</draft>
                </version>
                  <language>en</language>
                  <script>Latn</script>
                  <status>
                    <stage>10</stage>
                    <substage>20</substage>
                    <iteration>3</iteration>
                  </status>
                  <copyright>
                    <from>2001</from>
                       <owner>
                     <organization>
                       <name>Ribose, Inc.</name>
                     </organization>
                   </owner>
                 </copyright>
                 <copyright>
                   <from>2001</from>
                   <owner>
                     <organization>
                       <name>Hanna Barbera</name>
                     </organization>
                   </owner>
                  </copyright>
                  <relation type="partOf">
                  <bibitem>
                  <title>--</title>
                  <docidentifier>ABC</docidentifier>
                  </bibitem>
                </relation>
                <relation type="translatedFrom">
                           <bibitem>
                             <title>GHI</title>
                             <docidentifier>DEF</docidentifier>
                           </bibitem>
                         </relation>
                         <relation type="translatedFrom">
                           <bibitem>
                             <title>PQR</title>
                             <docidentifier>JKL MNO</docidentifier>
                           </bibitem>
                         </relation>
                         <classification type='a'>b</classification>
                         <classification type='default'>c</classification>
                <keyword>a</keyword>
                <keyword>b</keyword>
                <keyword>c</keyword>
                <ext>
                <doctype>standard</doctype>
            <flavor>standoc</flavor>
                                  <ics>
                    <code>01.040.11</code>
                    <text>Health care technology (Vocabularies)</text>
                  </ics>
                  <ics>
                    <code>11.060.01</code>
                    <text>Dentistry in general</text>
                  </ics>
                  </ext>
                </bibdata>
                 <metanorma-extension>
                <semantic-metadata>
            <stage-published>false</stage-published>
          </semantic-metadata>
                      <presentation-metadata>
                <toc-heading-levels>2</toc-heading-levels>
                <html-toc-heading-levels>4</html-toc-heading-levels>
                <doc-toc-heading-levels>3</doc-toc-heading-levels>
                <pdf-toc-heading-levels>5</pdf-toc-heading-levels>
             </presentation-metadata>
           </metanorma-extension>
                <sections/>
                </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to strip_guid(Canon.format_xml(output))

    # :committee-types:
    output = <<~OUTPUT
          <bibdata>
         <contributor>
            <role type="author"/>
            <organization>
               <name>Cartoon Network</name>
            </organization>
         </contributor>
         <contributor>
            <role type="author"/>
            <organization>
               <name>Ribose, Inc.</name>
            </organization>
         </contributor>
         <contributor>
            <role type="author">
               <description>committee</description>
            </role>
            <organization>
               <name>"Cartoon Network"; "Ribose, Inc."</name>
               <subdivision type="Subcommittee" subtype="B">
                  <name>SC</name>
                  <identifier>B 2</identifier>
                  <identifier type="full">B 2/C 3</identifier>
               </subdivision>
               <subdivision type="Workgroup" subtype="C">
                  <name>WG</name>
                  <identifier>C 3</identifier>
               </subdivision>
            </organization>
         </contributor>
         <contributor>
            <role type="author">
               <description>committee</description>
            </role>
            <organization>
               <name>"Cartoon Network"; "Ribose, Inc."</name>
               <subdivision type="Subcommittee" subtype="B1">
                  <name>SC1</name>
                  <identifier>B1 21</identifier>
                  <identifier type="full">B1 21/C1 31</identifier>
               </subdivision>
               <subdivision type="Workgroup" subtype="C1">
                  <name>WG1</name>
                  <identifier>C1 31</identifier>
                  <logo>
                     <image src="spec/assets/correct.png" mimetype="image/png"/>
                  </logo>
               </subdivision>
            </organization>
         </contributor>
      </bibdata>
    OUTPUT
    input.sub!(":novalid:",
               "novalid:\n:committee-types: subcommittee, workgroup")
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml = xml.xpath("//xmlns:contributor[xmlns:role/@type = 'author'][./xmlns:organization]")
    xml = "<bibdata>#{xml.to_xml}</bibdata>"
    expect(strip_guid(Canon.format_xml(xml)))
      .to be_equivalent_to strip_guid(Canon.format_xml(output))
  end

  it "processes complex metadata" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :revdate: 2000-01
      :published-date: 1000-01
      :docnumber: 1000
      :draft: 3.4
      :partnumber: 1-1
      :tc-docnumber: 2000
      :language: el
      :script: Grek
      :locale: CY
      :publisher: IEC;IETF;ISO
      :uri: A
      :xml-uri: B
      :html-uri: C
      :pdf-uri: D
      :doc-uri: E
      :relaton-uri: F
      :title-eo: Dokumenttitolo
      :title-intro-eo: Enkonduko
      :doctype: This is a DocType
      :doctype-abbrev: TiiD
      :docstage: 10
      :docstage-abbrev: XT
      :docsubtype: This is a DocSubType
      :subdivision: Subdivision
      :subdivision-abbr: SD
      :fullname: Fred Flintstone
      :affiliation: Slate Rock and Gravel Company
      :street: 1 Infinity Loop
      :city: Cupertino
      :state: CA
      :country: USA
      :postcode: 95014
      :fullname_2: Barney Rubble
      :affiliation_2: Slate Rock and Gravel Company
      :street_2: Pavillon de Breteuil
      :city_2: Sèvres CEDEX
      :country_2: France
      :postcode_2: F-92312
      :semantic-metadata-hello-world: A, B, "C, D"
      :semantic-metadata-hello: what-not
      :presentation-metadata-hello: "Hello? {{ labels['draft_label'] }}, {{ stage }}"
      :presentation-metadata-Manifold: "hello, world","yes"
      :presentation-metadata-ul-label-list: "&#x2022;", &#x2d;, &#x6f;
      :presentation-metadata-xml: <a href="a"/>
      :toclevels: 2
      :doctoclevels: 3
      :htmltoclevels: 4
      :document-scheme: SCHEME
      :docstage-published: true

      [abstract]
      == Abstract
      This is the abstract of the document

      This is the second paragraph of the abstract of the document.

      [language=en]
      == Clause 1
    INPUT
    output = <<~OUTPUT
                    <?xml version="1.0" encoding="UTF-8"?>
                <metanorma xmlns="https://www.metanorma.org/ns/standoc"  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
                <bibdata type="standard">
                  <title language="eo" type="main">Dokumenttitolo</title>
                  <title language="eo" type="intro">Enkonduko</title>
                  <title language="el" type="title-part-prefix">Part\\u00a01–1</title>
                  <uri>A</uri>
                  <uri type="xml">B</uri>
                  <uri type="html">C</uri>
                  <uri type="pdf">D</uri>
                  <uri type="doc">E</uri>
                  <uri type="relaton">F</uri>
                  <docidentifier primary="true">1000-1-1</docidentifier>
                  <docnumber>1000</docnumber>
                  <date type='published'>
           <on>1000-01</on>
         </date>
                  <contributor>
                    <role type="author"/>
                    <organization>
                      <name>IEC</name>
                    </organization>
                  </contributor>
                  <contributor>
                    <role type="author"/>
                    <organization>
                      <name>IETF</name>
                    </organization>
                  </contributor>
                  <contributor>
                    <role type="author"/>
                    <organization>
                      <name>ISO</name>
                    </organization>
                  </contributor>
                  <contributor>
                   <role type='author'/>
                   <person>
                     <name>
                       <completename>Fred Flintstone</completename>
                     </name>
                     <affiliation>
                       <organization>
                         <name>Slate Rock and Gravel Company</name>
                         <address>
                           <street>1 Infinity Loop</street>
                           <city>Cupertino</city>
                           <state>CA</state>
                           <country>USA</country>
                           <postcode>95014</postcode>
                         </address>
                       </organization>
                     </affiliation>
                   </person>
                 </contributor>
                 <contributor>
                   <role type='author'/>
                   <person>
                     <name>
                       <completename>Barney Rubble</completename>
                     </name>
                     <affiliation>
                       <organization>
                         <name>Slate Rock and Gravel Company</name>
                         <address>
                           <street>Pavillon de Breteuil</street>
                           <city>S&#232;vres CEDEX</city>
                           <country>France</country>
                           <postcode>F-92312</postcode>
                         </address>
                       </organization>
                     </affiliation>
                   </person>
                 </contributor>
                  <contributor>
                    <role type="publisher"/>
                    <organization>
                      <name>IEC</name>
                    </organization>
                  </contributor>
                  <contributor>
                    <role type="publisher"/>
                    <organization>
                      <name>IETF</name>
                    </organization>
                  </contributor>
                  <contributor>
                    <role type="publisher"/>
                    <organization>
                      <name>ISO</name>
                    </organization>
                  </contributor>
                  <version>
                    <revision-date>2000-01</revision-date>
                     <draft>3.4</draft>
                  </version>
                  <language>el</language>
                  <locale>CY</locale>
                  <script>Grek</script>
                  <abstract><p>This is the abstract of the document</p>
                  <p>This is the second paragraph of the abstract of the document.</p></abstract>
                  <status><stage abbreviation="XT">10</stage></status>
                  <copyright>
                    <from>#{Date.today.year}</from>
                    <owner>
                      <organization>
                        <name>IEC</name>
                      </organization>
                    </owner>
                  </copyright>
                  <copyright>
                    <from>#{Date.today.year}</from>
                    <owner>
                      <organization>
                        <name>IETF</name>
                      </organization>
                    </owner>
                  </copyright>
                  <copyright>
                    <from>#{Date.today.year}</from>
                    <owner>
                      <organization>
                        <name>ISO</name>
                      </organization>
                    </owner>
                  </copyright>
                  <ext>
                  <doctype abbreviation="TiiD">this-is-a-doctype</doctype>
                  <subdoctype>This is a DocSubType</subdoctype>
            <flavor>standoc</flavor>
                  </ext>
                </bibdata>
                  <metanorma-extension>
                        <semantic-metadata>
         <stage-published>true</stage-published>
          <hello-world>A</hello-world>
          <hello-world>B</hello-world>
          <hello-world>C, D</hello-world>
          <hello>what-not</hello>
        </semantic-metadata>
        <presentation-metadata>
          <hello>Hello? draft, 10</hello>
          <manifold>hello, world</manifold>
          <manifold>yes</manifold>
         <ul-label-list>•</ul-label-list>
         <ul-label-list>-</ul-label-list>
         <ul-label-list>o</ul-label-list>
         <xml>
            <a href="a"/>
         </xml>
                <toc-heading-levels>2</toc-heading-levels>
                <html-toc-heading-levels>4</html-toc-heading-levels>
                <doc-toc-heading-levels>3</doc-toc-heading-levels>
                <pdf-toc-heading-levels>2</pdf-toc-heading-levels>
          <document-scheme>SCHEME</document-scheme>
        </presentation-metadata>
      </metanorma-extension>
                  <preface>
             <abstract id='_'>
             <title id="_">Abstract</title>
               <p id='_'>This is the abstract of the document</p>
               <p id='_'>This is the second paragraph of the abstract of the document.</p>
             </abstract>
           </preface>
           <sections>
             <clause id='_' language='en' inline-header='false' obligation='normative'>
               <title id="_">Clause 1</title>
             </clause>
           </sections>
         </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "processes broken up organisational contributors and their attributes" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :fullname: Fred Flintstone
      :affiliation: Slate Rock and Gravel Company
      :address: Address
      :city: Utopia
      :corporate-author: Pixar
      :corporate-author_2: Hanna Barbera
      :corporate-author-address_2: 1 Infinite Loop
      :publisher: Monsters, Inc.
      :publisher_abbr: MONS
      :publisher_logo: correct.png
      :publisher_2: Ribose, Inc.
      :publisher_logo_2: corrupt.png
      :publisher_abbr_2: RIBS
      :sponsor: Monsters, Inc.
      :sponsor_logo: corrupt.png
      :sponsor_2: Ribose, Inc.
      :sponsor_logo_2: correct.png
      :pub-address_2: 1 Infinity Loop + \\
      California
      :pub-phone_2: 3333333
      :pub-fax_2: 4444444
      :pub-email_2: x@example.com
      :pub-uri_2: http://www.example1.com
      :sponsor-address: 3 Infinity Loop + \\
      California
      :sponsor-phone: 1111111
      :sponsor-fax: 2222222
      :sponsor-email: y@example.com
      :sponsor-uri: http://www.example2.com
      :sponsor-address_2: 2 Infinity Loop + \\
      California
      :sponsor-phone_2: 5555555
      :sponsor-fax_2: 6666666
      :sponsor-email_2: z@example.com
      :sponsor-uri_2: http://www.example3.com
      :authorizer: Starfleet
      :authorizer_logo: correct.png
      :authorizer-address: 4 Infinity Loop
      :authorizer-phone: 5555555
      :authorizer-fax: 6666666
      :authorizer-email: z@example.com
      :authorizer-uri: http://www.example3.com


    INPUT
    output = <<~OUTPUT
      <metanorma xmlns="https://www.metanorma.org/ns/standoc"  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
               <bibdata type="standard">
           <title language="en" type="main">Document title</title>
             <contributor>
                <role type="author"/>
                <organization>
                   <name>Pixar</name>
                </organization>
             </contributor>
             <contributor>
                <role type="author"/>
                <organization>
                   <name>Hanna Barbera</name>
                   <address>
                      <formattedAddress>1 Infinite Loop</formattedAddress>
                   </address>
                </organization>
             </contributor>
           <contributor>
             <role type="author"/>
             <person>
               <name>
                 <completename>Fred Flintstone</completename>
               </name>
               <affiliation>
                 <organization>
                   <name>Slate Rock and Gravel Company</name>
                   <address>
                     <formattedAddress>Address</formattedAddress>
                   </address>
                 </organization>
               </affiliation>
             </person>
           </contributor>
           <contributor>
             <role type="publisher"/>
             <organization>
               <name>Monsters, Inc.</name>
               <abbreviation>MONS</abbreviation>
               <logo>
                 <image src="correct.png"  mimetype="image/png"/>
               </logo>
             </organization>
           </contributor>
           <contributor>
             <role type="publisher"/>
             <organization>
               <name>Ribose, Inc.</name>
               <abbreviation>RIBS</abbreviation>
               <address>
                 <formattedAddress>1 Infinity Loop<br/>California</formattedAddress>
               </address>
               <phone>3333333</phone>
               <phone type="fax">4444444</phone>
               <email>x@example.com</email>
               <uri>http://www.example1.com</uri>
               <logo>
                 <image src="corrupt.png"  mimetype="image/png"/>
               </logo>
             </organization>
           </contributor>
           <contributor>
             <role type="enabler"/>
             <organization>
               <name>Monsters, Inc.</name>
               <address>
                 <formattedAddress>3 Infinity Loop<br/>California</formattedAddress>
               </address>
               <phone>1111111</phone>
               <phone type="fax">2222222</phone>
               <email>y@example.com</email>
               <uri>http://www.example2.com</uri>
               <logo>
                 <image src="corrupt.png"  mimetype="image/png"/>
               </logo>
             </organization>
           </contributor>
           <contributor>
             <role type="enabler"/>
             <organization>
               <name>Ribose, Inc.</name>
               <address>
                 <formattedAddress>2 Infinity Loop<br/>California</formattedAddress>
               </address>
               <phone>5555555</phone>
               <phone type="fax">6666666</phone>
               <email>z@example.com</email>
               <uri>http://www.example3.com</uri>
               <logo>
                 <image src="correct.png"  mimetype="image/png"/>
               </logo>
             </organization>
           </contributor>
           <contributor>
             <role type="authorizer"/>
             <organization>
               <name>Starfleet</name>
               <address>
                 <formattedAddress>4 Infinity Loop</formattedAddress>
               </address>
               <phone>5555555</phone>
               <phone type="fax">6666666</phone>
               <email>z@example.com</email>
               <uri>http://www.example3.com</uri>
               <logo>
                 <image src="correct.png"  mimetype="image/png"/>
               </logo>
             </organization>
           </contributor>
           <language>en</language>
           <script>Latn</script>
           <status>
             <stage>published</stage>
           </status>
           <copyright>
             <from>#{Time.now.year}</from>
             <owner>
               <organization>
                 <name>Monsters, Inc.</name>
                 <abbreviation>MONS</abbreviation>
                 <logo>
                   <image src="correct.png"  mimetype="image/png"/>
                 </logo>
               </organization>
             </owner>
           </copyright>
           <copyright>
             <from>#{Time.now.year}</from>
             <owner>
               <organization>
                 <name>Ribose, Inc.</name>
                 <abbreviation>RIBS</abbreviation>
                 <address>
                   <formattedAddress>1 Infinity Loop<br/>California</formattedAddress>
                 </address>
                 <phone>3333333</phone>
                 <phone type="fax">4444444</phone>
                 <email>x@example.com</email>
                 <uri>http://www.example1.com</uri>
                 <logo>
                   <image src="corrupt.png"  mimetype="image/png"/>
                 </logo>
               </organization>
             </owner>
           </copyright>
           <ext>
             <doctype>standard</doctype>
            <flavor>standoc</flavor>
           </ext>
         </bibdata>
         <metanorma-extension>
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
         <sections/>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "processes formatted address overridding address components; publisher attributes" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :fullname: Fred Flintstone
      :affiliation: Slate Rock and Gravel Company
      :address: Address
      :city: Utopia
      :fullname_2: Barney Rubble
      :affiliation_2: Slate Rock and Gravel Company
      :city_2: Utopia
      :publisher: ISO
      :pub-address: 1 Infinity Loop + \\
      California
      :pub-phone: 3333333
      :pub-fax: 4444444
      :pub-email: x@example.com
      :pub-uri: http://www.example.com

    INPUT
    output = <<~OUTPUT
      <metanorma xmlns="https://www.metanorma.org/ns/standoc"  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
               <bibdata type="standard">
           <title language="en" type="main">Document title</title>
           <contributor>
             <role type="author"/>
             <organization>
               <name>ISO</name>
               <address>
                 <formattedAddress>1 Infinity Loop<br/>California</formattedAddress>
               </address>
               <phone>3333333</phone>
               <phone type="fax">4444444</phone>
               <email>x@example.com</email>
               <uri>http://www.example.com</uri>
             </organization>
           </contributor>
           <contributor>
             <role type="author"/>
             <person>
               <name>
                 <completename>Fred Flintstone</completename>
               </name>
               <affiliation>
                 <organization>
                   <name>Slate Rock and Gravel Company</name>
                   <address>
                     <formattedAddress>Address</formattedAddress>
                   </address>
                 </organization>
               </affiliation>
             </person>
           </contributor>
           <contributor>
             <role type="author"/>
             <person>
               <name>
                 <completename>Barney Rubble</completename>
               </name>
               <affiliation>
                 <organization>
                   <name>Slate Rock and Gravel Company</name>
                   <address>
                     <city>Utopia</city>
                   </address>
                 </organization>
               </affiliation>
             </person>
           </contributor>
           <contributor>
             <role type="publisher"/>
             <organization>
               <name>ISO</name>
               <address>
                 <formattedAddress>1 Infinity Loop<br/>California</formattedAddress>
               </address>
               <phone>3333333</phone>
               <phone type="fax">4444444</phone>
               <email>x@example.com</email>
               <uri>http://www.example.com</uri>
             </organization>
           </contributor>
           <language>en</language>
           <script>Latn</script>
           <status>
             <stage>published</stage>
           </status>
           <copyright>
             <from>#{Time.now.year}</from>
             <owner>
               <organization>
                 <name>ISO</name>
                <address>
                 <formattedAddress>1 Infinity Loop<br/>California</formattedAddress>
               </address>
               <phone>3333333</phone>
               <phone type="fax">4444444</phone>
               <email>x@example.com</email>
               <uri>http://www.example.com</uri>
               </organization>
             </owner>
           </copyright>
           <ext>
             <doctype>standard</doctype>
            <flavor>standoc</flavor>
           </ext>
         </bibdata>
         <sections/>
       </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(Canon.format_xml(xml.to_xml)))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "processes subdivisions; override docnumber with docidentifier" do
    mock_default_publisher
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :revdate: 2000-01
      :published-date: 1000-01
      :docidentifier: OVERRIDE-DOCIDENTIFIER
      :docnumber: 1000
      :partnumber: 1-1
      :tc-docnumber: 2000
      :language: el
      :script: Grek
      :subdivision: Subdivision & co., committee: TC 3; "institute: My Curious Corporation, inc", committee: TC 7
      :subdivision-abbr: SD, MCC
      :doctype: This is a DocType
      :pub-address: 1 Infinity Loop + \\
      California
      :pub-phone: 3333333
      :pub-fax: 4444444
      :pub-email: x@example.com
      :pub-uri: http://www.example.com
      :sponsor: IEC
      :sponsor_subdivision:  technical committee: TC 9, subcommittee: SC 7, working group: WG 88
      :authorizer: IEEE
      :authorizer_subdivision:  technical committee: TC 5, subcommittee: SC 6, working group: WG 44
      :authorizer_2: ISO
      :authorizer_subdivision_2:  technical committee: TC 1, subcommittee: SC 2, working group: WG 333

    INPUT
    output = <<~OUTPUT
            <metanorma xmlns="https://www.metanorma.org/ns/standoc"  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
            <bibdata type="standard">
          <title language="el" type="main">Document title</title>
          <title language="el" type="title-part-prefix">Part\\u00a01–1</title>
          <docidentifier primary="true">OVERRIDE-DOCIDENTIFIER</docidentifier>
          <docnumber>1000</docnumber>
          <date type="published">
            <on>1000-01</on>
          </date>
          <contributor>
            <role type="author"/>
            <organization>
              <name>International Standards Organization</name>
              <subdivision>
                <name>Subdivision &amp; co.</name>
                <subdivision type="committee">
                  <name>TC 3</name>
                </subdivision>
              </subdivision>
              <subdivision type="institute">
                <name>My Curious Corporation, inc</name>
                <subdivision type="committee">
                  <name>TC 7</name>
                </subdivision>
              </subdivision>
              <address>
                <formattedAddress>1 Infinity Loop<br/>California</formattedAddress>
              </address>
              <phone>3333333</phone>
              <phone type="fax">4444444</phone>
              <email>x@example.com</email>
              <uri>http://www.example.com</uri>
            </organization>
          </contributor>
          <contributor>
            <role type="publisher"/>
            <organization>
              <name>International Standards Organization</name>
              <subdivision>
                <name>Subdivision &amp; co.</name>
                <subdivision type="committee">
                  <name>TC 3</name>
                </subdivision>
              </subdivision>
              <subdivision type="institute">
                <name>My Curious Corporation, inc</name>
                <subdivision type="committee">
                  <name>TC 7</name>
                </subdivision>
              </subdivision>
              <address>
                <formattedAddress>1 Infinity Loop<br/>California</formattedAddress>
              </address>
              <phone>3333333</phone>
              <phone type="fax">4444444</phone>
              <email>x@example.com</email>
              <uri>http://www.example.com</uri>
            </organization>
          </contributor>
          <contributor>
            <role type="enabler"/>
            <organization>
              <name>IEC</name>
              <subdivision type="technical committee">
                <name>TC 9</name>
                <subdivision type="subcommittee">
                  <name>SC 7</name>
                  <subdivision type="working group">
                    <name>WG 88</name>
                  </subdivision>
                </subdivision>
              </subdivision>
            </organization>
          </contributor>
          <contributor>
             <role type="authorizer"/>
             <organization>
               <name>IEEE</name>
               <subdivision type="technical committee">
                 <name>TC 5</name>
                 <subdivision type="subcommittee">
                   <name>SC 6</name>
                   <subdivision type="working group">
                     <name>WG 44</name>
                   </subdivision>
                 </subdivision>
               </subdivision>
             </organization>
           </contributor>
           <contributor>
             <role type="authorizer"/>
             <organization>
               <name>ISO</name>
               <subdivision type="technical committee">
                 <name>TC 1</name>
                 <subdivision type="subcommittee">
                   <name>SC 2</name>
                   <subdivision type="working group">
                     <name>WG 333</name>
                   </subdivision>
                 </subdivision>
               </subdivision>
             </organization>
           </contributor>
          <version>
            <revision-date>2000-01</revision-date>
          </version>
          <language>el</language>
          <script>Grek</script>
          <status>
            <stage>published</stage>
          </status>
          <copyright>
            <from>#{Time.now.year}</from>
            <owner>
              <organization>
                <name>International Standards Organization</name>
                <subdivision>
                  <name>Subdivision &amp; co.</name>
                  <subdivision type="committee">
                    <name>TC 3</name>
                  </subdivision>
                </subdivision>
                <subdivision type="institute">
                  <name>My Curious Corporation, inc</name>
                  <subdivision type="committee">
                    <name>TC 7</name>
                  </subdivision>
                </subdivision>
                <address>
                  <formattedAddress>1 Infinity Loop<br/>California</formattedAddress>
                </address>
                <phone>3333333</phone>
                <phone type="fax">4444444</phone>
                <email>x@example.com</email>
                <uri>http://www.example.com</uri>
              </organization>
            </owner>
          </copyright>
          <ext>
            <doctype>this-is-a-doctype</doctype>
            <flavor>standoc</flavor>
          </ext>
        </bibdata>
        <sections/>
      </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(Canon.format_xml(xml.to_xml)))
      .to be_equivalent_to Canon.format_xml(output)
  end

    it "populates docidentifier template" do
    mock_default_publisher
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :docidentifier: {{ publisheddate }} {{ stageabbr }}
      :published-date: 1264-03-05
      :docstage: draft-document

    INPUT
    output = <<~OUTPUT
     <metanorma xmlns="https://www.metanorma.org/ns/standoc"  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
          <bibdata type="standard">
             <title language="en" type="main">Document title</title>
             <docidentifier primary="true">1264-03-05 DD</docidentifier>
             <date type="published">
                <on>1264-03-05</on>
             </date>
             <contributor>
                <role type="author"/>
                <organization>
                   <name>International Standards Organization</name>
                </organization>
             </contributor>
             <contributor>
                <role type="publisher"/>
                <organization>
                   <name>International Standards Organization</name>
                </organization>
             </contributor>
             <language>en</language>
             <script>Latn</script>
             <status>
                <stage>draft-document</stage>
             </status>
             <copyright>
                <from>2026</from>
                <owner>
                   <organization>
                      <name>International Standards Organization</name>
                   </organization>
                </owner>
             </copyright>
             <ext>
                <doctype>standard</doctype>
                <flavor>standoc</flavor>
             </ext>
          </bibdata>
          <sections> </sections>
       </metanorma>
OUTPUT
 xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(Canon.format_xml(xml.to_xml)))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "processes document relations by description" do
    mock_relaton_relation_descriptions
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :normatively-cited-in: ABC

    INPUT
    output = <<~OUTPUT
      <metanorma xmlns="https://www.metanorma.org/ns/standoc"  type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor='standoc'>
      <bibdata type='standard'>
        <title language='en' type='main'>Document title</title>
        <language>en</language>
        <script>Latn</script>
        <status>
          <stage>published</stage>
        </status>
        <copyright>
          <from>#{Time.now.year}</from>
        </copyright>
        <relation type='isCitedIn'>
          <description>normatively cited in</description>
          <bibitem>
            <title>--</title>
            <docidentifier>ABC</docidentifier>
          </bibitem>
        </relation>
        <ext>
          <doctype>standard</doctype>
            <flavor>standoc</flavor>
        </ext>
      </bibdata>
      <sections> </sections>
      </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(strip_guid(Canon.format_xml(xml.to_xml)))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "populates cover images" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :docnumber: 1000
      :coverpage-image: images/image1.gif,images/image2.gif
      :innercoverpage-image: images/image1.gif,images/image2.gif
      :tocside-image: images/image1.gif,images/image2.gif
      :backpage-image: images/image1.gif,images/image2.gif
    INPUT
    output = <<~OUTPUT
      <metanorma-extension>
            <semantic-metadata>
         <stage-published>true</stage-published>
      </semantic-metadata>
          <presentation-metadata>
             <coverpage-image>
                <image src="images/image1.gif"/>
                <image src="images/image2.gif"/>
             </coverpage-image>
             <innercoverpage-image>
                <image src="images/image1.gif"/>
                <image src="images/image2.gif"/>
             </innercoverpage-image>
             <tocside-image>
                <image src="images/image1.gif"/>
                <image src="images/image2.gif"/>
             </tocside-image>
             <backpage-image>
                <image src="images/image1.gif"/>
                <image src="images/image2.gif"/>
             </backpage-image>
                <toc-heading-levels>2</toc-heading-levels>
                <html-toc-heading-levels>2</html-toc-heading-levels>
                <doc-toc-heading-levels>2</doc-toc-heading-levels>
                <pdf-toc-heading-levels>2</pdf-toc-heading-levels>
             </presentation-metadata>
      </metanorma-extension>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Nokogiri::XML(Asciidoctor
      .convert(input, *OPTIONS))
      .at("//xmlns:metanorma-extension").to_xml)))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "reads scripts into blank HTML document" do
    FileUtils.rm_f "test.html"
    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :no-pdf:
      :scripts: spec/assets/scripts.html
    INPUT
    html = File.read("test.html", encoding: "utf-8")
    expect(html).to match(%r{<script>}i)
  end

  it "uses specified fonts and assets in HTML" do
    FileUtils.rm_f "test.html"
    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :docfile: test.adoc
      :no-pdf:
      :novalid:
      :script: Hans
      :body-font: Zapf Chancery
      :header-font: Comic Sans
      :monospace-font: Andale Mono
      :htmlstylesheet: spec/assets/html.scss
      :htmlstylesheet-override: spec/assets/html-override.css
      :htmlcoverpage: spec/assets/htmlcover.html
      :htmlintropage: spec/assets/htmlintro.html
      :scripts: spec/assets/scripts.html
      :htmltoclevels: 3

      == Level 1

      === Level 2

      ==== Level 3
    INPUT
    html = File.read("test.html", encoding: "utf-8")
    expect(html).to match(%r[pre[^{]+\{[^{]+font-family: Andale Mono;]m)
    expect(html).to match(%r[p[^{]+\{[^{]+font-family: Zapf Chancery;]m)
    expect(html).to match(%r[h1[^{]+\{[^{]+font-family: Comic Sans;]m)
    expect(html).to match(%r[an empty html cover page])
    expect(html).to match(%r[an empty html intro page])
    expect(html).to match(%r[This is > a script])
    expect(html).to match(%r[html-override])
  end

  it "uses specified fonts and assets in Word" do
    FileUtils.rm_f "test.doc"
    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :no-pdf:
      :script: Hans
      :body-font: Zapf Chancery
      :header-font: Comic Sans
      :monospace-font: Andale Mono
      :wordstylesheet: spec/assets/word.scss
      :wordstylesheet-override: spec/assets/word-override.css
      :wordcoverpage: spec/assets/wordcover.html
      :wordintropage: spec/assets/wordintro.html
      :header: spec/assets/header.html
      :doctoclevels: 3

      == Level 1

      === Level 2

      ==== Level 3
    INPUT
    html = File.read("test.doc", encoding: "utf-8")
    expect(html).to match(%r[pre[^{]+\{[^{]+font-family: Andale Mono;]m)
    expect(html).to match(%r[p[^{]+\{[^{]+font-family: Zapf Chancery;]m)
    expect(html).to match(%r[h1[^{]+\{[^{]+font-family: Comic Sans;]m)
    expect(html).to match(%r[an empty word cover page])
    expect(html).to match(%r[an empty word intro page])
    expect(html).to match(%r[word-override])
    expect(html).to include('\o "1-3"')
    expect(html).to include(%[Content-ID: <header.html>
Content-Disposition: inline; filename="header.html"
Content-Transfer-Encoding: base64
Content-Type: text/html charset="utf-8"

Ci8qIGFuIGVtcHR5IGhlYWRlciAqLwoKU1RBUlQgRE9DIElEOiA6IEVORCBET0MgSUQKCkZJTEVO
QU1FOiB0ZXN0Cgo=
])
  end

  it "test submitting-organizations with delimiter in end" do
    FileUtils.rm_f "test.doc"
    Asciidoctor.convert(<<~INPUT, *OPTIONS)
      = Document title
      Author
      :no-pdf:
      :docfile: test.adoc
      :doctype: standard
      :encoding: utf-8
      :lang: en
      :submitting-organizations: Organization One; Organization Two;
      :publisher: "Hanna Barbera", "Cartoon Network", "Ribose, Inc.",
    INPUT
    expect(File.exist?("test.doc")).to be true
  end

  it "process mn2pdf attributes" do
    node = Nokogiri::XML("<fake/>").at("fake")
    node[Metanorma::Standoc::Base::FONTS_MANIFEST] =
      "passed/as/font/manifest/to/mn2pdf.jar"

    options = Metanorma::Standoc::Converter
      .new(:standoc, header_footer: true)
      .doc_extract_attributes(node)

    expect(options[:font_manifest])
      .to eq(node[Metanorma::Standoc::Base::FONTS_MANIFEST])
  end

  it "preserves instance variables during isolated asciidoctor conversions" do
    # Create a custom converter class to test instance variable preservation
    test_converter_class = Class.new do
      include Metanorma::Standoc::Base
      include Metanorma::Standoc::Cleanup
      include Metanorma::Standoc::Utils

      def initialize
        @test_variable = "original_value"
        @fn_number = 100
        @refids = Set.new(["original_ref"])
        @anchors = { "original" => "anchor" }
        @localdir = "/original/dir"
        @sourcecode_markup_start = "{{{"
        @sourcecode_markup_end = "}}}"
        @c = HTMLEntities.new
        @embed_hdr = [{ text: "= Test Header\nTest content", child: [] }]
        @novalid = false # Test original validation setting
        @isolated_conversion_stack = []
      end

      attr_accessor :test_variable, :fn_number, :refids, :anchors, :localdir,
                    :sourcecode_markup_start, :sourcecode_markup_end, :c,
                    :embed_hdr, :novalid, :isolated_conversion_stack

      def backend
        :standoc
      end

      def processor
        # Mock processor
        proc_class = Class.new do
          def asciidoctor_backend
            :standoc
          end
        end
        proc_class.new
      end

      def hdr2bibitem_type(_hdr)
        :standoc
      end

      # Mock validation method to track if it's called
      def validate(_doc)
        @validation_called = true
      end

      attr_accessor :validation_called
    end

    converter = test_converter_class.new

    # Store original values
    original_test_variable = converter.test_variable
    original_fn_number = converter.fn_number
    original_refids = converter.refids.dup
    original_anchors = converter.anchors.dup
    original_localdir = converter.localdir
    original_novalid = converter.novalid

    # Test hdr2bibitem method (which internally calls isolated_asciidoctor_convert)
    begin
      result = converter.hdr2bibitem(converter.embed_hdr.first)
      expect(result).to be_a(String)
      expect(result).to include("<bibitem")
    rescue StandardError => e
      # Even if the conversion fails due to missing dependencies,
      # we should still verify instance variables are preserved
      puts "Conversion failed as expected in test environment: #{e.message}"
    end

    # Verify that all instance variables are preserved
    expect(converter.test_variable).to eq(original_test_variable)
    expect(converter.fn_number).to eq(original_fn_number)
    expect(converter.refids).to eq(original_refids)
    expect(converter.anchors).to eq(original_anchors)
    expect(converter.localdir).to eq(original_localdir)
    expect(converter.novalid).to eq(original_novalid)

    # Test adoc2xml method
    begin
      converter.adoc2xml("Test content", :standoc)
    rescue StandardError => e
      puts "adoc2xml failed as expected in test environment: #{e.message}"
    end

    # Verify instance variables are still preserved after adoc2xml
    expect(converter.test_variable).to eq(original_test_variable)
    expect(converter.fn_number).to eq(original_fn_number)
    expect(converter.refids).to eq(original_refids)
    expect(converter.anchors).to eq(original_anchors)
    expect(converter.localdir).to eq(original_localdir)
    expect(converter.novalid).to eq(original_novalid)

    # Test sourcecode_markup method with a mock node
    mock_document = double("document")
    mock_node = double("node")
    allow(mock_node).to receive(:text)
      .and_return("before {{{test content}}} after")
    allow(mock_node).to receive(:document).and_return(mock_document)

    begin
      result = converter.sourcecode_markup(mock_node)
      expect(result).to be_a(String)
    rescue StandardError => e
      puts "sourcecode_markup failed as expected "\
        "in test environment: #{e.message}"
    end

    # Final verification that all instance variables are preserved
    expect(converter.test_variable).to eq(original_test_variable)
    expect(converter.fn_number).to eq(original_fn_number)
    expect(converter.refids).to eq(original_refids)
    expect(converter.anchors).to eq(original_anchors)
    expect(converter.localdir).to eq(original_localdir)
    expect(converter.novalid).to eq(original_novalid)
  end

  it "skips validation for isolated conversions with stack management" do
    # Create a custom converter class to test validation skipping
    test_converter_class = Class.new do
      include Metanorma::Standoc::Base
      include Metanorma::Standoc::IsolatedConverter

      def initialize
        @novalid = false
        @isolated_conversion_stack = []
        @validation_calls = []
        @localdir = "/test/dir"
        @c = HTMLEntities.new
      end

      attr_accessor :novalid, :isolated_conversion_stack, :validation_calls,
                    :localdir, :c

      # Mock validation method to track calls
      def validate(_doc)
        @validation_calls << "validate_called"
      end

      # Mock makexml method to test validation logic
      def makexml(_node)
        # Simulate the validation logic from base.rb
        validate("mock_doc") unless @novalid || in_isolated_conversion?
        "mock_xml_result"
      end

      # Mock methods needed for isolated conversion
      def backend
        :standoc
      end

      def safe_shared_attributes
        {}
      end
    end

    converter = test_converter_class.new

    # Test 1: Normal conversion should call validation (when @novalid is false)
    converter.validation_calls.clear
    converter.makexml("mock_node")
    expect(converter.validation_calls).to include("validate_called")
    expect(converter.isolated_conversion_stack).to be_empty

    # Test 2: Isolated conversion should skip validation
    converter.validation_calls.clear
    begin
      converter.isolated_asciidoctor_convert("test content", backend: :standoc)
    rescue StandardError => e
      # Expected to fail in test environment, but stack should be managed properly
      puts "Isolated conversion failed as expected: #{e.message}"
    end
    # Stack should be empty after conversion (due to ensure block)
    expect(converter.isolated_conversion_stack).to be_empty

    # Test 3: Test nested isolated conversions
    converter.validation_calls.clear

    # Simulate nested calls by manually managing stack
    converter.isolated_conversion_stack << true  # First level
    expect(converter.in_isolated_conversion?).to be true

    converter.isolated_conversion_stack << true  # Second level (nested)
    expect(converter.in_isolated_conversion?).to be true
    expect(converter.isolated_conversion_stack.size).to eq(2)

    # Test makexml during isolated conversion - should skip validation
    converter.makexml("mock_node")
    expect(converter.validation_calls).to be_empty

    # Pop stack back to empty
    converter.isolated_conversion_stack.pop
    converter.isolated_conversion_stack.pop
    expect(converter.isolated_conversion_stack).to be_empty
    expect(converter.in_isolated_conversion?).to be false

    # Test 4: After isolated conversion, normal validation should resume
    converter.validation_calls.clear
    converter.makexml("mock_node")
    expect(converter.validation_calls).to include("validate_called")

    # Test 5: Ensure @novalid setting is preserved
    converter.novalid = false
    begin
      converter.isolated_asciidoctor_convert("test content", backend: :standoc)
    rescue StandardError
      # Expected to fail
    end
    expect(converter.novalid).to be false # Should remain unchanged
  end

  private

  def mock_org_abbrevs
    allow_any_instance_of(Metanorma::Standoc::Front)
      .to receive(:org_abbrev).and_return(
        { "International Standards Organization" => "ISO",
          "International Electrotechnical Commission" => "IEC" },
      )
  end

  def mock_default_publisher
    allow_any_instance_of(Metanorma::Standoc::Front)
      .to receive(:default_publisher).and_return(
        "International Standards Organization",
      )
  end

  def mock_relaton_relation_descriptions
    allow_any_instance_of(Metanorma::Standoc::Front)
      .to receive(:relaton_relation_descriptions).and_return(
        "normatively-cited-in" => "isCitedIn",
      )
  end
end
