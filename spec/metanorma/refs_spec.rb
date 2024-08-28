require "spec_helper"
require "relaton_iso"
require "relaton_ietf"
require "relaton_nist"

RSpec.describe Metanorma::Standoc do
  it "processes simple ISO reference" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123]]] _Standard_
      * [[[iso124,(1)ISO 123]]] _Standard_
      * [[[iso124,number=2,code=ISO 123]]] _Standard_
      * [[[iso124,number=3,ISO 123]]] _Standard_
      * [[[iso124,usrlabel=4,ISO 123]]] _Standard_
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
            <sections>
            </sections><bibliography><references id="_" obligation="informative" normative="true">
              <title>Normative references</title>
              #{NORM_REF_BOILERPLATE}
              <bibitem id="iso123" type="standard">
               <title format="text/plain">Standard</title>
               <docidentifier>ISO 123</docidentifier>
               <docnumber>123</docnumber>
               <contributor>
                 <role type="publisher"/>
                 <organization>
                   <name>ISO</name>
                 </organization>
               </contributor>
             </bibitem>
             <bibitem id='iso124' type='standard'>
        <title format='text/plain'>Standard</title>
        <docidentifier type='metanorma'>[1]</docidentifier>
        <docidentifier>ISO 123</docidentifier>
               <docnumber>123</docnumber>
        <contributor>
          <role type='publisher'/>
          <organization>
            <name>ISO</name>
          </organization>
        </contributor>
      </bibitem>
            <bibitem id="iso124">
        <formattedref format="application/x-isodoc+xml">
          <em>Standard</em>
        </formattedref>
        <docidentifier type='metanorma'>[2]</docidentifier>
        <docidentifier>ISO 123</docidentifier>
        <docnumber>123</docnumber>
      </bibitem>
      <bibitem id="iso124">
        <formattedref format="application/x-isodoc+xml">
          <em>Standard</em>
        </formattedref>
        <docidentifier type='metanorma'>[3]</docidentifier>
        <docidentifier>ISO 123</docidentifier>
        <docnumber>123</docnumber>
      </bibitem>
            <bibitem id="iso124">
        <formattedref format="application/x-isodoc+xml">
          <em>Standard</em>
        </formattedref>
        <docidentifier type='metanorma'>[4]</docidentifier>
        <docidentifier>ISO 123</docidentifier>
        <docnumber>123</docnumber>
      </bibitem>
            </references>
            </bibliography>
            </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes simple ISO reference with date range" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:1066-1067]]] _Standard_
      * [[[iso124,(1)ISO 123:1066-1067]]] _Standard_
    INPUT
    output = <<~OUTPUT
          #{BLANK_HDR}
          <sections>
          </sections><bibliography><references id="_" obligation="informative" normative="true">
            <title>Normative references</title>
            #{NORM_REF_BOILERPLATE}
            <bibitem id="iso123" type="standard">
              <title format="text/plain">Standard</title>
      <docidentifier>ISO 123:1066-1067</docidentifier>
             <docnumber>123</docnumber>
      <date type="published">
        <from>1066</from>
        <to>1067</to>
      </date>
      <contributor>
        <role type="publisher"/>
        <organization>
          <name>ISO</name>
        </organization>
      </contributor>
           </bibitem>
           <bibitem id="iso124" type="standard">
              <title format="text/plain">Standard</title>
              <docidentifier type='metanorma'>[1]</docidentifier>
      <docidentifier>ISO 123:1066-1067</docidentifier>
             <docnumber>123</docnumber>
      <date type="published">
        <from>1066</from>
        <to>1067</to>
      </date>
      <contributor>
        <role type="publisher"/>
        <organization>
          <name>ISO</name>
        </organization>
      </contributor>
           </bibitem>
          </references>
          </bibliography>
          </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "repairs simple fetched ISO reference" do
    mock_isobib_get_123_no_docid(2)
    mock_isobib_get_123_no_docid_lbl(2)
    mock_isobib_get_123_no_docid_fn(2)
    input = <<~"INPUT"
      #{ISOBIB_BLANK_HDR}

      <<iso123>>
      <<iso124>>

      [bibliography]
      == Normative References

      * [[[iso123,ISO 123]]] _Standard_
      * [[[iso124,(1)ISO 123]]] _Standard_
      * [[[iso125,(2)ISO 123]]] _Standard_.footnote:[footnote]
    INPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(<<~"OUTPUT")
               #{BLANK_HDR}
               <preface>
          <foreword id='_' obligation='informative'>
            <title>Foreword</title>
            <p id='_'>
              <eref type='inline' bibitemid='iso123' citeas='ISO&#xa0;123'/>
              <eref type='inline' bibitemid='iso124' citeas='[1]'/>
            </p>
          </foreword>
        </preface>
               <sections>
               </sections><bibliography><references id="_" obligation="informative" normative="true"><title>Normative references</title>
                #{NORM_REF_BOILERPLATE}
        <bibitem type="standard" id="iso123">
          <uri type="src">https://www.iso.org/standard/23281.html</uri>
          <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:23281:en</uri>
          <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
          <date type="published">
            <on>2001</on>
          </date>
          <contributor>
            <role type="publisher"/>
            <organization>
              <name>International Organization for Standardization</name>
              <abbreviation>ISO</abbreviation>
              <uri>www.iso.org</uri>
            </organization>
          </contributor>
          <edition>3</edition>
          <language>en</language>
          <language>fr</language>
          <script>Latn</script>
          <status>
            <stage>Published</stage>
          </status>
          <copyright>
            <from>2001</from>
            <owner>
              <organization>
                <name>ISO</name>
                <abbreviation/>
              </organization>
            </owner>
          </copyright>
          <relation type="obsoletes">
            <bibitem type="standard">
              <formattedref format="text/plain">ISO 123:1985</formattedref>
            </bibitem>
          </relation>
          <relation type="updates">
            <bibitem type="standard">
              <formattedref format="text/plain">ISO 123:2001</formattedref>
            </bibitem>
          </relation>
        <docidentifier>ISO 123</docidentifier>
        <title><em>Standard</em></title>
        </bibitem>
        <bibitem type="standard" id="iso124">
          <uri type="src">https://www.iso.org/standard/23281.html</uri>
          <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:23281:en</uri>
          <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
          <date type="published">
            <on>2001</on>
          </date>
          <contributor>
            <role type="publisher"/>
            <organization>
              <name>International Organization for Standardization</name>
              <abbreviation>ISO</abbreviation>
              <uri>www.iso.org</uri>
            </organization>
          </contributor>
          <edition>3</edition>
          <language>en</language>
          <language>fr</language>
          <script>Latn</script>
          <status>
            <stage>Published</stage>
          </status>
          <copyright>
            <from>2001</from>
            <owner>
              <organization>
                <name>ISO</name>
                <abbreviation/>
              </organization>
            </owner>
          </copyright>
          <relation type="obsoletes">
            <bibitem type="standard">
              <formattedref format="text/plain">ISO 123:1985</formattedref>
            </bibitem>
          </relation>
          <relation type="updates">
            <bibitem type="standard">
              <formattedref format="text/plain">ISO 123:2001</formattedref>
            </bibitem>
          </relation>
        <docidentifier>ISO 123</docidentifier>
         <docidentifier type='metanorma'>[1]</docidentifier>
        <title><em>Standard</em></title>
        </bibitem>
        <bibitem type="standard" id="iso125">
               <uri type="src">https://www.iso.org/standard/23281.html</uri>
               <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:23281:en</uri>
               <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
               <date type="published">
                 <on>2001</on>
               </date>
               <contributor>
                 <role type="publisher"/>
                 <organization>
                   <name>International Organization for Standardization</name>
                   <abbreviation>ISO</abbreviation>
                   <uri>www.iso.org</uri>
                 </organization>
               </contributor>
               <edition>3</edition>
               <language>en</language>
               <language>fr</language>
               <script>Latn</script>
               <status>
                 <stage>Published</stage>
               </status>
               <copyright>
                 <from>2001</from>
                 <owner>
                   <organization>
                     <name>ISO</name>
                     <abbreviation/>
                   </organization>
                 </owner>
               </copyright>
               <relation type="obsoletes">
                 <bibitem type="standard">
                   <formattedref format="text/plain">ISO 123:1985</formattedref>
                 </bibitem>
               </relation>
               <relation type="updates">
                 <bibitem type="standard">
                   <formattedref format="text/plain">ISO 123:2001</formattedref>
                 </bibitem>
               </relation>
               <docidentifier>ISO 123</docidentifier>
               <docidentifier type="metanorma">[2]</docidentifier>
               <formattedref><em>Standard</em>.<fn reference="1"><p id="_">footnote</p></fn></formattedref>
             </bibitem>
        </references></bibliography>
        </standard-document>
      OUTPUT
    expect do
      Asciidoctor.convert(input, *OPTIONS)
    end.to output(/ERROR: No document identifier retrieved for ISO 123/)
      .to_stderr
  end

  it "customises docidentifier by language" do
    mock_rfcbib_get_rfc8342(3)
    mock_rfcbib_get_rfc8343(3)
    input = <<~"INPUT"
      #{ISOBIB_BLANK_HDR}

      <<iso123>>
      <<iso124>>

      [bibliography]
      == Normative References

      * [[[iso123,ISO 8342]]] _Standard_
      * [[[iso124,ISO 8343]]] _Standard_
    INPUT
    doc = Asciidoctor.convert(input
      .sub(":novalid:", ":language: de\n:novalid:"), *OPTIONS)
    expect(doc).to include('<eref type="inline" bibitemid="iso123" citeas="ISO 8342-DE"/>')
    expect(doc).to include('<eref type="inline" bibitemid="iso124" citeas="ISO 8343-DE"/>')
    doc = Asciidoctor.convert(input
  .sub(":novalid:", ":language: fr\n:novalid:"), *OPTIONS)
    expect(doc).to include('<eref type="inline" bibitemid="iso123" citeas="ISO 8342-EN"/>')
    expect(doc).to include('<eref type="inline" bibitemid="iso124" citeas="ISO 8343-FR"/>')
    doc = Asciidoctor.convert(input
      .sub(":novalid:", ":language: en\n:novalid:"), *OPTIONS)
    expect(doc).to include('<eref type="inline" bibitemid="iso123" citeas="ISO 8342-EN"/>')
    expect(doc).to include('<eref type="inline" bibitemid="iso124" citeas="ISO 8341"/>')
  end

  it "processes simple IEC reference" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,IEC 123]]] _Standard_
      * [[[iso124,(1)IEC 123]]] _Standard_
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
             </sections><bibliography><references id="_" obligation="informative" normative="true">
               <title>Normative references</title>
              #{NORM_REF_BOILERPLATE}
               <bibitem id="iso123" type="standard">
               <title format="text/plain">Standard</title>
               <docidentifier>IEC 123</docidentifier>
               <docnumber>123</docnumber>
               <contributor>
                 <role type="publisher"/>
                 <organization>
                   <name>IEC</name>
                 </organization>
               </contributor>
             </bibitem>
             <bibitem id='iso124' type='standard'>
        <title format='text/plain'>Standard</title>
        <docidentifier type='metanorma'>[1]</docidentifier>
        <docidentifier>IEC 123</docidentifier>
        <docnumber>123</docnumber>
        <contributor>
          <role type='publisher'/>
          <organization>
            <name>IEC</name>
          </organization>
        </contributor>
      </bibitem>
             </references>
             </bibliography>
             </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes draft ISO reference" do
    # stub_fetch_ref no_year: true, note: "The standard is in press"

    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:--]]] _Standard_
      * [[[iso124,ISO 124:—]]]{blank}footnote:[The standard is in press] _Standard_
      * [[[iso125,ISO 125:&ndash;]]], footnote:[The standard is in press] _Standard_
      * [[[iso126,(1)ISO 123:--]]] _Standard_
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
             <sections>
                    </sections><bibliography><references id="_" obligation="informative" normative="true">
               <title>Normative references</title>
              #{NORM_REF_BOILERPLATE}
               <bibitem id="iso123" type="standard">
               <title format="text/plain">Standard</title>
               <docidentifier>ISO 123:—</docidentifier>
               <docnumber>123</docnumber>
               <date type="published">
                 <on>–</on>
               </date>
               <contributor>
                 <role type="publisher"/>
                 <organization>
                   <name>ISO</name>
                 </organization>
               </contributor>
             </bibitem>
               <bibitem id="iso124" type="standard">
               <title format="text/plain">Standard</title>
               <docidentifier>ISO 124:—</docidentifier>
               <docnumber>124</docnumber>
               <date type="published">
                 <on>–</on>
               </date>
               <contributor>
                 <role type="publisher"/>
                 <organization>
                   <name>ISO</name>
                 </organization>
               </contributor>
               <note format="text/plain" type="Unpublished-Status">The standard is in press</note>
             </bibitem>
               <bibitem id="iso125" type="standard">
               <title format="text/plain">Standard</title>
               <docidentifier>ISO 125:—</docidentifier>
               <docnumber>125</docnumber>
               <date type="published">
                 <on>–</on>
               </date>
               <contributor>
                 <role type="publisher"/>
                 <organization>
                   <name>ISO</name>
                 </organization>
               </contributor>
               <note format="text/plain" type="Unpublished-Status">The standard is in press</note>
             </bibitem>
             <bibitem id='iso126' type='standard'>
        <title format='text/plain'>Standard</title>
        <docidentifier type='metanorma'>[1]</docidentifier>
        <docidentifier>ISO 123:—</docidentifier>
               <docnumber>123</docnumber>
        <date type='published'>
          <on>–</on>
        </date>
        <contributor>
          <role type='publisher'/>
          <organization>
            <name>ISO</name>
          </organization>
        </contributor>
      </bibitem>
             </references>
             </bibliography>
             </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes all-parts ISO reference" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:1066 (all parts)]]] _Standard_
      * [[[iso124,(1)ISO 123:1066 (all parts)]]] _Standard_
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
            <sections>
            </sections><bibliography><references id="_" obligation="informative" normative="true">
              <title>Normative references</title>
              #{NORM_REF_BOILERPLATE}
              <bibitem id="iso123" type="standard">
               <title format="text/plain">Standard</title>
               <docidentifier>ISO 123:1066 (all parts)</docidentifier>
               <docnumber>123</docnumber>
               <date type="published">
                 <on>1066</on>
               </date>
               <contributor>
                 <role type="publisher"/>
                 <organization>
                   <name>ISO</name>
                 </organization>
               </contributor>
               <extent type="part">
                      <referenceFrom>all</referenceFrom>
              </extent>
             </bibitem>
             <bibitem id='iso124' type='standard'>
        <title format='text/plain'>Standard</title>
        <docidentifier type='metanorma'>[1]</docidentifier>
        <docidentifier>ISO 123:1066 (all parts)</docidentifier>
               <docnumber>123</docnumber>
        <date type='published'>
          <on>1066</on>
        </date>
        <contributor>
          <role type='publisher'/>
          <organization>
            <name>ISO</name>
          </organization>
        </contributor>
        <extent type='part'>
          <referenceFrom>all</referenceFrom>
        </extent>
      </bibitem>
            </references>
            </bibliography>
            </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes non-ISO reference in Normative References" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,XYZ 123:1966 (all parts)]]] _Standard_
      * [[[iso124,(1)XYZ 123:1966]]] _Standard_
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
             </sections><bibliography><references id="_" obligation="informative" normative="true">
               <title>Normative references</title>
              #{NORM_REF_BOILERPLATE}
               <bibitem id="iso123">
               <formattedref format="application/x-isodoc+xml">
                 <em>Standard</em>
               </formattedref>
               <docidentifier>XYZ 123:1966 (all parts)</docidentifier>
               <docnumber>123:1966 (all parts)</docnumber>
             </bibitem>
             <bibitem id='iso124'>
        <formattedref format='application/x-isodoc+xml'>
          <em>Standard</em>
        </formattedref>
        <docidentifier type='metanorma'>[1]</docidentifier>
        <docidentifier>XYZ 123:1966</docidentifier>
        <docnumber>123</docnumber>
                      <date type='published'>
         <on>1966</on>
       </date>
      </bibitem>
             </references>
             </bibliography>
             </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes non-ISO reference in Bibliography" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Bibliography

      * [[[iso123,2]]] _Standard_
      * [[[iso124,(B)]]] _Standard_
      * [[[iso125,1]]] _Standard_
      * [[[iso126,usrlabel=A1]]] _Standard_
      * [[[iso127,(4)XYZ 123:1066 (all parts)]]] _Standard_
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
             </sections>
             <bibliography><references id="_" obligation="informative" normative="false">
               <title>Bibliography</title><bibitem id="iso123">
               <formattedref format="application/x-isodoc+xml">
                 <em>Standard</em>
               </formattedref>
               <docidentifier type="metanorma">[1]</docidentifier>
             </bibitem><bibitem id="iso124">
               <formattedref format="application/x-isodoc+xml">
                 <em>Standard</em>
               </formattedref>
               <docidentifier type="metanorma">[B]</docidentifier>
             </bibitem><bibitem id="iso125">
               <formattedref format="application/x-isodoc+xml">
                 <em>Standard</em>
               </formattedref>
               <docidentifier type="metanorma">[3]</docidentifier>
             </bibitem><bibitem id="iso126">
               <formattedref format="application/x-isodoc+xml">
                 <em>Standard</em>
               </formattedref>
               <docidentifier type="metanorma">[A1]</docidentifier>
             </bibitem>
      <bibitem id='iso127'>
        <formattedref format='application/x-isodoc+xml'>
          <em>Standard</em>
        </formattedref>
        <docidentifier type='metanorma'>[5]</docidentifier>
        <docidentifier>XYZ 123:1066 (all parts)</docidentifier>
        <docnumber>123:1066 (all parts)</docnumber>
      </bibitem>
             </references>
             </bibliography>
             </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "process ISO reference without an Internet connection" do
    expect(RelatonIso::IsoBibliography).to receive(:search) do
      raise RelatonBib::RequestError.new "getaddrinfo"
    end.at_least :once
    input = <<~INPUT
      #{ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123]]] _Standard_
      * [[[iso124,(1)ISO 123]]] _Standard_
    INPUT
    output = <<~OUTPUT
            <?xml version="1.0" encoding="UTF-8"?>
            <standard-document xmlns="https://www.metanorma.org/ns/standoc"  type="semantic" version="#{Metanorma::Standoc::VERSION}">
            <bibdata type="standard">
            <title language="en" format="text/plain">Document title</title>
              <language>en</language>
              <script>Latn</script>
              <status><stage>published</stage></status>
              <copyright>
                <from>#{Date.today.year}</from>
              </copyright>
              <ext>
              <doctype>standard</doctype>
              </ext>
            </bibdata>
            <sections>
            </sections><bibliography><references id="_" obligation="informative" normative="true">
              <title>Normative references</title>
              #{NORM_REF_BOILERPLATE}
              <bibitem id="iso123" type="standard">
              <title format="text/plain">Standard</title>
              <docidentifier type="ISO">ISO 123</docidentifier>
        <docnumber>123</docnumber>
              <contributor>
                <role type="publisher"/>
                <organization>
                  <name>ISO</name>
                </organization>
              </contributor>
            </bibitem>
            <bibitem id='iso124' type='standard'>
        <title format='text/plain'>Standard</title>
        <docidentifier type='metanorma'>[1]</docidentifier>
        <docidentifier type='ISO'>ISO 123</docidentifier>
        <docnumber>123</docnumber>
        <contributor>
          <role type='publisher'/>
          <organization>
            <name>ISO</name>
          </organization>
        </contributor>
      </bibitem>
            </references></bibliography>
            </standard-document>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.at("//xmlns:metanorma-extension")&.remove
    expect(Xml::C14n.format(strip_guid(xml.to_xml)))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes repository reference" do
    input = <<~INPUT
      #{ISOBIB_BLANK_HDR}
      == Scope

      <<iso123>>
      <<iso123,clause=1>>
      <<iso124>>
      <<iso124,clause=1>>

      [bibliography]
      == Normative References

      * [[[iso123,repo:(ab/ISO 123)]]] _Standard_
      * [[[iso123a,repo=ab/ISO 123]]] _Standard_
      * [[[iso124,repo:(ab/ISO 124,id)]]] _Standard_
      * [[[iso124a,repo=ab/ISO 124,code=id]]] _Standard_
      * [[[iso125,dropid(repo:(ab/ISO 124,id))]]] _Standard_
      * [[[iso125a,dropid=true,repo=ab/ISO 124,id]]] _Standard_
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
      <sections>
                 <clause id='_' type='scope' inline-header='false' obligation='normative'>
                   <title>Scope</title>
                   <p id='_'>
                     <eref type='inline' bibitemid='iso123' citeas='ISO&#xa0;123'/>
                     <eref type='inline' bibitemid='iso123' citeas='ISO&#xa0;123'>
                       <localityStack>
                         <locality type='clause'>
                           <referenceFrom>1</referenceFrom>
                         </locality>
                       </localityStack>
                     </eref>
                     <eref type='inline' bibitemid='iso124' citeas='id'/>
                     <eref type='inline' bibitemid='iso124' citeas='id'>
                       <localityStack>
                         <locality type='clause'>
                           <referenceFrom>1</referenceFrom>
                         </locality>
                       </localityStack>
                     </eref>
                   </p>
                 </clause>
               </sections>
               <bibliography>
                 <references id='_' normative='true' obligation='informative'>
                   <title>Normative references</title>
                   <p id='_'>
                     The following documents are referred to in the text in such a way that
                     some or all of their content constitutes requirements of this document.
                     For dated references, only the edition cited applies. For undated
                     references, the latest edition of the referenced document (including any
                     amendments) applies.
                   </p>
                   <bibitem id='iso123'>
                     <formattedref format='application/x-isodoc+xml'>
                       <em>Standard</em>
                     </formattedref>
                     <docidentifier type='ISO'>ISO 123</docidentifier>
                     <docidentifier type='repository'>ab/ISO 123</docidentifier>
                     <docnumber>123</docnumber>
                   </bibitem>
                   <bibitem id='iso123a'>
                     <formattedref format='application/x-isodoc+xml'>
                       <em>Standard</em>
                     </formattedref>
                     <docidentifier type='ISO'>ISO 123</docidentifier>
                     <docidentifier type='repository'>ab/ISO 123</docidentifier>
                     <docnumber>123</docnumber>
                   </bibitem>
                   <bibitem id='iso124'>
                     <formattedref format='application/x-isodoc+xml'>
                      <em>Standard</em>
                    </formattedref>
                    <docidentifier>id</docidentifier>
                    <docidentifier type='repository'>ab/ISO 124</docidentifier>
                  </bibitem>
                  <bibitem id='iso124a'>
                     <formattedref format='application/x-isodoc+xml'>
                      <em>Standard</em>
                    </formattedref>
                    <docidentifier>id</docidentifier>
                    <docidentifier type='repository'>ab/ISO 124</docidentifier>
                  </bibitem>
                  <bibitem id='iso125' suppress_identifier='true'>
                     <formattedref format='application/x-isodoc+xml'>
                       <em>Standard</em>
                     </formattedref>
                     <docidentifier>id</docidentifier>
                     <docidentifier type='repository'>ab/ISO 124</docidentifier>
                   </bibitem>
                   <bibitem id='iso125a' suppress_identifier='true'>
                     <formattedref format='application/x-isodoc+xml'>
                       <em>Standard</em>
                     </formattedref>
                     <docidentifier>id</docidentifier>
                     <docidentifier type='repository'>ab/ISO 124</docidentifier>
                   </bibitem>
                 </references>
               </bibliography>
             </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "processes hyperlink reference, ingest RXL or XML if available" do
    input = <<~INPUT
      #{ISOBIB_BLANK_HDR}
      == Scope

      <<iso123>>

      <<iso124,clause=1>>

      <<iso123,anchor=xyz>>

      <<iso124,clause=1,anchor=xyz>>

      [bibliography]
      == Normative References

      * [[[iso123,path:(spec/assets/iso123,ISO 123)]]] _Standard_
      * [[[iso124,path=a/b.adoc,ISO 124]]] _Standard_
    INPUT
    output = <<~OUTPUT
           #{BLANK_HDR}
        <sections>
          <clause id='_' type="scope" inline-header='false' obligation='normative'>
            <title>Scope</title>
            <p id='_'>
              <eref type='inline' bibitemid='iso123' citeas='ISO&#xa0;123&#xa0;(all&#xa0;parts)'/>
            </p>
            <p id='_'>
              <eref type='inline' bibitemid='iso124' citeas='ISO&#xa0;124'>
                <localityStack>
                  <locality type='clause'>
                    <referenceFrom>1</referenceFrom>
                  </locality>
                </localityStack>
              </eref>
            </p>
            <p id='_'>
              <eref type='inline' bibitemid='iso123' citeas='ISO&#xa0;123&#xa0;(all&#xa0;parts)'>
                <localityStack>
              <locality type='anchor'>
        <referenceFrom>xyz</referenceFrom>
      </locality>
                </localityStack>
              </eref>
            </p>
            <p id='_'>
              <eref type='inline' bibitemid='iso124' citeas='ISO&#xa0;124'>
                <localityStack>
                  <locality type='clause'>
                    <referenceFrom>1</referenceFrom>
                  </locality>
                  <locality type='anchor'>
        <referenceFrom>xyz</referenceFrom>
      </locality>
                </localityStack>
              </eref>
            </p>
          </clause>
        </sections>
        <bibliography>
          <references id='_' normative='true' obligation='informative'>
            <title>Normative references</title>
            <p id='_'>
              The following documents are referred to in the text in such a way that
              some or all of their content constitutes requirements of this document.
              For dated references, only the edition cited applies. For undated
              references, the latest edition of the referenced document (including any
              amendments) applies.
            </p>
            <bibitem id='iso123' type='standard'>
        <fetched/>
        <title type='title-intro' format='text/plain' language='en' script='Latn'>Rubber latex</title>
        <title type='title-main' format='text/plain' language='en' script='Latn'>Sampling</title>
        <title type='main' format='text/plain' language='en' script='Latn'>Rubber latex – Sampling</title>
        <title type='title-intro' format='text/plain' language='fr' script='Latn'>Latex de caoutchouc</title>
      <title type='title-main' format='text/plain' language='fr' script='Latn'>Échantillonnage</title>
      <title type='main' format='text/plain' language='fr' script='Latn'>Latex de caoutchouc – Échantillonnage</title>
        <uri type='src'>https://www.iso.org/standard/23281.html</uri>
        <uri type='obp'>https://www.iso.org/obp/ui/#!iso:std:23281:en</uri>
        <uri type='rss'>https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
        <uri type='citation'>spec/assets/iso123</uri>
        <docidentifier type='ISO'>ISO 123 (all parts)</docidentifier>
        <docnumber>123</docnumber>
        <date type='published'>
          <on>2001</on>
        </date>
        <contributor>
          <role type='publisher'/>
          <organization>
            <name>International Organization for Standardization</name>
            <abbreviation>ISO</abbreviation>
            <uri>www.iso.org</uri>
          </organization>
        </contributor>
        <edition>3</edition>
        <language>en</language>
        <language>fr</language>
        <script>Latn</script>
        <status>
          <stage>90</stage>
          <substage>93</substage>
        </status>
        <copyright>
          <from>2001</from>
          <owner>
            <organization>
              <name>ISO</name>
            </organization>
          </owner>
        </copyright>
        <relation type='obsoletes'>
          <bibitem type='standard'>
            <formattedref format='text/plain'>ISO 123:1985</formattedref>
          </bibitem>
        </relation>
        <relation type='instanceOf'>
          <bibitem type='standard'>
            <fetched/>
            <title type='title-intro' format='text/plain' language='en' script='Latn'>Rubber latex</title>
            <title type='title-main' format='text/plain' language='en' script='Latn'>Sampling</title>
            <title type='main' format='text/plain' language='en' script='Latn'>Rubber latex – Sampling</title>
            <title type='title-intro' format='text/plain' language='fr' script='Latn'>Latex de caoutchouc</title>
      <title type='title-main' format='text/plain' language='fr' script='Latn'>Échantillonnage</title>
      <title type='main' format='text/plain' language='fr' script='Latn'>Latex de caoutchouc – Échantillonnage</title>
            <uri type='src'>https://www.iso.org/standard/23281.html</uri>
            <uri type='obp'>https://www.iso.org/obp/ui/#!iso:std:23281:en</uri>
            <uri type='rss'>https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
            <docidentifier type='ISO'>ISO 123:2001</docidentifier>
            <docnumber>123</docnumber>
            <date type='published'>
              <on>2001</on>
            </date>
            <contributor>
              <role type='publisher'/>
              <organization>
                <name>International Organization for Standardization</name>
                <abbreviation>ISO</abbreviation>
                <uri>www.iso.org</uri>
              </organization>
            </contributor>
            <edition>3</edition>
            <language>en</language>
            <language>fr</language>
            <script>Latn</script>
            <status>
              <stage>90</stage>
              <substage>93</substage>
            </status>
            <copyright>
              <from>2001</from>
              <owner>
                <organization>
                  <name>ISO</name>
                </organization>
              </owner>
            </copyright>
            <relation type='obsoletes'>
              <bibitem type='standard'>
                <formattedref format='text/plain'>ISO 123:1985</formattedref>
              </bibitem>
            </relation>
            <place>Geneva</place>
          </bibitem>
        </relation>
        <relation type='instanceOf'>
          <bibitem type='standard'>
            <formattedref format='text/plain'>ISO 123:1985</formattedref>
          </bibitem>
        </relation>
        <relation type='instanceOf'>
          <bibitem type='standard'>
            <formattedref format='text/plain'>ISO 123:1974</formattedref>
          </bibitem>
        </relation>
        <place>Geneva</place>
      </bibitem>
            <bibitem id='iso124'>
              <formattedref format='application/x-isodoc+xml'>
                <em>Standard</em>
              </formattedref>
              <uri type='URI'>a/b</uri>
      <uri type='citation'>a/b</uri>
              <docidentifier type="ISO">ISO 124</docidentifier>
              <docnumber>124</docnumber>
            </bibitem>
          </references>
        </bibliography>
      </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "overrides normative status of bibliographies" do
    input = <<~INPUT
      #{ISOBIB_BLANK_HDR}

      [bibliography,normative=false]
      == Normative References

      * [[[iso123,A]]] _Standard_

      [bibliography,normative=true]
      == Bibliography

      * [[[iso124,B]]] _Standard_
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
        <sections/>
        <bibliography>
          <references id="_" normative="false" obligation="informative">
            <title>Bibliography</title>
            <bibitem id="iso123">
              <formattedref format="application/x-isodoc+xml">
                <em>Standard</em>
              </formattedref>
              <docidentifier>A</docidentifier>
            </bibitem>
          </references>
          <references id="_" normative="true" obligation="informative">
            <title>Normative references</title>
            <p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
            <bibitem id="iso124">
              <formattedref format="application/x-isodoc+xml">
                <em>Standard</em>
              </formattedref>
              <docidentifier>B</docidentifier>
            </bibitem>
          </references>
        </bibliography>
      </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "have formatted reference tag" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      <<iso124>>
      <<iso125>>

      [bibliography]
      == Bibliography

      * [[[iso124,(*A*.footnote:[hello])XYZ]]] _Standard_
      * [[[iso125,usrlabel="*A*.footnote:[hello]",XYZ]]] _Standard_
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <preface>
           <foreword id='_' obligation='informative'>
             <title>Foreword</title>
             <p id='_'>
               <eref type="inline" bibitemid="iso124" citeas="[&lt;strong&gt;A&lt;/strong&gt;.]"/>
               <eref type="inline" bibitemid="iso125" citeas="[&lt;strong&gt;A&lt;/strong&gt;.]"/>
             </p>
           </foreword>
         </preface>
         <sections> </sections>
         <bibliography>
           <references id='_' normative='false' obligation='informative'>
             <title>Bibliography</title>
             <bibitem id='iso124'>
               <formattedref format='application/x-isodoc+xml'>
                 <em>Standard</em>
               </formattedref>
               <docidentifier type='metanorma'>
                 [
                 <strong>A</strong>
                 .
                 <fn reference='1'>
                   <p id='_'>hello</p>
                 </fn>
                 ]
               </docidentifier>
               <docidentifier>XYZ</docidentifier>
             </bibitem>
             <bibitem id='iso125'>
               <formattedref format='application/x-isodoc+xml'>
                 <em>Standard</em>
               </formattedref>
               <docidentifier type='metanorma'>
                 [
                 <strong>A</strong>
                 .
                 <fn reference='1'>
                   <p id='_'>hello</p>
                 </fn>
                 ]
               </docidentifier>
               <docidentifier>XYZ</docidentifier>
             </bibitem>
           </references>
         </bibliography>
       </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "mixes bibitems and bibliographic subclauses" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}

      [bibliography]
      == Bibliography

      Text

      * [[[iso124,(*A*.footnote:[hello])XYZ]]] _Standard_

      More text

      [bibliography]
      === Bibliography 1
      * [[[iso125,usrlabel="*A*.footnote:[hello]",XYZ]]] _Standard_
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
         <sections/>
         <bibliography>
           <clause id="_" obligation="informative">
             <title>Bibliography</title>
             <p id="_">Text</p>
             <references unnumbered="true" normative="false">
               <bibitem id="iso124">
                 <formattedref format="application/x-isodoc+xml">
                   <em>Standard</em>
                 </formattedref>
                 <docidentifier type="metanorma">[<strong>A</strong>.<fn reference="1"><p id="_">hello</p></fn>]</docidentifier>
                 <docidentifier>XYZ</docidentifier>
               </bibitem>
               <p id="_">More text</p>
             </references>
             <references id="_" normative="false" obligation="informative">
               <title>Bibliography 1</title>
               <bibitem id="iso125">
                 <formattedref format="application/x-isodoc+xml">
                   <em>Standard</em>
                 </formattedref>
                 <docidentifier type="metanorma">[<strong>A</strong>.<fn reference="1"><p id="_">hello</p></fn>]</docidentifier>
                 <docidentifier>XYZ</docidentifier>
               </bibitem>
             </references>
           </clause>
         </bibliography>
       </standard-document>
    OUTPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(output)
  end

  it "renders not found reference with no fall-back title" do
    mock_isobib_get_123_nil
    input = <<~"INPUT"
      #{ISOBIB_BLANK_HDR}

      [bibliography]
      == Normative References

      * [[[iso123,NIST 123]]]
    INPUT
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to Xml::C14n.format(<<~"OUTPUT")
        #{BLANK_HDR}
           <sections/>
           <bibliography>
             <references id="_" normative="true" obligation="informative">
               <title>Normative references</title>
               <p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
               <bibitem id="iso123">
                 <formattedref format="application/x-isodoc+xml">[NO INFORMATION AVAILABLE]</formattedref>
                 <docidentifier type="NIST">NIST 123</docidentifier>
                 <docnumber>123</docnumber>
               </bibitem>
             </references>
           </bibliography>
         </standard-document>
      OUTPUT
  end

  it "processes attachments" do
    attachment =
      if RUBY_PLATFORM.include?("mingw") || RUBY_PLATFORM.include?("mswin")
        <<~OUTPUT
          DQpwIHsNCiAgZm9udC1mYW1
          pbHk6ICRib2R5Zm9udDsNCn0NCg0KaDEgew0KICBmb250LWZhbWlseTogJGh
          lYWRlcmZvbnQ7DQp9DQoNCnByZSB7DQogIGZvbnQtZmFtaWx5OiAkbW9ub3N
          wYWNlZm9udDsNCn0NCg0K
        OUTPUT
      else
        <<~OUTPUT
          CnAgewogIGZvbnQtZmFtaWx
          5OiAkYm9keWZvbnQ7Cn0KCmgxIHsKICBmb250LWZhbWlseTogJGhlYWRlcmZ
          vbnQ7Cn0KCnByZSB7CiAgZm9udC1mYW1pbHk6ICRtb25vc3BhY2Vmb250Owp
          9Cgo=
        OUTPUT
      end
    input = File.read("spec/assets/attach.adoc")
      .gsub("iso.xml", "spec/assets/iso.xml")
      .gsub("html.scss", "spec/assets/html.scss")
    output = <<~OUTPUT
      <standard-document xmlns="https://www.metanorma.org/ns/standoc" type="semantic" version="#{Metanorma::Standoc::VERSION}">
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
             <doctype>standard</doctype>
           </ext>
         </bibdata>
                  <metanorma-extension>
             <attachment name="_attach_attachments/iso.xml">data:application/octet-stream;base64,ICAgIC...</attachment>
             <attachment name="_attach_attachments/iso.xml_">data:application/octet-stream;base64,ICAgIC...</attachment>
             <attachment name="_attach_attachments/html.scss">data:application/octet-stream;base64,#{attachment}</attachment>
             <presentation-metadata>
                <name>TOC Heading Levels</name>
                <value>2</value>
             </presentation-metadata>
             <presentation-metadata>
                <name>HTML TOC Heading Levels</name>
                <value>2</value>
             </presentation-metadata>
             <presentation-metadata>
                <name>DOC TOC Heading Levels</name>
                <value>2</value>
             </presentation-metadata>
             <presentation-metadata>
                <name>PDF TOC Heading Levels</name>
                <value>2</value>
             </presentation-metadata>
          </metanorma-extension>
          <sections>
             <clause id="_" inline-header="false" obligation="normative">
                <title>Clause</title>
                <p id="_">
                   <eref type="inline" bibitemid="iso123" citeas="[spec/assets/iso.xml]"/>
                </p>
             </clause>
          </sections>
          <bibliography>
             <references id="_" normative="true" obligation="informative">
                <title>Normative references</title>
                <p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
                <bibitem id="iso123" hidden="true">
                   <formattedref format="application/x-isodoc+xml">[NO INFORMATION AVAILABLE]</formattedref>
                   <uri type="attachment">_attach_attachments/iso.xml</uri>
                   <uri type="citation">_attach_attachments/iso.xml</uri>
                   <docidentifier type="metanorma">[spec/assets/iso.xml]</docidentifier>
                </bibitem>
                <bibitem id="iso124" hidden="true">
                   <formattedref format="application/x-isodoc+xml">[NO INFORMATION AVAILABLE]</formattedref>
                   <uri type="attachment">_attach_attachments/iso.xml_</uri>
                   <uri type="citation">_attach_attachments/iso.xml_</uri>
                   <docidentifier type="metanorma">[spec/assets/iso.xml]</docidentifier>
                </bibitem>
                <bibitem id="iso125" hidden="true">
                   <formattedref format="application/x-isodoc+xml">[NO INFORMATION AVAILABLE]</formattedref>
                   <uri type="attachment">_attach_attachments/html.scss</uri>
                   <uri type="citation">_attach_attachments/html.scss</uri>
                   <docidentifier type="metanorma">[spec/assets/html.scss]</docidentifier>
                </bibitem>
             </references>
          </bibliography>
       </standard-document>
    OUTPUT

    # Windows/Unix differences in XML encoding: remove body of Data URI
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS)
      .gsub(/iso.xml_[a-f0-9-]+/, "iso.xml_")
      .gsub(/ICAgIC[^<]+/, "ICAgIC..."))))
      .to be_equivalent_to Xml::C14n.format(output)
    input.sub!(":docfile:", ":data-uri-attachment: false\n:docfile:")
    expect(Xml::C14n.format(strip_guid(Asciidoctor.convert(input, *OPTIONS)
      .gsub(/iso.xml_[a-f0-9-]+/, "iso.xml_")
      .gsub(/ICAgIC[^<]+/, "ICAgIC..."))))
      .to be_equivalent_to Xml::C14n.format(output
      .gsub(%r{<attachment .+?</attachment>}m, "")
      .gsub("_attach_attachments", "spec/assets")
      .gsub("iso.xml_", "iso.xml"))

    FileUtils.rm_rf "spec/assets/attach.xml"
    system "bundle exec asciidoctor -b standoc -r metanorma-standoc spec/assets/attach.adoc"
    expect(Xml::C14n.format(strip_guid(File.read("spec/assets/attach.xml")
      .gsub(/iso.xml_[a-f0-9-]+/, "iso.xml_")
      .gsub(/ICAgIC[^<]+/, "ICAgIC..."))))
      .to be_equivalent_to Xml::C14n.format(output
      .gsub("spec/assets/iso.xml", "iso.xml")
      .gsub("spec/assets/html.scss", "html.scss"))
  end

  private

  def mock_isobib_get_123_nil
    expect(RelatonNist::NistBibliography).to receive(:get)
      .with("NIST 123", nil, { code: "NIST 123",
                               lang: "en",
                               match: anything,
                               analyse_code: anything,
                               process: 0,
                               ord: anything,
                               title: "" }).and_return(nil)
  end

  def mock_isobib_get_123_no_docid(times)
    expect(RelatonIso::IsoBibliography).to receive(:get)
      .with("ISO 123", nil, { code: "ISO 123",
                              lang: "en",
                              match: anything,
                              analyse_code: anything,
                              process: 1,
                              ord: anything,
                              title: "<em>Standard</em>",
                              usrlbl: nil,
                              year: nil }) do
      RelatonBib::XMLParser.from_xml(<<~"OUTPUT")
        <bibitem type="standard" id="ISO123">\n  <uri type="src">https://www.iso.org/standard/23281.html</uri>\n  <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:23281:en</uri>\n  <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>\n  <date type="published">\n    <on>2001</on>\n  </date>\n  <contributor>\n    <role type="publisher"/>\n    <organization>\n      <name>International Organization for Standardization</name>\n      <abbreviation>ISO</abbreviation>\n      <uri>www.iso.org</uri>\n    </organization>\n  </contributor>\n  <edition>3</edition>\n  <language>en</language>\n  <language>fr</language>\n  <script>Latn</script>\n  <status><stage>Published</stage></status>\n  <copyright>\n    <from>2001</from>\n    <owner>\n      <organization>\n        <name>ISO</name>\n        <abbreviation></abbreviation>\n      </organization>\n    </owner>\n  </copyright>\n  <relation type="obsoletes">\n    <bibitem type="standard">\n      <formattedref format="text/plain">ISO 123:1985</formattedref>\n      </bibitem>\n  </relation>\n  <relation type="updates">\n    <bibitem type="standard">\n      <formattedref format="text/plain">ISO 123:2001</formattedref>\n      </bibitem>\n  </relation>\n<ext></fred></ext></bibitem>
      OUTPUT
    end.exactly(times).times
  end

  def mock_isobib_get_123_no_docid_lbl(times)
    expect(RelatonIso::IsoBibliography).to receive(:get)
      .with("ISO 123", nil, { code: "ISO 123",
                              analyse_code: anything,
                              lang: "en",
                              match: anything,
                              process: 1,
                              ord: anything,
                              title: "<em>Standard</em>",
                              usrlbl: "(1)",
                              year: nil }) do
      RelatonBib::XMLParser.from_xml(<<~"OUTPUT")
        <bibitem type="standard" id="ISO123">\n  <uri type="src">https://www.iso.org/standard/23281.html</uri>\n  <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:23281:en</uri>\n  <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>\n  <date type="published">\n    <on>2001</on>\n  </date>\n  <contributor>\n    <role type="publisher"/>\n    <organization>\n      <name>International Organization for Standardization</name>\n      <abbreviation>ISO</abbreviation>\n      <uri>www.iso.org</uri>\n    </organization>\n  </contributor>\n  <edition>3</edition>\n  <language>en</language>\n  <language>fr</language>\n  <script>Latn</script>\n  <status><stage>Published</stage></status>\n  <copyright>\n    <from>2001</from>\n    <owner>\n      <organization>\n        <name>ISO</name>\n        <abbreviation></abbreviation>\n      </organization>\n    </owner>\n  </copyright>\n  <relation type="obsoletes">\n    <bibitem type="standard">\n      <formattedref format="text/plain">ISO 123:1985</formattedref>\n      </bibitem>\n  </relation>\n  <relation type="updates">\n    <bibitem type="standard">\n      <formattedref format="text/plain">ISO 123:2001</formattedref>\n      </bibitem>\n  </relation>\n<ext></fred></ext></bibitem>
      OUTPUT
    end.exactly(times).times
  end

  def mock_isobib_get_123_no_docid_fn(times)
    expect(RelatonIso::IsoBibliography).to receive(:get)
      .with("ISO 123", nil, { code: "ISO 123",
                              analyse_code: anything,
                              lang: "en",
                              match: anything,
                              process: 1,
                              ord: anything,
                              title: "<em>Standard</em>.<fn reference=\"1\"><p>footnote</p></fn>",
                              usrlbl: "(2)",
                              year: nil }) do
      RelatonBib::XMLParser.from_xml(<<~"OUTPUT")
        <bibitem type="standard" id="ISO123">\n  <uri type="src">https://www.iso.org/standard/23281.html</uri>\n  <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:23281:en</uri>\n  <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>\n  <date type="published">\n    <on>2001</on>\n  </date>\n  <contributor>\n    <role type="publisher"/>\n    <organization>\n      <name>International Organization for Standardization</name>\n      <abbreviation>ISO</abbreviation>\n      <uri>www.iso.org</uri>\n    </organization>\n  </contributor>\n  <edition>3</edition>\n  <language>en</language>\n  <language>fr</language>\n  <script>Latn</script>\n  <status><stage>Published</stage></status>\n  <copyright>\n    <from>2001</from>\n    <owner>\n      <organization>\n        <name>ISO</name>\n        <abbreviation></abbreviation>\n      </organization>\n    </owner>\n  </copyright>\n  <relation type="obsoletes">\n    <bibitem type="standard">\n      <formattedref format="text/plain">ISO 123:1985</formattedref>\n      </bibitem>\n  </relation>\n  <relation type="updates">\n    <bibitem type="standard">\n      <formattedref format="text/plain">ISO 123:2001</formattedref>\n      </bibitem>\n  </relation>\n<ext></fred></ext></bibitem>
      OUTPUT
    end.exactly(times).times
  end

  def mock_rfcbib_get_rfc8342(times)
    expect(RelatonIso::IsoBibliography).to receive(:get).with("ISO 8342", nil,
                                                              anything) do
      RelatonBib::XMLParser.from_xml(<<~OUTPUT)
              <bibitem id="RFC8342">
          <title format="text/plain" language="en" script="Latn">Network Configuration Access Control Model</title>
          <docidentifier type="DOI">10.17487/RFC8341</docidentifier>
          <docidentifier type="ISO">ISO 8341</docidentifier>
          <docidentifier type="ISO" primary="true">ISO 8342-EN</docidentifier>
          <docidentifier type="ISO" language="fr">ISO 8342-FR</docidentifier>
          <docidentifier type="ISO" primary="true" language="de">ISO 8342-DE</docidentifier>
          <date type="published">
            <on>2018</on>
          </date>
          <status>published</status>
        </bibitem>
      OUTPUT
    end.exactly(times).times
  end

  def mock_rfcbib_get_rfc8343(times)
    expect(RelatonIso::IsoBibliography).to receive(:get).with("ISO 8343", nil,
                                                              anything) do
      RelatonBib::XMLParser.from_xml(<<~OUTPUT)
              <bibitem id="RFC8343">
          <title format="text/plain" language="en" script="Latn">Network Configuration Access Control Model</title>
          <docidentifier type="DOI">10.17487/RFC8341</docidentifier>
          <docidentifier type="ISO">ISO 8341</docidentifier>
          <docidentifier type="ISO">ISO 8343-EN</docidentifier>
          <docidentifier type="ISO" language="fr">ISO 8343-FR</docidentifier>
          <docidentifier type="ISO" language="de">ISO 8343-DE</docidentifier>
          <date type="published">
            <on>2018</on>
          </date>
          <status>published</status>
        </bibitem>
      OUTPUT
    end.exactly(times).times
  end
end
