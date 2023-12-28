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
                   <mstyle mathvariant="sans-serif">
                     <mi>cd</mi>
                   </mstyle>
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
               <address>
                <formattedAddress>10 Jack St<br/>Antarctica</formattedAddress>
            </address>
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

  it "reads contributors from YAML" do
    input = <<~INPUT
      = X
      A
      :corrected-date: 2022-10
      :no-pdf:
      :fullname: Author One
      :affiliation: Computer Security Division, Information Technology Laboratory
      :role: author
      :fullname_2: Sponsor Person One
      :affiliation_2: Department of Homeland Security
      :affiliation_role_2: Secretary
      :role_2: enabler
      :novalid:
      :stem:

      [.preface]
      == misc-container

      === contributor metadata

      [source,yaml]
      ----
      fullname: Fred Flintstone
      ----
    INPUT
    output = <<~OUTPUT
      <bibdata type="standard">
         <title language="en" format="text/plain">X</title>
         <date type="corrected">
           <on>2022-10</on>
         </date>
         <contributor>
           <role type="author"/>
           <person>
             <name>
               <completename>Author One</completename>
             </name>
             <affiliation>
               <organization>
                 <name>Computer Security Division, Information Technology Laboratory</name>
               </organization>
             </affiliation>
           </person>
         </contributor>
         <contributor>
           <role type="enabler"/>
           <person>
             <name>
               <completename>Sponsor Person One</completename>
             </name>
             <affiliation>
               <organization>
                 <name>Department of Homeland Security</name>
               </organization>
             </affiliation>
           </person>
         </contributor>
         <contributor>
           <role type="author"/>
           <name>
             <completename>Fred Flintstone</completename>
           </name>
         </contributor>
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
         </ext>
       </bibdata>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(xmlpp(strip_guid(ret.at("//xmlns:bibdata").to_xml)))
      .to be_equivalent_to(xmlpp(output))
  end

  it "reads contributors from YAML" do
    input = <<~INPUT
      = X
      A
      :corrected-date: 2022-10
      :no-pdf:
      :fullname: Author One
      :affiliation: Computer Security Division, Information Technology Laboratory
      :role: author
      :fullname_2: Sponsor Person One
      :affiliation_2: Department of Homeland Security
      :affiliation_role_2: Secretary
      :role_2: enabler
      :novalid:
      :stem:

      [.preface]
      == misc-container

      === contributor metadata

      [source,yaml]
      ----
      - fullname: Fred Flintstone
        role: author
        contributor-credentials: PhD, F.R.Pharm.S.
        contributor-uri: http://facebook.com/fred
        affiliations:
          - contributor-position: Vice President, Medical Devices Quality & Compliance -- Strategic programmes
            affiliation: Slate Rock and Gravel Company
            affiliation_abbrev: SRG
            affiliation_subdiv: Hermeneutics Unit; Exegetical Subunit
            contributor-uri: http://slate.example.com
            affiliation_logo: a.gif
      - surname: Rubble
        givenname: Barney
        initials: B. X.
        role: editor
        role-description: consulting editor
        contributor-credentials: PhD, F.R.Pharm.S.
        address: 18 Rubble Way, Bedrock
        email: barney@personal.example.com
        phone: 11111
        fax: 121212
        affiliations:
          - contributor-position: Former Chair ISO TC 210
            affiliation: Rockhead and Quarry Cave Construction Company
            affiliation_abbrev: RQCCC
            affiliation_subdiv: Hermeneutics Unit; Exegetical Subunit
            address: 6A Rubble Way, Bedrock
            email: barney@rockhead.example.com
            phone: 789
            fax: 012
      -  fullname: Barry Fussell
         street: 170 West Tasman Drive
         city: San Jose
         region: California
         affiliations:
           affiliation: Cisco Systems, Inc.
      -  fullname: Apostol Vassilev
         affiliations:
           affiliation: Information Technology Laboratory
           affiliation_subdiv: Computer Security Division
      -  fullname: Ronny Jopp
         affiliations:
          -  affiliation_subdiv: Biochemical Science Division
             affiliation: National Institute of Standards and Technology
             address: Gaithersburg, MD, U.S.A.
          -  affiliation_subdiv: Computer Science Department
             affiliation: University of Applied Sciences
             city: Wiesbaden
             country: Germany
      ----
    INPUT
    output = <<~OUTPUT
      <bibdata type="standard">
         <title language="en" format="text/plain">X</title>
         <date type="corrected">
           <on>2022-10</on>
         </date>
         <contributor>
           <role type="author"/>
           <person>
             <name>
               <completename>Author One</completename>
             </name>
             <affiliation>
               <organization>
                 <name>Computer Security Division, Information Technology Laboratory</name>
               </organization>
             </affiliation>
           </person>
         </contributor>
         <contributor>
           <role type="enabler"/>
           <person>
             <name>
               <completename>Sponsor Person One</completename>
             </name>
             <affiliation>
               <organization>
                 <name>Department of Homeland Security</name>
               </organization>
             </affiliation>
           </person>
         </contributor>
         <contributor>
           <role type="author"/>
           <name>
             <completename>Fred Flintstone</completename>
           </name>
           <credentials>PhD, F.R.Pharm.S.</credentials>
           <affiliation>
             <name>Vice President, Medical Devices Quality  Compliance -- Strategic programmes</name>
             <organization>
               <name>Slate Rock and Gravel Company</name>
               <abbreviation>SRG</abbreviation>
               <subdivision>Hermeneutics Unit; Exegetical Subunit</subdivision>
               <uri>http://slate.example.com</uri>
               <logo>
                 <image src="a.gif"/>
               </logo>
             </organization>
           </affiliation>
           <uri>http://facebook.com/fred</uri>
         </contributor>
         <contributor>
           <role type="editor"/>
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
               <subdivision>Hermeneutics Unit; Exegetical Subunit</subdivision>
               <address>
                 <formattedAddress>6A Rubble Way, Bedrock</formattedAddress>
               </address>
               <phone>789</phone>
               <phone type="fax">10</phone>
               <email>barney@rockhead.example.com</email>
             </organization>
           </affiliation>
           <address>
             <formattedAddress>18 Rubble Way, Bedrock</formattedAddress>
           </address>
           <phone>11111</phone>
           <phone type="fax">121212</phone>
           <email>barney@personal.example.com</email>
         </contributor>
         <contributor>
           <role type="author"/>
           <name>
             <completename>Barry Fussell</completename>
           </name>
           <affiliation>
             <organization>
               <name>Cisco Systems, Inc.</name>
             </organization>
           </affiliation>
           <address>
             <street>170 West Tasman Drive</street>
             <city>San Jose</city>
           </address>
         </contributor>
         <contributor>
           <role type="author"/>
           <name>
             <completename>Apostol Vassilev</completename>
           </name>
           <affiliation>
             <organization>
               <name>Information Technology Laboratory</name>
               <subdivision>Computer Security Division</subdivision>
             </organization>
           </affiliation>
         </contributor>
         <contributor>
           <role type="author"/>
           <name>
             <completename>Ronny Jopp</completename>
           </name>
           <affiliation>
             <organization>
               <name>National Institute of Standards and Technology</name>
               <subdivision>Biochemical Science Division</subdivision>
               <address>
                 <formattedAddress>Gaithersburg, MD, U.S.A.</formattedAddress>
               </address>
             </organization>
           </affiliation>
           <affiliation>
             <organization>
               <name>University of Applied Sciences</name>
               <subdivision>Computer Science Department</subdivision>
               <address>
                 <city>Wiesbaden</city>
                 <country>Germany</country>
               </address>
             </organization>
           </affiliation>
         </contributor>
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
         </ext>
       </bibdata>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(xmlpp(strip_guid(ret.at("//xmlns:bibdata").to_xml)))
      .to be_equivalent_to(xmlpp(output))
  end

  private

  def mock_mathml_italicise(string)
    allow_any_instance_of(Metanorma::Standoc::Cleanup)
      .to receive(:mathml_mi_italics).and_return(string)
  end
end
