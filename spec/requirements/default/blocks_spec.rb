require "spec_helper"
require "open3"

RSpec.describe Metanorma::Requirements::Default do
  it "processes recommendation" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [.recommendation,identifier="/ogc/recommendation/wfs/2",subject="user;developer, implementer",inherit="/ss/584/2015/level/1; /ss/584/2015/level/2",options="unnumbered",type=verification,model=ogc,tag=X,multilingual-rendering=common]
      ====
      I recommend this
      ====
    INPUT
    output = <<~"OUTPUT"
      #{BLANK_HDR}
              <sections>
         <recommendation id="_" unnumbered="true" type="verification" model="ogc" tag='X' multilingual-rendering='common'>
         <identifier>/ogc/recommendation/wfs/2</identifier>
       <subject>user</subject>
       <subject>developer, implementer</subject>
       <inherit>/ss/584/2015/level/1</inherit>
       <inherit>/ss/584/2015/level/2</inherit>
         <description><p id="_">I recommend this</p>
       </description>
       </recommendation>
              </sections>
              </standard-document>
    OUTPUT

    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes requirement" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
      [[ABC]]
      [.requirement,subsequence="A",inherit="/ss/584/2015/level/1 &amp; /ss/584/2015/level/2",number=3,keep-with-next=true,keep-lines-together=true,tag=X,multilingual-rendering=common]
      .Title
      ====
      I recommend this

      . http://www.example.com[]
      . <<ABC>>
      ====
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections>
        <requirement id="ABC" subsequence="A" number="3" keep-with-next="true" keep-lines-together="true" tag='X' multilingual-rendering='common' model="default">
              <title>Title</title>
        <inherit>/ss/584/2015/level/1 &amp; /ss/584/2015/level/2</inherit>
        <description><p id="_">I recommend this</p>
                       <ol id='_' type='arabic'>
                 <li>
                   <p id='_'>
                     <link target='http://www.example.com'/>
                   </p>
                 </li>
                 <li>
                   <p id='_'>
                     <xref target='ABC'/>
                   </p>
                 </li>
               </ol>
      </description>
      </requirement>
             </sections>
             </standard-document>
    OUTPUT

    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes permission" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}

      [[ABC]]
      [.permission,tag=X,multilingual-rendering=common]
      ====
      I recommend this
      ====
    INPUT
    output = <<~"OUTPUT"
                  #{BLANK_HDR}
             <sections>
        <permission id="ABC" tag='X' multilingual-rendering='common' model="default">
        <description><p id="_">I recommend this</p></description>
      </permission>
             </sections>
             </standard-document>
    OUTPUT

    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
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

      . List
      . List
      =====

      [requirement,type="general",identifier="/req/core/quantities-uom"]
      ======
      ======
      ====
    INPUT
    output = <<~"OUTPUT"
      #{BLANK_HDR}
             <sections>
               <permission id="_" model="default"><description><p id="_">I permit this</p>
      <example id="_">
        <p id="_">Example 2</p>
      </example></description>
      <permission id="_" model="default">
        <description><p id="_">I also permit this</p>
                  <ol id='_' type='arabic'>
            <li>
              <p id='_'>List</p>
            </li>
            <li>
              <p id='_'>List</p>
            </li>
          </ol>
        </description>
      </permission>
      <requirement id='_' type='general' model="default">
      <identifier>/req/core/quantities-uom</identifier>
      </requirement>
      </permission>
      </sections>
      </standard-document>
    OUTPUT

    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end

  it "processes recommendation with internal markup of structure" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}

      [[ABC]]
      [.recommendation,identifier="/ogc/recommendation/wfs/2",subject="user",classification="control-class:Technical;priority:P0;family:System &amp; Communications Protection,System and Communications Protocols",obligation="permission,recommendation",filename="reqt1.rq"]
      ====
      I recommend _this_.

      [.specification,type="tabular",keep-with-next=true,keep-lines-together=true]
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

      [.component]
      --
      Hello
      --

      [.component,class=condition]
      --
      If this be thus
      --
      ====
    INPUT
    output = <<~"OUTPUT"
         #{BLANK_HDR}
                 <sections>
                 <recommendation id="ABC"  obligation="permission,recommendation" filename="reqt1.rq" model="default"><identifier>/ogc/recommendation/wfs/2</identifier><subject>user</subject>
          <classification><tag>control-class</tag><value>Technical</value></classification><classification><tag>priority</tag><value>P0</value></classification><classification><tag>family</tag><value>System &amp; Communications Protection</value></classification><classification><tag>family</tag><value>System and Communications Protocols</value></classification>
                  <description><p id="_">I recommend <em>this</em>.</p>
                 </description><specification exclude="false" type="tabular" keep-with-next="true" keep-lines-together="true"><p id="_">This is the object of the recommendation:</p><table id="_">  <tbody>    <tr>      <td valign="top" align="left">Object</td>      <td valign="top" align="left">Value</td>    </tr>    <tr>      <td valign="top" align="left">Mission</td>      <td valign="top" align="left">Accomplished</td>    </tr>  </tbody></table></specification><description>
                 <p id="_">As for the measurement targets,</p>
                 </description><measurement-target exclude="false"><p id="_">The measurement target shall be measured as:</p><formula id="_">  <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mfrac>
                 <mrow>
            <mi>r</mi>
          </mrow>
          <mrow>
            <mn>1</mn>
          </mrow>
          </mfrac><mo>=</mo><mn>0</mn></math></stem></formula></measurement-target>
                 <verification exclude="false"><p id="_">The following code will be run for verification:</p><sourcecode  lang="CoreRoot" id="_">CoreRoot(success): HttpResponse
          if (success)
            recommendation(label: success-response)
          end</sourcecode></verification>
                 <import exclude="true">  <sourcecode  lang="CoreRoot" id="_">success-response()</sourcecode></import>
                 <component exclude='false' class='component'>
        <p id='_'>Hello</p>
      </component>
      <component exclude='false' class='condition'>
        <p id='_'>If this be thus</p>
      </component>
          </recommendation>
                 </sections>
                 </standard-document>
    OUTPUT

    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end
end
