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
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "profiles number formatting in macros" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :number-presentation: notation=e,,exponent_sign=plus,precision=4
      :number-presentation-profile-3: notation=scientific,exponent_sign=nil,decimal=",",e=" "
      :number-presentation-profile-x: notation=engineering,precision=4,times=',',e=""
      :number-presentation-profile-y: group_digits=3,fraction_group_digits=3,decimal=",",group=&#x2009;,notation=general

      number:145[]
      number:245[profile=3]
      number:345[profile=x]
      number:445[profile=x,precision=5]
      number:545[profile=x,precision=5,digit_count=10,precision=nil]
      number:645[precision=5,digit_count=10,exponent_sign=nil]
      number:745[profile=y]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <sections>
           <p id="_">
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="notation='e',exponent_sign='plus',precision='4'">0.145e3</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="notation='scientific',precision='4',decimal=',',e=' '">0.245e3</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="notation='engineering',exponent_sign='plus',precision='4',times=',',e=''">0.345e3</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="notation='engineering',exponent_sign='plus',precision='5',times=',',e=''">0.445e3</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="notation='engineering',exponent_sign='plus',times=',',e='',digit_count='10'">0.545e3</mn>
               </math>
             </stem>
             <stem type="MathML">
               <math xmlns="http://www.w3.org/1998/Math/MathML">
                 <mn data-metanorma-numberformat="notation='e',precision='5',digit_count='10'">0.645e3</mn>
               </math>
             </stem>
             <stem type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mn data-metanorma-numberformat="notation='general',exponent_sign='plus',precision='4',group_digits='3',fraction_group_digits='3',decimal=',',group='\\u2009'">0.745e3</mn>
                   </math>
             </stem>
           </p>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "applies number formatting in formulas" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :stem:

      [stem]
      ++++
      1 + x
      ++++

      [stem,number-format="notation=basic,exponent_sign='plus',precision=4"]
      ++++
      2 + x
      ++++

      [stem,number-format=default]
      ++++
      3 + x
      ++++

      stem:[number-format="notation=basic,exponent_sign=&#x25;,precision=4"% 1 xx 3]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
          <sections>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn>1</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>1 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='basic',exponent_sign='plus',precision='4'">2</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>2 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='basic'">3</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>3 + x</asciimath>
                </stem>
             </formula>
              <p id="_">
                <stem block="false" type="MathML">
                  <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="false">
                        <mn data-metanorma-numberformat="notation='basic,exponent_sign=%,precision=4'">1</mn>
                        <mo>×</mo>
                        <mn data-metanorma-numberformat="notation='basic,exponent_sign=%,precision=4'">3</mn>
                      </mstyle>
                  </math>
                  <asciimath> 1 xx 3</asciimath>
                </stem>
            </p>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "profiles number formatting in formulas" do
    input = <<~INPUT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :stem:
      :number-presentation: notation=e,group=&#x2009;,exponent_sign=plus,precision=4
      :number-presentation-profile-3: notation=scientific,exponent_sign=nil,decimal=","
      :number-presentation-profile-x: notation=engineering,precision=4,times=','

      [stem]
      ++++
      1 + x
      ++++

      [stem,number-format="notation=basic,significant='7',precision=4"]
      ++++
      2 + x
      ++++

      [stem,number-format=default]
      ++++
      3 + x
      ++++

      [stem,number-format=profile=3]
      ++++
      4 + x
      ++++

      [stem,number-format=profile=x,precision=5]
      ++++
      5 + x
      ++++

      [stem,number-format=nil]
      ++++
      6 + x
      ++++
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='e',group='\\u2009',exponent_sign='plus',precision='4'">1</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>1 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='basic',group='\\u2009',exponent_sign='plus',precision='4',significant='7'">2</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>2 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='e',group='\\u2009',exponent_sign='plus',precision='4'">3</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>3 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='scientific',group='\\u2009',precision='4',decimal=','">4</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>4 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='engineering',group='\\u2009',exponent_sign='plus',precision='4',times=','">5</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>5 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn>6</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>6 + x</asciimath>
                </stem>
             </formula>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)

    output = <<~OUTPUT
      #{BLANK_HDR}
       <sections>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="precision='6',decimal=':'">1</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>1 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='basic',group='\\u2009',exponent_sign='plus',precision='4',significant='7'">2</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>2 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='e',group='\\u2009',exponent_sign='plus',precision='4'">3</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>3 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='scientific',group='\\u2009',precision='4',decimal=','">4</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>4 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='engineering',group='\\u2009',exponent_sign='plus',precision='4',times=','">5</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>5 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn>6</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>6 + x</asciimath>
                </stem>
             </formula>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input
      .sub(":number-presentation:",
           ":number-presentation-formula: precision=6,decimal=:\n" \
              ":number-presentation:"), *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)

    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='e',group='\\u2009',exponent_sign='plus',precision='4'">1</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>1 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='basic',group='\\u2009',exponent_sign='plus',precision='4',significant='7'">2</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>2 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='e',group='\\u2009',exponent_sign='plus',precision='4'">3</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>3 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='scientific',group='\\u2009',precision='4',decimal=','">4</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>4 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='engineering',group='\\u2009',exponent_sign='plus',precision='4',times=','">5</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>5 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn>6</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>6 + x</asciimath>
                </stem>
             </formula>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input
      .sub(":number-presentation:",
           ":number-presentation-formula: number-presentation\n" \
              ":number-presentation:"), *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)

    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn>1</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>1 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='basic',group='\\u2009',exponent_sign='plus',precision='4',significant='7'">2</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>2 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='e',group='\\u2009',exponent_sign='plus',precision='4'">3</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>3 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='scientific',group='\\u2009',precision='4',decimal=','">4</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>4 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn data-metanorma-numberformat="notation='engineering',group='\\u2009',exponent_sign='plus',precision='4',times=','">5</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>5 + x</asciimath>
                </stem>
             </formula>
             <formula id="_">
                <stem block="true" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="true">
                         <mn>6</mn>
                         <mo>+</mo>
                         <mi>x</mi>
                      </mstyle>
                   </math>
                   <asciimath>6 + x</asciimath>
                </stem>
             </formula>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input
      .sub(":number-presentation:",
           ":number-presentation-formula: nil\n" \
              ":number-presentation:"), *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "cleans up text MathML" do
    input = <<~INPUT
      #{BLANK_HDR.sub(/<metanorma [^>]+>/, '<standard-document>')}
      <sections>
      <stem type="MathML">&lt;math xmlns="http://www.w3.org/1998/Math/MathML"&gt;&lt;mfrac&gt;&lt;mn&gt;1&lt;/mn&gt;&lt;mi&gt;r&lt;/mi&gt;&lt;/mfrac&gt;&lt;/math&gt;</stem>
      </sections>
      </metanorma>
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR.sub(/<metanorma [^>]+>/, '<standard-document>')}
      <sections>
      <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mfrac><mn>1</mn><mi>r</mi></mfrac></math></stem>
      </sections>
      </metanorma>
    OUTPUT
    expect(Canon.format_xml(Metanorma::Standoc::Converter.new(nil, *OPTIONS)
      .cleanup(Nokogiri::XML(input)).to_xml))
      .to be_equivalent_to Canon.format_xml(output)
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
                <mo rspace="thickmathspace">⁢</mo>
              <mrow xref="U_NISTu7">
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
    expect(strip_guid(Canon.format_xml(Nokogiri::XML(
      Asciidoctor.convert(input, *OPTIONS),
    ).at("//xmlns:sections").to_xml)))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "converts UnitsML to MathML" do
    input = <<~INPUT
      = Document title
      Author
      :stem:

      stem:[1 "unitsml(cd)"]

      stem:[1 
      "unitsml(cd)"]

      stem:[7 "unitsml(m*kg^-2)" + 8 "unitsml(m*kg^-3)"]
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR.sub('<metanorma-extension>', <<~EXT
          <metanorma-extension>
             <UnitsML xmlns="https://schema.unitsml.org/unitsml/1.0">
                <UnitSet>
                   <Unit dimensionURL="#NISTd7" id="U_NISTu7">
                      <UnitSystem name="SI" type="SI_derived" lang="en-US"/>
                      <UnitName lang="en">candela</UnitName>
                      <UnitSymbol type="HTML">cd</UnitSymbol>
                      <UnitSymbol type="MathMl">
                         <math xmlns="http://www.w3.org/1998/Math/MathML">
                            <mi mathvariant="normal">cd</mi>
                         </math>
                      </UnitSymbol>
                   </Unit>
                   <Unit dimensionURL="#D_LM-2" id="U_m.kg-2">
                      <UnitSystem name="SI" type="SI_derived" lang="en-US"/>
                      <UnitName lang="en">m*kg^-2</UnitName>
                      <UnitSymbol type="HTML">
                         m\\u00a0kg
                         <sup>−2</sup>
                      </UnitSymbol>
                      <UnitSymbol type="MathMl">
                         <math xmlns="http://www.w3.org/1998/Math/MathML">
                            <mi mathvariant="normal">m</mi>
                            <mo rspace="thickmathspace">⁢</mo>
                            <msup>
                               <mrow>
                                  <mi mathvariant="normal">kg</mi>
                               </mrow>
                               <mrow>
                                  <mo>−</mo>
                                  <mn>2</mn>
                               </mrow>
                            </msup>
                         </math>
                      </UnitSymbol>
                      <RootUnits>
                         <EnumeratedRootUnit unit="meter"/>
                         <EnumeratedRootUnit unit="gram" prefix="k" powerNumerator="-2"/>
                      </RootUnits>
                   </Unit>
                   <Unit dimensionURL="#D_LM-3" id="U_m.kg-3">
                      <UnitSystem name="SI" type="SI_derived" lang="en-US"/>
                      <UnitName lang="en">m*kg^-3</UnitName>
                      <UnitSymbol type="HTML">
                         m\\u00a0kg
                         <sup>−3</sup>
                      </UnitSymbol>
                      <UnitSymbol type="MathMl">
                         <math xmlns="http://www.w3.org/1998/Math/MathML">
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
                         </math>
                      </UnitSymbol>
                      <RootUnits>
                         <EnumeratedRootUnit unit="meter"/>
                         <EnumeratedRootUnit unit="gram" prefix="k" powerNumerator="-3"/>
                      </RootUnits>
                   </Unit>
                </UnitSet>
                <QuantitySet>
                   <Quantity id="NISTq7" quantityType="base" dimensionURL="#NISTd7">
                      <QuantityName lang="en-US">luminous intensity</QuantityName>
                   </Quantity>
                </QuantitySet>
                <DimensionSet>
                   <Dimension id="NISTd7">
                      <LuminousIntensity symbol="J" powerNumerator="1"/>
                   </Dimension>
                   <Dimension id="D_LM-2">
                      <Length symbol="L" powerNumerator="1"/>
                      <Mass symbol="M" powerNumerator="-2"/>
                   </Dimension>
                   <Dimension id="D_LM-3">
                      <Length symbol="L" powerNumerator="1"/>
                      <Mass symbol="M" powerNumerator="-3"/>
                   </Dimension>
                </DimensionSet>
                <PrefixSet>
                   <Prefix prefixBase="10" prefixPower="3" id="NISTp10_3">
                      <PrefixName lang="en">kilo</PrefixName>
                      <PrefixSymbol type="ASCII">k</PrefixSymbol>
                      <PrefixSymbol type="unicode">k</PrefixSymbol>
                      <PrefixSymbol type="LaTeX">k</PrefixSymbol>
                      <PrefixSymbol type="HTML">k</PrefixSymbol>
                   </Prefix>
                </PrefixSet>
             </UnitsML>
      EXT
      )}
          <sections>
             <p id="_">
                <stem block="false" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="false">
                         <mn>1</mn>
                         <mo rspace="thickmathspace">⁢</mo>
                         <mrow xref="U_NISTu7">
                            <mstyle mathvariant="normal">
                               <mi>cd</mi>
                            </mstyle>
                         </mrow>
                      </mstyle>
                   </math>
                   <asciimath>1 "unitsml(cd)"</asciimath>
                </stem>
             </p>
             <p id="_">
                <stem block="false" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="false">
                         <mn>1</mn>
                         <mo rspace="thickmathspace">⁢</mo>
                         <mrow xref="U_NISTu7">
                            <mstyle mathvariant="normal">
                               <mi>cd</mi>
                            </mstyle>
                         </mrow>
                      </mstyle>
                   </math>
                   <asciimath>1
       "unitsml(cd)"</asciimath>
                </stem>
             </p>
             <p id="_">
                <stem block="false" type="MathML">
                   <math xmlns="http://www.w3.org/1998/Math/MathML">
                      <mstyle displaystyle="false">
                         <mn>7</mn>
                         <mo rspace="thickmathspace">⁢</mo>
                         <mrow xref="U_m.kg-2">
                            <mstyle mathvariant="normal">
                               <mi>m</mi>
                            </mstyle>
                            <mi rspace="thickmathspace">⁢</mi>
                            <msup>
                               <mstyle mathvariant="normal">
                                  <mi>kg</mi>
                               </mstyle>
                               <mrow>
                                  <mo>−</mo>
                                  <mn>2</mn>
                               </mrow>
                            </msup>
                         </mrow>
                         <mo>+</mo>
                         <mn>8</mn>
                         <mo rspace="thickmathspace">⁢</mo>
                         <mrow xref="U_m.kg-3">
                            <mstyle mathvariant="normal">
                               <mi>m</mi>
                            </mstyle>
                            <mi rspace="thickmathspace">⁢</mi>
                            <msup>
                               <mstyle mathvariant="normal">
                                  <mi>kg</mi>
                               </mstyle>
                               <mrow>
                                  <mo>−</mo>
                                  <mn>3</mn>
                               </mrow>
                            </msup>
                         </mrow>
                      </mstyle>
                   </math>
                   <asciimath>7 "unitsml(m*kg^-2)" + 8 "unitsml(m*kg^-3)"</asciimath>
                </stem>
             </p>
          </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
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

    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(<<~"OUTPUT")
        #{BLANK_HDR}
                 <sections>
            <formula id="_">
              <stem type="MathML" block="true"><math xmlns="http://www.w3.org/1998/Math/MathML">
          <mi>A</mi><mo>+</mo><mi>a</mi><mo>+</mo><mi>Α</mi><mo>+</mo><mi>α</mi><mo>+</mo><mi>AB</mi><mstyle mathvariant="italic"><mrow><mi>Α</mi></mrow></mstyle></stem>
            </formula>
          </sections>
        </metanorma>
      OUTPUT
    mock_mathml_italicise({ uppergreek: false, upperroman: true,
                            lowergreek: true, lowerroman: true })
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(<<~"OUTPUT")
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
        </metanorma>
      OUTPUT
    mock_mathml_italicise({ uppergreek: true, upperroman: false,
                            lowergreek: true, lowerroman: true })
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(<<~"OUTPUT")
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
        </metanorma>
      OUTPUT
    mock_mathml_italicise({ uppergreek: true, upperroman: true,
                            lowergreek: false, lowerroman: true })
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(<<~"OUTPUT")
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
        </metanorma>
      OUTPUT
    mock_mathml_italicise({ uppergreek: true, upperroman: true,
                            lowergreek: true, lowerroman: false })
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(<<~"OUTPUT")
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
        </metanorma>
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
