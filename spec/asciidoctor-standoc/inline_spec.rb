require "spec_helper"

RSpec.describe Asciidoctor::Standoc do
    it "handles spacing around markup" do
    expect((strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to (<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      This is
      a paragraph with <<x>>
      markup _for_
      text, including **__nest__**ed markup.
      INPUT
      <?xml version="1.0" encoding="UTF-8"?>
<standard-document xmlns="https://www.metanorma.org/ns/standoc">
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
<doctype>article</doctype>
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
  end

  it "processes inline_quoted formatting" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
      [alt]#alt#
      [deprecated]#deprecated#
      [domain]#domain#
      [strike]#strike#
      [smallcap]#smallcap#
      [keyword]#keyword#
    INPUT
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
       <admitted>alt</admitted>
       <deprecates>deprecated</deprecates>
       <domain>domain</domain>
       <strike>strike</strike>
       <smallcap>smallcap</smallcap>
       <keyword>keyword</keyword>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "properly handles inline substitution" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{DUMBQUOTE_BLANK_HDR}

      stem:[n < 1] +
      latexmath:[n < 1]
      INPUT
            #{BLANK_HDR}
      <sections>
      <p id="_">
          <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>n</mi><mo>&lt;</mo><mn>1</mn></math></stem><br/>
          <stem type="MathML"> <math xmlns="http://www.w3.org/1998/Math/MathML" display="block">   <mrow>     <mi>n</mi>     <mo>&lt;</mo>     <mn>1</mn>   </mrow> </math></stem>
        </p>
      </sections>
       </standard-document>
      OUTPUT
  end

  it "normalises inline stem" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{DUMBQUOTE_BLANK_HDR}

      stem:[n < 1]
      latexmath:[n < 1]
      INPUT
            #{BLANK_HDR}
      <sections>
      <p id="_">
          <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>n</mi><mo>&lt;</mo><mn>1</mn></math></stem>
          <stem type="MathML"> <math xmlns="http://www.w3.org/1998/Math/MathML" display="block">   <mrow>     <mi>n</mi>     <mo>&lt;</mo>     <mn>1</mn>   </mrow> </math></stem>
        </p>
      </sections>
       </standard-document>
      OUTPUT
  end

  it "generates desired smart quotes for 'dd'" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      '99'.

    INPUT
            #{BLANK_HDR}
       <sections><p id="_">‘99’.</p>
       </sections>
       </standard-document>
    OUTPUT
  end


  it "processes breaks" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
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
  end

  it "processes links" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      mailto:fred@example.com
      http://example.com[]
      http://example.com[Link]
      http://example.com[Link,title="tip"]
    INPUT
            #{BLANK_HDR}
       <sections>
         <p id="_">mailto:fred@example.com
       <link target="http://example.com"/>
       <link target="http://example.com">Link</link>
       <link target="http://example.com" alt="tip">Link</link></p>
       </sections>
       </standard-document>
    OUTPUT
  end

    it "processes bookmarks" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      Text [[bookmark]] Text
    INPUT
            #{BLANK_HDR}
       <sections>
         <p id="_">Text <bookmark id="bookmark"/> Text</p>
       </sections>
       </standard-document>
    OUTPUT
    end

    it "processes crossreferences" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [[reference]]
      == Section

      Inline Reference to <<reference>>
      Footnoted Reference to <<reference,fn>>
      Inline Reference with Text to <<reference,text>>
      Footnoted Reference with Text to <<reference,fn: text>>
      Anchored Crossreference to other document <<a.adoc#b>>
    INPUT
       #{BLANK_HDR}
        <sections>
         <clause id="reference" inline-header="false" obligation="normative">
         <title>Section</title>
         <p id="_">Inline Reference to <xref target="reference"/>
       Footnoted Reference to <xref target="reference"/>
       Inline Reference with Text to <xref target="reference">text</xref>
       Footnoted Reference with Text to <xref target="reference">text</xref>
       Anchored Crossreference to other document <xref target="a#b"/></p>
       </clause>
       </sections>
       </standard-document>
      OUTPUT
    end

    it "processes bibliographic anchors" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[ISO712,x]]] Reference
      * [[[ISO713]]] Reference

    INPUT
            #{BLANK_HDR}
       <sections>

       </sections><bibliography><references id="_" obligation="informative" normative="true">
         <title>Normative References</title>
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
  end

  it "processes footnotes" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      Hello!footnote:[Footnote text]

      == Title footnote:[Footnote text 2]

      Hello.footnote:abc[This is a repeated footnote]

      Repetition.footnote:abc[]     
    INPUT
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
  end

  it "processes index terms" do 
          expect((strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to (<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      ((See)) Index ((_term_)) and(((A, B, C))).
   INPUT
   #{BLANK_HDR}
  <sections>
    <p id='_'>
      See
      <index primary='See'/> Index <em>term</em> <index primary='term'/> and<index primary='A' secondary='B' tertiary='C'/>.
    </p>
  </sections>
</standard-document>
   OUTPUT
  end


end
