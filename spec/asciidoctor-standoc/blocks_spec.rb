require "spec_helper"
require "open3"

RSpec.describe Asciidoctor::Standoc do
    it "processes pass blocks" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      
      ++++
      <abc>X &gt; Y</abc>
      ++++
    INPUT
        #{BLANK_HDR}
       <sections>
       <abc>X &gt; Y</abc>
       </sections>
       </standard-document>
    OUTPUT
  end

  it "processes open blocks" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      --
      x

      y

      z
      --
    INPUT
        #{BLANK_HDR}
       <sections><p id="_">x</p>
       <p id="_">y</p>
       <p id="_">z</p></sections>
       </standard-document>
    OUTPUT
  end

  it "processes stem blocks" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [stem%inequality]
      ++++
      r = 1 % 
      r = 1 % 
      ++++

      [stem%unnumbered]
      ++++
      <mml:math><mml:msub xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"> <mml:mrow> <mml:mrow> <mml:mi mathvariant="bold-italic">F</mml:mi> </mml:mrow> </mml:mrow> <mml:mrow> <mml:mrow> <mml:mi mathvariant="bold-italic">&#x0391;</mml:mi> </mml:mrow> </mml:mrow> </mml:msub> </mml:math>
      ++++

      [latexmath,subsequence=A]
      ++++
      M =
      \\begin{bmatrix}
      -\\sin λ_0 & \\cos λ_0 & 0 \\\\
      -\\sin φ_0 \\cos λ_0 & -\\sin φ_0 \\sin λ_0 & \\cos φ_0 \\\\
      \\cos φ_0 \\cos λ_0 & \\cos φ_0 \\sin λ_0 & \\sin φ_0
      \\end{bmatrix}
      ++++

    INPUT
            #{BLANK_HDR}
       <sections>
         <formula id="_" inequality="true">
         <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>r</mi><mo>=</mo><mn>1</mn><mi>%</mi><mi>r</mi><mo>=</mo><mn>1</mn><mi>%</mi></math></stem>
       </formula>

       <formula id="_" unnumbered="true">
         <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub> <mrow> <mrow> <mi mathvariant="bold-italic">F</mi> </mrow> </mrow> <mrow> <mrow> <mi mathvariant="bold-italic">Α</mi> </mrow> </mrow> </msub> </math></stem>
       </formula>
              <formula id="_" subsequence="A">
         <stem type="MathML">
       <math xmlns="http://www.w3.org/1998/Math/MathML" alttext="M=\\begin{bmatrix}-\\sin\\lambda_{0}&amp;\\cos\\lambda_{0}&amp;0\\\\&#10;-\\sin\\varphi_{0}\\cos\\lambda_{0}&amp;-\\sin\\varphi_{0}\\sin\\lambda_{0}&amp;\\cos\\varphi_{0%&#10;}\\\\&#10;\\cos\\varphi_{0}\\cos\\lambda_{0}&amp;\\cos\\varphi_{0}\\sin\\lambda_{0}&amp;\\sin\\varphi_{0}%&#10;\\end{bmatrix}" display="block">
         <mrow>
           <mi>M</mi>
           <mo>=</mo>
           <mrow>
             <mo>[</mo>
             <mtable columnspacing="5pt" displaystyle="true" rowspacing="0pt">
               <mtr>
                 <mtd columnalign="center">
                   <mrow>
                     <mo>-</mo>
                     <mrow>
                       <mi>sin</mi>
                       <mo>⁡</mo>
                       <msub>
                         <mi>λ</mi>
                         <mn>0</mn>
                       </msub>
                     </mrow>
                   </mrow>
                 </mtd>
                 <mtd columnalign="center">
                   <mrow>
                     <mi>cos</mi>
                     <mo>⁡</mo>
                     <msub>
                       <mi>λ</mi>
                       <mn>0</mn>
                     </msub>
                   </mrow>
                 </mtd>
                 <mtd columnalign="center">
                   <mn>0</mn>
                 </mtd>
               </mtr>
               <mtr>
                 <mtd columnalign="center">
                   <mrow>
                     <mo>-</mo>
                     <mrow>
                       <mrow>
                         <mi>sin</mi>
                         <mo>⁡</mo>
                         <msub>
                           <mi>φ</mi>
                           <mn>0</mn>
                         </msub>
                       </mrow>
                       <mo>⁢</mo>
                       <mrow>
                         <mi>cos</mi>
                         <mo>⁡</mo>
                         <msub>
                           <mi>λ</mi>
                           <mn>0</mn>
                         </msub>
                       </mrow>
                     </mrow>
                   </mrow>
                 </mtd>
                 <mtd columnalign="center">
                   <mrow>
                     <mo>-</mo>
                     <mrow>
                       <mrow>
                         <mi>sin</mi>
                         <mo>⁡</mo>
                         <msub>
                           <mi>φ</mi>
                           <mn>0</mn>
                         </msub>
                       </mrow>
                       <mo>⁢</mo>
                       <mrow>
                         <mi>sin</mi>
                         <mo>⁡</mo>
                         <msub>
                           <mi>λ</mi>
                           <mn>0</mn>
                         </msub>
                       </mrow>
                     </mrow>
                   </mrow>
                 </mtd>
                 <mtd columnalign="center">
                   <mrow>
                     <mi>cos</mi>
                     <mo>⁡</mo>
                     <msub>
                       <mi>φ</mi>
                       <mn>0</mn>
                     </msub>
                   </mrow>
                 </mtd>
               </mtr>
               <mtr>
                 <mtd columnalign="center">
                   <mrow>
                     <mrow>
                       <mi>cos</mi>
                       <mo>⁡</mo>
                       <msub>
                         <mi>φ</mi>
                         <mn>0</mn>
                       </msub>
                     </mrow>
                     <mo>⁢</mo>
                     <mrow>
                       <mi>cos</mi>
                       <mo>⁡</mo>
                       <msub>
                         <mi>λ</mi>
                         <mn>0</mn>
                       </msub>
                     </mrow>
                   </mrow>
                 </mtd>
                 <mtd columnalign="center">
                   <mrow>
                     <mrow>
                       <mi>cos</mi>
                       <mo>⁡</mo>
                       <msub>
                         <mi>φ</mi>
                         <mn>0</mn>
                       </msub>
                     </mrow>
                     <mo>⁢</mo>
                     <mrow>
                       <mi>sin</mi>
                       <mo>⁡</mo>
                       <msub>
                         <mi>λ</mi>
                         <mn>0</mn>
                       </msub>
                     </mrow>
                   </mrow>
                 </mtd>
                 <mtd columnalign="center">
                   <mrow>
                     <mi>sin</mi>
                     <mo>⁡</mo>
                     <msub>
                       <mi>φ</mi>
                       <mn>0</mn>
                     </msub>
                   </mrow>
                 </mtd>
               </mtr>
             </mtable>
             <mo>]</mo>
           </mrow>
         </mrow>
       </math></stem>
       </formula>
       </sections></standard-document>
    OUTPUT
  end
  
    it "ignores review blocks unless document is in draft mode" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [[foreword]]
      .Foreword
      Foreword

      [reviewer=ISO,date=20170101,from=foreword,to=foreword]
      ****
      A Foreword shall appear in each document. The generic text is shown here. It does not contain requirements, recommendations or permissions.

      For further information on the Foreword, see *ISO/IEC Directives, Part 2, 2016, Clause 12.*
      ****
      INPUT
              #{BLANK_HDR}
       <sections><p id="foreword">Foreword</p>
       </sections>
       </standard-document>
      OUTPUT
    end

  it "processes review blocks if document is in draft mode" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :draft: 1.2

      [[foreword]]
      .Foreword
      Foreword

      [reviewer=ISO,date=20170101,from=foreword,to=foreword]
      ****
      A Foreword shall appear in each document. The generic text is shown here. It does not contain requirements, recommendations or permissions.

      For further information on the Foreword, see *ISO/IEC Directives, Part 2, 2016, Clause 12.*
      ****
      INPUT
      <standard-document xmlns="http://riboseinc.com/isoxml">
       <bibdata type="standard">
         <title language="en" format="text/plain">Document title</title>


         <version>
           <draft>1.2</draft>
         </version>
         <language>en</language>
         <script>Latn</script>
         <status><stage>published</stage></status>
         <copyright>
           <from>#{Date.today.year}</from>
         </copyright>
         <ext>
         <doctype>article</doctype>
         </ext>
       </bibdata>
       <sections><p id="foreword">Foreword</p>
       <review reviewer="ISO" id="_" date="20170101T00:00:00Z" from="foreword" to="foreword"><p id="_">A Foreword shall appear in each document. The generic text is shown here. It does not contain requirements, recommendations or permissions.</p>
       <p id="_">For further information on the Foreword, see <strong>ISO/IEC Directives, Part 2, 2016, Clause 12.</strong></p></review></sections>
       </standard-document>

      OUTPUT
  end

  it "processes term notes" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      NOTE: This is a note
      INPUT
              #{BLANK_HDR}
       <sections>
         <terms id="_" obligation="normative">
         <title>Terms and definitions</title>
         <p id="_">For the purposes of this document, the following terms and definitions apply.</p>
         <term id="_">
         <preferred>Term1</preferred>
         <termnote id="_">
         <p id="_">This is a note</p>
       </termnote>
       </term>
       </terms>
       </sections>
       </standard-document>
      OUTPUT
  end

    it "processes term notes as plain notes in nonterm clauses" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      [.nonterm]
      === Term1

      NOTE: This is a note
      INPUT
              #{BLANK_HDR}
              <sections>
  <terms id="_" obligation="normative">
  <title>Terms and definitions</title>
         <p id="_">No terms and definitions are listed in this document.</p>
  <clause id="_" inline-header="false" obligation="normative">
  <title>Term1</title>
  <note id="_">
  <p id="_">This is a note</p>
