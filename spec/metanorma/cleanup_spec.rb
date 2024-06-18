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

  it "do not apply substitutions to links in included docs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Clause

      include::spec/fixtures/included-link.adoc[]

    INPUT
    output = <<~OUTPUT
      <clause id="_" inline-header="false" obligation="normative">
         <title>Clause</title>
         <p id="_">
           <link target="http://www.example.com/...abc"/>
         </p>
       </clause>
    OUTPUT
    a = [OPTIONS[0].merge(safe: :unsafe)]
    ret = Nokogiri::XML(Asciidoctor.convert(input, *a))
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
      person:
        name:
          completename: Fred Flintstone
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
           <person>
           <name>
             <completename>Fred Flintstone</completename>
           </name>
           </person>
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
      - role: author
        person:
          name:
            completename: Fred Flintstone
          credential:
          - PhD, F.R.Pharm.S.
          affiliation:
          - name:
              content: Vice President, Medical Devices Quality & Compliance -- Strategic programmes
            organization:
              name: Slate Rock and Gravel Company
              abbreviation: SRG
              subdivision: Hermeneutics Unit; Exegetical Subunit
              contact:
                - address:
                    street: 6 Rubble Way
                    city: Bedrock
                    country: U.S.A
                - uri: http://slate.example.com
                - phone: 123
                - phone:
                    type: fax
                    value: fax456
      - role:
          type: editor
          description: consulting editor
        person:
          name:
            surname: Rubble
            given:
              forename: Barney
              formatted_initials: B. X.
          credential:
          - PhD, F.R.Pharm.S.
          affiliation:
          - name:
              content: Former Chair ISO TC 210
            organization:
              name: Rockhead and Quarry Cave Construction Company
              abbreviation: RQCCC
              subdivision: Hermeneutics Unit; Exegetical Subunit
              contact:
                - address:
                    street: 6A Rubble Way
                    city: Bedrock
                    country: U.S.A
                - email: barney@rockhead.example.com
                - phone: 789
                - phone:
                  type: fax
                  value: 012
      -  person:
           name:
             completename: Barry Fussell
           affiliation:
             - organization:
                 name: Cisco Systems, Inc.
           contact:
             - address:
                  street: 170 West Tasman Drive
                  city: San Jose
                  region: California
                  country: U.S.A
      -  person:
           name:
             completename: Apostol Vassilev
           affiliation:
             - organization:
                 name: Information Technology Laboratory
                 subdivision: Computer Security Division
      -  person:
          name:
            completename: Ronny Jopp
          affiliation:
          -  organization:
               subdivision: Biochemical Science Division
               name: National Institute of Standards and Technology
               contact:
                 - address:
                    city:  Gaithersburg
                    region: MD
                    country: U.S.A.
          -  organization:
               subdivision: Computer Science Department
               name: University of Applied Sciences
               contact:
                 - address:
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
           <person>
             <name>
               <completename>Fred Flintstone</completename>
             </name>
             <credential>PhD, F.R.Pharm.S.</credential>
             <affiliation>
               <name>Vice President, Medical Devices Quality &amp; Compliance -- Strategic programmes</name>
               <organization>
                 <name>Slate Rock and Gravel Company</name>
                 <subdivision>Hermeneutics Unit; Exegetical Subunit</subdivision>
                 <abbreviation>SRG</abbreviation>
                 <address>
                   <street>6 Rubble Way</street>
                   <city>Bedrock</city>
                   <country>U.S.A</country>
                 </address>
                 <uri>http://slate.example.com</uri>
                 <phone>123</phone>
               </organization>
             </affiliation>
           </person>
         </contributor>
         <contributor>
           <role type="editor">
             <description>consulting editor</description>
           </role>
           <person>
             <name>
               <forename>Barney</forename>
               <formatted-initials>B. X.</formatted-initials>
               <surname>Rubble</surname>
             </name>
             <credential>PhD, F.R.Pharm.S.</credential>
             <affiliation>
               <name>Former Chair ISO TC 210</name>
               <organization>
                 <name>Rockhead and Quarry Cave Construction Company</name>
                 <subdivision>Hermeneutics Unit; Exegetical Subunit</subdivision>
                 <abbreviation>RQCCC</abbreviation>
                 <address>
                   <street>6A Rubble Way</street>
                   <city>Bedrock</city>
                   <country>U.S.A</country>
                 </address>
                 <email>barney@rockhead.example.com</email>
                 <phone>789</phone>
               </organization>
             </affiliation>
           </person>
         </contributor>
         <contributor>
           <role type="author"/>
           <person>
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
               <country>U.S.A</country>
             </address>
           </person>
         </contributor>
         <contributor>
           <role type="author"/>
           <person>
             <name>
               <completename>Apostol Vassilev</completename>
             </name>
             <affiliation>
               <organization>
                 <name>Information Technology Laboratory</name>
                 <subdivision>Computer Security Division</subdivision>
               </organization>
             </affiliation>
           </person>
         </contributor>
         <contributor>
           <role type="author"/>
           <person>
             <name>
               <completename>Ronny Jopp</completename>
             </name>
             <affiliation>
               <organization>
                 <name>National Institute of Standards and Technology</name>
                 <subdivision>Biochemical Science Division</subdivision>
                 <address>
                   <city>Gaithersburg</city>
                   <country>U.S.A.</country>
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
           </person>
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

  it "reads document history from YAML" do
    input = <<~INPUT
      = X
      A
      :corrected-date: 2022-10
      :no-pdf:
      :fullname: Author One
      :novalid:
      :stem:

      [.preface]
      == misc-container

      === document history

      [source,yaml]
      ----
      - date:
          - type: published
            value: 2016-05
        docid:
            type: BSI
            id: A1
        amend:
           description: see Foreword
      - date:
          - type: published
            value: 2016-08
        docid:
            type: BSI
            id: C1
        amend:
           description: see Foreword
      - date:
          - type: published
            value: 2019-01
        docid:
            type: BSI
            id: A2
        amend:
           description: see Foreword
           classification: editorial
      - date:
          - type: published
            value: 2020-06
        docid:
            type: BSI
            id: C2
        amend:
           location: table=A.4;table=A.5
           classification:
             tag: type
             value: editorial
      - date:
          - type: published
            value: 2016-03-31
        amend:
           description: "Implementation of CEN/CENELEC correction notice March 2016: Annexes ZA, ZB and ZC updated"
           classification:
             - tag: type
               value: editorial
             - tag: impact
               value: major
           change: replace
           location:
             - annex=ZA
             - annex=ZB
             - annex=ZC
      - date:
          - type: published
            value: 2017-01-31
        amend:
           description: "Implementation of CEN/CENELEC corrigendum December 2016: European foreword and Annexes ZA, ZB and ZC corrected"
      - date:
          - type: published
            value: 2021-09-30
        relation.type: merges
        amend:
           description: |
             The following:

             * Implementation of CEN/CENELEC amendment A11:2021: European foreword and Annexes ZA and ZB revised, and Annex ZC removed.#{' '}
             * National Annex NZ added, and Amendments/corrigenda issued since publication table corrected
      - date:
        - type: published
          value: 1976-03
        docid:
          - type: BSI
            id: BS 5500
        edition: 1
      - date:
        - type: published
          value: 1982-01
        docid:
          - type: BSI
            id: BS 5500
        edition: 2
      - date:
        - type: published
          value: 1985-01
        docid:
          - type: BSI
            id: BS 5500
        edition: 3
      - date:
        - type: published
          value: 1988-01
        docid:
          - type: BSI
            id: BS 5500
        edition: 4
      - date:
        - type: published
          value: 1991-01
        docid:
          - type: BSI
            id: BS 5500
        edition: 5
      - date:
        - type: published
          value: 1994-01
        docid:
          - type: BSI
            id: BS 5500
        edition: 6
      - date:
        - type: published
          value: 1997-01
        docid:
          - type: BSI
            id: BS 5500
        edition: 7
      - date:
        - type: published
          value: 2000-01
        docid:
          - type: BSI
            id: PD 5500
        edition: 1
      - date:
        - type: published
          value: 2003-01
        docid:
          - type: BSI
            id: PD 5500
        edition: 2
      - date:
        - type: published
          value: 2006-01
        docid:
          - type: BSI
            id: PD 5500
        edition: 3
      - date:
        - type: published
          value: 2009-01
        docid:
          - type: BSI
            id: PD 5500
        edition: 4
      - date:
        - type: published
          value: 2012-01
        docid:
          - type: BSI
            id: PD 5500
        edition: 5
      - date:
        - type: published
          value: 2015-01
        docid:
          - type: BSI
            id: PD 5500
        edition: 6
      - date:
        - type: published
          value: 2018-01
        docid:
          - type: BSI
            id: PD 5500
        edition: 7
      - date:
        - type: published
          value: 2021-01
        docid:
          - type: BSI
            id: PD 5500
        edition: 8
      - date:
        - type: updated
          value: 2021-09
        - type: implemented
          value: 2022-01
        docid:
          - type: BSI
            id: Amendment 1, tagged
        amend:
          description: SEE FOREWORD
      - date:
        - type: updated
          value: 2022-09
        - type: implemented
          value: 2023-01
        docid:
          - type: BSI
            id: Amendment 2, tagged
        amend:
          description: SEE FOREWORD
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
           </person>
         </contributor>
         <language>en</language>
         <script>Latn</script>
         <status>
           <stage>published</stage>
         </status>
         <copyright>
           <from>2024</from>
         </copyright>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">A1</docidentifier>
             <date type="published">
               <on>2016-05</on>
             </date>
             <amend change="modify">
               <description>
                 <p id="_">see Foreword</p>
               </description>
             </amend>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">C1</docidentifier>
             <date type="published">
               <on>2016-08</on>
             </date>
             <amend change="modify">
               <description>
                 <p id="_">see Foreword</p>
               </description>
             </amend>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">A2</docidentifier>
             <date type="published">
               <on>2019-01</on>
             </date>
             <amend change="modify">
               <description>
                 <p id="_">see Foreword</p>
               </description>
               <classification>
                 <tag>default</tag>
                 <value>editorial</value>
               </classification>
             </amend>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">C2</docidentifier>
             <date type="published">
               <on>2020-06</on>
             </date>
             <amend change="modify">
               <location>
                 <localityStack connective="and">
                   <locality type="table">
                     <referenceFrom>A.4</referenceFrom>
                   </locality>
                 </localityStack>
                 <localityStack connective="and">
                   <locality type="table">
                     <referenceFrom>A.5</referenceFrom>
                   </locality>
                 </localityStack>
               </location>
               <classification>
                 <tag>type</tag>
                 <value>editorial</value>
               </classification>
             </amend>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <date type="published">
               <on>2016-03-31</on>
             </date>
             <amend change="replace">
               <description>
                 <p id="_">Implementation of CEN/CENELEC correction notice March 2016: Annexes ZA, ZB and ZC updated</p>
               </description>
               <location>
                 <localityStack>
                   <locality type="annex">
                     <referenceFrom>ZA</referenceFrom>
                   </locality>
                 </localityStack>
                 <localityStack>
                   <locality type="annex">
                     <referenceFrom>ZB</referenceFrom>
                   </locality>
                 </localityStack>
                 <localityStack>
                   <locality type="annex">
                     <referenceFrom>ZC</referenceFrom>
                   </locality>
                 </localityStack>
               </location>
               <classification>
                 <tag>type</tag>
                 <value>editorial</value>
               </classification>
               <classification>
                 <tag>impact</tag>
                 <value>major</value>
               </classification>
             </amend>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <date type="published">
               <on>2017-01-31</on>
             </date>
             <amend change="modify">
               <description>
                 <p id="_">Implementation of CEN/CENELEC corrigendum December 2016: European foreword and Annexes ZA, ZB and ZC corrected</p>
               </description>
             </amend>
           </bibitem>
         </relation>
         <relation type="merges">
           <bibitem>
             <date type="published">
               <on>2021-09-30</on>
             </date>
             <amend change="modify">
               <description>
                 <p id="_">The following:</p>
                 <ul id="_">
                   <li>
                     <p id="_">Implementation of CEN/CENELEC amendment A11:2021: European foreword and Annexes ZA and ZB revised, and Annex ZC removed.</p>
                   </li>
                   <li>
                     <p id="_">National Annex NZ added, and Amendments/corrigenda issued since publication table corrected</p>
                   </li>
                 </ul>
               </description>
             </amend>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">BS 5500</docidentifier>
             <date type="published">
               <on>1976-03</on>
             </date>
             <edition>1</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">BS 5500</docidentifier>
             <date type="published">
               <on>1982-01</on>
             </date>
             <edition>2</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">BS 5500</docidentifier>
             <date type="published">
               <on>1985-01</on>
             </date>
             <edition>3</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">BS 5500</docidentifier>
             <date type="published">
               <on>1988-01</on>
             </date>
             <edition>4</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">BS 5500</docidentifier>
             <date type="published">
               <on>1991-01</on>
             </date>
             <edition>5</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">BS 5500</docidentifier>
             <date type="published">
               <on>1994-01</on>
             </date>
             <edition>6</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">BS 5500</docidentifier>
             <date type="published">
               <on>1997-01</on>
             </date>
             <edition>7</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">PD 5500</docidentifier>
             <date type="published">
               <on>2000-01</on>
             </date>
             <edition>1</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">PD 5500</docidentifier>
             <date type="published">
               <on>2003-01</on>
             </date>
             <edition>2</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">PD 5500</docidentifier>
             <date type="published">
               <on>2006-01</on>
             </date>
             <edition>3</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">PD 5500</docidentifier>
             <date type="published">
               <on>2009-01</on>
             </date>
             <edition>4</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">PD 5500</docidentifier>
             <date type="published">
               <on>2012-01</on>
             </date>
             <edition>5</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">PD 5500</docidentifier>
             <date type="published">
               <on>2015-01</on>
             </date>
             <edition>6</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">PD 5500</docidentifier>
             <date type="published">
               <on>2018-01</on>
             </date>
             <edition>7</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">PD 5500</docidentifier>
             <date type="published">
               <on>2021-01</on>
             </date>
             <edition>8</edition>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">Amendment 1, tagged</docidentifier>
             <date type="updated">
               <on>2021-09</on>
             </date>
             <date type="implemented">
               <on>2022-01</on>
             </date>
             <amend change="modify">
               <description>
                 <p id="_">SEE FOREWORD</p>
               </description>
             </amend>
           </bibitem>
         </relation>
         <relation type="updatedBy">
           <bibitem>
             <docidentifier type="BSI">Amendment 2, tagged</docidentifier>
             <date type="updated">
               <on>2022-09</on>
             </date>
             <date type="implemented">
               <on>2023-01</on>
             </date>
             <amend change="modify">
               <description>
                 <p id="_">SEE FOREWORD</p>
               </description>
             </amend>
           </bibitem>
         </relation>
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

  def mock_boilerplate_file
    allow_any_instance_of(Metanorma::Standoc::Cleanup)
      .to receive(:boilerplate_file).and_return(
        "spec/assets/boilerplate.adoc",
      )
  end
end
