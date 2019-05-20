require "spec_helper"
require "open3"

RSpec.describe Asciidoctor::Standoc do
    it "processes pass blocks" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [stem]
      ++++
      r = 1 % 
      r = 1 % 
      ++++

      [stem]
      ++++
      <mml:math><mml:msub xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"> <mml:mrow> <mml:mrow> <mml:mi mathvariant="bold-italic">F</mml:mi> </mml:mrow> </mml:mrow> <mml:mrow> <mml:mrow> <mml:mi mathvariant="bold-italic">&#x0391;</mml:mi> </mml:mrow> </mml:mrow> </mml:msub> </mml:math>
      ++++

      [latexmath]
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
         <formula id="_">
         <stem type="AsciiMath">r = 1 %
       r = 1 %</stem>
       </formula>

       <formula id="_">
         <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub> <mrow> <mrow> <mi mathvariant="bold-italic">F</mi> </mrow> </mrow> <mrow> <mrow> <mi mathvariant="bold-italic">Α</mi> </mrow> </mrow> </msub> </math></stem>
       </formula>
              <formula id="_">
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
       </sections>
       </standard-document>
    OUTPUT
  end

    it "ignores review blocks unless document is in draft mode" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      NOTE: This is a note
      INPUT
              #{BLANK_HDR}
       <sections>
         <terms id="_" obligation="normative">
         <title>Terms and definitions</title>
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
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      === Symbols

      NOTE: This is a note
      INPUT
              #{BLANK_HDR}
              <sections>
  <terms id="_" obligation="normative"><title>Terms, definitions, symbols and abbreviated terms</title><term id="_">
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
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      ....
      <LITERAL>
      ....
      INPUT
      #{BLANK_HDR}
       <sections>
           <figure id="_">
        <pre id="_">&lt;LITERAL&gt;</pre>
        </figure>
       </sections>
       </standard-document>

      OUTPUT
    end

    it "processes simple admonitions with Asciidoc names" do
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      === Symbols

      [example]
      This is an example
      INPUT
              #{BLANK_HDR}
<sections> 
  <terms id="_" obligation="normative"><title>Terms, definitions, symbols and abbreviated terms</title><term id="_">   
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
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [example]
      ====
      This is an example

      Amen
      ====
      INPUT
      #{BLANK_HDR}
       <sections>
         <example id="_"><p id="_">This is an example</p>
       <p id="_">Amen</p></example>
       </sections>
       </standard-document>
      OUTPUT
    end

    it "processes preambles" do
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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


    it "processes images" do
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      .Split-it-right sample divider
      image::spec/examples/rice_images/rice_image1.png[alttext]

      INPUT
      #{BLANK_HDR}
              <sections>
         <figure id="_">
         <name>Split-it-right sample divider</name>
                  <image src="spec/examples/rice_images/rice_image1.png" id="_" imagetype="PNG" height="auto" width="auto" alt="alttext"/>
       </figure>
       </sections>
       </standard-document>
      OUTPUT
    end

    it "accepts attributes on images" do
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [height=4,width=3,alt="IMAGE",filename="riceimg1.png"]
      image::spec/examples/rice_images/rice_image1.png[]

      INPUT
      #{BLANK_HDR}
              <sections>
         <figure id="_">
         <image src="spec/examples/rice_images/rice_image1.png" id="_" imagetype="PNG" height="4" width="3" alt="IMAGE" filename="riceimg1.png"/>
       </figure>
       </sections>
       </standard-document>
      OUTPUT
    end

    it "accepts auto for width and height attributes on images" do
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [height=4,width=auto]
      image::spec/examples/rice_images/rice_image1.png[]

      INPUT
      #{BLANK_HDR}
              <sections>
         <figure id="_">
         <image src="spec/examples/rice_images/rice_image1.png" id="_" imagetype="PNG" height="4" width="auto"/>
       </figure>
       </sections>
       </standard-document>
      OUTPUT
    end

        it "processes inline images with width and height attributes on images" do
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      Hello image:spec/examples/rice_images/rice_image1.png[alt, 4, 3], how are you?

      INPUT
      #{BLANK_HDR}
              <sections>
          <p id="_">Hello <image src="spec/examples/rice_images/rice_image1.png" id="_" imagetype="PNG" height="3" width="4" alt="alt"/>, how are you?</p>
       </figure>
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
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      .Caption
      [source,ruby,filename=sourcecode1.rb]
      --
      puts "Hello, world."
      %w{a b c}.each do |x|
        puts x
      end
      --
      INPUT
      #{BLANK_HDR}
       <sections>
         <sourcecode id="_" lang="ruby" filename="sourcecode1.rb"><name>Caption</name>puts "Hello, world."
       %w{a b c}.each do |x|
         puts x
       end</sourcecode>
       </sections>
       </standard-document>
      OUTPUT
    end

    it "processes callouts" do
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === Term1

      [.source]
      <<ISO2191,section=1>>
      INPUT
      #{BLANK_HDR}
       <sections>
         <terms id="_" obligation="normative">
         <title>Terms and definitions</title>
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
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
      [.recommendation,label="/ogc/recommendation/wfs/2",subject="user",inherit="/ss/584/2015/level/1"]
      ====
      I recommend this
      ====
    INPUT
             output = <<~"OUTPUT"
            #{BLANK_HDR}
       <sections>
  <recommendation id="_">
  <label>/ogc/recommendation/wfs/2</label>
<subject>user</subject>
<inherit>/ss/584/2015/level/1</inherit>
  <description><p id="_">I recommend this</p></description>
</recommendation>
       </sections>
       </standard-document>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true))).to be_equivalent_to output
  end

    it "processes requirement" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [.requirement]
      .Title
      ====
      I recommend this
      ====
    INPUT
             output = <<~"OUTPUT"
            #{BLANK_HDR}
       <sections>
  <requirement id="_"><title>Title</title>
  <description><p id="_">I recommend this</p></description>
</requirement>
       </sections>
       </standard-document>
    OUTPUT

    expect(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true))).to be_equivalent_to output
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

    expect(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true))).to be_equivalent_to output
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

    expect(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true))).to be_equivalent_to output
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

    expect(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true))).to be_equivalent_to output
  end

end
