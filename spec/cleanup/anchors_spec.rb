require "spec_helper"
require "relaton/iec"
require "fileutils"

RSpec.describe Metanorma::Standoc do
  it "does not alter anchors illegal as xsd:ID, xsd:IDREF" do
    input = <<~INPUT
      #{VALIDATING_BLANK_HDR}

      [[a:b]]
      == A
      <</:ab>>
      <<:>>
      <<1>>
      <<1:>>
      <<1#b>>
      <<:a#b:>>
      <</%ab>>
      <<1!>>
      <<Löwe>>

      [[Löwe]]
      .See <<Löwner2016>>
      ----
      ABC
      ----

      [bibliography]
      == Bibliography
      * [[[Löwner2016,Löwner et al. 2016]]], Löwner, M.-O., Gröger, G., Benner, J., Biljecki, F., Nagel, C., 2016: *Proposal for a new LOD and multi-representation concept for CityGML*. In: Proceedings of the 11th 3D Geoinfo Conference 2016, ISPRS Annals of the Photogrammetry, Remote Sensing and Spatial Information Sciences, Vol. IV-2/W1, 3–12. https://doi.org/10.5194/isprs-annals-IV-2-W1-3-2016
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
           <sections>
             <clause id="_" anchor="a:b" inline-header="false" obligation="normative">
                <title id="_">A</title>
                <p id="_">
                   <eref bibitemid="/_ab" citeas=""/>
                   <xref target=":"/>
                   <xref target="1"/>
                   <xref target="1:"/>
                   <xref target="1#b"/>
                   <xref target=":a#b:"/>
                   <xref target="/%ab"/>
                   <xref target="1!"/>
                   <xref target="Löwe"/>
      #{'          '}
                <sourcecode id="_" anchor="Löwe">
                   <name id="_">
                      See
                      <eref type="inline" bibitemid="Löwner2016" citeas="Löwner\\u00a0et\\u00a0al.\\u00a02016"/>
                   </name>
                   <body>ABC</body>
                </sourcecode>
             </clause>
          </sections>
          <bibliography>
             <references id="_" normative="false" obligation="informative">
                <title id="_">Bibliography</title>
                <bibitem anchor="Löwner2016" id="_">
                   <formattedref format="application/x-isodoc+xml">
                      Löwner, M.-O., Gröger, G., Benner, J., Biljecki, F., Nagel, C., 2016:
                      <strong>Proposal for a new LOD and multi-representation concept for CityGML</strong>
                      . In: Proceedings of the 11th 3D Geoinfo Conference 2016, ISPRS Annals of the Photogrammetry, Remote Sensing and Spatial Information Sciences, Vol. IV-2/W1, 3–12.
                      <link target="https://doi.org/10.5194/isprs-annals-IV-2-W1-3-2016"/>
                   </formattedref>
                   <docidentifier>Löwner et al. 2016</docidentifier>
                   <docnumber>2016</docnumber>
                   <language>en</language>
                   <script>Latn</script>
                </bibitem>
             </references>
             <references hidden="true" normative="false">
                <bibitem anchor="/_ab" id="_" type="internal">
                   <docidentifier type="repository">//ab</docidentifier>
                </bibitem>
             </references>
          </bibliography>
       </metanorma>
    OUTPUT
    FileUtils.rm_rf("test.err.html")
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))
      .gsub(/<p id="_" anchor="_[^"]+">/, "").gsub("</p>", "")))
      .to be_equivalent_to(strip_guid(Canon.format_xml(output)))
  end

  it "creates content-based GUIDs" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      .Foreword
      Foreword

      [NOTE,beforeclauses=true]
      ====
      Note which is very important <<a>>
      ====

      == Introduction
      Introduction

      == Scope
      Scope statement

      [IMPORTANT,beforeclauses=true]
      ====
      Notice which is very important
      ====
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
           <preface>
             <note id="_55e11b0f-6e72-8c69-60c3-4f276a04b2cd">
                <p id="_a877a5e9-28a1-be75-c5a6-13da74ffd20a">
                   Note which is very important
                   <xref target="a"/>
                </p>
             </note>
             <foreword id="_c4ed5244-dd15-eb83-1eab-e935fc376ea9" obligation="informative">
                <title id="_41c9fad3-d4c1-eecc-4fad-f91704acc026">Foreword</title>
                <p id="_82273bb2-9729-2179-e364-4dbceaa3e7a1">Foreword</p>
             </foreword>
             <introduction id="_2f104f30-6e11-5838-9236-2dac93424538" obligation="informative">
                <title id="_2b2e98d1-114a-3da4-8556-01ae0a724280">Introduction</title>
                <p id="_9fe8092e-7508-826b-87ab-137652bcc88a">Introduction</p>
             </introduction>
          </preface>
          <sections>
             <admonition id="_6c0f0fe2-050a-efee-d118-dbe50bac31ce" type="important">
                <p id="_076fdc2d-399b-eaae-0c30-43f9ee0c414a">Notice which is very important</p>
             </admonition>
             <clause id="_3f790a3c-6599-f0b3-b794-2e36cbde5d7b" type="scope" inline-header="false" obligation="normative">
                <title id="_6770b367-e1d0-8e49-8515-6b9fe405d4ad">Scope</title>
                <p id="_c7deb0c6-abf2-07ec-468c-68d2ecbf922e">Scope statement</p>
             </clause>
          </sections>
       </metanorma>
    OUTPUT
    expect(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))
      .sub(/ schema-version="v[^"]+"/, ""))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "aliases anchors" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      == Misc-Container

      [[_misccontainer_anchor_aliases]]
      |===
      | id1 | http://www.example.com | %2
      |===

      [[id1]]
      == Clause 1

      <<id1>>
      <<id1,style=id%>>
      xref:http://www.example.com[]
      xref:http://www.example.com[style=id%]

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR.sub('<metanorma-extension>', <<~EXT
        <metanorma-extension>
          <table id="_" anchor="_misccontainer_anchor_aliases">
            <tbody>
              <tr id="_">
                <td id="_" valign='top' align='left'>id1</td>
                <td id="_" valign='top' align='left'>
                  <link target='http://www.example.com'/>
                </td>
                <td id="_" valign='top' align='left'>%2</td>
              </tr>
            </tbody>
          </table>
      EXT
      )}
         <sections>
           <clause id="_" anchor="id1" inline-header='false' obligation='normative'>
             <title id="_">Clause 1</title>
             <p id='_'>
               <xref target='id1'/>
               <xref target='id1' style='id'/>
               <xref target='id1'/>
               <xref target='id1' style="id"><display-text>http://www.example.com</display-text></xref>
             </p>
           </clause>
         </sections>
       </metanorma>
    OUTPUT
    expect(strip_guid(Canon.format_xml(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Canon.format_xml(output)
  end

  it "removes redundant bookmarks" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [appendix]
      == Annex [[bookmark]]

    INPUT
    output = <<~OUTPUT
      <annex id="_" anchor="bookmark" inline-header="false" obligation="normative">
        <title id="_">Annex</title>
      </annex>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(strip_guid(Canon.format_xml(ret.at("//xmlns:annex").to_xml)))
      .to be_equivalent_to(Canon.format_xml(output))

    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [appendix]
      [[annex]]
      == Annex [[bookmark]]

    INPUT
    output = <<~OUTPUT
      <annex id="_" anchor="annex" inline-header="false" obligation="normative">
        <title id="_">Annex <bookmark id="_" anchor="bookmark"/></title>
      </annex>
    OUTPUT
    ret = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(strip_guid(Canon.format_xml(ret.at("//xmlns:annex").to_xml)))
      .to be_equivalent_to(Canon.format_xml(output))
  end
end
