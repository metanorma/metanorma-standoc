require "spec_helper"
require "relaton/iec"
require "fileutils"

RSpec.describe Metanorma::Standoc do
  it "permits multiple preferred terms and admitted terms, " \
     "and treats them as synonyms in concepts" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === First Designation

      preferred:[Second Designation]

      alt:[Third Designation]

      alt:[Fourth Designation]

      deprecated:[Fourth Designation]

      deprecated:[Fifth Designation]

      related:see[Sixth Designation]

      related:contrast[Seventh Designation]

      Definition

      === Sixth Designation

      === Seventh Designation

      == Clause

      {{First Designation}}

      {{Second Designation}}

      {{Third Designation}}

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <sections>
           <terms id="_" obligation="normative">
             <title id="_">Terms and definitions</title>
             <p id="_">For the purposes of this document,
           the following terms and definitions apply.</p>
             <term id="_" anchor="term-First-Designation">
               <preferred>
                 <expression>
                   <name>First Designation</name>
                 </expression>
               </preferred>
               <preferred>
                 <expression>
                   <name>Second Designation</name>
                 </expression>
               </preferred>
               <admitted>
                 <expression>
                   <name>Third Designation</name>
                 </expression>
               </admitted>
               <admitted>
                 <expression>
                   <name>Fourth Designation</name>
                 </expression>
               </admitted>
               <deprecates>
                 <expression>
                   <name>Fourth Designation</name>
                 </expression>
               </deprecates>
               <deprecates>
                 <expression>
                   <name>Fifth Designation</name>
                 </expression>
               </deprecates>
               <related type="see">
                 <preferred>
                   <expression>
                     <name>Sixth Designation</name>
                   </expression>
                 </preferred>
                 <xref target="term-Sixth-Designation"><display-text>Sixth Designation</display-text></xref>
               </related>
               <related type="contrast">
                 <preferred>
                   <expression>
                     <name>Seventh Designation</name>
                   </expression>
                 </preferred>
                 <xref target="term-Seventh-Designation"><display-text>Seventh Designation</display-text></xref>
               </related>
               <definition id="_">
                 <verbal-definition id="_">
                   <p id="_">Definition</p>
                 </verbal-definition>
               </definition>
             </term>
             <term id="_" anchor="term-Sixth-Designation">
               <preferred>
                 <expression>
                   <name>Sixth Designation</name>
                 </expression>
               </preferred>
             </term>
             <term id="_" anchor="term-Seventh-Designation">
               <preferred>
                 <expression>
                   <name>Seventh Designation</name>
                 </expression>
               </preferred>
             </term>
           </terms>
           <clause id="_" inline-header="false" obligation="normative">
             <title id="_">Clause</title>
             <p id="_">
               <concept>
                 <refterm>First Designation</refterm>
                 <renderterm>First Designation</renderterm>
                 <xref target="term-First-Designation"/>
               </concept>
             </p>
             <p id="_">
               <concept>
                 <refterm>First Designation</refterm>
                 <renderterm>Second Designation</renderterm>
                 <xref target="term-First-Designation"/>
               </concept>
             </p>
             <p id="_">
               <concept>
                 <refterm>First Designation</refterm>
                 <renderterm>Third Designation</renderterm>
                 <xref target="term-First-Designation"/>
               </concept>
             </p>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "respects case in tagging of concepts" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === First Designation

      Definition

      === First designation

      Definition

      == Clause

      {{First Designation}}

      {{First designation}}

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
        <sections>
          <terms id="_" obligation='normative'>
            <title id="_">Terms and definitions</title>
            <p id='_'>For the purposes of this document, the following terms and definitions apply.</p>
            <term id="_" anchor="term-First-Designation">
              <preferred>
                <expression>
                  <name>First Designation</name>
                </expression>
              </preferred>
              <definition id="_">
                <verbal-definition id="_">
                  <p id='_'>Definition</p>
                </verbal-definition>
              </definition>
            </term>
            <term id="_" anchor="term-First-designation">
              <preferred>
                <expression>
                  <name>First designation</name>
                </expression>
              </preferred>
              <definition id="_">
                <verbal-definition id="_">
                  <p id='_'>Definition</p>
                </verbal-definition>
              </definition>
            </term>
          </terms>
          <clause id="_" inline-header='false' obligation='normative'>
            <title id="_">Clause</title>
            <p id='_'>
              <concept>
                <refterm>First Designation</refterm>
                <renderterm>First Designation</renderterm>
                <xref target='term-First-Designation'/>
              </concept>
            </p>
            <p id='_'>
              <concept>
                <refterm>First designation</refterm>
                <renderterm>First designation</renderterm>
                <xref target='term-First-designation'/>
              </concept>
            </p>
          </clause>
        </sections>
      </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "uses domains in disambiguation of concept mentions" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === First Designation

      preferred:[Second Designation]

      alt:[Third Designation]

      domain:[Rice]

      === First Designation

      preferred:[Second Designation]

      alt:[Third Designation]

      domain:[Wheat]

      === First Designation

      preferred:[Second Designation]

      alt:[Third Designation]

      Definition

      == Clause

      {{First Designation}}

      {{Second Designation}}

      {{Third Designation}}


      {{<Rice> First Designation}}

      {{<Rice> Second Designation}}

      {{<Rice> Third Designation}}


      {{<Wheat> First Designation}}

      {{<Wheat> Second Designation}}

      {{<Wheat> Third Designation}}

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <sections>
           <terms id="_" obligation="normative">
             <title id="_">Terms and definitions</title>
             <p id="_">For the purposes of this document,
           the following terms and definitions apply.</p>
             <term id="_" anchor="term-_Rice_-First-Designation">
               <preferred>
                 <expression>
                   <name>First Designation</name>
                 </expression>
               </preferred>
               <preferred>
                 <expression>
                   <name>Second Designation</name>
                 </expression>
               </preferred>
               <admitted>
                 <expression>
                   <name>Third Designation</name>
                 </expression>
               </admitted>
               <domain>Rice</domain>
             </term>
             <term id="_" anchor="term-_Wheat_-First-Designation">
               <preferred>
                 <expression>
                   <name>First Designation</name>
                 </expression>
               </preferred>
               <preferred>
                 <expression>
                   <name>Second Designation</name>
                 </expression>
               </preferred>
               <admitted>
                 <expression>
                   <name>Third Designation</name>
                 </expression>
               </admitted>
               <domain>Wheat</domain>
             </term>
             <term id="_" anchor="term-First-Designation">
               <preferred>
                 <expression>
                   <name>First Designation</name>
                 </expression>
               </preferred>
               <preferred>
                 <expression>
                   <name>Second Designation</name>
                 </expression>
               </preferred>
               <admitted>
                 <expression>
                   <name>Third Designation</name>
                 </expression>
               </admitted>
               <definition id="_">
                 <verbal-definition id="_">
                   <p id="_">Definition</p>
                 </verbal-definition>
               </definition>
             </term>
           </terms>
                      <clause id="_" inline-header="false" obligation="normative">
             <title id="_">Clause</title>
             <p id="_">
               <concept>
                 <refterm>First Designation</refterm>
                 <renderterm>First Designation</renderterm>
                 <xref target="term-First-Designation"/>
               </concept>
             </p>
             <p id="_">
               <concept>
                 <refterm>First Designation</refterm>
                 <renderterm>Second Designation</renderterm>
                 <xref target="term-First-Designation"/>
               </concept>
             </p>
             <p id="_">
               <concept>
                 <refterm>First Designation</refterm>
                 <renderterm>Third Designation</renderterm>
                 <xref target="term-First-Designation"/>
               </concept>
             </p>
             <p id="_">
               <concept>
                 <refterm>&lt;Rice&gt; First Designation</refterm>
                 <renderterm>&lt;Rice&gt; First Designation</renderterm>
                 <xref target="term-_Rice_-First-Designation"/>
               </concept>
             </p>
             <p id="_">
               <concept>
                 <refterm>&lt;Rice&gt; First Designation</refterm>
                 <renderterm>&lt;Rice&gt; Second Designation</renderterm>
                 <xref target="term-_Rice_-First-Designation"/>
               </concept>
             </p>
             <p id="_">
               <concept>
                 <refterm>&lt;Rice&gt; First Designation</refterm>
                 <renderterm>&lt;Rice&gt; Third Designation</renderterm>
                 <xref target="term-_Rice_-First-Designation"/>
               </concept>
             </p>
             <p id="_">
               <concept>
                 <refterm>&lt;Wheat&gt; First Designation</refterm>
                 <renderterm>&lt;Wheat&gt; First Designation</renderterm>
                 <xref target="term-_Wheat_-First-Designation"/>
               </concept>
             </p>
             <p id="_">
               <concept>
                 <refterm>&lt;Wheat&gt; First Designation</refterm>
                 <renderterm>&lt;Wheat&gt; Second Designation</renderterm>
                 <xref target="term-_Wheat_-First-Designation"/>
               </concept>
             </p>
             <p id="_">
               <concept>
                 <refterm>&lt;Wheat&gt; First Designation</refterm>
                 <renderterm>&lt;Wheat&gt; Third Designation</renderterm>
                 <xref target="term-_Wheat_-First-Designation"/>
               </concept>
             </p>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "drop domains for unambiguous concept mentions" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      == Terms and Definitions

      === First Designation

      preferred:[Second Designation]

      alt:[Third Designation]

      domain:[Rice]

      === First Designation

      domain:[Wheat]

      == Clause

      {{First Designation}}

      {{Second Designation}}

      {{Third Designation}}

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <sections>
           <terms id="_" obligation="normative">
             <title id="_">Terms and definitions</title>
             <p id="_">For the purposes of this document,#{' '}
           the following terms and definitions apply.</p>
             <term id="_" anchor="term-_Rice_-First-Designation">
               <preferred>
                 <expression>
                   <name>First Designation</name>
                 </expression>
               </preferred>
               <preferred>
                 <expression>
                   <name>Second Designation</name>
                 </expression>
               </preferred>
               <admitted>
                 <expression>
                   <name>Third Designation</name>
                 </expression>
               </admitted>
               <domain>Rice</domain>
             </term>
             <term id="_" anchor="term-_Wheat_-First-Designation">
               <preferred>
                 <expression>
                   <name>First Designation</name>
                 </expression>
               </preferred>
               <domain>Wheat</domain>
             </term>
           </terms>
           <clause id="_" inline-header="false" obligation="normative">
             <title id="_">Clause</title>
             <p id="_">
               <concept>
                 <strong>term <tt>First Designation</tt> not resolved via ID <tt>First-Designation</tt></strong>
               </concept>
             </p>
             <p id="_">
               <concept>
                 <refterm>&lt;Rice&gt; First Designation</refterm>
                 <renderterm>Second Designation</renderterm>
                 <xref target="term-_Rice_-First-Designation"/>
               </concept>
             </p>
             <p id="_">
               <concept>
                 <refterm>&lt;Rice&gt; First Designation</refterm>
                 <renderterm>Third Designation</renderterm>
                 <xref target="term-_Rice_-First-Designation"/>
               </concept>
             </p>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end
end
