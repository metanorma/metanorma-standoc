require "spec_helper"

RSpec.describe Asciidoctor::Standoc do
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
    INPUT
            #{BLANK_HDR}
       <sections>
         <formula id="_">
         <stem type="AsciiMath">r = 1 %
       r = 1 %</stem>
       </formula>

       <formula id="_">
         <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><msub> <mrow> <mrow> <mi mathvariant="bold-italic">F</mi> </mrow> </mrow> <mrow> <mrow> <mi mathvariant="bold-italic">Α</mi> </mrow> </mrow> </msub> </math></stem>
       </stem>
       </formula>
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
              #{BLANK_HDR}
       <version>
         <draft>1.2</draft>
       </version>
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
      .Safety Precautions
      ====
      While werewolves are hardy community members, keep in mind the following dietary concerns:

      . They are allergic to cinnamon.
      . More than two glasses of orange juice in 24 hours makes them howl in harmony with alarms and sirens.
      . Celery makes them sad.
      ====
      INPUT
      #{BLANK_HDR}
      <sections>
         <admonition id="_" type="safety precautions"><p id="_">While werewolves are hardy community members, keep in mind the following dietary concerns:</p>
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
       </termexample>
       </term>
       </terms>
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

    it "processes images" do
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      .Split-it-right sample divider
      image::spec/examples/rice_images/rice_image1.png[]

      INPUT
      #{BLANK_HDR}
              <sections>
         <figure id="_">
         <name>Split-it-right sample divider</name>
                  <image src="spec/examples/rice_images/rice_image1.png" id="_" imagetype="PNG" height="auto" width="auto"/>
       </figure>
       </sections>
       </standard-document>
      OUTPUT
    end

    it "accepts width and height attributes on images" do
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [height=4,width=3]
      image::spec/examples/rice_images/rice_image1.png[]

      INPUT
      #{BLANK_HDR}
              <sections>
         <figure id="_">
         <image src="spec/examples/rice_images/rice_image1.png" id="_" imagetype="PNG" height="4" width="3"/>
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
      [source,ruby]
      --
      puts "Hello, world."
      %w{a b c}.each do |x|
        puts x
      end
      --
      INPUT
      #{BLANK_HDR}
       <sections>
         <sourcecode id="_">puts "Hello, world."
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
              <sections><sourcecode id="_">puts "Hello, world." <callout target="_">1</callout>
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


end
