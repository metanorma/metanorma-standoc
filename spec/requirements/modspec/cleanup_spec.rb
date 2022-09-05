require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Requirements::Modspec do
  it "extends requirement dl syntax" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [requirement,model=ogc]
      ====
      [%metadata]
      type:: class
      identifier:: \\http://www.opengis.net/spec/waterml/2.0/req/xsd-xml-rules
      subject:: Encoding of logical models
      inherit:: urn:iso:dis:iso:19156:clause:7.2.2
      inherit:: urn:iso:dis:iso:19156:clause:8
      inherit:: http://www.opengis.net/doc/IS/GML/3.2/clause/2.4
      inherit:: O&M Abstract model, OGC 10-004r3, clause D.3.4
      inherit:: http://www.opengis.net/spec/SWE/2.0/req/core/core-concepts-used
      inherit:: <<ref2>>
      inherit:: <<ref3>>
      classification:: priority:P0
      classification:: domain:Hydrology,Groundwater
      classification:: control-class:Technical
      obligation:: recommendation,requirement
      conditions::
      . Candidate test subject is a witch
      . Widget has been suitably calibrated for aerodynamics
      part:: Determine travel distance by flight path
      description:: Interpolated description
      recommendation:: /label/1
      part:: Widget has been suitably calibrated for aerodynamics
      test-method:: Method
      description::: Method description
      step::: Step 1
      step:::: Step 2
      test-purpose:: Purpose
      test-method-type:: Method Type
      reference:: <<ref2>>
      step:: Step
      Test Method:: Method2
      Test Purpose:: Purpose2
      Test Method Type:: Method Type2
      target:: http://www.example.com
      indirect-dependency:: http://www.example.com
      indirect-dependency:: <<ref3>>

      Logical models encoded as XSDs should be faithful to the original UML conceptual
      models.
      ====
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
        <sections>
        <requirement id='_' obligation='recommendation,requirement' model='ogc' type='class'>
        <identifier>http://www.opengis.net/spec/waterml/2.0/req/xsd-xml-rules</identifier>
        <subject>Encoding of logical models</subject>
        <inherit>urn:iso:dis:iso:19156:clause:7.2.2</inherit>
        <inherit>urn:iso:dis:iso:19156:clause:8</inherit>
        <inherit>http://www.opengis.net/doc/IS/GML/3.2/clause/2.4</inherit>
        <inherit>O&amp;M Abstract model, OGC 10-004r3, clause D.3.4</inherit>
        <inherit>http://www.opengis.net/spec/SWE/2.0/req/core/core-concepts-used</inherit>
        <inherit>
          <xref target='ref2'/>
        </inherit>
        <inherit>
          <xref target='ref3'/>
        </inherit>
        <classification>
          <tag>priority</tag>
          <value>P0</value>
        </classification>
        <classification>
          <tag>domain</tag>
          <value>Hydrology</value>
        </classification>
        <classification>
          <tag>domain</tag>
          <value>Groundwater</value>
        </classification>
        <classification>
          <tag>control-class</tag>
          <value>Technical</value>
        </classification>
             <classification>
        <tag>Test Method</tag>
        <value>Method2</value>
      </classification>
      <classification>
        <tag>Test Purpose</tag>
        <value>Purpose2</value>
      </classification>
      <classification>
        <tag>Test Method Type</tag>
        <value>Method Type2</value>
      </classification>
            <classification>
         <tag>target</tag>
         <value>http://www.example.com</value>
       </classification>
             <classification>
        <tag>indirect-dependency</tag>
        <value>
          <link target='http://www.example.com'/>
        </value>
      </classification>
      <classification>
        <tag>indirect-dependency</tag>
        <value>
          <xref target='ref3'/>
        </value>
      </classification>
           <component class='conditions'>
                 <ol id='_' type='arabic'>
                   <li>
                     <p id='_'>Candidate test subject is a witch</p>
                   </li>
                   <li>
                     <p id='_'>Widget has been suitably calibrated for aerodynamics</p>
                   </li>
                 </ol>
             </component>
             <component class='part'>
                 <p id='_'>Determine travel distance by flight path</p>
             </component>
             <description>
                 <p id='_'>Interpolated description</p>
             </description>
             <recommendation id='_' model="ogc" type=""><identifier>/label/1</identifier></recommendation>
             <component class='part'>
                 <p id='_'>Widget has been suitably calibrated for aerodynamics</p>
             </component>
             <component class='test-method'>
               <p id='_'>Method</p>
               <description>
                 <p id='_'>Method description</p>
               </description>
               <component class='step'>
                 <p id='_'>Step 1</p>
                 <component class='step'>
                 <p id='_'>Step 2</p>
               </component>
               </component>
             </component>
             <component class='test-purpose'>
               <p id='_'>Purpose</p>
             </component>
             <component class='test-method-type'>
               <p id='_'>Method Type</p>
             </component>
             <component class='reference'>
               <p id='_'>
                 <xref target='ref2'/>
               </p>
             </component>
             <component class='step'>
               <p id='_'>Step</p>
             </component>
             <component class='test-method'>
               <p id='_'>Method2</p>
             </component>
             <component class='test-purpose'>
               <p id='_'>Purpose2</p>
             </component>
             <component class='test-method-type'>
               <p id='_'>Method Type2</p>
             </component>
             <description>
               <p id='_'>
                 Logical models encoded as XSDs should be faithful to the original UML
                 conceptual models.
               </p>
             </description>
           </requirement>
         </sections>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "allows nested steps in requirement test methods" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [requirement,model=ogc]
      ====
      [.component,class=Test method type]
      --
      Manual Inspection
      --

      [.component,class=Test method]
      =====

      [.component,class=step]
      ======
      For each UML class defined or referenced in the Tunnel Package:

      [.component,class=step]
      --
      Validate that the Implementation Specification contains a data element which represents the same concept as that defined for the UML class.
      --

      [.component,class=step]
      --
      Validate that the data element has the same relationships with other elements as those defined for the UML class. Validate that those relationships have the same source, target, direction, roles, and multiplicies as those documented in the Conceptual Model.
      --
      ======
      =====
      ====
    INPUT
    output = <<~OUTPUT
                #{BLANK_HDR}
           <sections>
         <requirement id='_' model='ogc' type="">
           <component exclude='false' class='Test method type'>
             <p id='_'>Manual Inspection</p>
           </component>
           <component exclude='false' class='Test method'>
               <component exclude='false' class='step'>
                 <p id='_'>For each UML class defined or referenced in the Tunnel Package:</p>
                 <component exclude='false' class='step'>
                   <p id='_'>
                     Validate that the Implementation Specification contains a data
                     element which represents the same concept as that defined for
                     the UML class.
                   </p>
                 </component>
                 <component exclude='false' class='step'>
                   <p id='_'>
                     Validate that the data element has the same relationships with
                     other elements as those defined for the UML class. Validate that
                     those relationships have the same source, target, direction,
                     roles, and multiplicies as those documented in the Conceptual
                     Model.
                   </p>
                 </component>
               </component>
           </component>
         </requirement>
       </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "uses ModSpec requirement types" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [.requirement,type=requirement,model=ogc]
      ====
      ====

      [.requirement,type=recommendation,model=ogc]
      ====
      ====

      [.requirement,type=permission,model=ogc]
      ====
      ====

      [.requirement,type=requirements_class,model=ogc]
      ====
      ====

      [.requirement,type=conformance_test,model=ogc]
      ====
      ====

      [.requirement,type=conformance_class,model=ogc]
      ====
      ====

      [.requirement,type=abstract_test,model=ogc]
      ====
      ====

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
            <sections>
          <requirement id='_' type='general' model="ogc"> </requirement>
          <requirement id='_' type='general' model="ogc"> </requirement>
          <requirement id='_' type='general' model="ogc"> </requirement>
          <requirement id='_' type='class' model="ogc"> </requirement>
          <requirement id='_' type='verification' model="ogc"> </requirement>
          <requirement id='_' type='conformanceclass' model="ogc"> </requirement>
          <requirement id='_' type='abstracttest' model="ogc"> </requirement>
        </sections>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "uses ModSpec requirement style attributes" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [requirements_class,model=ogc]
      ====
      ====

      [conformance_test,model=ogc]
      ====
      ====

      [conformance_class,model=ogc]
      ====
      ====

      [abstract_test,model=ogc]
      ====
      ====

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
            <sections>
          <requirement id='_' type='class' model="ogc"> </requirement>
          <requirement id='_' type='verification' model="ogc"> </requirement>
          <requirement id='_' type='conformanceclass' model="ogc"> </requirement>
          <requirement id='_' type='abstracttest' model="ogc"> </requirement>
        </sections>
       </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end
end