</note>
</clause>
</terms>
</sections>
</standard-document>

      OUTPUT
  end

        it "processes term notes as plain notes in definitions subclauses of terms & definitions" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      === Symbols

      NOTE: This is a note
      INPUT
              #{BLANK_HDR}
              <sections>
  <terms id="_" obligation="normative"><title>Terms, definitions, symbols and abbreviated terms</title>
<p id="_">For the purposes of this document, the following terms and definitions apply.</p>
<term id="_">
  <preferred>Term1</preferred>
</term>
<definitions id="_">
  <title>Symbols</title>
  <note id="_">
  <p id="_">This is a note</p>
</note>
</definitions></terms>
</sections>
</standard-document>

      OUTPUT
  end

    it "processes notes" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      NOTE: This is a note

      == Clause 1


      NOTE: This is a note
      INPUT
              #{BLANK_HDR}
              <preface><foreword obligation="informative">
         <title>Foreword</title>
         <note id="_">
         <p id="_">This is a note</p>
       </note>
       </foreword></preface><sections>
       <clause id="_" inline-header="false" obligation="normative">
         <title>Clause 1</title>
         <note id="_">
         <p id="_">This is a note</p>
       </note>
       </clause></sections>

       </standard-document>

      OUTPUT
    end

    it "processes literals" do
      expect((strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to (<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      [alt=Literal]
      ....
      <LITERAL>
      FIGURATIVE
      ....
      INPUT
      #{BLANK_HDR}
       <sections>
           <figure id="_">
        <pre alt="Literal" id="_">&lt;LITERAL&gt;
        FIGURATIVE
        </pre>
        </figure>
       </sections>
       </standard-document>

      OUTPUT
    end

    it "processes simple admonitions with Asciidoc names" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      CAUTION: Only use paddy or parboiled rice for the determination of husked rice yield.
      INPUT
      #{BLANK_HDR}
       <sections>
         <admonition id="_" type="caution">
         <p id="_">Only use paddy or parboiled rice for the determination of husked rice yield.</p>
       </admonition>
       </sections>
       </standard-document>

      OUTPUT
    end


    it "processes complex admonitions with non-Asciidoc names" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [CAUTION,type=Safety Precautions]
      .Precautions
      ====
      While werewolves are hardy community members, keep in mind the following dietary concerns:

      . They are allergic to cinnamon.
      . More than two glasses of orange juice in 24 hours makes them howl in harmony with alarms and sirens.
      . Celery makes them sad.
      ====
      INPUT
      #{BLANK_HDR}
      <sections>
         <admonition id="_" type="safety precautions"><name>Precautions</name><p id="_">While werewolves are hardy community members, keep in mind the following dietary concerns:</p>
       <ol id="_" type="arabic">
         <li>
           <p id="_">They are allergic to cinnamon.</p>
         </li>
         <li>
           <p id="_">More than two glasses of orange juice in 24 hours makes them howl in harmony with alarms and sirens.</p>
         </li>
         <li>
           <p id="_">Celery makes them sad.</p>
         </li>
       </ol></admonition>
       </sections>
       </standard-document>

      OUTPUT
    end

    it "processes term examples" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      [example]
      This is an example
      INPUT
      #{BLANK_HDR}
      <sections>
  <terms id="_" obligation="normative">
  <title>Terms and definitions</title>
<p id="_">For the purposes of this document, the following terms and definitions apply.</p>
  <term id="_">
  <preferred>Term1</preferred>

<termexample id="_">
  <p id="_">This is an example</p>
</termexample></term>
</terms>
</sections>
</standard-document>
      OUTPUT
    end

    it "processes term examples as plain examples in nonterm clauses" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      [.nonterm]
      === Term1

      [example]
      This is an example
      INPUT
      #{BLANK_HDR}
<sections> 
  <terms id="_" obligation="normative">  
  <title>Terms and definitions</title>  
<p id="_">No terms and definitions are listed in this document.</p>
  <clause id="_" inline-header="false" obligation="normative">   
  <title>Term1</title>   
  <example id="_">    
  <p id="_">This is an example</p>    
</example>   
</clause>  
</terms> 
</sections>
</standard-document>
      OUTPUT
    end

  it "processes term examples as plain examples in definitions subclauses of terms & definitions" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      === Symbols

      [example]
      This is an example
      INPUT
              #{BLANK_HDR}
<sections> 
  <terms id="_" obligation="normative"><title>Terms, definitions, symbols and abbreviated terms</title>
<p id="_">For the purposes of this document, the following terms and definitions apply.</p><term id="_">   
  <preferred>Term1</preferred>   
</term>  
<definitions id="_">   
  <title>Symbols</title>   
  <example id="_">    
  <p id="_">This is an example</p>    
</example>   
</definitions></terms> 
</sections>
</standard-document>
      OUTPUT
  end


    it "processes examples" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [example,subsequence=A]
      .Title
      ====
      This is an example

      Amen
      ====

      [example%unnumbered]
      ====
      This is another example
      ====
      INPUT
      #{BLANK_HDR}
       <sections>
         <example id="_" subsequence="A">
         <name>Title</name>
        <p id="_">This is an example</p>
       <p id="_">Amen</p></example>
         <example id="_" unnumbered="true"><p id="_">This is another example</p></example>
       </sections>
       </standard-document>
      OUTPUT
    end

    it "processes preambles" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      This is a preamble

      == Section 1
      INPUT
      #{BLANK_HDR}
             <preface><foreword obligation="informative">
         <title>Foreword</title>
         <p id="_">This is a preamble</p>
       </foreword></preface><sections>
       <clause id="_" inline-header="false" obligation="normative">
         <title>Section 1</title>
       </clause></sections>
       </standard-document>
      OUTPUT
    end

    it "processes preambles with titles" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      .Preamble
      This is a preamble

      == Section 1
      INPUT
      #{BLANK_HDR}
             <preface><foreword obligation="informative">
         <title>Preamble</title>
         <p id="_">This is a preamble</p>
       </foreword></preface><sections>
       <clause id="_" inline-header="false" obligation="normative">
         <title>Section 1</title>
       </clause></sections>
       </standard-document>
      OUTPUT
    end

  it "processes subfigures" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [[figureC-2]]
      .Stages of gelatinization
      ====
      .Initial stages: No grains are fully gelatinized (ungelatinized starch granules are visible inside the kernels)
      image::spec/examples/rice_images/rice_image3_1.png[]

      .Intermediate stages: Some fully gelatinized kernels are visible
      image::spec/examples/rice_images/rice_image3_2.png[]

      .Final stages: All kernels are fully gelatinized
      image::spec/examples/rice_images/rice_image3_3.png[]
      ====
    INPUT
       #{BLANK_HDR}
              <sections>
         <figure id="figureC-2"><name>Stages of gelatinization</name><figure id="_">
         <name>Initial stages: No grains are fully gelatinized (ungelatinized starch granules are visible inside the kernels)</name>
         <image src="spec/examples/rice_images/rice_image3_1.png" id="_" mimetype="image/png" height="auto" width="auto"/>
       </figure>
       <figure id="_">
         <name>Intermediate stages: Some fully gelatinized kernels are visible</name>
         <image src="spec/examples/rice_images/rice_image3_2.png" id="_" mimetype="image/png" height="auto" width="auto"/>
       </figure>
       <figure id="_">
         <name>Final stages: All kernels are fully gelatinized</name>
         <image src="spec/examples/rice_images/rice_image3_3.png" id="_" mimetype="image/png" height="auto" width="auto"/>
       </figure></figure>
       </sections>
       </standard-document>
    OUTPUT
  end

    it "processes figures within examples" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [[figureC-2]]
      .Stages of gelatinization
      ====
      .Initial stages: No grains are fully gelatinized (ungelatinized starch granules are visible inside the kernels)
      image::spec/examples/rice_images/rice_image3_1.png[]

      Text

      .Intermediate stages: Some fully gelatinized kernels are visible
      image::spec/examples/rice_images/rice_image3_2.png[]

      .Final stages: All kernels are fully gelatinized
      image::spec/examples/rice_images/rice_image3_3.png[]
      ====
    INPUT
       #{BLANK_HDR}
              <sections>
         <example id="figureC-2"><name>Stages of gelatinization</name><figure id="_">
         <name>Initial stages: No grains are fully gelatinized (ungelatinized starch granules are visible inside the kernels)</name>
         <image src="spec/examples/rice_images/rice_image3_1.png" id="_" mimetype="image/png" height="auto" width="auto"/>
       </figure>
       <p id="_">Text</p>
       <figure id="_">
         <name>Intermediate stages: Some fully gelatinized kernels are visible</name>
         <image src="spec/examples/rice_images/rice_image3_2.png" id="_" mimetype="image/png" height="auto" width="auto"/>
       </figure>
       <figure id="_">
         <name>Final stages: All kernels are fully gelatinized</name>
         <image src="spec/examples/rice_images/rice_image3_3.png" id="_" mimetype="image/png" height="auto" width="auto"/>
       </figure></example>
       </sections>
       </standard-document>
    OUTPUT
  end


    it "processes images" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [%unnumbered]
      .Split-it-right sample divider
      image::spec/examples/rice_images/rice_image1.png[alttext]

      INPUT
      #{BLANK_HDR}
              <sections>
         <figure id="_" unnumbered="true">
         <name>Split-it-right sample divider</name>
                  <image src="spec/examples/rice_images/rice_image1.png" id="_" mimetype="image/png" height="auto" width="auto" alt="alttext"/>
       </figure>
       </sections>
       </standard-document>
      OUTPUT
    end

    it "processes data URI images" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [subsequence=A]
      .Split-it-right sample divider
      image::data:image/*;base64,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[alttext]

      INPUT
      #{BLANK_HDR}
              <sections>
         <figure id="_" subsequence="A">
         <name>Split-it-right sample divider</name>
           <image src="data:image/png;base64,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" id="_" mimetype="image/png" height="auto" width="auto" alt="alttext"/>
       </figure>
       </sections>
       </standard-document>
      OUTPUT
    end

    it "accepts attributes on images" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [height=4,width=3,alt="IMAGE",filename="riceimg1.png",titleattr="TITLE"]
      .Caption
      image::spec/examples/rice_images/rice_image1.png[]

      INPUT
      #{BLANK_HDR}
              <sections>
         <figure id="_"><name>Caption</name>
         <image src="spec/examples/rice_images/rice_image1.png" id="_" mimetype="image/png" height="4" width="3" title="TITLE" alt="IMAGE" filename="riceimg1.png"/>
       </figure>
       </sections>
       </standard-document>
      OUTPUT
    end

    it "accepts auto for width and height attributes on images" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [height=4,width=auto]
      image::spec/examples/rice_images/rice_image1.png[]

      INPUT
      #{BLANK_HDR}
              <sections>
         <figure id="_">
         <image src="spec/examples/rice_images/rice_image1.png" id="_" mimetype="image/png" height="4" width="auto"/>
       </figure>
       </sections>
       </standard-document>
      OUTPUT
    end

        it "processes inline images with width and height attributes on images" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      Hello image:spec/examples/rice_images/rice_image1.png[alt, 4, 3], how are you?

      INPUT
      #{BLANK_HDR}
              <sections>
          <p id="_">Hello <image src="spec/examples/rice_images/rice_image1.png" id="_" mimetype="image/png" height="3" width="4" alt="alt"/>, how are you?</p>
       </sections>
       </standard-document>
      OUTPUT
    end

        it "processes images as datauri" do
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to include '<image src="data:image/png;base64'
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :data-uri-image:

      .Split-it-right sample divider
      image::spec/examples/rice_images/rice_image1.png[]
      INPUT
    end

    it "accepts alignment attribute on paragraphs" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [align=right]
      This para is right-aligned.
      INPUT
      #{BLANK_HDR}
      <sections>
         <p align="right" id="_">This para is right-aligned.</p>
       </sections>
      </standard-document>
      OUTPUT
    end

    it "processes blockquotes" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [quote, ISO, "ISO7301,section 1"]
      ____
      Block quotation
      ____
      INPUT
      #{BLANK_HDR}
       <sections>
         <quote id="_">
         <source type="inline" bibitemid="ISO7301" citeas=""><locality type="section"><referenceFrom>1</referenceFrom></locality></source>
         <author>ISO</author>
         <p id="_">Block quotation</p>
       </quote>
       </sections>
       </standard-document>
      OUTPUT
    end

    it "processes source code" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      .Caption
      [source%unnumbered,ruby,filename=sourcecode1.rb]
      --
      puts "Hello, world."
      %w{a b c}.each do |x|
        puts x
      end
      --
      INPUT
      #{BLANK_HDR}
       <sections>
         <sourcecode id="_" lang="ruby" filename="sourcecode1.rb" unnumbered="true"><name>Caption</name>puts "Hello, world."
       %w{a b c}.each do |x|
         puts x
       end</sourcecode>
       </sections>
       </standard-document>
      OUTPUT
    end

    it "processes callouts" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [source,ruby]
      --
      puts "Hello, world." <1>
      %w{a b c}.each do |x|
        puts x <2>
      end
      --
      <1> This is one callout
      <2> This is another callout
      INPUT
      #{BLANK_HDR}
              <sections><sourcecode id="_" lang="ruby">puts "Hello, world." <callout target="_">1</callout>
       %w{a b c}.each do |x|
         puts x <callout target="_">2</callout>
       end<annotation id="_">
         <p id="_">This is one callout</p>
       </annotation><annotation id="_">
         <p id="_">This is another callout</p>
       </annotation></sourcecode>
       </sections>
       </standard-document>
      OUTPUT
    end

    it "processes unmodified term sources" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      [.source]
      <<ISO2191,section=1>>
      INPUT
      #{BLANK_HDR}
       <sections>
         <terms id="_" obligation="normative">
         <title>Terms and definitions</title><p id="_">For the purposes of this document,
       the following terms and definitions apply.</p>
         <term id="_">
         <preferred>Term1</preferred>
         <termsource status="identical">
         <origin bibitemid="ISO2191" type="inline" citeas=""><locality type="section"><referenceFrom>1</referenceFrom></locality></origin>
       </termsource>
       </term>
       </terms>
       </sections>
       </standard-document>
      OUTPUT
    end

    it "processes modified term sources" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      [.source]
      <<ISO2191,section=1>>, with adjustments
      INPUT
      #{BLANK_HDR}
            <sections>
         <terms id="_" obligation="normative">
         <title>Terms and definitions</title>
         <p id="_">For the purposes of this document,
       the following terms and definitions apply.</p>
         <term id="_">
         <preferred>Term1</preferred>
         <termsource status="modified">
         <origin bibitemid="ISO2191" type="inline" citeas=""><locality type="section"><referenceFrom>1</referenceFrom></locality></origin>
         <modification>
           <p id="_">with adjustments</p>
         </modification>
       </termsource>
       </term>
       </terms>
       </sections>
       </standard-document>
      OUTPUT
    end

        it "processes recommendation" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [.recommendation,label="/ogc/recommendation/wfs/2",subject="user",inherit="/ss/584/2015/level/1; /ss/584/2015/level/2",options="unnumbered",type=verification,model=ogc]
      ====
      I recommend this
      ====
    INPUT
             output = <<~"OUTPUT"
            #{BLANK_HDR}
       <sections>
  <recommendation id="_" unnumbered="true" type="verification" model="ogc">
  <label>/ogc/recommendation/wfs/2</label>
<subject>user</subject>
<inherit>/ss/584/2015/level/1</inherit>
<inherit>/ss/584/2015/level/2</inherit>
  <description><p id="_">I recommend this</p></description>
</recommendation>
       </sections>
       </standard-document>
    OUTPUT

    expect(xmlpp(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(output)
  end

    it "processes requirement" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [.requirement,subsequence="A"]
      .Title
      ====
      I recommend this
      ====
    INPUT
             output = <<~"OUTPUT"
            #{BLANK_HDR}
       <sections>
  <requirement id="_" subsequence="A"><title>Title</title>
  <description><p id="_">I recommend this</p></description>
</requirement>
       </sections>
       </standard-document>
    OUTPUT

    expect(xmlpp(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(output)
  end

        it "processes permission" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [.permission]
      ====
      I recommend this
      ====
    INPUT
             output = <<~"OUTPUT"
            #{BLANK_HDR}
       <sections>
  <permission id="_">
  <description><p id="_">I recommend this</p></description>
</permission>
       </sections>
       </standard-document>
    OUTPUT

    expect(xmlpp(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(output)
  end


       it "processes nested permissions" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [.permission]
      ====
      I permit this

      =====
      Example 2
      =====

      [.permission]
      =====
      I also permit this
      =====
      ====
    INPUT
             output = <<~"OUTPUT"
            #{BLANK_HDR}
       <sections>
         <permission id="_"><description><p id="_">I permit this</p>
<example id="_">
  <p id="_">Example 2</p>
</example></description>
<permission id="_">
  <description><p id="_">I also permit this</p></description>
</permission></permission>
</sections>
</standard-document>
    OUTPUT

    expect(xmlpp(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(output)
  end

        it "processes recommendation with internal markup of structure" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [.recommendation,label="/ogc/recommendation/wfs/2",subject="user",classification="control-class:Technical;priority:P0;family:System and Communications Protection,System and Communications Protocols",obligation="permission,recommendation",filename="reqt1.rq"]
      ====
      I recommend _this_.

      [.specification,type="tabular"]
      --
      This is the object of the recommendation:
      |===
      |Object |Value
      |Mission | Accomplished
      |===
      -- 

      As for the measurement targets,

      [.measurement-target]
      --
      The measurement target shall be measured as:
      [stem]
      ++++
      r/1 = 0
      ++++
      --

      [.verification]
      --
      The following code will be run for verification:

      [source,CoreRoot]
      ----
      CoreRoot(success): HttpResponse
      if (success)
        recommendation(label: success-response)
      end
      ----
      --
      
      [.import%exclude]
      --
      [source,CoreRoot]
      ----
      success-response()
      ----
      --
      ====
    INPUT
             output = <<~"OUTPUT"
            #{BLANK_HDR}
       <sections>
       <recommendation id="_"  obligation="permission,recommendation" filename="reqt1.rq"><label>/ogc/recommendation/wfs/2</label><subject>user</subject>
<classification><tag>control-class</tag><value>Technical</value></classification><classification><tag>priority</tag><value>P0</value></classification><classification><tag>family</tag><value>System and Communications Protection</value></classification><classification><tag>family</tag><value>System and Communications Protocols</value></classification>
        <description><p id="_">I recommend <em>this</em>.</p>
       </description><specification exclude="false" type="tabular"><p id="_">This is the object of the recommendation:</p><table id="_">  <tbody>    <tr>      <td align="left">Object</td>      <td align="left">Value</td>    </tr>    <tr>      <td align="left">Mission</td>      <td align="left">Accomplished</td>    </tr>  </tbody></table></specification><description>
       <p id="_">As for the measurement targets,</p>
       </description><measurement-target exclude="false"><p id="_">The measurement target shall be measured as:</p><formula id="_">  <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mfrac><mi>r</mi><mn>1</mn></mfrac><mo>=</mo><mn>0</mn></math></stem></formula></measurement-target>
       <verification exclude="false"><p id="_">The following code will be run for verification:</p><sourcecode  lang="CoreRoot" id="_">CoreRoot(success): HttpResponse
if (success)
  recommendation(label: success-response)
end</sourcecode></verification>
       <import exclude="true">  <sourcecode  lang="CoreRoot" id="_">success-response()</sourcecode></import></recommendation>
       </sections>
       </standard-document>
    OUTPUT

    expect(xmlpp(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp(output)
  end

end
