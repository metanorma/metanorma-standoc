require "spec_helper"

RSpec.describe Metanorma::Standoc do
  it "handles spacing around markup" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      This is
      a paragraph with <<x>>
      markup _for_
      text, including **__nest__**ed markup.
    INPUT
    output = <<~OUTPUT
            <?xml version="1.0" encoding="UTF-8"?>
      <standard-document xmlns="https://www.metanorma.org/ns/standoc"  type="semantic" version="#{Metanorma::Standoc::VERSION}">
      <bibdata type="standard">
      <title language="en" format="text/plain">Document title</title>
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
      <sections>
      <p id="_">This is
      a paragraph with <xref target="x"/>
      markup <em>for</em>
      text, including <strong><em>nest</em></strong>ed markup.</p>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes inline_quoted formatting" do
    input = <<~INPUT
      #{DUMBQUOTE_BLANK_HDR}
      _Physical noise
      sources_
      *strong*
      `monospace`
      "double quote"
      'single quote'
      super^script^
      sub~script~
      sub~__scr__ipt~
      stem:[<mml:math><mml:msub xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"> <mml:mrow> <mml:mrow> <mml:mi mathvariant="bold-italic">F</mml:mi> </mml:mrow> </mml:mrow> <mml:mrow> <mml:mrow> <mml:mi mathvariant="bold-italic">&#x391;</mml:mi> </mml:mrow> </mml:mrow> </mml:msub> </mml:math>]
      #mark#
      [alt]#alt#
      [deprecated]#deprecated#
      [domain]#domain#
      [strike]#strike#
      [underline]#underline#
      [smallcap]#smallcap#
      [keyword]#keyword#
      [css font-family:"Noto Sans JP"]#text#
      [css font-family:'Noto Sans JP']#text#
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
      <sections>
      <em>Physical noise sources</em>
      <strong>strong</strong>
      <tt>monospace</tt>
      "double quote"
      'single quote'
      super<sup>script</sup>
      sub<sub>script</sub>
      sub<sub><em>scr</em>ipt</sub>
      <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub> <mrow> <mrow> <mi mathvariant="bold-italic">F</mi> </mrow> </mrow> <mrow> <mrow> <mi mathvariant="bold-italic">Α</mi> </mrow> </mrow> </msub> </math></stem>
      mark
      <admitted><expression><name>alt</name></expression></admitted>
      <deprecates><expression><name>deprecated</name></expression></deprecates>
      <domain>domain</domain>
      <strike>strike</strike>
      <underline>underline</underline>
      <smallcap>smallcap</smallcap>
      <keyword>keyword</keyword>
      <span style="font-family:&quot;Noto Sans JP&quot;">text</span>
      <span style="font-family:'Noto Sans JP'">text</span>
      </sections>
      </standard-document>
    OUTPUT
    expect((strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(output)
  end

  it "process mtext spaces" do
    input = <<~INPUT
      #{DUMBQUOTE_BLANK_HDR}

      stem:[n < 1 " for all text "]
    INPUT
    output = <<~OUTPUT
                  #{BLANK_HDR}
        <sections>
          <p id='_'>
            <stem type='MathML'>
              <math xmlns='http://www.w3.org/1998/Math/MathML'>
                <mi>n</mi>
                <mo>&lt;</mo>
                <mn>1</mn>
                <mtext> for all text </mtext>
              </math>
              <asciimath>n &lt; 1 " for all text "</asciimath>
            </stem>
          </p>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "properly handles inline substitution" do
    input = <<~INPUT
      #{DUMBQUOTE_BLANK_HDR}

      stem:[n < 1] +
      latexmath:[n < 1]
      stem:["&#x200c;"^199 "Hg"^+]
    INPUT
    output = <<~OUTPUT
                  #{BLANK_HDR}
            <sections>
            <p id="_">
                <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>n</mi><mo>&lt;</mo><mn>1</mn></math><asciimath>n &lt; 1</asciimath></stem><br/>
                <stem type="MathML"> <math xmlns="http://www.w3.org/1998/Math/MathML">   <mrow>     <mi>n</mi>     <mo>&lt;</mo>     <mn>1</mn>   </mrow> </math></stem>
                <stem type='MathML'>
        <math xmlns='http://www.w3.org/1998/Math/MathML'>
          <msup>
            <mrow>
              <mtext>‌</mtext>
            </mrow>
            <mrow>
              <mn>199</mn>
            </mrow>
          </msup>
          <msup>
            <mrow>
              <mtext>Hg</mtext>
            </mrow>
            <mrow>
              <mo>+</mo>
            </mrow>
          </msup>
        </math>
        <asciimath>"‌"^199 "Hg"^+</asciimath>
      </stem>
              </p>
            </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "normalises inline stem, straight quotes" do
    input = <<~INPUT
      #{DUMBQUOTE_BLANK_HDR}

      stem:[n < 1]
      latexmath:[n < 1]
      stem:["&#x200c;"^199 "Hg"^+]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections><p id="_"><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>n</mi><mo>&lt;</mo><mn>1</mn></math><asciimath>n &lt; 1</asciimath></stem>
       <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mrow><mi>n</mi><mo>&lt;</mo><mn>1</mn></mrow></math></stem>
       <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msup><mrow><mtext>‌</mtext></mrow><mrow><mn>199</mn></mrow></msup><msup><mrow><mtext>Hg</mtext></mrow><mrow><mo>+</mo></mrow></msup></math><asciimath>"‌"^199 "Hg"^+</asciimath></stem></p>
       </sections>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "normalises inline stem, smart quotes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      stem:[n < 1]
      latexmath:[n < 1]
      stem:["&#x200c;"^199 "Hg"^+]
    INPUT
    output = <<~OUTPUT
                #{BLANK_HDR}
          <sections>
          <p id="_">
              <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>n</mi><mo>&lt;</mo><mn>1</mn></math>
              <asciimath>n &lt; 1</asciimath></stem>
              <stem type="MathML"> <math xmlns="http://www.w3.org/1998/Math/MathML">   <mrow>     <mi>n</mi>     <mo>&lt;</mo>     <mn>1</mn>   </mrow> </math>
              </stem>
              <stem type='MathML'>
      <math xmlns='http://www.w3.org/1998/Math/MathML'>
        <msup>
          <mrow>
            <mtext>‌</mtext>
          </mrow>
          <mrow>
            <mn>199</mn>
          </mrow>
        </msup>
        <msup>
          <mrow>
            <mtext>Hg</mtext>
          </mrow>
          <mrow>
            <mo>+</mo>
          </mrow>
        </msup>
      </math>
      <asciimath>"&#x200c;"^199 "Hg"^+</asciimath>
      </stem>
            </p>
          </sections>
           </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "generates desired smart quotes for 'dd'" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      '99'.

    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
      <sections><p id="_">‘99’.</p>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes breaks" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      Line break +
      line break

      '''

      <<<

      [%landscape]
      <<<

      [%portrait]
      <<<
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
      <sections><p id="_">Line break<br/>
      line break</p>
      <hr/>
      <pagebreak/>
      <pagebreak orientation="landscape"/>
      <pagebreak orientation="portrait"/>
       </sections>
      </standard-document>
    OUTPUT
    expect((strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(output)
  end

  it "processes links" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      mailto:fred@example.com
      http://example.com[]
      http://example.com[Link]
      http://example.com[Link,title="tip"]
      link:++https://asciidoctor.org/now_this__link_works.html++[]
      http://example.com[Link,update-type=true]
      link:../example[updatetype=true]
      link:../example[Link,update-type=true]
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
      <sections>
        <p id="_">mailto:fred@example.com
      <link target="http://example.com"/>
      <link target="http://example.com">Link</link>
      <link target="http://example.com" alt="tip">Link</link>
      <link target='https://asciidoctor.org/now_this__link_works.html'/>
      <link target="http://example.com" update-type="true">Link</link>
      <link target="../example" update-type="true"/>
      <link target="../example" update-type="true">Link</link></p>
      </p>
      </sections>
      </standard-document>
    OUTPUT
    expect((strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(output)
  end

  it "processes bookmarks" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      Text [[bookmark]] Text
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
      <sections>
        <p id="_">Text <bookmark id="bookmark"/> Text</p>
      </sections>
      </standard-document>
    OUTPUT
    expect((strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(output)
  end

  it "processes crossreferences" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [[reference]]
      == Section

      Inline Reference to <<reference>>
      Footnoted Reference to <<reference,fn>>
      Inline Reference with Text to <<reference,text>>
      Footnoted Reference with Text to <<reference,fn: text>>
      Anchored Crossreference to other document <<a.adoc#b>>
      Capitalised Reference to <<reference,droploc%capital%>>
      Lowercase Footnoted Reference to <<reference,capital%droploc%fn>>
      Capitalised Reference to <<reference,capital%>>
      Lowercase Footnoted Reference to <<reference,capital%fn>>
      Capitalised Reference to <<reference,droploc%>>
      Lowercase Footnoted Reference to <<reference,droploc%fn>>
      Capitalised Reference to <<reference,droploc%capital%>>
      Lowercase Footnoted Reference to <<reference,droploc%capital%fn>>
      Lowercase Footnoted Reference to <<reference,droploc%capital%text>>
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
              <sections>
               <clause id="reference" inline-header="false" obligation="normative">
               <title>Section</title>
               <p id="_">Inline Reference to <xref target="reference"/>
             Footnoted Reference to <xref target="reference"/>
             Inline Reference with Text to <xref target="reference">text</xref>
             Footnoted Reference with Text to <xref target="reference">text</xref>
             Anchored Crossreference to other document <xref target="a#b"/>
             Capitalised Reference to <xref target='reference' case='capital' droploc="true"></xref>
             Lowercase Footnoted Reference to <xref target='reference' case='capital' droploc="true"></xref>
              Capitalised Reference to
      <xref target='reference' case='capital'/>
       Lowercase Footnoted Reference to
      <xref target='reference' case='capital'/>
       Capitalised Reference to
      <xref target='reference' droploc='true'/>
       Lowercase Footnoted Reference to
      <xref target='reference' droploc='true'/>
       Capitalised Reference to
      <xref target='reference' case='capital' droploc='true'/>
       Lowercase Footnoted Reference to
      <xref target='reference' case='capital' droploc='true'/>
       Lowercase Footnoted Reference to
      <xref target='reference' case='capital' droploc='true'>text</xref>
      </p>
             </clause>
             </sections>
             </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(xmlpp(output))
  end

  it "processes crossreferences style" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [[reference]]
      == Section

      Inline Reference to <<reference>>
      Inline Reference to <<reference,style=basic%>>
      Inline Reference to <<reference,style=basic>>
      Inline Reference to <<reference,style=%>>
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
          <clause id='reference' inline-header='false' obligation='normative'>
            <title>Section</title>
            <p id='_'>
              Inline Reference to
              <xref target='reference'/>
               Inline Reference to
              <xref target='reference' style='basic'/>
               Inline Reference to
              <xref target='reference'>style=basic</xref>
               Inline Reference to
              <xref target='reference'>style=%</xref>
            </p>
          </clause>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(xmlpp(output))
  end

  it "processes crossreferences style as document attribute" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR.sub(/:nodoc:/, ":nodoc:\n:xrefstyle: full")}
      [[reference]]
      == Section

      Inline Reference to <<reference>>
      Inline Reference to <<reference,style=basic%>>
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
          <clause id='reference' inline-header='false' obligation='normative'>
            <title>Section</title>
            <p id='_'>
              Inline Reference to
              <xref target='reference'/>
               Inline Reference to
              <xref target='reference' style='basic'/>
            </p>
          </clause>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(xmlpp(output))
  end

  it "processes formatting within crossreferences" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [[reference]]
      == Section

      <<reference,_reference_>>
      <<reference,_**reference**_>>
      <<reference,_A_ stem:[x^2]>>
      <<reference,_A_ footnote:[_B_]>>
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
       <clause id="reference" inline-header="false" obligation="normative">
       <title>Section</title>
       <p id="_"><xref target="reference"><em>reference</em></xref>
       <xref target="reference"><em><strong>reference</strong></em></xref>
       <xref target="reference"><em>A</em> <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msup><mrow><mi>x</mi></mrow><mrow><mn>2</mn></mrow></msup></math><asciimath>x^2</asciimath></stem></xref>
       <xref target="reference"><em>A</em><fn reference="1"><p id="_"><em>B</em></p></fn></xref></p>
       </clause>
       </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(xmlpp(output))
  end

  it "processes formatting within crossreferences to non-existent anchor" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Section

      <<reference,_reference_>>
      <<reference,_**reference**_>>
      <<reference,_A_ stem:[x^2]>>
      <<reference,_A_ footnote:[_B_]>>
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections>
       <clause id="_" inline-header="false" obligation="normative">
       <title>Section</title>
       <p id="_"><xref target="reference"><em>reference</em></xref>
       <xref target="reference"><em><strong>reference</strong></em></xref>
       <xref target="reference"><em>A</em> <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msup><mrow><mi>x</mi></mrow><mrow><mn>2</mn></mrow></msup></math><asciimath>x^2</asciimath></stem></xref>
       <xref target="reference"><em>A</em><fn reference="1"><p id="_"><em>B</em></p></fn></xref></p>
       </clause>
       </sections>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(xmlpp(output))
  end

  it "processes combinations of crossreferences" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Section

      <<ref1;to!ref2>>
      <<from!ref1;to!ref2,text>>
      <<ref1;ref2>>
      <<ref1;and!ref2>>
      <<ref1;or!ref2,text>>
      <<from!ref1;to!ref2;and!ref3;to!ref4>>
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
       <sections>
       <clause id="_" inline-header="false" obligation="normative">
       <title>Section</title>
       <p id="_"><xref target="ref1"><location target="ref1" connective="from"/><location target="ref2" connective="to"/></xref>
       <xref target="ref1"><location target="ref1" connective="from"/><location target="ref2" connective="to"/>text</xref>
       <xref target="ref1"><location target="ref1" connective="and"/><location target="ref2" connective="and"/></xref>
       <xref target="ref1"><location target="ref1" connective="and"/><location target="ref2" connective="and"/></xref>
       <xref target="ref1"><location target="ref1" connective="and"/><location target="ref2" connective="or"/>text</xref>
       <xref target="ref1"><location target="ref1" connective="from"/><location target="ref2" connective="to"/><location target="ref3" connective="and"/><location target="ref4" connective="to"/></xref></p>
       </clause>
       </sections>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(xmlpp(output))
  end

  it "processes bibliographic anchors" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[ISO712,x]]] Reference
      * [[[ISO713]]] Reference

    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
      <sections>

      </sections><bibliography><references id="_" obligation="informative" normative="true">
        <title>Normative references</title>
        <p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
        <bibitem id="ISO712">
        <formattedref format="application/x-isodoc+xml">Reference</formattedref>
        <docidentifier>x</docidentifier>
      </bibitem>
        <bibitem id="ISO713">
        <formattedref format="application/x-isodoc+xml">Reference</formattedref>
        <docidentifier>ISO713</docidentifier>
        <docnumber>713</docnumber>
      </bibitem>
      </references>
      </bibliography>
      </standard-document>
    OUTPUT
    expect((strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(output)
  end

  it "processes formatting within bibliographic references" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Section

      <<reference,_reference_>>
      <<reference,_**reference**_>>
      <<reference,_A_ stem:[x^2]>>
      <<reference,_A_ footnote:[_B_]>>
      <<reference,clause=3.4.2, ISO 9000:2005 footnote:[Superseded by ISO 9000:2015.]>>

      [bibliography]
      == Normative References

      * [[[reference,ABC]]] Reference
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections><clause id="_" inline-header="false" obligation="normative">
       <title>Section</title>
       <p id="_"><eref type="inline" bibitemid="reference" citeas="ABC"><em>reference</em></eref>
       <eref type="inline" bibitemid="reference" citeas="ABC"><em><strong>reference</strong></em></eref>
       <eref type="inline" bibitemid="reference" citeas="ABC"><em>A</em> <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msup><mrow><mi>x</mi></mrow><mrow><mn>2</mn></mrow></msup></math><asciimath>x^2</asciimath></stem></eref>
       <eref type="inline" bibitemid="reference" citeas="ABC"><em>A</em><fn reference="1"><p id="_"><em>B</em></p></fn></eref>
       <eref type="inline" bibitemid="reference" citeas="ABC"><localityStack><locality type="clause"><referenceFrom>3.4.2</referenceFrom></locality></localityStack>ISO 9000:2005<fn reference="2"><p id="_">Superseded by ISO 9000:2015.</p></fn></eref></p>
       </clause>
       </sections><bibliography><references id="_" normative="true" obligation="informative">
       <title>Normative references</title><p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
       <bibitem id="reference">
       <formattedref format="application/x-isodoc+xml">Reference</formattedref>
       <docidentifier>ABC</docidentifier>
       </bibitem>
       </references></bibliography>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes formatting within term sources" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      [.source]
      <<reference,_reference_>>

      [.source]
      <<reference,_**reference**_>>

      [.source]
      <<reference,_A_ stem:[x^2]>>

      [.source]
      <<reference,_A_ footnote:[_B_]>>

      [.source]
      <<reference,clause=3.4.2, ISO 9000:2005 footnote:[Superseded by ISO 9000:2015.]>>

      [bibliography]
      == Normative References

      * [[[reference,ABC]]] Reference
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections><terms id="_" obligation="normative">
       <title>Terms and definitions</title><p id="_">For the purposes of this document,
           the following terms and definitions apply.</p>

       <term id="term-Term1"><preferred><expression><name>Term1</name></expression><termsource status="identical" type="authoritative">
       <origin bibitemid="reference" type="inline" citeas="ABC">
       <em>reference</em>
       </origin>
       </termsource><termsource status="identical" type="authoritative">
       <origin bibitemid="reference" type="inline" citeas="ABC">
       <em>
         <strong>reference</strong>
       </em>
       </origin>
       </termsource><termsource status="identical" type="authoritative">
       <origin bibitemid="reference" type="inline" citeas="ABC"><em>A</em> <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msup><mrow><mi>x</mi></mrow><mrow><mn>2</mn></mrow></msup></math><asciimath>x^2</asciimath></stem></origin>
       </termsource><termsource status="identical" type="authoritative">
       <origin bibitemid="reference" type="inline" citeas="ABC"><em>A</em><fn reference="1">
         <p id="_">
           <em>B</em>
         </p>
       </fn></origin>
       </termsource><termsource status="identical" type="authoritative">
       <origin bibitemid="reference" type="inline" citeas="ABC"><localityStack><locality type="clause"><referenceFrom>3.4.2</referenceFrom></locality></localityStack>ISO 9000:2005<fn reference="2">
         <p id="_">Superseded by ISO 9000:2015.</p>
       </fn></origin>
       </termsource></preferred>



       </term>
       </terms>
       </sections><bibliography><references id="_" normative="true" obligation="informative">
       <title>Normative references</title><p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
       <bibitem id="reference">
       <formattedref format="application/x-isodoc+xml">Reference</formattedref>
       <docidentifier>ABC</docidentifier>

       </bibitem>
       </references></bibliography>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes footnotes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      Hello!footnote:[Footnote text]

      == Title footnote:[Footnote text 2]

      Hello.footnote:abc[This is a repeated footnote]

      Repetition.footnote:abc[]
    INPUT
    output = <<~OUTPUT
                  #{BLANK_HDR}
                    <preface><foreword id="_" obligation="informative">
               <title>Foreword</title>
               <p id="_">Hello!<fn reference="1">
               <p id="_">Footnote text</p>
             </fn></p>
             </foreword></preface><sections>
             <clause id="_" inline-header="false" obligation="normative">
               <title>Title<fn reference="2">
               <p id="_">Footnote text 2</p>
             </fn></title>
             <p id='_'>
        Hello.
        <fn reference='3'>
          <p id='_'>This is a repeated footnote</p>
        </fn>
      </p>
      <p id='_'>
        Repetition.
        <fn reference='3'>
          <p id='_'>This is a repeated footnote</p>
        </fn>
      </p>
             </clause></sections>
             </standard-document>
    OUTPUT
    expect((strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(output)
  end

  it "processes index terms" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      ((See)) Index ((_term_)) and(((A~B~, stem:[alpha], &#x2c80;))).
    INPUT
    output = <<~OUTPUT
         #{BLANK_HDR}
        <sections>
            <p id="_">See<index><primary>See</primary></index> Index <em>term</em><index><primary><em>term</em></primary></index> and<index><primary>A<sub>B</sub></primary><secondary><stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>α</mi></math><asciimath>alpha</asciimath></stem></secondary><tertiary>Ⲁ</tertiary></index>.</p>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes format-specific inline pass" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      pass-format:rfc,html[<abc>X &gt; Y</abc> http://www.example.com (c)]
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
      <sections>
      <p id='_'>
      <passthrough formats='rfc,html'>&lt;abc&gt;X &gt; Y&lt;/abc&gt; http://www.example.com (c)</passthrough>
      </p>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes Metanorma XML inline pass" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      +<abc>X &gt;+ +++Y+++ pass:c[</abc>]
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
      <sections>
      <p id='_'>&lt;abc&gt;X &gt; Y &lt;/abc&gt;</p>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end
end
