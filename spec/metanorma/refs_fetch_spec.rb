require "spec_helper"
require "relaton/iso"
require "relaton/ietf"

RSpec.describe Metanorma::Standoc do
  it "fetches simple ISO reference" do
    input = <<~INPUT
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR}

      [bibliography]
      == Normative References

      * [[[iso123, ISO 123]]] _Standard_
      * [[[iso124,(1)ISO 123 ]]] _Standard_
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
             <sections>

             </sections><bibliography><references id="_" obligation="informative" normative="true"><title id="_">Normative references</title>
              #{NORM_REF_BOILERPLATE}
                 <bibitem id="_" type="standard" anchor="iso123">
                    <fetched/>
                    <title language="en" script="Latn" type="title-intro" format="text/plain">Rubber latex</title>
                    <title language="en" script="Latn" type="title-main" format="text/plain">Sampling</title>
                    <title language="en" script="Latn" type="main" format="text/plain">Rubber latex\\u2009—\\u2009Sampling</title>
                    <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex de caoutchouc</title>
                    <title language="fr" script="Latn" type="title-main" format="text/plain">Échantillonnage</title>
                    <title language="fr" script="Latn" type="main" format="text/plain">Latex de caoutchouc\\u2009—\\u2009Échantillonnage</title>
                    <uri type="src">https://www.iso.org/standard/23281.html</uri>
                    <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:23281:en</uri>
                    <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
                    <docidentifier type="ISO" primary="true">ISO 123</docidentifier>
                    <docidentifier type="iso-reference">ISO 123(E)</docidentifier>
                    <docidentifier type="URN">urn:iso:std:iso:123:stage-90.93</docidentifier>
                    <docnumber>123</docnumber>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <abbreviation>ISO</abbreviation>
                          <uri>www.iso.org</uri>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="author">
                          <description>committee</description>
                       </role>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <subdivision type="technical-committee" subtype="TC">
                             <name>Raw materials (including latex) for use in the rubber industry</name>
                             <identifier>ISO/TC 45/SC 3</identifier>
                          </subdivision>
                          <abbreviation>ISO</abbreviation>
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
                    <relation type="obsoletes">
                       <bibitem type="standard">
                          <formattedref>ISO 123:1985</formattedref>
                          <docidentifier type="ISO" primary="true">ISO 123:1985</docidentifier>
                       </bibitem>
                    </relation>
                    <relation type="instanceOf">
                       <bibitem type="standard">
                          <title language="en" script="Latn" type="title-intro" format="text/plain">Rubber latex</title>
                          <title language="en" script="Latn" type="title-main" format="text/plain">Sampling</title>
                          <title language="en" script="Latn" type="main" format="text/plain">Rubber latex\\u2009—\\u2009Sampling</title>
                          <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex de caoutchouc</title>
                          <title language="fr" script="Latn" type="title-main" format="text/plain">Échantillonnage</title>
                          <title language="fr" script="Latn" type="main" format="text/plain">Latex de caoutchouc\\u2009—\\u2009Échantillonnage</title>
                          <uri type="src">https://www.iso.org/standard/23281.html</uri>
                          <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:23281:en</uri>
                          <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
                          <docidentifier type="ISO" primary="true">ISO 123:2001</docidentifier>
                          <docidentifier type="iso-reference">ISO 123:2001(E)</docidentifier>
                          <docidentifier type="URN">urn:iso:std:iso:123:stage-90.93</docidentifier>
                          <docnumber>123</docnumber>
                          <date type="published">
                             <on>2001-05</on>
                          </date>
                          <contributor>
                             <role type="publisher"/>
                             <organization>
                                <name>International Organization for Standardization</name>
                                <abbreviation>ISO</abbreviation>
                                <uri>www.iso.org</uri>
                             </organization>
                          </contributor>
                          <contributor>
                             <role type="author">
                                <description>committee</description>
                             </role>
                             <organization>
                                <name>International Organization for Standardization</name>
                                <subdivision type="technical-committee" subtype="TC">
                                   <name>Raw materials (including latex) for use in the rubber industry</name>
                                   <identifier>ISO/TC 45/SC 3</identifier>
                                </subdivision>
                                <abbreviation>ISO</abbreviation>
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
                          <relation type="obsoletes">
                             <bibitem type="standard">
                                <formattedref>ISO 123:1985</formattedref>
                                <docidentifier type="ISO" primary="true">ISO 123:1985</docidentifier>
                             </bibitem>
                          </relation>
                          <place>
                             <formattedPlace>Geneva</formattedPlace>
                          </place>
                       </bibitem>
                    </relation>
                    <place>
                       <formattedPlace>Geneva</formattedPlace>
                    </place>
                 </bibitem>
                 <bibitem id="_" type="standard" anchor="iso124">
                    <fetched/>
                    <title language="en" script="Latn" type="title-intro" format="text/plain">Rubber latex</title>
                    <title language="en" script="Latn" type="title-main" format="text/plain">Sampling</title>
                    <title language="en" script="Latn" type="main" format="text/plain">Rubber latex\\u2009—\\u2009Sampling</title>
                    <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex de caoutchouc</title>
                    <title language="fr" script="Latn" type="title-main" format="text/plain">Échantillonnage</title>
                    <title language="fr" script="Latn" type="main" format="text/plain">Latex de caoutchouc\\u2009—\\u2009Échantillonnage</title>
                    <uri type="src">https://www.iso.org/standard/23281.html</uri>
                    <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:23281:en</uri>
                    <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
                    <docidentifier type="ISO" primary="true">ISO 123</docidentifier>
                    <docidentifier type="metanorma">[1]</docidentifier>
                    <docidentifier type="iso-reference">ISO 123(E)</docidentifier>
                    <docidentifier type="URN">urn:iso:std:iso:123:stage-90.93</docidentifier>
                    <docnumber>123</docnumber>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <abbreviation>ISO</abbreviation>
                          <uri>www.iso.org</uri>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="author">
                          <description>committee</description>
                       </role>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <subdivision type="technical-committee" subtype="TC">
                             <name>Raw materials (including latex) for use in the rubber industry</name>
                             <identifier>ISO/TC 45/SC 3</identifier>
                          </subdivision>
                          <abbreviation>ISO</abbreviation>
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
                    <relation type="obsoletes">
                       <bibitem type="standard">
                          <formattedref>ISO 123:1985</formattedref>
                          <docidentifier type="ISO" primary="true">ISO 123:1985</docidentifier>
                       </bibitem>
                    </relation>
                    <relation type="instanceOf">
                       <bibitem type="standard">
                          <title language="en" script="Latn" type="title-intro" format="text/plain">Rubber latex</title>
                          <title language="en" script="Latn" type="title-main" format="text/plain">Sampling</title>
                          <title language="en" script="Latn" type="main" format="text/plain">Rubber latex\\u2009—\\u2009Sampling</title>
                          <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex de caoutchouc</title>
                          <title language="fr" script="Latn" type="title-main" format="text/plain">Échantillonnage</title>
                          <title language="fr" script="Latn" type="main" format="text/plain">Latex de caoutchouc\\u2009—\\u2009Échantillonnage</title>
                          <uri type="src">https://www.iso.org/standard/23281.html</uri>
                          <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:23281:en</uri>
                          <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
                          <docidentifier type="ISO" primary="true">ISO 123:2001</docidentifier>
                          <docidentifier type="iso-reference">ISO 123:2001(E)</docidentifier>
                          <docidentifier type="URN">urn:iso:std:iso:123:stage-90.93</docidentifier>
                          <docnumber>123</docnumber>
                          <date type="published">
                             <on>2001-05</on>
                          </date>
                          <contributor>
                             <role type="publisher"/>
                             <organization>
                                <name>International Organization for Standardization</name>
                                <abbreviation>ISO</abbreviation>
                                <uri>www.iso.org</uri>
                             </organization>
                          </contributor>
                          <contributor>
                             <role type="author">
                                <description>committee</description>
                             </role>
                             <organization>
                                <name>International Organization for Standardization</name>
                                <subdivision type="technical-committee" subtype="TC">
                                   <name>Raw materials (including latex) for use in the rubber industry</name>
                                   <identifier>ISO/TC 45/SC 3</identifier>
                                </subdivision>
                                <abbreviation>ISO</abbreviation>
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
                          <relation type="obsoletes">
                             <bibitem type="standard">
                                <formattedref>ISO 123:1985</formattedref>
                                <docidentifier type="ISO" primary="true">ISO 123:1985</docidentifier>
                             </bibitem>
                          </relation>
                          <place>
                             <formattedPlace>Geneva</formattedPlace>
                          </place>
                       </bibitem>
                    </relation>
                    <place>
                       <formattedPlace>Geneva</formattedPlace>
                    </place>
                 </bibitem>
              </references>
           </bibliography>
        </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.xpath("//xmlns:abstract").each(&:remove)
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
  end

  it "fetches simple ISO reference in French" do
    input = <<~INPUT
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR.sub(':novalid:', ":novalid:\n:language: fr")}

      [bibliography]
      == Normative References

      * [[[iso123,ISO 123]]] _Standard_
      * [[[iso124,(1)ISO 123]]] _Standard_
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR.sub(%r{<language>en</language>}, '<language>fr</language>').sub('<title language="en"', '<title language="fr"')}
                      <sections> </sections>
        <bibliography>
          <references id="_" normative='true' obligation='informative'>
            <title id="_">R&#233;f&#233;rences normatives</title>
            <p id='_'>
              Les documents suivants cit&#233;s dans le texte constituent, pour tout
              ou partie de leur contenu, des exigences du pr&#233;sent document. Pour
              les r&#233;f&#233;rences dat&#233;es, seule l&#8217;&#233;dition
              cit&#233;e s&#8217;applique. Pour les r&#233;f&#233;rences non
              dat&#233;es, la derni&#232;re &#233;dition du document de
              r&#233;f&#233;rence s&#8217;applique (y compris les &#233;ventuels
              amendements).
            </p>
                 <bibitem id="_" type="standard" anchor="iso123">
                    <fetched/>
                    <title language="en" script="Latn" type="title-intro" format="text/plain">Rubber latex</title>
                    <title language="en" script="Latn" type="title-main" format="text/plain">Sampling</title>
                    <title language="en" script="Latn" type="main" format="text/plain">Rubber latex\\u2009—\\u2009Sampling</title>
                    <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex de caoutchouc</title>
                    <title language="fr" script="Latn" type="title-main" format="text/plain">Échantillonnage</title>
                    <title language="fr" script="Latn" type="main" format="text/plain">Latex de caoutchouc\\u2009—\\u2009Échantillonnage</title>
                    <uri type="src">https://www.iso.org/standard/23281.html</uri>
                    <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:23281:en</uri>
                    <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
                    <docidentifier type="ISO" primary="true">ISO 123</docidentifier>
                    <docidentifier type="iso-reference">ISO 123(E)</docidentifier>
                    <docidentifier type="URN">urn:iso:std:iso:123:stage-90.93</docidentifier>
                    <docnumber>123</docnumber>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <abbreviation>ISO</abbreviation>
                          <uri>www.iso.org</uri>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="author">
                          <description>committee</description>
                       </role>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <subdivision type="technical-committee" subtype="TC">
                             <name>Raw materials (including latex) for use in the rubber industry</name>
                             <identifier>ISO/TC 45/SC 3</identifier>
                          </subdivision>
                          <abbreviation>ISO</abbreviation>
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
                    <relation type="obsoletes">
                       <bibitem type="standard">
                          <formattedref>ISO 123:1985</formattedref>
                          <docidentifier type="ISO" primary="true">ISO 123:1985</docidentifier>
                       </bibitem>
                    </relation>
                    <relation type="instanceOf">
                       <bibitem type="standard">
                          <title language="en" script="Latn" type="title-intro" format="text/plain">Rubber latex</title>
                          <title language="en" script="Latn" type="title-main" format="text/plain">Sampling</title>
                          <title language="en" script="Latn" type="main" format="text/plain">Rubber latex\\u2009—\\u2009Sampling</title>
                          <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex de caoutchouc</title>
                          <title language="fr" script="Latn" type="title-main" format="text/plain">Échantillonnage</title>
                          <title language="fr" script="Latn" type="main" format="text/plain">Latex de caoutchouc\\u2009—\\u2009Échantillonnage</title>
                          <uri type="src">https://www.iso.org/standard/23281.html</uri>
                          <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:23281:en</uri>
                          <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
                          <docidentifier type="ISO" primary="true">ISO 123:2001</docidentifier>
                          <docidentifier type="iso-reference">ISO 123:2001(E)</docidentifier>
                          <docidentifier type="URN">urn:iso:std:iso:123:stage-90.93</docidentifier>
                          <docnumber>123</docnumber>
                          <date type="published">
                             <on>2001-05</on>
                          </date>
                          <contributor>
                             <role type="publisher"/>
                             <organization>
                                <name>International Organization for Standardization</name>
                                <abbreviation>ISO</abbreviation>
                                <uri>www.iso.org</uri>
                             </organization>
                          </contributor>
                          <contributor>
                             <role type="author">
                                <description>committee</description>
                             </role>
                             <organization>
                                <name>International Organization for Standardization</name>
                                <subdivision type="technical-committee" subtype="TC">
                                   <name>Raw materials (including latex) for use in the rubber industry</name>
                                   <identifier>ISO/TC 45/SC 3</identifier>
                                </subdivision>
                                <abbreviation>ISO</abbreviation>
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
                          <relation type="obsoletes">
                             <bibitem type="standard">
                                <formattedref>ISO 123:1985</formattedref>
                                <docidentifier type="ISO" primary="true">ISO 123:1985</docidentifier>
                             </bibitem>
                          </relation>
                          <place>
                             <formattedPlace>Geneva</formattedPlace>
                          </place>
                       </bibitem>
                    </relation>
                    <place>
                       <formattedPlace>Geneva</formattedPlace>
                    </place>
                 </bibitem>
                 <bibitem id="_" type="standard" anchor="iso124">
                    <fetched/>
                    <title language="en" script="Latn" type="title-intro" format="text/plain">Rubber latex</title>
                    <title language="en" script="Latn" type="title-main" format="text/plain">Sampling</title>
                    <title language="en" script="Latn" type="main" format="text/plain">Rubber latex\\u2009—\\u2009Sampling</title>
                    <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex de caoutchouc</title>
                    <title language="fr" script="Latn" type="title-main" format="text/plain">Échantillonnage</title>
                    <title language="fr" script="Latn" type="main" format="text/plain">Latex de caoutchouc\\u2009—\\u2009Échantillonnage</title>
                    <uri type="src">https://www.iso.org/standard/23281.html</uri>
                    <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:23281:en</uri>
                    <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
                    <docidentifier type="ISO" primary="true">ISO 123</docidentifier>
                    <docidentifier type="metanorma">[1]</docidentifier>
                    <docidentifier type="iso-reference">ISO 123(E)</docidentifier>
                    <docidentifier type="URN">urn:iso:std:iso:123:stage-90.93</docidentifier>
                    <docnumber>123</docnumber>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <abbreviation>ISO</abbreviation>
                          <uri>www.iso.org</uri>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="author">
                          <description>committee</description>
                       </role>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <subdivision type="technical-committee" subtype="TC">
                             <name>Raw materials (including latex) for use in the rubber industry</name>
                             <identifier>ISO/TC 45/SC 3</identifier>
                          </subdivision>
                          <abbreviation>ISO</abbreviation>
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
                    <relation type="obsoletes">
                       <bibitem type="standard">
                          <formattedref>ISO 123:1985</formattedref>
                          <docidentifier type="ISO" primary="true">ISO 123:1985</docidentifier>
                       </bibitem>
                    </relation>
                    <relation type="instanceOf">
                       <bibitem type="standard">
                          <title language="en" script="Latn" type="title-intro" format="text/plain">Rubber latex</title>
                          <title language="en" script="Latn" type="title-main" format="text/plain">Sampling</title>
                          <title language="en" script="Latn" type="main" format="text/plain">Rubber latex\\u2009—\\u2009Sampling</title>
                          <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex de caoutchouc</title>
                          <title language="fr" script="Latn" type="title-main" format="text/plain">Échantillonnage</title>
                          <title language="fr" script="Latn" type="main" format="text/plain">Latex de caoutchouc\\u2009—\\u2009Échantillonnage</title>
                          <uri type="src">https://www.iso.org/standard/23281.html</uri>
                          <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:23281:en</uri>
                          <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
                          <docidentifier type="ISO" primary="true">ISO 123:2001</docidentifier>
                          <docidentifier type="iso-reference">ISO 123:2001(E)</docidentifier>
                          <docidentifier type="URN">urn:iso:std:iso:123:stage-90.93</docidentifier>
                          <docnumber>123</docnumber>
                          <date type="published">
                             <on>2001-05</on>
                          </date>
                          <contributor>
                             <role type="publisher"/>
                             <organization>
                                <name>International Organization for Standardization</name>
                                <abbreviation>ISO</abbreviation>
                                <uri>www.iso.org</uri>
                             </organization>
                          </contributor>
                          <contributor>
                             <role type="author">
                                <description>committee</description>
                             </role>
                             <organization>
                                <name>International Organization for Standardization</name>
                                <subdivision type="technical-committee" subtype="TC">
                                   <name>Raw materials (including latex) for use in the rubber industry</name>
                                   <identifier>ISO/TC 45/SC 3</identifier>
                                </subdivision>
                                <abbreviation>ISO</abbreviation>
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
                          <relation type="obsoletes">
                             <bibitem type="standard">
                                <formattedref>ISO 123:1985</formattedref>
                                <docidentifier type="ISO" primary="true">ISO 123:1985</docidentifier>
                             </bibitem>
                          </relation>
                          <place>
                             <formattedPlace>Geneva</formattedPlace>
                          </place>
                       </bibitem>
                    </relation>
                    <place>
                       <formattedPlace>Geneva</formattedPlace>
                    </place>
                 </bibitem>
              </references>
           </bibliography>
        </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.xpath("//xmlns:abstract").each(&:remove)
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
  end

  it "processes dated ISO reference and joint ISO/IEC references" do
    input = <<~INPUT
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO/IEC TR 12382:1992]]] _Standard_
      * [[[iso124,ISO 124:2014]]] _Standard_
      * [[[iso125,(1)ISO/IEC TR 12382:1992]]] _Standard_
      * [[[iso126,(1)ISO 124:2014]]] _Standard_
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
       <sections>

       </sections><bibliography><references id="_" obligation="informative" normative="true">
         <title id="_">Normative references</title>
       #{NORM_REF_BOILERPLATE}
                 <bibitem id="_" type="standard" anchor="iso123">
                    <fetched/>
                    <title language="en" script="Latn" type="title-main" format="text/plain">Permuted index of the vocabulary of information technology</title>
                    <title language="en" script="Latn" type="main" format="text/plain">Permuted index of the vocabulary of information technology</title>
                    <title language="fr" script="Latn" type="title-main" format="text/plain">Index permuté du vocabulaire des technologies de l’information</title>
                    <title language="fr" script="Latn" type="main" format="text/plain">Index permuté du vocabulaire des technologies de l’information</title>
                    <uri type="src">https://www.iso.org/standard/21071.html</uri>
                    <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:21071:en</uri>
                    <uri type="rss">https://www.iso.org/contents/data/standard/02/10/21071.detail.rss</uri>
                    <docidentifier type="ISO" primary="true">ISO/IEC TR 12382:1992</docidentifier>
                    <docidentifier type="iso-reference">ISO/IEC TR 12382:1992(E)</docidentifier>
                    <docidentifier type="URN">urn:iso:std:iso-iec:tr:12382:stage-90.93</docidentifier>
                    <docnumber>12382</docnumber>
                    <date type="published">
                       <on>1992-12</on>
                    </date>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <abbreviation>ISO</abbreviation>
                          <uri>www.iso.org</uri>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name>International Electrotechnical Commission</name>
                          <abbreviation>IEC</abbreviation>
                          <uri>www.iec.ch</uri>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="author">
                          <description>committee</description>
                       </role>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <subdivision type="technical-committee" subtype="IEC">
                             <name>Information technology</name>
                             <identifier>ISO/IEC JTC 1</identifier>
                          </subdivision>
                          <abbreviation>ISO</abbreviation>
                       </organization>
                    </contributor>
                    <edition>2</edition>
                    <language>en</language>
                    <language>fr</language>
                    <script>Latn</script>
                    <status>
                       <stage>90</stage>
                       <substage>93</substage>
                    </status>
                    <copyright>
                       <from>1992</from>
                       <owner>
                          <organization>
                             <name>ISO/IEC</name>
                          </organization>
                       </owner>
                    </copyright>
                    <place>
                       <formattedPlace>Geneva</formattedPlace>
                    </place>
                 </bibitem>
                 <bibitem id="_" type="standard" anchor="iso124">
                    <fetched/>
                    <title language="en" script="Latn" type="title-intro" format="text/plain">Latex, rubber</title>
                    <title language="en" script="Latn" type="title-main" format="text/plain">Determination of total solids content</title>
                    <title language="en" script="Latn" type="main" format="text/plain">Latex, rubber\\u2009—\\u2009Determination of total solids content</title>
                    <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex de caoutchouc</title>
                    <title language="fr" script="Latn" type="title-main" format="text/plain">Détermination des matières solides totales</title>
                    <title language="fr" script="Latn" type="main" format="text/plain">Latex de caoutchouc\\u2009—\\u2009Détermination des matières solides totales</title>
                    <uri type="src">https://www.iso.org/standard/61884.html</uri>
                    <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:61884:en</uri>
                    <uri type="rss">https://www.iso.org/contents/data/standard/06/18/61884.detail.rss</uri>
                    <docidentifier type="ISO" primary="true">ISO 124:2014</docidentifier>
                    <docidentifier type="iso-reference">ISO 124:2014(E)</docidentifier>
                    <docidentifier type="URN">urn:iso:std:iso:124:stage-90.20</docidentifier>
                    <docnumber>124</docnumber>
                    <date type="published">
                       <on>2014-03</on>
                    </date>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <abbreviation>ISO</abbreviation>
                          <uri>www.iso.org</uri>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="author">
                          <description>committee</description>
                       </role>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <subdivision type="technical-committee" subtype="TC">
                             <name>Raw materials (including latex) for use in the rubber industry</name>
                             <identifier>ISO/TC 45/SC 3</identifier>
                          </subdivision>
                          <abbreviation>ISO</abbreviation>
                       </organization>
                    </contributor>
                    <edition>7</edition>
                    <language>en</language>
                    <language>fr</language>
                    <script>Latn</script>
                    <status>
                       <stage>90</stage>
                       <substage>20</substage>
                    </status>
                    <copyright>
                       <from>2014</from>
                       <owner>
                          <organization>
                             <name>ISO</name>
                          </organization>
                       </owner>
                    </copyright>
                    <relation type="obsoletes">
                       <bibitem type="standard">
                          <formattedref>ISO 124:2011</formattedref>
                          <docidentifier type="ISO" primary="true">ISO 124:2011</docidentifier>
                       </bibitem>
                    </relation>
                    <place>
                       <formattedPlace>Geneva</formattedPlace>
                    </place>
                 </bibitem>
                 <bibitem id="_" type="standard" anchor="iso125">
                    <fetched/>
                    <title language="en" script="Latn" type="title-main" format="text/plain">Permuted index of the vocabulary of information technology</title>
                    <title language="en" script="Latn" type="main" format="text/plain">Permuted index of the vocabulary of information technology</title>
                    <title language="fr" script="Latn" type="title-main" format="text/plain">Index permuté du vocabulaire des technologies de l’information</title>
                    <title language="fr" script="Latn" type="main" format="text/plain">Index permuté du vocabulaire des technologies de l’information</title>
                    <uri type="src">https://www.iso.org/standard/21071.html</uri>
                    <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:21071:en</uri>
                    <uri type="rss">https://www.iso.org/contents/data/standard/02/10/21071.detail.rss</uri>
                    <docidentifier type="ISO" primary="true">ISO/IEC TR 12382:1992</docidentifier>
                    <docidentifier type="metanorma">[1]</docidentifier>
                    <docidentifier type="iso-reference">ISO/IEC TR 12382:1992(E)</docidentifier>
                    <docidentifier type="URN">urn:iso:std:iso-iec:tr:12382:stage-90.93</docidentifier>
                    <docnumber>12382</docnumber>
                    <date type="published">
                       <on>1992-12</on>
                    </date>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <abbreviation>ISO</abbreviation>
                          <uri>www.iso.org</uri>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name>International Electrotechnical Commission</name>
                          <abbreviation>IEC</abbreviation>
                          <uri>www.iec.ch</uri>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="author">
                          <description>committee</description>
                       </role>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <subdivision type="technical-committee" subtype="IEC">
                             <name>Information technology</name>
                             <identifier>ISO/IEC JTC 1</identifier>
                          </subdivision>
                          <abbreviation>ISO</abbreviation>
                       </organization>
                    </contributor>
                    <edition>2</edition>
                    <language>en</language>
                    <language>fr</language>
                    <script>Latn</script>
                    <status>
                       <stage>90</stage>
                       <substage>93</substage>
                    </status>
                    <copyright>
                       <from>1992</from>
                       <owner>
                          <organization>
                             <name>ISO/IEC</name>
                          </organization>
                       </owner>
                    </copyright>
                    <place>
                       <formattedPlace>Geneva</formattedPlace>
                    </place>
                 </bibitem>
                 <bibitem id="_" type="standard" anchor="iso126">
                    <fetched/>
                    <title language="en" script="Latn" type="title-intro" format="text/plain">Latex, rubber</title>
                    <title language="en" script="Latn" type="title-main" format="text/plain">Determination of total solids content</title>
                    <title language="en" script="Latn" type="main" format="text/plain">Latex, rubber\\u2009—\\u2009Determination of total solids content</title>
                    <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex de caoutchouc</title>
                    <title language="fr" script="Latn" type="title-main" format="text/plain">Détermination des matières solides totales</title>
                    <title language="fr" script="Latn" type="main" format="text/plain">Latex de caoutchouc\\u2009—\\u2009Détermination des matières solides totales</title>
                    <uri type="src">https://www.iso.org/standard/61884.html</uri>
                    <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:61884:en</uri>
                    <uri type="rss">https://www.iso.org/contents/data/standard/06/18/61884.detail.rss</uri>
                    <docidentifier type="ISO" primary="true">ISO 124:2014</docidentifier>
                    <docidentifier type="metanorma">[1]</docidentifier>
                    <docidentifier type="iso-reference">ISO 124:2014(E)</docidentifier>
                    <docidentifier type="URN">urn:iso:std:iso:124:stage-90.20</docidentifier>
                    <docnumber>124</docnumber>
                    <date type="published">
                       <on>2014-03</on>
                    </date>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <abbreviation>ISO</abbreviation>
                          <uri>www.iso.org</uri>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="author">
                          <description>committee</description>
                       </role>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <subdivision type="technical-committee" subtype="TC">
                             <name>Raw materials (including latex) for use in the rubber industry</name>
                             <identifier>ISO/TC 45/SC 3</identifier>
                          </subdivision>
                          <abbreviation>ISO</abbreviation>
                       </organization>
                    </contributor>
                    <edition>7</edition>
                    <language>en</language>
                    <language>fr</language>
                    <script>Latn</script>
                    <status>
                       <stage>90</stage>
                       <substage>20</substage>
                    </status>
                    <copyright>
                       <from>2014</from>
                       <owner>
                          <organization>
                             <name>ISO</name>
                          </organization>
                       </owner>
                    </copyright>
                    <relation type="obsoletes">
                       <bibitem type="standard">
                          <formattedref>ISO 124:2011</formattedref>
                          <docidentifier type="ISO" primary="true">ISO 124:2011</docidentifier>
                       </bibitem>
                    </relation>
                    <place>
                       <formattedPlace>Geneva</formattedPlace>
                    </place>
                 </bibitem>
              </references>
           </bibliography>
        </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.xpath("//xmlns:abstract").each(&:remove)
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
  end

  it "processes DOI references" do
    input = <<~INPUT
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR}
      == Section

      [bibliography]
      == Bibliography

      * [[[ref1,doi:10.1045/november2010-massart]]] _Standard_
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
                      <sections>
          <clause id="_" inline-header="false" obligation="normative">
            <title id="_">Section</title>
          </clause>
        </sections>
        <bibliography>
          <references id="_" normative="false" obligation="informative">
            <title id="_">Bibliography</title>
                 <bibitem id="_" type="article" anchor="ref1">
                    <fetched/>
                    <title script="Latn" type="main">Taming the Metadata Beast: ILOX</title>
                    <uri type="DOI">https://doi.org/10.1045/november2010-massart</uri>
                    <uri type="src">http://www.dlib.org/dlib/november10/massart/11massart.html</uri>
                    <docidentifier type="DOI" primary="true">10.1045/november2010-massart</docidentifier>
                    <docidentifier type="issn.electronic" primary="false">1082-9873</docidentifier>
                    <date type="issued">
                       <on>2010-11</on>
                    </date>
                    <date type="published">
                       <on>2010-11</on>
                    </date>
                    <contributor>
                       <role type="author"/>
                       <person>
                          <name>
                             <forename language="en" script="Latn">David</forename>
                             <surname language="en" script="Latn">Massart</surname>
                          </name>
                       </person>
                    </contributor>
                    <contributor>
                       <role type="author"/>
                       <person>
                          <name>
                             <forename language="en" script="Latn">Elena</forename>
                             <surname language="en" script="Latn">Shulman</surname>
                          </name>
                       </person>
                    </contributor>
                    <contributor>
                       <role type="author"/>
                       <person>
                          <name>
                             <forename language="en" script="Latn">Nick</forename>
                             <surname language="en" script="Latn">Nicholas</surname>
                          </name>
                       </person>
                    </contributor>
                    <contributor>
                       <role type="author"/>
                       <person>
                          <name>
                             <forename language="en" script="Latn">Nigel</forename>
                             <surname language="en" script="Latn">Ward</surname>
                          </name>
                       </person>
                    </contributor>
                    <contributor>
                       <role type="author"/>
                       <person>
                          <name>
                             <forename language="en" script="Latn">Frédéric</forename>
                             <surname language="en" script="Latn">Bergeron</surname>
                          </name>
                       </person>
                    </contributor>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name>CNRI Acct</name>
                       </organization>
                    </contributor>
                    <language>en</language>
                    <script>Latn</script>
                    <series>
                       <title>D-Lib Magazine</title>
                    </series>
                    <extent>
                       <locality type="volume">
                          <referenceFrom>16</referenceFrom>
                       </locality>
                       <locality type="issue">
                          <referenceFrom>11/12</referenceFrom>
                       </locality>
                    </extent>
                 </bibitem>
              </references>
           </bibliography>
        </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

  # that class of docids has been rescinded?
  it "processes document identifiers ignoring Asciidoctor substitutions" do
    input = <<~INPUT
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,BIPM CIPM RES 1 (1879)]]] _Standard_
    INPUT
    output = <<~OUTPUT
         #{BLANK_HDR}
                         <sections>
                  </sections>
                           <bibliography>
           <references id="_" normative="true" obligation="informative">
             <title id="_">Normative references</title>
             <p id="_">The following documents are referred to in the text in such a way that some or all of their content constitutes requirements of this document. For dated references, only the edition cited applies. For undated references, the latest edition of the referenced document (including any amendments) applies.</p>
                 <bibitem id="_" type="proceedings" anchor="iso123">
                    <fetched/>
                    <title language="en" script="Latn">Signes abréviatifs pour les poids et mesures métriques</title>
                    <title language="fr" script="Latn">Signes abréviatifs pour les poids et mesures métriques</title>
                    <uri language="en" script="Latn" type="citation">https://www.bipm.org/en/committees/ci/cipm/4-1879/resolution-</uri>
                    <uri language="fr" script="Latn" type="citation">https://www.bipm.org/fr/committees/ci/cipm/4-1879/resolution-</uri>
                    <uri language="en" script="Latn" type="src">https://raw.githubusercontent.com/metanorma/bipm-data-outcomes/main/cipm/meetings-en/meeting-4.yml</uri>
                    <uri language="fr" script="Latn" type="src">https://raw.githubusercontent.com/metanorma/bipm-data-outcomes/main/cipm/meetings-fr/meeting-4.yml</uri>
                    <uri type="pdf">https://www.bipm.org/documents/20126/17315032/CIPM4.pdf/47e647d4-26c2-d3d6-b367-e749fb22b261</uri>
                    <docidentifier type="BIPM" primary="true">CIPM RES (1879)</docidentifier>
                    <docidentifier language="en" script="Latn" type="BIPM" primary="true">CIPM RES (1879, E)</docidentifier>
                    <docidentifier language="fr" script="Latn" type="BIPM" primary="true">CIPM RES (1879, F)</docidentifier>
                    <docidentifier language="en" script="Latn" type="BIPM-long">CIPM Resolution (1879)</docidentifier>
                    <docidentifier language="fr" script="Latn" type="BIPM-long">Résolution du CIPM (1879)</docidentifier>
                    <docidentifier type="BIPM-long">CIPM Resolution (1879) / Résolution du CIPM (1879)</docidentifier>
                    <docnumber>CIPM RES (1879)</docnumber>
                    <date type="published">
                       <on>1879-10-13</on>
                    </date>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name language="en" script="Latn">International Bureau of Weights and Measures</name>
                          <name language="fr" script="Latn">Bureau international des poids et mesures</name>
                          <abbreviation language="fr" script="Latn">BIPM</abbreviation>
                          <uri>www.bipm.org</uri>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="author"/>
                       <organization>
                          <name language="en" script="Latn">International Committee for Weights and Measures</name>
                          <name language="fr" script="Latn">Comité international des poids et mesures</name>
                          <abbreviation language="fr" script="Latn">CIPM</abbreviation>
                       </organization>
                    </contributor>
                    <language>en</language>
                    <language>fr</language>
                    <script>Latn</script>
                    <place>
                       <city>Paris</city>
                    </place>
                 </bibitem>
              </references>
           </bibliography>
        </metanorma>
    OUTPUT
    expect(strip_guid(Asciidoctor.convert(input, *OPTIONS)))
      .to be_xml_equivalent_to output
  end

  it "declines to fetch individual references" do
    input = <<~INPUT
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,nofetch(ISO/IEC TR 12382:1992)]]] _Standard_
      * [[[iso124,nofetch=true,ISO/IEC TR 12382:1992]]] _Standard_
      * [[[iso125,nofetch=false,code=ISO 124:2014]]] _Standard_
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>

      </sections><bibliography><references id="_" normative="true" obligation="informative" >
        <title id="_">Normative references</title>
      #{NORM_REF_BOILERPLATE}
                 <bibitem anchor="iso123" id="_">
                    <formattedref format="application/x-isodoc+xml">
                       <em>Standard</em>
                    </formattedref>
                    <docidentifier type="ISO">ISO/IEC TR 12382:1992</docidentifier>
                    <docnumber>12382</docnumber>
                    <date type="published">
                       <on>1992</on>
                    </date>
                    <language>en</language>
                    <script>Latn</script>
                 </bibitem>
                 <bibitem anchor="iso124" id="_">
                    <formattedref format="application/x-isodoc+xml">
                       <em>Standard</em>
                    </formattedref>
                    <docidentifier type="ISO">ISO/IEC TR 12382:1992</docidentifier>
                    <docnumber>12382</docnumber>
                    <date type="published">
                       <on>1992</on>
                    </date>
                    <language>en</language>
                    <script>Latn</script>
                 </bibitem>
                 <bibitem id="_" type="standard" anchor="iso125">
                    <fetched/>
                    <title language="en" script="Latn" type="title-intro" format="text/plain">Latex, rubber</title>
                    <title language="en" script="Latn" type="title-main" format="text/plain">Determination of total solids content</title>
                    <title language="en" script="Latn" type="main" format="text/plain">Latex, rubber\\u2009—\\u2009Determination of total solids content</title>
                    <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex de caoutchouc</title>
                    <title language="fr" script="Latn" type="title-main" format="text/plain">Détermination des matières solides totales</title>
                    <title language="fr" script="Latn" type="main" format="text/plain">Latex de caoutchouc\\u2009—\\u2009Détermination des matières solides totales</title>
                    <uri type="src">https://www.iso.org/standard/61884.html</uri>
                    <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:61884:en</uri>
                    <uri type="rss">https://www.iso.org/contents/data/standard/06/18/61884.detail.rss</uri>
                    <docidentifier type="ISO" primary="true">ISO 124:2014</docidentifier>
                    <docidentifier type="iso-reference">ISO 124:2014(E)</docidentifier>
                    <docidentifier type="URN">urn:iso:std:iso:124:stage-90.20</docidentifier>
                    <docnumber>124</docnumber>
                    <date type="published">
                       <on>2014-03</on>
                    </date>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <abbreviation>ISO</abbreviation>
                          <uri>www.iso.org</uri>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="author">
                          <description>committee</description>
                       </role>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <subdivision type="technical-committee" subtype="TC">
                             <name>Raw materials (including latex) for use in the rubber industry</name>
                             <identifier>ISO/TC 45/SC 3</identifier>
                          </subdivision>
                          <abbreviation>ISO</abbreviation>
                       </organization>
                    </contributor>
                    <edition>7</edition>
                    <language>en</language>
                    <language>fr</language>
                    <script>Latn</script>
                    <status>
                       <stage>90</stage>
                       <substage>20</substage>
                    </status>
                    <copyright>
                       <from>2014</from>
                       <owner>
                          <organization>
                             <name>ISO</name>
                          </organization>
                       </owner>
                    </copyright>
                    <relation type="obsoletes">
                       <bibitem type="standard">
                          <formattedref>ISO 124:2011</formattedref>
                          <docidentifier type="ISO" primary="true">ISO 124:2011</docidentifier>
                       </bibitem>
                    </relation>
                    <place>
                       <formattedPlace>Geneva</formattedPlace>
                    </place>
                 </bibitem>
              </references>
           </bibliography>
        </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.xpath("//xmlns:abstract").each(&:remove)
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
  end

  it "suppress identifier on bibitem" do
    input = <<~INPUT
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,dropid(ABC)]]] _Standard_
      * [[[iso124,dropid(ISO 124:2014)]]] _Standard_
      * [[[iso125,dropid=true,ABC]]] _Standard_
      * [[[iso126,dropid=true,ISO 124:2014]]] _Standard_
    INPUT
    doc = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(doc.at("//xmlns:bibitem[@anchor = 'iso123']/@suppress_identifier")&.text)
      .to eq("true")
    expect(doc.at("//xmlns:bibitem[@anchor = 'iso124']/@suppress_identifier")&.text)
      .to eq("true")
    expect(doc.at("//xmlns:bibitem[@anchor = 'iso125']/@suppress_identifier")&.text)
      .to eq("true")
    expect(doc.at("//xmlns:bibitem[@anchor = 'iso126']/@suppress_identifier")&.text)
      .to eq("true")
  end

  it "hides individual references" do
    input = <<~INPUT
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,hidden(ISO 124)]]] _Standard_
      * [[[iso124,ISO 125]]] _Standard_

      [bibliography]
      == Bibliography

      * [[[iso125,hidden(ISO 125)]]] _Standard_
      * [[[iso126,hidden=true,XYZ]]] _Standard_
      * [[[iso127,ISO 124]]] _Standard_
      * [[[iso128,hidden=false,ABC]]] _Standard_
    INPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    expect(xml.at("//xmlns:bibitem[@anchor = 'iso125']/@hidden")&.text)
      .to eq "true"
    expect(xml.at("//xmlns:bibitem[@anchor = 'iso126']/@hidden")&.text)
      .to eq "true"
    expect(xml.at("//xmlns:bibitem[@anchor = 'iso127']/@hidden")&.text)
      .not_to eq "true"
    expect(xml.at("//xmlns:bibitem[@anchor = 'iso128']/@hidden")&.text)
      .not_to eq "true"
  end

  it "processes BSI reference with year" do
    input = <<~INPUT
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso124,BSI BS EN ISO 19011:2018]]] _Standard_
      * [[[iso123,BSI BS EN 16341]]] _Standard_
      * [[[ref_2,BSI BS EN ISO 14044:2006+A2:2020]]], _Environmental management – Life cycle assessment – Requirements and guidelines_
    INPUT
    output = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
      .xpath("//xmlns:docidentifier[@type = 'BSI']").map(&:text)
    expect(output).to include("BS EN ISO 14044:2006+A2:2020")
    expect(output).to include("BS EN 16341:2012")
    expect(output).to include("BS EN 16341")
    expect(output).not_to include("BS EN ISO 19011")
    expect(output).to include("BS EN ISO 19011:2018")
  end

  it "processes RFC reference in Normative References" do
    input = <<~INPUT
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,IETF(RFC 8341)]]], _Standard_
      * [[[iso124,(1)IETF(RFC 8341)]]], _Standard_

      == Clause 4

      <<iso123>>
    INPUT
    output = <<~OUTPUT
       #{BLANK_HDR}
       <sections>
       <clause id="_" inline-header="false" obligation="normative">
         <title id="_">Clause 4</title>
         <p id="_">
         <eref type="inline" bibitemid="iso123" citeas="IETF\\u00a0RFC\\u00a08341"/>
       </p>
       </clause>
       </sections><bibliography><references id="_" obligation="informative" normative="true">
       <title id="_">Normative references</title>
             #{NORM_REF_BOILERPLATE}
                 <bibitem id="_" type="standard" anchor="iso123">
                    <fetched/>
                    <title type="main">Network Configuration Access Control Model</title>
                    <uri type="src">https://www.rfc-editor.org/info/rfc8341</uri>
                    <docidentifier type="IETF" primary="true">RFC 8341</docidentifier>
                    <docidentifier type="DOI">10.17487/RFC8341</docidentifier>
                    <docnumber>RFC8341</docnumber>
                    <date type="published">
                       <on>2018-03</on>
                    </date>
                    <contributor>
                       <role type="author"/>
                       <person>
                          <name>
                             <formatted-initials language="en" script="Latn">A.</formatted-initials>
                             <surname language="en" script="Latn">Bierman</surname>
                             <completename language="en" script="Latn">A. Bierman</completename>
                          </name>
                       </person>
                    </contributor>
                    <contributor>
                       <role type="author"/>
                       <person>
                          <name>
                             <formatted-initials language="en" script="Latn">M.</formatted-initials>
                             <surname language="en" script="Latn">Bjorklund</surname>
                             <completename language="en" script="Latn">M. Bjorklund</completename>
                          </name>
                       </person>
                    </contributor>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name language="en">RFC Publisher</name>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="authorizer"/>
                       <organization>
                          <name language="en">RFC Series</name>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="author">
                          <description>committee</description>
                       </role>
                       <organization>
                          <name language="en">Internet Engineering Task Force</name>
                          <subdivision type="workgroup">
                             <name>Network Configuration</name>
                             <identifier>netconf</identifier>
                          </subdivision>
                          <abbreviation language="en">IETF</abbreviation>
                       </organization>
                    </contributor>
                    <language>en</language>
                    <script>Latn</script>
                    <status>
                       <stage>INTERNET STANDARD</stage>
                    </status>
                    <series>
                       <title>STD</title>
                       <number>91</number>
                    </series>
                    <series>
                       <title>RFC</title>
                       <number>8341</number>
                    </series>
                    <series type="stream">
                       <title>IETF</title>
                    </series>
                    <keyword>
                       <vocab>NETCONF RESTCONF</vocab>
                    </keyword>
                    <keyword>
                       <vocab>YANG</vocab>
                    </keyword>
                    <keyword>
                       <vocab>XML</vocab>
                    </keyword>
                 </bibitem>
                 <bibitem id="_" type="standard" anchor="iso124">
                    <fetched/>
                    <title type="main">Network Configuration Access Control Model</title>
                    <uri type="src">https://www.rfc-editor.org/info/rfc8341</uri>
                    <docidentifier type="IETF" primary="true">RFC 8341</docidentifier>
                    <docidentifier type="metanorma">[1]</docidentifier>
                    <docidentifier type="DOI">10.17487/RFC8341</docidentifier>
                    <docnumber>RFC8341</docnumber>
                    <date type="published">
                       <on>2018-03</on>
                    </date>
                    <contributor>
                       <role type="author"/>
                       <person>
                          <name>
                             <formatted-initials language="en" script="Latn">A.</formatted-initials>
                             <surname language="en" script="Latn">Bierman</surname>
                             <completename language="en" script="Latn">A. Bierman</completename>
                          </name>
                       </person>
                    </contributor>
                    <contributor>
                       <role type="author"/>
                       <person>
                          <name>
                             <formatted-initials language="en" script="Latn">M.</formatted-initials>
                             <surname language="en" script="Latn">Bjorklund</surname>
                             <completename language="en" script="Latn">M. Bjorklund</completename>
                          </name>
                       </person>
                    </contributor>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name language="en">RFC Publisher</name>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="authorizer"/>
                       <organization>
                          <name language="en">RFC Series</name>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="author">
                          <description>committee</description>
                       </role>
                       <organization>
                          <name language="en">Internet Engineering Task Force</name>
                          <subdivision type="workgroup">
                             <name>Network Configuration</name>
                             <identifier>netconf</identifier>
                          </subdivision>
                          <abbreviation language="en">IETF</abbreviation>
                       </organization>
                    </contributor>
                    <language>en</language>
                    <script>Latn</script>
                    <status>
                       <stage>INTERNET STANDARD</stage>
                    </status>
                    <series>
                       <title>STD</title>
                       <number>91</number>
                    </series>
                    <series>
                       <title>RFC</title>
                       <number>8341</number>
                    </series>
                    <series type="stream">
                       <title>IETF</title>
                    </series>
                    <keyword>
                       <vocab>NETCONF RESTCONF</vocab>
                    </keyword>
                    <keyword>
                       <vocab>YANG</vocab>
                    </keyword>
                    <keyword>
                       <vocab>XML</vocab>
                    </keyword>
                 </bibitem>
              </references>
           </bibliography>
        </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.xpath("//xmlns:abstract").each(&:remove)
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
  end

  it "processes merged joint references" do
    input = <<~INPUT
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,merge(ISO 125, IETF(RFC 8341))]]], _Standard_
    INPUT
    output = <<~OUTPUT
             #{BLANK_HDR}
                    <sections>
             </sections><bibliography><references id="_" obligation="informative" normative="true">
               <title id="_">Normative references</title>
              #{NORM_REF_BOILERPLATE}
                 <bibitem id="_" type="standard" anchor="iso123">
                    <fetched/>
                    <title language="en" script="Latn" type="title-intro" format="text/plain">Natural rubber latex concentrate</title>
                    <title language="en" script="Latn" type="title-main" format="text/plain">Determination of alkalinity</title>
                    <title language="en" script="Latn" type="main" format="text/plain">Natural rubber latex concentrate\\u2009—\\u2009Determination of alkalinity</title>
                    <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex concentré de caoutchouc naturel</title>
                    <title language="fr" script="Latn" type="title-main" format="text/plain">Détermination de l’alcalinité</title>
                    <title language="fr" script="Latn" type="main" format="text/plain">Latex concentré de caoutchouc naturel\\u2009—\\u2009Détermination de l’alcalinité</title>
                    <uri type="src">https://www.iso.org/standard/72849.html</uri>
                    <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:72849:en</uri>
                    <uri type="rss">https://www.iso.org/contents/data/standard/07/28/72849.detail.rss</uri>
                    <uri type="src">https://www.rfc-editor.org/info/rfc8341</uri>
                    <docidentifier type="ISO" primary="true">ISO 125</docidentifier>
                    <docidentifier type="iso-reference">ISO 125(E)</docidentifier>
                    <docidentifier type="URN">urn:iso:std:iso:125:stage-60.60</docidentifier>
                    <docidentifier type="IETF" primary="true">RFC 8341</docidentifier>
                    <docidentifier type="DOI">10.17487/RFC8341</docidentifier>
                    <docnumber>125</docnumber>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <abbreviation>ISO</abbreviation>
                          <uri>www.iso.org</uri>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="author">
                          <description>committee</description>
                       </role>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <subdivision type="technical-committee" subtype="TC">
                             <name>Raw materials (including latex) for use in the rubber industry</name>
                             <identifier>ISO/TC 45/SC 3</identifier>
                          </subdivision>
                          <abbreviation>ISO</abbreviation>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name language="en">RFC Publisher</name>
                       </organization>
                    </contributor>
                    <edition>7</edition>
                    <language>en</language>
                    <language>fr</language>
                    <script>Latn</script>
                    <status>
                       <stage>60</stage>
                       <substage>60</substage>
                    </status>
                    <copyright>
                       <from>2020</from>
                       <owner>
                          <organization>
                             <name>ISO</name>
                          </organization>
                       </owner>
                    </copyright>
                    <relation type="obsoletes">
                       <bibitem type="standard">
                          <formattedref>ISO 125:2011</formattedref>
                          <docidentifier type="ISO" primary="true">ISO 125:2011</docidentifier>
                       </bibitem>
                    </relation>
                    <relation type="instanceOf">
                       <bibitem type="standard">
                          <title language="en" script="Latn" type="title-intro" format="text/plain">Natural rubber latex concentrate</title>
                          <title language="en" script="Latn" type="title-main" format="text/plain">Determination of alkalinity</title>
                          <title language="en" script="Latn" type="main" format="text/plain">Natural rubber latex concentrate\\u2009—\\u2009Determination of alkalinity</title>
                          <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex concentré de caoutchouc naturel</title>
                          <title language="fr" script="Latn" type="title-main" format="text/plain">Détermination de l’alcalinité</title>
                          <title language="fr" script="Latn" type="main" format="text/plain">Latex concentré de caoutchouc naturel\\u2009—\\u2009Détermination de l’alcalinité</title>
                          <uri type="src">https://www.iso.org/standard/72849.html</uri>
                          <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:72849:en</uri>
                          <uri type="rss">https://www.iso.org/contents/data/standard/07/28/72849.detail.rss</uri>
                          <docidentifier type="ISO" primary="true">ISO 125:2020</docidentifier>
                          <docidentifier type="iso-reference">ISO 125:2020(E)</docidentifier>
                          <docidentifier type="URN">urn:iso:std:iso:125:stage-60.60</docidentifier>
                          <docnumber>125</docnumber>
                          <date type="published">
                             <on>2020-02</on>
                          </date>
                          <contributor>
                             <role type="publisher"/>
                             <organization>
                                <name>International Organization for Standardization</name>
                                <abbreviation>ISO</abbreviation>
                                <uri>www.iso.org</uri>
                             </organization>
                          </contributor>
                          <contributor>
                             <role type="author">
                                <description>committee</description>
                             </role>
                             <organization>
                                <name>International Organization for Standardization</name>
                                <subdivision type="technical-committee" subtype="TC">
                                   <name>Raw materials (including latex) for use in the rubber industry</name>
                                   <identifier>ISO/TC 45/SC 3</identifier>
                                </subdivision>
                                <abbreviation>ISO</abbreviation>
                             </organization>
                          </contributor>
                          <edition>7</edition>
                          <language>en</language>
                          <language>fr</language>
                          <script>Latn</script>
                          <status>
                             <stage>60</stage>
                             <substage>60</substage>
                          </status>
                          <copyright>
                             <from>2020</from>
                             <owner>
                                <organization>
                                   <name>ISO</name>
                                </organization>
                             </owner>
                          </copyright>
                          <relation type="obsoletes">
                             <bibitem type="standard">
                                <formattedref>ISO 125:2011</formattedref>
                                <docidentifier type="ISO" primary="true">ISO 125:2011</docidentifier>
                             </bibitem>
                          </relation>
                          <place>
                             <formattedPlace>Geneva</formattedPlace>
                          </place>
                       </bibitem>
                    </relation>
                    <place>
                       <formattedPlace>Geneva</formattedPlace>
                    </place>
                 </bibitem>
              </references>
           </bibliography>
        </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.xpath("//xmlns:abstract").each(&:remove)
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
  end

  it "processes dual joint references" do
    input = <<~INPUT
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,dual(ISO 125, IETF(RFC 8341))]]], _Standard_
    INPUT
    output = <<~OUTPUT
            #{BLANK_HDR}
                   <sections>
            </sections><bibliography><references id="_" obligation="informative" normative="true">
              <title id="_">Normative references</title>
             #{NORM_REF_BOILERPLATE}
                 <bibitem id="_" type="standard" anchor="iso123">
                    <fetched/>
                    <title language="en" script="Latn" type="title-intro" format="text/plain">Natural rubber latex concentrate</title>
                    <title language="en" script="Latn" type="title-main" format="text/plain">Determination of alkalinity</title>
                    <title language="en" script="Latn" type="main" format="text/plain">Natural rubber latex concentrate\\u2009—\\u2009Determination of alkalinity</title>
                    <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex concentré de caoutchouc naturel</title>
                    <title language="fr" script="Latn" type="title-main" format="text/plain">Détermination de l’alcalinité</title>
                    <title language="fr" script="Latn" type="main" format="text/plain">Latex concentré de caoutchouc naturel\\u2009—\\u2009Détermination de l’alcalinité</title>
                    <uri type="src">https://www.iso.org/standard/72849.html</uri>
                    <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:72849:en</uri>
                    <uri type="rss">https://www.iso.org/contents/data/standard/07/28/72849.detail.rss</uri>
                    <docidentifier type="ISO" primary="true">ISO 125</docidentifier>
                    <docidentifier type="iso-reference">ISO 125(E)</docidentifier>
                    <docidentifier type="URN">urn:iso:std:iso:125:stage-60.60</docidentifier>
                    <docnumber>125</docnumber>
                    <contributor>
                       <role type="publisher"/>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <abbreviation>ISO</abbreviation>
                          <uri>www.iso.org</uri>
                       </organization>
                    </contributor>
                    <contributor>
                       <role type="author">
                          <description>committee</description>
                       </role>
                       <organization>
                          <name>International Organization for Standardization</name>
                          <subdivision type="technical-committee" subtype="TC">
                             <name>Raw materials (including latex) for use in the rubber industry</name>
                             <identifier>ISO/TC 45/SC 3</identifier>
                          </subdivision>
                          <abbreviation>ISO</abbreviation>
                       </organization>
                    </contributor>
                    <edition>7</edition>
                    <language>en</language>
                    <language>fr</language>
                    <script>Latn</script>
                    <status>
                       <stage>60</stage>
                       <substage>60</substage>
                    </status>
                    <copyright>
                       <from>2020</from>
                       <owner>
                          <organization>
                             <name>ISO</name>
                          </organization>
                       </owner>
                    </copyright>
                    <relation type="obsoletes">
                       <bibitem type="standard">
                          <formattedref>ISO 125:2011</formattedref>
                          <docidentifier type="ISO" primary="true">ISO 125:2011</docidentifier>
                       </bibitem>
                    </relation>
                    <relation type="instanceOf">
                       <bibitem type="standard">
                          <title language="en" script="Latn" type="title-intro" format="text/plain">Natural rubber latex concentrate</title>
                          <title language="en" script="Latn" type="title-main" format="text/plain">Determination of alkalinity</title>
                          <title language="en" script="Latn" type="main" format="text/plain">Natural rubber latex concentrate\\u2009—\\u2009Determination of alkalinity</title>
                          <title language="fr" script="Latn" type="title-intro" format="text/plain">Latex concentré de caoutchouc naturel</title>
                          <title language="fr" script="Latn" type="title-main" format="text/plain">Détermination de l’alcalinité</title>
                          <title language="fr" script="Latn" type="main" format="text/plain">Latex concentré de caoutchouc naturel\\u2009—\\u2009Détermination de l’alcalinité</title>
                          <uri type="src">https://www.iso.org/standard/72849.html</uri>
                          <uri type="obp">https://www.iso.org/obp/ui/en/#!iso:std:72849:en</uri>
                          <uri type="rss">https://www.iso.org/contents/data/standard/07/28/72849.detail.rss</uri>
                          <docidentifier type="ISO" primary="true">ISO 125:2020</docidentifier>
                          <docidentifier type="iso-reference">ISO 125:2020(E)</docidentifier>
                          <docidentifier type="URN">urn:iso:std:iso:125:stage-60.60</docidentifier>
                          <docnumber>125</docnumber>
                          <date type="published">
                             <on>2020-02</on>
                          </date>
                          <contributor>
                             <role type="publisher"/>
                             <organization>
                                <name>International Organization for Standardization</name>
                                <abbreviation>ISO</abbreviation>
                                <uri>www.iso.org</uri>
                             </organization>
                          </contributor>
                          <contributor>
                             <role type="author">
                                <description>committee</description>
                             </role>
                             <organization>
                                <name>International Organization for Standardization</name>
                                <subdivision type="technical-committee" subtype="TC">
                                   <name>Raw materials (including latex) for use in the rubber industry</name>
                                   <identifier>ISO/TC 45/SC 3</identifier>
                                </subdivision>
                                <abbreviation>ISO</abbreviation>
                             </organization>
                          </contributor>
                          <edition>7</edition>
                          <language>en</language>
                          <language>fr</language>
                          <script>Latn</script>
                          <status>
                             <stage>60</stage>
                             <substage>60</substage>
                          </status>
                          <copyright>
                             <from>2020</from>
                             <owner>
                                <organization>
                                   <name>ISO</name>
                                </organization>
                             </owner>
                          </copyright>
                          <relation type="obsoletes">
                             <bibitem type="standard">
                                <formattedref>ISO 125:2011</formattedref>
                                <docidentifier type="ISO" primary="true">ISO 125:2011</docidentifier>
                             </bibitem>
                          </relation>
                          <place>
                             <formattedPlace>Geneva</formattedPlace>
                          </place>
                       </bibitem>
                    </relation>
                    <relation type="hasReproduction">
                       <bibitem type="standard">
                          <fetched/>
                          <title type="main">Network Configuration Access Control Model</title>
                          <uri type="src">https://www.rfc-editor.org/info/rfc8341</uri>
                          <docidentifier type="IETF" primary="true">RFC 8341</docidentifier>
                          <docidentifier type="DOI">10.17487/RFC8341</docidentifier>
                          <docnumber>RFC8341</docnumber>
                          <date type="published">
                             <on>2018-03</on>
                          </date>
                          <contributor>
                             <role type="author"/>
                             <person>
                                <name>
                                   <formatted-initials language="en" script="Latn">A.</formatted-initials>
                                   <surname language="en" script="Latn">Bierman</surname>
                                   <completename language="en" script="Latn">A. Bierman</completename>
                                </name>
                             </person>
                          </contributor>
                          <contributor>
                             <role type="author"/>
                             <person>
                                <name>
                                   <formatted-initials language="en" script="Latn">M.</formatted-initials>
                                   <surname language="en" script="Latn">Bjorklund</surname>
                                   <completename language="en" script="Latn">M. Bjorklund</completename>
                                </name>
                             </person>
                          </contributor>
                          <contributor>
                             <role type="publisher"/>
                             <organization>
                                <name language="en">RFC Publisher</name>
                             </organization>
                          </contributor>
                          <contributor>
                             <role type="authorizer"/>
                             <organization>
                                <name language="en">RFC Series</name>
                             </organization>
                          </contributor>
                          <contributor>
                             <role type="author">
                                <description>committee</description>
                             </role>
                             <organization>
                                <name language="en">Internet Engineering Task Force</name>
                                <subdivision type="workgroup">
                                   <name>Network Configuration</name>
                                   <identifier>netconf</identifier>
                                </subdivision>
                                <abbreviation language="en">IETF</abbreviation>
                             </organization>
                          </contributor>
                          <language>en</language>
                          <script>Latn</script>
                          <status>
                             <stage>INTERNET STANDARD</stage>
                          </status>
                          <series>
                             <title>STD</title>
                             <number>91</number>
                          </series>
                          <series>
                             <title>RFC</title>
                             <number>8341</number>
                          </series>
                          <series type="stream">
                             <title>IETF</title>
                          </series>
                          <keyword>
                             <vocab>NETCONF RESTCONF</vocab>
                          </keyword>
                          <keyword>
                             <vocab>YANG</vocab>
                          </keyword>
                          <keyword>
                             <vocab>XML</vocab>
                          </keyword>
                       </bibitem>
                    </relation>
                    <place>
                       <formattedPlace>Geneva</formattedPlace>
                    </place>
                 </bibitem>
              </references>
           </bibliography>
        </metanorma>
    OUTPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    xml.xpath("//xmlns:abstract").each(&:remove)
    expect(strip_guid(xml.to_xml))
      .to be_xml_equivalent_to output
  end

  it "processes formatting within bibliographic references" do
    input = <<~INPUT
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[reference,ISO 123]]] _Standard_

      == Section

      <<reference,_reference_>>
      <<reference,_**reference**_>>
      <<reference,_A_ stem:[x^2]>>
      <<reference,_A_ footnote:[_B_]>>
      <<reference,clause=3.4.2, ISO 9000:2005 footnote:[Superseded by ISO 9000:2015.]>>

    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
      <clause id="_" inline-header="false" obligation="normative">
      <title id="_">Section</title>
      <p id="_"><eref type="inline" bibitemid="reference" citeas="ISO\\u00a0123"><display-text><em>reference</em></display-text></eref>
      <eref type="inline" bibitemid="reference" citeas="ISO\\u00a0123"><display-text><em><strong>reference</strong></em></display-text></eref>
      <eref type="inline" bibitemid="reference" citeas="ISO\\u00a0123"><display-text><em>A</em> <stem type="MathML" block="false"><math xmlns="http://www.w3.org/1998/Math/MathML">
      <mstyle displaystyle="false">
        <msup>
          <mi>x</mi>
          <mn>2</mn>
        </msup>
      </mstyle>
      </math><asciimath>x^2</asciimath></stem></display-text>
      </eref>
      <eref type="inline" bibitemid="reference" citeas="ISO\\u00a0123"><display-text><em>A</em><fn id="_" reference="1"><p id="_"><em>B</em></p></fn></display-text></eref>
      <eref type="inline" bibitemid="reference" citeas="ISO\\u00a0123"><localityStack><locality type="clause"><referenceFrom>3.4.2</referenceFrom></locality></localityStack><display-text>ISO 9000:2005<fn id="_" reference="2"><p id="_">Superseded by ISO 9000:2015.</p></fn></display-text></eref></p>
      </clause></sections>
      </metanorma>
    OUTPUT
    a = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    a.at("//xmlns:bibliography").remove
    expect(strip_guid(a.to_xml))
      .to be_xml_equivalent_to output
  end

  it "different cutoff dates: without publication date cutoff" do
    input = <<~"INPUT"
      #{ISOBIB_BLANK_HDR}

      [bibliography]
      == Normative References

      * [[[iso123,IEC 80000-6]]]
    INPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    ident = xml.at("//xmlns:bibitem[@anchor='iso123']/xmlns:relation[@type = 'instanceOf']/xmlns:bibitem/xmlns:docidentifier[@type='IEC']")
    expect(ident.text).to eq("IEC 80000-6:2022")
  end

  it "different cutoff dates: with publication date cutoff" do
    input = <<~"INPUT"
      #{ISOBIB_BLANK_HDR.sub(':nodoc:', ":nodoc:\n:published-date: 2019")}

      [bibliography]
      == Normative References

      * [[[iso123,IEC 80000-6]]]
    INPUT
    xml = Nokogiri::XML(Asciidoctor.convert(input, *OPTIONS))
    ident = xml.at("//xmlns:bibitem[@anchor='iso123']/xmlns:docidentifier[@type='IEC']")
    expect(ident.text).to eq("IEC 80000-6:2008")
  end
end
