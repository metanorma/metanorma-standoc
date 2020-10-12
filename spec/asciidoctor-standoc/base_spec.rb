require "spec_helper"
require "fileutils"

RSpec.describe Asciidoctor::Standoc do
  it "has a version number" do
    expect(Metanorma::Standoc::VERSION).not_to be nil
  end

  it "processes a blank document" do
    expect(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)).to be_equivalent_to <<~"OUTPUT"
    #{ASCIIDOC_BLANK_HDR}
    INPUT
    #{BLANK_HDR}
<sections/>
</standard-document>
    OUTPUT
  end

  it "converts a blank document" do
    FileUtils.rm_f "test.doc"
    expect(xmlpp(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
    INPUT
    #{BLANK_HDR}
<sections/>
</standard-document>
    OUTPUT
    expect(File.exist?("test.doc")).to be true
    expect(File.exist?("htmlstyle.css")).to be false
  end

    it "processes publisher abbreviations" do
    mock_org_abbrevs
    expect(xmlpp(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :publisher: International Electrotechnical Commission,IETF,ISO
INPUT
<standard-document xmlns='https://www.metanorma.org/ns/standoc' type='semantic' version='#{Metanorma::Standoc::VERSION}'>
  <bibdata type='standard'>
    <title language='en' format='text/plain'>Document title</title>
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
      <from>2020</from>
      <owner>
        <organization>
          <name>International Electrotechnical Commission</name>
          <abbreviation>IEC</abbreviation>
        </organization>
      </owner>
    </copyright>
    <copyright>
      <from>2020</from>
      <owner>
        <organization>
          <name>IETF</name>
        </organization>
      </owner>
    </copyright>
    <copyright>
      <from>2020</from>
      <owner>
        <organization>
          <name>International Standards Organization</name>
          <abbreviation>ISO</abbreviation>
        </organization>
      </owner>
    </copyright>
    <ext>
      <doctype>article</doctype>
    </ext>
  </bibdata>
  <sections> </sections>
</standard-document>
OUTPUT
  end

  it "processes default metadata" do
    expect(xmlpp(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
      :draft: 3.4
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
      :subcommittee_2: SC1
      :subcommittee-number_2: 21
      :subcommittee-type_2: B1
      :workgroup_2: WG1
      :workgroup-number_2: 31
      :workgroup-type_2: C1
      :secretariat: SECRETARIAT
      :copyright-year: 2001
      :docstage: 10
      :docsubstage: 20
      :iteration: 3
      :language: en
      :title: Main Title -- Title
      :library-ics: 1,2,3
      :fullname: Fred Flintstone
      :role: author
      :affiliation: Slate Rock and Gravel Company
      :affiliation_abbrev: SRG
      :address: 6 Rubble Way, Bedrock
      :contributor-uri: http://slate.example.com
      :phone: 123
      :fax: 456
      :surname_2: Rubble
      :givenname_2: Barney
      :initials_2: B. X.
      :role_2: editor
      :affiliation_2: Rockhead and Quarry Cave Construction Company
      :affiliation_abbrev_2: RQCCC
      :address_2: 6A Rubble Way, + \\
      Bedrock
      :email_2: barney@rockhead.example.com
      :phone_2: 789
      :fax_2: 012
      :publisher: "Hanna Barbera", "Cartoon Network", "Ribose, Inc."
      :copyright-holder: "Ribose, Inc.", Hanna Barbera
      :part-of: ABC
      :translated-from: DEF,GHI;JKL MNO,PQR
      :keywords: a, b, c
      :pub-address: 1 Infinity Loop + \\
      California
      :pub-phone: 3333333
      :pub-fax: 4444444
      :pub-email: x@example.com
      :pub-uri: http://www.example.com
      :isbn: ISBN-13
      :isbn10: ISBN-10
    INPUT
    <?xml version="1.0" encoding="UTF-8"?>
<standard-document xmlns="https://www.metanorma.org/ns/standoc" type="semantic" version="#{Metanorma::Standoc::VERSION}">
<bibdata type="standard">
<title language="en" format="text/plain">Main Title — Title</title>
  <docidentifier>1000-1</docidentifier>
  <docidentifier type='ISBN'>ISBN-13</docidentifier>
<docidentifier type='ISBN10'>ISBN-10</docidentifier>
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
    <name>Hanna Barbera</name>
  </organization>
</contributor>
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
     <affiliation>
   <organization>
     <name>Slate Rock and Gravel Company</name>
     <abbreviation>SRG</abbreviation>
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
  <role type="editor"/>
  <person>
    <name>
      <forename>Barney</forename>
      <initial>B. X.</initial>
      <surname>Rubble</surname>
    </name>
<affiliation>
  <organization>
    <name>Rockhead and Quarry Cave Construction Company</name>
    <abbreviation>RQCCC</abbreviation>
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
<keyword>a</keyword>
<keyword>b</keyword>
<keyword>c</keyword>
<ext>
<doctype>article</doctype>
  <editorialgroup>
    <technical-committee number="1" type="A">TC</technical-committee>
    <technical-committee number="11" type="A1">TC1</technical-committee>
  </editorialgroup>
  <ics>
    <code>1</code>
  </ics>
  <ics>
    <code>2</code>
  </ics>
  <ics>
    <code>3</code>
  </ics>
  </ext>
</bibdata>
<sections/>
</standard-document>
    OUTPUT
  end

  it "processes complex metadata" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :revdate: 2000-01
      :published-date: 1000-01
      :docnumber: 1000
      :partnumber: 1-1
      :tc-docnumber: 2000
      :language: el
      :script: Grek
      :publisher: IEC,IETF,ISO
      :uri: A
      :xml-uri: B
      :html-uri: C
      :pdf-uri: D
      :doc-uri: E
      :relaton-uri: F
      :title-eo: Dokumenttitolo
      :doctype: This is a DocType
      :subdivision: Subdivision
      :subdivision-abbr: SD

      [abstract]
      == Abstract
      This is the abstract of the document

      This is the second paragraph of the abstract of the document.

      [language=en]
      == Clause 1
    INPUT
           <?xml version="1.0" encoding="UTF-8"?>
       <standard-document xmlns="https://www.metanorma.org/ns/standoc"  type="semantic" version="#{Metanorma::Standoc::VERSION}">
       <bibdata type="standard">
         <title language="en" format="text/plain">Document title</title>
         <title language="eo" format="text/plain">Dokumenttitolo</title>
         <uri>A</uri>
         <uri type="xml">B</uri>
         <uri type="html">C</uri>
         <uri type="pdf">D</uri>
         <uri type="doc">E</uri>
         <uri type="relaton">F</uri>
         <docidentifier>1000-1-1</docidentifier>
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
</version>
         <language>el</language>
         <script>Grek</script>
         <abstract><p>This is the abstract of the document</p>
         <p>This is the second paragraph of the abstract of the document.</p></abstract>
         <status><stage>published</stage></status>
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
         <doctype>this-is-a-doctype</doctype>
         </ext>
       </bibdata>
         <preface>
    <abstract id='_'>
    <title>Abstract</title>
      <p id='_'>This is the abstract of the document</p>
      <p id='_'>This is the second paragraph of the abstract of the document.</p>
    </abstract>
  </preface>
  <sections>
    <clause id='_' language='en' inline-header='false' obligation='normative'>
      <title>Clause 1</title>
    </clause>
  </sections>
</standard-document>
    OUTPUT
  end

   it "processes subdivisions" do
     mock_default_publisher
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :revdate: 2000-01
      :published-date: 1000-01
      :docnumber: 1000
      :partnumber: 1-1
      :tc-docnumber: 2000
      :language: el
      :script: Grek
      :subdivision: Subdivision
      :subdivision-abbr: SD
      :doctype: This is a DocType
      :pub-address: 1 Infinity Loop + \\
      California
      :pub-phone: 3333333
      :pub-fax: 4444444
      :pub-email: x@example.com
      :pub-uri: http://www.example.com

    INPUT
       <standard-document xmlns="https://www.metanorma.org/ns/standoc"  type="semantic" version="#{Metanorma::Standoc::VERSION}">
  <bibdata type='standard'>
    <title language='en' format='text/plain'>Document title</title>
    <docidentifier>1000-1-1</docidentifier>
    <docnumber>1000</docnumber>
    <date type='published'>
      <on>1000-01</on>
    </date>
    <contributor>
      <role type='author'/>
      <organization>
        <name>International Standards Organization</name>
        <subdivision>Subdivision</subdivision>
        <abbreviation>SD</abbreviation>
        <address>
  <formattedAddress>1 Infinity Loop <br/>California</formattedAddress>
</address>
<phone>3333333</phone>
<phone type='fax'>4444444</phone>
<email>x@example.com</email>
<uri>http://www.example.com</uri>
      </organization>
    </contributor>
    <contributor>
      <role type='publisher'/>
      <organization>
        <name>International Standards Organization</name>
        <subdivision>Subdivision</subdivision>
        <abbreviation>SD</abbreviation>
        <address>
  <formattedAddress>1 Infinity Loop <br/>California</formattedAddress>
</address>
<phone>3333333</phone>
<phone type='fax'>4444444</phone>
<email>x@example.com</email>
<uri>http://www.example.com</uri>
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
      <from>2020</from>
      <owner>
        <organization>
          <name>International Standards Organization</name>
          <subdivision>Subdivision</subdivision>
          <abbreviation>SD</abbreviation>
        <address>
  <formattedAddress>1 Infinity Loop <br/>California</formattedAddress>
</address>
<phone>3333333</phone>
<phone type='fax'>4444444</phone>
<email>x@example.com</email>
<uri>http://www.example.com</uri>
        </organization>
      </owner>
    </copyright>
    <ext>
      <doctype>this-is-a-doctype</doctype>
    </ext>
  </bibdata>
  <sections> </sections>
</standard-document>
        
OUTPUT
   end

  it "reads scripts into blank HTML document" do
    FileUtils.rm_f "test.html"
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :scripts: spec/assets/scripts.html
    INPUT
    html = File.read("test.html", encoding: "utf-8")
    expect(html).to match(%r{<script>})
  end

  it "uses specified fonts and assets in HTML" do
    FileUtils.rm_f "test.html"
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :script: Hans
      :body-font: Zapf Chancery
      :header-font: Comic Sans
      :monospace-font: Andale Mono
      :htmlstylesheet: spec/assets/html.scss
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
  end

  it "uses specified fonts and assets in Word" do
    FileUtils.rm_f "test.doc"
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :script: Hans
      :body-font: Zapf Chancery
      :header-font: Comic Sans
      :monospace-font: Andale Mono
      :wordstylesheet: spec/assets/word.scss
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
    expect(html).to include('\o "1-3"')
    expect(html).to include(%[Content-Location: file:///C:/Doc/test_files/header.html
Content-Transfer-Encoding: base64
Content-Type: text/html charset="utf-8"

Ci8qIGFuIGVtcHR5IGhlYWRlciAqLwoKU1RBUlQgRE9DIElEOiA6IEVORCBET0MgSUQKCkZJTEVO
QU1FOiB0ZXN0Cgo=
])
  end

  it "test submitting-organizations with delimiter in end" do
    FileUtils.rm_f "test.doc"
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      = Document title
      Author
      :docfile: test.adoc
      :doctype: standard
      :encoding: utf-8
      :lang: en
      :submitting-organizations: Organization One; Organization Two;
      :publisher: "Hanna Barbera", "Cartoon Network", "Ribose, Inc.",
    INPUT
    expect(File.exist?("test.doc")).to be true
  end

  private

  def mock_org_abbrevs
    allow_any_instance_of(::Asciidoctor::Standoc::Front).to receive(:org_abbrev).and_return(
      { "International Standards Organization" => "ISO",
        "International Electrotechnical Commission" => "IEC" }
    )
  end

   def mock_default_publisher 
    allow_any_instance_of(::Asciidoctor::Standoc::Front).to receive(:default_publisher).and_return(
        "International Standards Organization"
    )
  end
 

end



