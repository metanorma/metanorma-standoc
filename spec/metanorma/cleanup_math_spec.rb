require "spec_helper"
require "relaton_iec"
require "fileutils"

RSpec.describe Metanorma::Standoc do
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
      stem:[0.9321]
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
            <stem type="MathML" block="false">
            <math xmlns="http://www.w3.org/1998/Math/MathML">
              <mstyle displaystyle="false">
              <mn>0.9321</mn>
              </mstyle>
            </math>
            <asciimath>0.9321</asciimath>
          </stem>
          </p>
        </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "profiles number formatting" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :number-presentation: notation=e,exponent_sign=plus,precision=4
      :number-presentation-profile-3: notation=scientific,exponent_sign=nil,decimal=","
      :number-presentation-profile-x: notation=engineering,precision=4,times=','

      number:345[]
      number:345[profile=3]
      number:345[profile=x]
      number:345[profile=x,precision=5]
      number:345[profile=x,precision=5,digit_count=10,precision=nil]
      number:345[precision=5,digit_count=10,exponent_sign=nil]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <sections>
           <p id="_">
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="notation='basic',exponent_sign='plus',precision='4'">0.345e3</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="notation='scientific',precision='4',decimal=','">0.345e3</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="notation='engineering',exponent_sign='plus',precision='4',times=','">0.345e3</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="notation='engineering',exponent_sign='plus',precision='5',times=','">0.345e3</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="notation='engineering',exponent_sign='plus',times=',',digit_count='10'">0.345e3</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="notation='e',precision='5',digit_count='10'">0.345e3</mn>
               </math>
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
              <mrow>
                   <mstyle mathvariant="sans-serif">
                     <mi>cd</mi>
                   </mstyle>
                 </mrow>
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

  private

  def mock_mathml_italicise(string)
    allow_any_instance_of(Metanorma::Standoc::Cleanup)
      .to receive(:mathml_mi_italics).and_return(string)
  end
end
