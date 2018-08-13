require "spec_helper"

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
    system "rm -f test.doc"
    expect(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)).to be_equivalent_to <<~"OUTPUT"
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

  it "processes default metadata" do
    expect(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)).to be_equivalent_to <<~'OUTPUT'
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :docnumber: 1000
      :partnumber: 1
      :edition: 2
      :revdate: 2000-01-01
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
      :secretariat: SECRETARIAT
      :copyright-year: 2001
      :docstage: 10
      :docsubstage: 20
      :iteration: 3
      :language: en
      :title: Main Title -- Title
      :library-ics: 1,2,3
    INPUT
    <?xml version="1.0" encoding="UTF-8"?>
<standard-document xmlns="http://riboseinc.com/isoxml">
<bibdata type="article">
<title language="en" format="text/plain">Main Title — Title</title>
  <docidentifier>
    <project-number part="1"> 1000</project-number>
  </docidentifier>
  <language>en</language>
  <script>Latn</script>
  <status format="plain">published</status>
  <copyright>
    <from>2001</from>
  </copyright>
  <editorialgroup>
    <technical-committee number="1" type="A">TC</technical-committee>
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
</bibdata><version>
  <edition>2</edition>
  <revision-date>2000-01-01</revision-date>
  <draft>3.4</draft>
</version>
<sections/>
</standard-document>
    OUTPUT
  end

  it "processes complex metadata" do
    expect(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)).to be_equivalent_to <<~'OUTPUT'
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :docnumber: 1000
      :partnumber: 1-1
      :tc-docnumber: 2000
      :language: el
      :script: Grek
      :publisher: IEC,IETF,ISO
    INPUT
           <?xml version="1.0" encoding="UTF-8"?>
       <standard-document xmlns="http://riboseinc.com/isoxml">
       <bibdata type="article">

         <docidentifier>
           <project-number part="1" subpart="1">ISO/IEC/IETF 1000</project-number>
         </docidentifier>
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
         <language>el</language>
         <script>Grek</script>
         <status format="plain">published</status>
         <copyright>
           <from>2018</from>
           <owner>
             <organization>
               <name>IEC</name>
             </organization>
           </owner>
         </copyright>
         <copyright>
           <from>2018</from>
           <owner>
             <organization>
               <name>IETF</name>
             </organization>
           </owner>
         </copyright>
         <copyright>
           <from>2018</from>
           <owner>
             <organization>
               <name>ISO</name>
             </organization>
           </owner>
         </copyright>
         <editorialgroup>
           <technical-committee/>
         </editorialgroup>
       </bibdata>
       <sections/>
       </standard-document>
    OUTPUT
  end

  it "reads scripts into blank HTML document" do
    system "rm -f test.html"
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
    system "rm -f test.html"
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :script: Hans
      :body-font: Zapf Chancery
      :header-font: Comic Sans
      :monospace-font: Andale Mono
      :htmlstylesheet: spec/assets/html.css
      :htmlcoverpage: spec/assets/htmlcover.html
      :htmlintropage: spec/assets/htmlintro.html
      :scripts: spec/assets/scripts.html
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
    system "rm -f test.doc"
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      = Document title
      Author
      :docfile: test.adoc
      :novalid:
      :script: Hans
      :body-font: Zapf Chancery
      :header-font: Comic Sans
      :monospace-font: Andale Mono
      :wordstylesheet: spec/assets/word.css
      :wordcoverpage: spec/assets/wordcover.html
      :wordintropage: spec/assets/wordintro.html
      :header: spec/assets/header.html
    INPUT
    html = File.read("test.doc", encoding: "utf-8")
    expect(html).to match(%r[pre[^{]+\{[^{]+font-family: Andale Mono;]m)
    expect(html).to match(%r[p[^{]+\{[^{]+font-family: Zapf Chancery;]m)
    expect(html).to match(%r[h1[^{]+\{[^{]+font-family: Comic Sans;]m)
    expect(html).to match(%r[an empty word cover page])
    expect(html).to match(%r[an empty word intro page])
    expect(html).to match(%r[Content-Location: file:///C:/Doc/test_files/header.html
Content-Transfer-Encoding: base64
Content-Type: text/html charset="utf-8"

Ci8qIGFuIGVtcHR5IGhlYWRlciAqLwoKU1RBUlQgRE9DIElEOiAgOiBFTkQgRE9DIElECgpGSUxF
TkFNRTogdGVzdAoK
])
  end


end



