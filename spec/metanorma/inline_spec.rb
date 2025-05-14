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
      #{BLANK_HDR}
      <sections>
      <p id="_">This is
      a paragraph with <xref target="x"/>
      markup <em>for</em>
      text, including <strong><em>nest</em></strong>ed markup.</p>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
      [custom-charset: weather, random-attr: x]#xyz#
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
      <stem type="MathML" block="false"><mml:math><mml:msub xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"> <mml:mrow> <mml:mrow> <mml:mi mathvariant="bold-italic">F</mml:mi> </mml:mrow> </mml:mrow> <mml:mrow> <mml:mrow> <mml:mi mathvariant="bold-italic">Α</mml:mi> </mml:mrow> </mml:mrow> </mml:msub> </mml:math></stem>
      <span class="fmt-hi">mark</span>
      <admitted><expression><name>alt</name></expression></admitted>
      <deprecates><expression><name>deprecated</name></expression></deprecates>
      <domain>domain</domain>
      <strike>strike</strike>
      <underline>underline</underline>
      <smallcap>smallcap</smallcap>
      <keyword>keyword</keyword>
      <span style="font-family:&quot;Noto Sans JP&quot;">text</span>
      <span style="font-family:'Noto Sans JP'">text</span>
      <span custom-charset="weather">xyz</span>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
            <stem type='MathML' block="false">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
         <mstyle displaystyle="false">
           <mi>n</mi>
           <mo>&lt;</mo>
           <mn>1</mn>
           <mtext>\\u00a0for all text\\u00a0</mtext>
         </mstyle>
       </math>
              <asciimath>n &lt; 1 " for all text "</asciimath>
            </stem>
          </p>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
            <stem type="MathML" block="false">
              <math xmlns="http://www.w3.org/1998/Math/MathML">
                <mstyle displaystyle="false">
                  <mi>n</mi>
                  <mo>&lt;</mo>
                  <mn>1</mn>
                </mstyle>
              </math>
              <asciimath>n &lt; 1</asciimath>
            </stem>
            <br/>
            <stem type="MathML" block="false">
              <math xmlns="http://www.w3.org/1998/Math/MathML">
                <mstyle displaystyle="false">
                  <mi>n</mi>
                  <mo>&lt;</mo>
                  <mn>1</mn>
                </mstyle>
              </math>
              <latexmath>n &lt; 1</latexmath>
            </stem>
            <stem type="MathML" block="false">
              <math xmlns="http://www.w3.org/1998/Math/MathML">
                <mstyle displaystyle="false">
                  <msup>
                    <mtext>‌</mtext>
                    <mn>199</mn>
                  </msup>
                  <msup>
                    <mtext>Hg</mtext>
                    <mo>+</mo>
                  </msup>
                </mstyle>
              </math>
              <asciimath>"‌"^199 "Hg"^+</asciimath>
            </stem>
          </p>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(Xml::C14n.format(output))
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
                 <sections>
            <p id="_">
              <stem type="MathML" block="false">
                <math xmlns="http://www.w3.org/1998/Math/MathML">
                  <mstyle displaystyle="false">
                    <mi>n</mi>
                    <mo>&lt;</mo>
                    <mn>1</mn>
                  </mstyle>
                </math>
                <asciimath>n &lt; 1</asciimath>
              </stem>
              <stem type="MathML" block="false">
                <math xmlns="http://www.w3.org/1998/Math/MathML">
                  <mstyle displaystyle="false">
                    <mi>n</mi>
                    <mo>&lt;</mo>
                    <mn>1</mn>
                  </mstyle>
                </math>
                <latexmath>n &lt; 1</latexmath>
              </stem>
              <stem type="MathML" block="false">
                <math xmlns="http://www.w3.org/1998/Math/MathML">
                  <mstyle displaystyle="false">
                    <msup>
                      <mtext>‌</mtext>
                      <mn>199</mn>
                    </msup>
                    <msup>
                      <mtext>Hg</mtext>
                      <mo>+</mo>
                    </msup>
                  </mstyle>
                </math>
                <asciimath>"‌"^199 "Hg"^+</asciimath>
              </stem>
            </p>
          </sections>
        </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(Xml::C14n.format(output))
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
              <stem type="MathML" block="false">
                     <math xmlns="http://www.w3.org/1998/Math/MathML">
         <mstyle displaystyle="false">
           <mi>n</mi>
           <mo>&lt;</mo>
           <mn>1</mn>
         </mstyle>
         </math>
              <asciimath>n &lt; 1</asciimath></stem>
              <stem type="MathML" block="false"> <math xmlns="http://www.w3.org/1998/Math/MathML">   <mstyle displaystyle="false">     <mi>n</mi>     <mo>&lt;</mo>     <mn>1</mn>   </mstyle> </math>
              <latexmath>n &lt; 1</latexmath>
              </stem>
              <stem type='MathML' block="false">
              <math xmlns="http://www.w3.org/1998/Math/MathML">
                               <mstyle displaystyle="false">
                    <msup>
                      <mtext>‌</mtext>
                      <mn>199</mn>
                    </msup>
                    <msup>
                      <mtext>Hg</mtext>
                      <mo>+</mo>
                    </msup>
                  </mstyle>
      </math>
      <asciimath>"&#x200c;"^199 "Hg"^+</asciimath>
      </stem>
            </p>
          </sections>
           </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(Xml::C14n.format(output))
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
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
      link:../example1[style=brackets]
      link:../example4[_Link_,style=brackets]
      http://example1.com[style=brackets]
      http://example4.com[_Link_,style=brackets]

      :attribute: http://www.example1.com[]
      Text

      :attribute: http://www.example2.com[]
      :attribute2: http://www.example3.com[]

      Text
      :attribute: http://www.example4.com[]

      link:../example[Link,update-type=true]

      {attribute} {attribute2}
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                    <sections>
           <p id="_">mailto:fred@example.com
      <link target="http://example.com"/>
      <link target="http://example.com">Link</link>
      <link target="http://example.com" alt="tip">Link</link>
      <link target="https://asciidoctor.org/now_this__link_works.html"/>
      <link target="http://example.com" update-type="true">Link</link>
      <link target="../example" update-type="true"/>
      <link target="../example1" style="brackets"/>
      <link target="../example4" style="brackets"><em>Link</em></link>
      <link target="http://example1.com" style="brackets"/>
      <link target="http://example4.com" style="brackets"><em>Link</em></link>
      </p>
      <p id="_">Text</p>
               <p id="_">Text
      :attribute: <link target="http://www.example4.com"/></p>
           <p id="_">
             <link target="../example" update-type="true">Link</link>
           </p>
           <p id="_">
             <link target="http://www.example2.com"/>
             <link target="http://www.example3.com"/>
           </p>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes bookmarks" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      Text [[bookmark]] Text
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
      <sections>
        <p id="_">Text <bookmark id="_" anchor="bookmark"/> Text</p>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
               <clause id="_" anchor="reference" inline-header="false" obligation="normative">
               <title>Section</title>
               <p id="_">Inline Reference to <xref target="reference"/>
             Footnoted Reference to <xref target="reference"/>
             Inline Reference with Text to <xref target="reference"><display-text>text</display-text></xref>
             Footnoted Reference with Text to <xref target="reference"><display-text>text</display-text></xref>
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
      <xref target='reference' case='capital' droploc='true'><display-text>text</display-text></xref>
      </p>
             </clause>
             </sections>
             </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(Xml::C14n.format(output))
  end

  it "processes crossreferences style and labels" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [[reference]]
      == Section

      Inline Reference to <<reference>>
      Inline Reference to <<reference,style=basic%>>
      Inline Reference to <<reference,style=basic>>
      Inline Reference to <<reference,style=%>>
      Inline Reference to <<reference,label=Subclause%>>
      Inline Reference to <<reference,style=basic%label=Subclause%>>
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
          <clause id="_" anchor="reference" inline-header='false' obligation='normative'>
            <title>Section</title>
            <p id='_'>
              Inline Reference to
              <xref target='reference'/>
               Inline Reference to
              <xref target='reference' style='basic'/>
               Inline Reference to
              <xref target='reference'><display-text>style=basic</display-text></xref>
               Inline Reference to
              <xref target='reference'><display-text>style=%</display-text></xref>
               Inline Reference to
              <xref target='reference' label="Subclause"/>
               Inline Reference to
              <xref target='reference' label="Subclause" style='basic'/>
            </p>
          </clause>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(Xml::C14n.format(output))
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
          <clause id="_" anchor="reference" inline-header='false' obligation='normative'>
            <title>Section</title>
            <p id='_'>
              Inline Reference to
              <xref target='reference' style='full'/>
               Inline Reference to
              <xref target='reference' style='basic'/>
            </p>
          </clause>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(Xml::C14n.format(output))
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
       <clause id="_" anchor="reference" inline-header="false" obligation="normative">
       <title>Section</title>
       <p id="_"><xref target="reference"><display-text><em>reference</em></display-text></xref>
       <xref target="reference"><display-text><em><strong>reference</strong></em></display-text></xref>
       <xref target="reference"><display-text><em>A</em> <stem type="MathML" block="false">
                           <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="false">
                        <msup>
                          <mi>x</mi>
                          <mn>2</mn>
                        </msup>
                      </mstyle>
                    </math>
          <asciimath>x^2</asciimath></stem></display-text></xref>
       <xref target="reference"><display-text><em>A</em><fn reference="1"><p id="_"><em>B</em></p></fn></display-text></xref></p>
       </clause>
       </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(Xml::C14n.format(output))
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
       <clause id="_" anchor="_section" inline-header="false" obligation="normative">
       <title>Section</title>
       <p id="_"><xref target="reference"><display-text><em>reference</em></display-text></xref>
       <xref target="reference"><display-text><em><strong>reference</strong></em></display-text></xref>
       <xref target="reference"><display-text><em>A</em> <stem type="MathML" block="false">
                           <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="false">
                        <msup>
                          <mi>x</mi>
                          <mn>2</mn>
                        </msup>
                      </mstyle>
                    </math>
        <asciimath>x^2</asciimath></stem></display-text></xref>
       <xref target="reference"><display-text><em>A</em><fn reference="1"><p id="_"><em>B</em></p></fn></display-text></xref></p>
       </clause>
       </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(Xml::C14n.format(output))
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
       <clause id="_" anchor="_section" inline-header="false" obligation="normative">
       <title>Section</title>
       <p id="_"><xref target="ref1"><location target="ref1" connective="from"/><location target="ref2" connective="to"/></xref>
       <xref target="ref1"><location target="ref1" connective="from"/><location target="ref2" connective="to"/><display-text>text</display-text></xref>
       <xref target="ref1"><location target="ref1" connective="and"/><location target="ref2" connective="and"/></xref>
       <xref target="ref1"><location target="ref1" connective="and"/><location target="ref2" connective="and"/></xref>
       <xref target="ref1"><location target="ref1" connective="and"/><location target="ref2" connective="or"/><display-text>text</display-text></xref>
       <xref target="ref1"><location target="ref1" connective="from"/><location target="ref2" connective="to"/><location target="ref3" connective="and"/><location target="ref4" connective="to"/></xref></p>
       </clause>
       </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to(Xml::C14n.format(output))
  end

  it "processes bibliographic anchors" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Clause

      <<ISO712>>
      <<ISO713>>

      [bibliography]
      == Normative References

      * [[[ISO712,x]]] Reference
      * [[[ISO713]]] Reference

    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
      <sections>
             <clause id="_" anchor="_clause" inline-header="false" obligation="normative">
                <title>Clause</title>
                <p id="_">
                   <eref type="inline" bibitemid="ISO712" citeas="x"/>
                   <eref type="inline" bibitemid="ISO713" citeas="ISO713"/>
                </p>
             </clause>
      </sections><bibliography><references id="_" anchor="_normative_references" obligation="informative" normative="true">
        <title>Normative references</title>
        <p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
        <bibitem id="_" anchor="ISO712">
        <formattedref format="application/x-isodoc+xml">Reference</formattedref>
        <docidentifier>x</docidentifier>
      </bibitem>
        <bibitem id="_" anchor="ISO713">
        <formattedref format="application/x-isodoc+xml">Reference</formattedref>
        <docidentifier>ISO713</docidentifier>
        <docnumber>713</docnumber>
      </bibitem>
      </references>
      </bibliography>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "treats triple-hyphen in bibliographic location as a single reference" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      <<ISO712,clause=3-4-5,table=9,text>>

      [bibliography]
      == Normative References

      * [[[ISO712,x]]] Reference
    INPUT
    output = <<~OUTPUT
      <preface>
           <foreword id="_" obligation="informative">
             <title>Foreword</title>
             <p id="_">
               <eref type="inline" bibitemid="ISO712" citeas="x"><localityStack><locality type="clause"><referenceFrom>3-4-5</referenceFrom></locality><locality type="table"><referenceFrom>9</referenceFrom></locality></localityStack><display-text>text</display-text></eref>
             </p>
           </foreword>
       </preface>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml = xml.at("//xmlns:preface")
    expect(strip_guid(Xml::C14n.format(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes combinations of bibliographic crossreferences" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Section

      <<ref1,clause=3-5>>
      <<ref1,clause=3;to!clause=5>>
      <<ref1,from!clause=3;to!clause=5,text>>
      <<ref1,clause=3;clause=5>>
      <<ref1,clause=3;and!clause=5>>
      <<ref1,clause=3;or!clause=5,text>>
      <<ref1,from!clause=3;to!clause=5;and!clause=8;to!clause=10>>
      <<ref1,from!clause=3;to!5;and!8;to!10>>

      [bibliography]
      == Bibliography

      * [[[ref1,XYZ]]] _Standard_
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
            <sections>
          <clause id="_" anchor="_section" inline-header='false' obligation='normative'>
            <title>Section</title>
            <p id='_'>
            <eref type='inline' bibitemid='ref1' citeas='XYZ'>
               <localityStack>
                 <locality type='clause'>
                   <referenceFrom>3</referenceFrom>
                   <referenceTo>5</referenceTo>
                 </locality>
               </localityStack>
             </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='from'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='to'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='from'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='to'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
                <display-text>text</display-text>
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='or'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
                <display-text>text</display-text>
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='from'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='to'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>8</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='to'>
                  <locality type='clause'>
                    <referenceFrom>10</referenceFrom>
                  </locality>
                </localityStack>
              </eref>
              <eref type="inline" bibitemid="ref1" citeas="XYZ">
                 <localityStack connective="from">
                   <locality type="clause">
                     <referenceFrom>3</referenceFrom>
                   </locality>
                 </localityStack>
                 <localityStack connective="and">
                   <locality type="clause">
                     <referenceFrom>5</referenceFrom>
                   </locality>
                 </localityStack>
                 <localityStack connective="and">
                   <locality type="clause">
                     <referenceFrom>8</referenceFrom>
                   </locality>
                 </localityStack>
                 <localityStack connective="and">
                   <locality type="clause">
                     <referenceFrom>10</referenceFrom>
                   </locality>
                 </localityStack>
               </eref>
            </p>
          </clause>
        </sections>
        <bibliography>
          <references id="_" anchor="_bibliography" normative='false' obligation='informative'>
            <title>Bibliography</title>
            <bibitem id="_" anchor="ref1">
              <formattedref format='application/x-isodoc+xml'>
                <em>Standard</em>
              </formattedref>
              <docidentifier>XYZ</docidentifier>
            </bibitem>
          </references>
        </bibliography>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
             <sections><clause id="_" anchor="_section" inline-header="false" obligation="normative">
       <title>Section</title>
       <p id="_"><eref type="inline" bibitemid="reference" citeas="ABC"><display-text><em>reference</em></display-text></eref>
       <eref type="inline" bibitemid="reference" citeas="ABC"><display-text><em><strong>reference</strong></em></display-text></eref>
       <eref type="inline" bibitemid="reference" citeas="ABC"><display-text><em>A</em> <stem type="MathML" block="false">
                    <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="false">
                        <msup>
                          <mi>x</mi>
                          <mn>2</mn>
                        </msup>
                      </mstyle>
                    </math>
        <asciimath>x^2</asciimath></stem></display-text></eref>
       <eref type="inline" bibitemid="reference" citeas="ABC"><display-text><em>A</em><fn reference="1"><p id="_"><em>B</em></p></fn></display-text></eref>
       <eref type="inline" bibitemid="reference" citeas="ABC"><localityStack><locality type="clause"><referenceFrom>3.4.2</referenceFrom></locality></localityStack><display-text>ISO 9000:2005<fn reference="2"><p id="_">Superseded by ISO 9000:2015.</p></fn></display-text></eref></p>
       </clause>
       </sections><bibliography><references id="_" anchor="_normative_references" normative="true" obligation="informative">
       <title>Normative references</title><p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
       <bibitem id="_" anchor="reference">
       <formattedref format="application/x-isodoc+xml">Reference</formattedref>
       <docidentifier>ABC</docidentifier>
       </bibitem>
       </references></bibliography>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes citation styles" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Foreword

      <<reference>>
      <<reference,style=IDLONG%>>
      <<reference,style=IDPROSE%>>

      [bibliography]
      == Normative References

      * [[[reference,B]]], span:docid.IDLONG[ISO 1234 (E)]. span:docid.IDPROSE[document 1234 of the ISO].
    INPUT
    output = <<~OUTPUT
      <foreword id="_" anchor="_foreword" obligation="informative">
        <title>Foreword</title>
        <p id="_">
          <eref type="inline" bibitemid="reference" citeas="IDLONG\\u00a0ISO\\u00a01234\\u00a0(E)"/>
          <eref type="inline" style="IDLONG" bibitemid="reference" citeas="IDLONG\\u00a0ISO\\u00a01234\\u00a0(E)"/>
          <eref type="inline" style="IDPROSE" bibitemid="reference" citeas="IDPROSE\\u00a0document\\u00a01234\\u00a0of\\u00a0the\\u00a0ISO"/>
        </p>
      </foreword>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(
                   Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
                   .at("//xmlns:foreword").to_xml,
                 )))
      .to be_equivalent_to Xml::C14n.format(output)
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
             <sections><terms id="_" anchor="_terms_and_definitions" obligation="normative">
       <title>Terms and definitions</title><p id="_">For the purposes of this document,
           the following terms and definitions apply.</p>

       <term id="_" anchor="term-Term1"><preferred><expression><name>Term1</name></expression><source status="identical" type="authoritative">
       <origin bibitemid="reference" type="inline" citeas="ABC">
       <display-text>
       <em>reference</em>
       </display-text>
       </origin>
       </source><source status="identical" type="authoritative">
       <origin bibitemid="reference" type="inline" citeas="ABC">
       <display-text>
       <em>
         <strong>reference</strong>
       </em>
       </display-text>
       </origin>
       </source><source status="identical" type="authoritative">
       <origin bibitemid="reference" type="inline" citeas="ABC">
        <display-text><em>A</em> <stem type="MathML" block="false">
                               <math xmlns="http://www.w3.org/1998/Math/MathML">
                          <mstyle displaystyle="false">
                            <msup>
                              <mi>x</mi>
                              <mn>2</mn>
                            </msup>
                          </mstyle>
                        </math>
                        <asciimath>x^2</asciimath>
                      </stem>
                      </display-text>
                      </origin>
       </source><source status="identical" type="authoritative">
       <origin bibitemid="reference" type="inline" citeas="ABC">
        <display-text><em>A</em><fn reference="1">
         <p id="_">
           <em>B</em>
         </p>
       </fn></display-text></origin>
       </source><source status="identical" type="authoritative">
       <origin bibitemid="reference" type="inline" citeas="ABC"><localityStack><locality type="clause"><referenceFrom>3.4.2</referenceFrom></locality></localityStack><display-text>ISO 9000:2005<fn reference="2">
         <p id="_">Superseded by ISO 9000:2015.</p>
       </fn></display-text></origin>
       </source></preferred>



       </term>
       </terms>
       </sections><bibliography><references id="_" anchor="_normative_references" normative="true" obligation="informative">
       <title>Normative references</title><p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
       <bibitem id="_" anchor="reference">
       <formattedref format="application/x-isodoc+xml">Reference</formattedref>
       <docidentifier>ABC</docidentifier>

       </bibitem>
       </references></bibliography>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes footnotes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      Hello!footnote:[Footnote text]

      == Title footnote:[Footnote text 2]

      Hello.footnote:abc[This is a repeated footnote (((a)))]

      Hidden reference.footnote:[hiddenref%Another footnote]

      Repetition.footnote:abc[]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
                    <preface><foreword id="_" obligation="informative">
               <title>Foreword</title>
               <p id="_">Hello!<fn reference="1">
               <p id="_">Footnote text</p>
             </fn></p>
             </foreword></preface>
          <sections>
             <clause id="_" anchor="_title_footnote_text_2" inline-header="false" obligation="normative">
                <title>
                   Title
                   <fn reference="2">
                      <p id="_">Footnote text 2</p>
                   </fn>
                </title>
                <p id="_">
                   Hello.
                   <fn reference="3">
                      <p id="_">
                         This is a repeated footnote
                         <index>
                            <primary>a</primary>
                         </index>
                      </p>
                   </fn>
                </p>
          <p id="_">
            Hidden reference.
            <fn reference="4" hiddenref="true">
               <p id="_">Another footnote</p>
            </fn>
         </p>
               <p id="_">
                   Repetition.
                   <fn reference="3">
                      <p id="_">This is a repeated footnote </p>
                   </fn>
                </p>
             </clause>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes index terms" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      ((See)) Index ((_term_)) and(((A~B~, stem:[alpha], &#x2c80;))).
    INPUT
    output = <<~OUTPUT
         #{BLANK_HDR}
        <sections>
        <p id="_">See<index><primary>See</primary></index> Index <em>term</em><index><primary><em>term</em></primary></index> and<index><primary>A<sub>B</sub></primary><secondary><stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML"><mstyle displaystyle="false"><mi>α</mi></mstyle></math><asciimath>alpha</asciimath></stem></secondary><tertiary>Ⲁ</tertiary></index>.</p>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
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
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes Metanorma XML inline pass" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      +<abc>X &gt;+ +++A<sub>b<sub>c</sub></sub>+++ pass:c[</abc>]
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
      <sections>
      <p id='_'>&lt;abc&gt;X &gt; A<sub>b<sub>c</sub></sub> &lt;/abc&gt;</p>
      </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes combinations of crossreferences" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Section

      <<ref1,clause=3-5>>
      <<ref1,clause=3;to!clause=5>>
      <<ref1,from!clause=3;to!clause=5,text>>
      <<ref1,clause=3;clause=5>>
      <<ref1,clause=3;and!clause=5>>
      <<ref1,clause=3;or!clause=5,text>>
      <<ref1,from!clause=3;to!clause=5;and!clause=8;to!clause=10>>

      [bibliography]
      == Bibliography

      * [[[ref1,XYZ]]] _Standard_
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
            <sections>
          <clause id="_" anchor="_section" inline-header='false' obligation='normative'>
            <title>Section</title>
            <p id='_'>
            <eref type='inline' bibitemid='ref1' citeas='XYZ'>
               <localityStack>
                 <locality type='clause'>
                   <referenceFrom>3</referenceFrom>
                   <referenceTo>5</referenceTo>
                 </locality>
               </localityStack>
             </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='from'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='to'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='from'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='to'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
                <display-text>text</display-text>
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='or'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
                <display-text>text</display-text>
              </eref>
              <eref type='inline' bibitemid='ref1' citeas='XYZ'>
                <localityStack connective='from'>
                  <locality type='clause'>
                    <referenceFrom>3</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='to'>
                  <locality type='clause'>
                    <referenceFrom>5</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='and'>
                  <locality type='clause'>
                    <referenceFrom>8</referenceFrom>
                  </locality>
                </localityStack>
                <localityStack connective='to'>
                  <locality type='clause'>
                    <referenceFrom>10</referenceFrom>
                  </locality>
                </localityStack>
              </eref>
            </p>
          </clause>
        </sections>
        <bibliography>
          <references id="_" anchor="_bibliography" normative='false' obligation='informative'>
            <title>Bibliography</title>
            <bibitem id="_" anchor="ref1">
              <formattedref format='application/x-isodoc+xml'>
                <em>Standard</em>
              </formattedref>
              <docidentifier>XYZ</docidentifier>
            </bibitem>
          </references>
        </bibliography>
      </metanorma>
    OUTPUT
    expect(strip_guid(Xml::C14n.format(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end
end
