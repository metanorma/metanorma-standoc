require "spec_helper"
require "relaton_iso"
require "relaton_ietf"

RSpec.describe Asciidoctor::Standoc do
    it "processes simple ISO reference" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp( <<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123]]] _Standard_
    INPUT
      #{BLANK_HDR}
      <sections>
      </sections><bibliography><references id="_" obligation="informative">
        <title>Normative References</title>
        #{NORM_REF_BOILERPLATE}
        <bibitem id="iso123" type="standard">
         <title format="text/plain">Standard</title>
         <docidentifier>ISO 123</docidentifier>
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
  end

  it "processes simple ISO reference with date range" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp( <<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:1066-1067]]] _Standard_
    INPUT
      #{BLANK_HDR}
      <sections>
      </sections><bibliography><references id="_" obligation="informative">
        <title>Normative References</title>
        #{NORM_REF_BOILERPLATE}
        <bibitem id="iso123" type="standard">
          <title format="text/plain">Standard</title>
  <docidentifier>ISO 123:1066-1067</docidentifier>
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
  end

  it "repairs simple fetched ISO reference" do
    mock_isobib_get_123_no_docid
    input = <<~"INPUT"
        #{ISOBIB_BLANK_HDR}
        [bibliography]
        == Normative References

        * [[[iso123,ISO 123]]] _Standard_
      INPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp( <<~"OUTPUT")
       #{BLANK_HDR}
       <sections>
       </sections><bibliography><references id="_" obligation="informative"><title>Normative References</title>
        #{NORM_REF_BOILERPLATE}
<bibitem type="standard" id="iso123">
  <uri type="src">https://www.iso.org/standard/23281.html</uri>
  <uri type="obp">https://www.iso.org/obp/ui/#!iso:std:23281:en</uri>
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
</bibitem> </references></bibliography>
</standard-document>
     OUTPUT
        expect { Asciidoctor.convert(input, backend: :standoc, header_footer: true) }.to output(/ERROR: No document identifier retrieved for ISO 123/).to_stderr
  end

  it "fetches simple ISO reference" do
    # mock_isobib_get_123
    VCR.use_cassette "isobib_get_123" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp( <<~"OUTPUT")
        #{ISOBIB_BLANK_HDR}
        [bibliography]
        == Normative References

        * [[[iso123,ISO 123]]] _Standard_
      INPUT
        #{BLANK_HDR}
       <sections>

       </sections><bibliography><references id="_" obligation="informative"><title>Normative References</title>
        #{NORM_REF_BOILERPLATE}
       <bibitem id="iso123" type="standard">
         <fetched>#{Date.today}</fetched>
         <title type="title-intro" format="text/plain" language="en" script="Latn">Rubber latex</title>
         <title type="title-main" format="text/plain" language="en" script="Latn">Sampling</title>
         <title type="main" format="text/plain" language="en" script="Latn">Rubber latex – Sampling</title>
         <title type="title-intro" format="text/plain" language="fr" script="Latn">Latex de caoutchouc</title>
         <title type="title-main" format="text/plain" language="fr" script="Latn">Échantillonnage</title>
         <title type="main" format="text/plain" language="fr" script="Latn">Latex de caoutchouc – Échantillonnage</title>
         <uri type="src">https://www.iso.org/standard/23281.html</uri>
         <uri type="obp">https://www.iso.org/obp/ui/#!iso:std:23281:en</uri>
         <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
         <docidentifier type="ISO">ISO 123:2001</docidentifier>
         <docnumber>123</docnumber>
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
             <formattedref format="text/plain">ISO 123:1985</formattedref>
           </bibitem>
         </relation>
         </bibitem> </references></bibliography>
       </standard-document>
       OUTPUT
=begin
         <relation type="instance">
           <bibitem type="standard">
             <fetched>#{Date.today}</fetched>
             <title type="title-main" format="text/plain" language="en" script="Latn">Rubber latex – Sampling</title>
             <title type="main" format="text/plain" language="en" script="Latn">Rubber latex – Sampling</title>
             <title type="title-main" format="text/plain" language="fr" script="Latn">Latex de caoutchouc – Échantillonnage</title>
             <title type="main" format="text/plain" language="fr" script="Latn">Latex de caoutchouc – Échantillonnage</title>
             <uri type="src">https://www.iso.org/standard/23281.html</uri>
             <uri type="obp">https://www.iso.org/obp/ui/#!iso:std:23281:en</uri>
             <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
             <docidentifier type="ISO">ISO 123:2001</docidentifier>
             <docnumber>123</docnumber>
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
                 <formattedref format="text/plain">ISO 123:1985</formattedref>
               </bibitem>
             </relation>
           </bibitem>
         </relation>
       </bibitem> </references></bibliography>
       </standard-document>
      OUTPUT
=end
    end
  end

  it "processes simple IEC reference" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp( <<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,IEC 123]]] _Standard_
    INPUT
       #{BLANK_HDR}
              <sections>
       </sections><bibliography><references id="_" obligation="informative">
         <title>Normative References</title>
        #{NORM_REF_BOILERPLATE}
         <bibitem id="iso123" type="standard">
         <title format="text/plain">Standard</title>
         <docidentifier>IEC 123</docidentifier>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>IEC</name>
           </organization>
         </contributor>
       </bibitem>
       </references>
       </bibliography>
       </standard-document>
    OUTPUT
  end

  it "processes dated ISO reference and joint ISO/IEC references" do
    # mock_isobib_get_iec12382
    # mock_isobib_get_124
    VCR.use_cassette "dated_iso_ref_joint_iso_iec" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp( <<~"OUTPUT")
        #{ISOBIB_BLANK_HDR}
        [bibliography]
        == Normative References

        * [[[iso123,ISO/IEC TR 12382:1992]]] _Standard_
        * [[[iso124,ISO 124:2014]]] _Standard_
      INPUT
        #{BLANK_HDR}
        <sections>

        </sections><bibliography><references id="_" obligation="informative">
          <title>Normative References</title>
        #{NORM_REF_BOILERPLATE}
          <bibitem type="standard" id="iso123">
          <fetched>#{Date.today}</fetched>
          <title type="title-main" format="text/plain" language="en" script="Latn">Permuted index of the vocabulary of information technology</title>
          <title type="main" format="text/plain" language="en" script="Latn">Permuted index of the vocabulary of information technology</title>
          <title type="title-main" format="text/plain" language="fr" script="Latn">Index permuté du vocabulaire des technologies de l’information</title>
          <title type="main" format="text/plain" language="fr" script="Latn">Index permuté du vocabulaire des technologies de l’information</title>
          <uri type="src">https://www.iso.org/standard/21071.html</uri>
          <uri type="obp">https://www.iso.org/obp/ui/#!iso:std:21071:en</uri>
          <uri type="rss">https://www.iso.org/contents/data/standard/02/10/21071.detail.rss</uri>
          <docidentifier type="ISO">ISO/IEC TR 12382:1992</docidentifier>
          <docnumber>12382</docnumber>
          <date type="published">
            <on>1992</on>
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
          <edition>2</edition>
          <language>en</language>
          <language>fr</language>
          <script>Latn</script>
          <abstract format="text/plain" language="en" script="Latn">Contains a permuted index of all terms included in the parts 1 – 28 of ISO 2382. If any of these parts has been revised, the present TR refers to the revision.</abstract>
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
        </bibitem>
          <bibitem type="standard" id="iso124">
          <fetched>#{Date.today}</fetched>
          <title type="title-intro" format="text/plain" language="en" script="Latn">Latex, rubber</title>
          <title type="title-main" format="text/plain" language="en" script="Latn">Determination of total solids content</title>
          <title type="main" format="text/plain" language="en" script="Latn">Latex, rubber – Determination of total solids content</title>
          <title type="title-intro" format="text/plain" language="fr" script="Latn">Latex de caoutchouc</title>
<title type="title-main" format="text/plain" language="fr" script="Latn">Détermination des matières solides totales</title>
          <title type="main" format="text/plain" language="fr" script="Latn">Latex de caoutchouc – Détermination des matières solides totales</title>
          <uri type="src">https://www.iso.org/standard/61884.html</uri>
          <uri type="obp">https://www.iso.org/obp/ui/#!iso:std:61884:en</uri>
          <uri type="rss">https://www.iso.org/contents/data/standard/06/18/61884.detail.rss</uri>
          <docidentifier type="ISO">ISO 124:2014</docidentifier>
          <docnumber>124</docnumber>
          <date type="published">
            <on>2014</on>
          </date>
          <contributor>
            <role type="publisher"/>
            <organization>
              <name>International Organization for Standardization</name>
              <abbreviation>ISO</abbreviation>
              <uri>www.iso.org</uri>
            </organization>
          </contributor>
          <edition>7</edition>
          <language>en</language>
          <language>fr</language>
          <script>Latn</script>
          <abstract format="text/plain" language="en" script="Latn">ISO 124:2014 specifies methods for the determination of the total solids content of natural rubber field and concentrated latices and synthetic rubber latex. These methods are not necessarily suitable for latex from natural sources other than the Hevea brasiliensis, for vulcanized latex, for compounded latex, or for artificial dispersions of rubber.</abstract>
          <abstract format="text/plain" language="fr" script="Latn">L’ISO 124:2014 spécifie des méthodes pour la détermination des matières solides totales dans le latex de plantation, le latex de concentré de caoutchouc naturel et le latex de caoutchouc synthétique. Ces méthodes ne conviennent pas nécessairement au latex d’origine naturelle autre que celui de l’Hevea brasiliensis, au latex vulcanisé, aux mélanges de latex, ou aux dispersions artificielles de caoutchouc.</abstract>
          <status>
            <stage>90</stage>
            <substage>93</substage>
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
              <formattedref format="text/plain">ISO 124:2011</formattedref>
            </bibitem>
          </relation>
        </bibitem>
        </references></bibliography>
        </standard-document>

      OUTPUT
    end
  end

    it "declines to fetch individual references" do
    VCR.use_cassette "dated_iso_ref_joint_iso_iec" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp( <<~"OUTPUT")
        #{ISOBIB_BLANK_HDR}
        [bibliography]
        == Normative References

        * [[[iso123,nofetch(ISO/IEC TR 12382:1992)]]] _Standard_
        * [[[iso124,ISO 124:2014]]] _Standard_
      INPUT
        #{BLANK_HDR}
        <sections>

        </sections><bibliography><references id="_" obligation="informative">
          <title>Normative References</title>
        #{NORM_REF_BOILERPLATE}
        <bibitem id='iso123'>
               <formattedref format='application/x-isodoc+xml'>
                 <em>Standard</em>
               </formattedref>
               <docidentifier>ISO/IEC TR 12382:1992</docidentifier>
             </bibitem>
             <bibitem id='iso124' type='standard'>
               <fetched>#{Date.today}</fetched>
               <title type='title-intro' format='text/plain' language='en' script='Latn'>Latex, rubber</title>
               <title type='title-main' format='text/plain' language='en' script='Latn'>Determination of total solids content</title>
               <title type='main' format='text/plain' language='en' script='Latn'>Latex, rubber – Determination of total solids content</title>
               <title type='title-intro' format='text/plain' language='fr' script='Latn'>Latex de caoutchouc</title>
               <title type='title-main' format='text/plain' language='fr' script='Latn'>Détermination des matières solides totales</title>
               <title type='main' format='text/plain' language='fr' script='Latn'>Latex de caoutchouc – Détermination des matières solides totales</title>
               <uri type='src'>https://www.iso.org/standard/61884.html</uri>
               <uri type='obp'>https://www.iso.org/obp/ui/#!iso:std:61884:en</uri>
               <uri type='rss'>https://www.iso.org/contents/data/standard/06/18/61884.detail.rss</uri>
               <docidentifier type='ISO'>ISO 124:2014</docidentifier>
               <docnumber>124</docnumber>
               <date type='published'>
                 <on>2014</on>
               </date>
               <contributor>
                 <role type='publisher'/>
                 <organization>
                   <name>International Organization for Standardization</name>
                   <abbreviation>ISO</abbreviation>
                   <uri>www.iso.org</uri>
                 </organization>
               </contributor>
               <edition>7</edition>
               <language>en</language>
               <language>fr</language>
               <script>Latn</script>
               <abstract format='text/plain' language='en' script='Latn'>ISO 124:2014 specifies methods for the determination of the total solids content of natural rubber field and concentrated latices and synthetic rubber latex. These methods are not necessarily suitable for latex from natural sources other than the Hevea brasiliensis, for vulcanized latex, for compounded latex, or for artificial dispersions of rubber.</abstract>
               <abstract format='text/plain' language='fr' script='Latn'>L’ISO 124:2014 spécifie des méthodes pour la détermination des matières solides totales dans le latex de plantation, le latex de concentré de caoutchouc naturel et le latex de caoutchouc synthétique.  Ces méthodes ne conviennent pas nécessairement au latex d’origine naturelle autre que celui de l’Hevea brasiliensis, au latex vulcanisé, aux mélanges de latex, ou aux dispersions artificielles de caoutchouc.</abstract>
               <status>
                 <stage>90</stage>
                 <substage>93</substage>
               </status>
               <copyright>
                 <from>2014</from>
                 <owner>
                   <organization>
                     <name>ISO</name>
                   </organization>
                 </owner>
               </copyright>
               <relation type='obsoletes'>
                 <bibitem type='standard'>
                   <formattedref format='text/plain'>ISO 124:2011</formattedref>
                 </bibitem>
               </relation>
             </bibitem>
        </references></bibliography></standard-document>
OUTPUT
    end
    end

  it "processes draft ISO reference" do
    #stub_fetch_ref no_year: true, note: "The standard is in press"

    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp( <<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:--]]] _Standard_
      * [[[iso124,ISO 124:—]]]{blank}footnote:[The standard is in press] _Standard_
      * [[[iso125,ISO 125:&ndash;]]], footnote:[The standard is in press] _Standard_
    INPUT
       #{BLANK_HDR}
       <sections>
              </sections><bibliography><references id="_" obligation="informative">
         <title>Normative References</title>
        #{NORM_REF_BOILERPLATE}
         <bibitem id="iso123" type="standard">
         <title format="text/plain">Standard</title>
         <docidentifier>ISO 123:–</docidentifier>
         <date type="published">
           <on>--</on>
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
         <docidentifier>ISO 124:–</docidentifier>
         <date type="published">
           <on>--</on>
         </date>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>ISO</name>
           </organization>
         </contributor>
         <note format="text/plain">ISO DATE: The standard is in press</note>
       </bibitem>
         <bibitem id="iso125" type="standard">
         <title format="text/plain">Standard</title>
         <docidentifier>ISO 125:–</docidentifier>
         <date type="published">
           <on>--</on>
         </date>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>ISO</name>
           </organization>
         </contributor>
         <note format="text/plain">ISO DATE: The standard is in press</note>
       </bibitem>
       </references>
       </bibliography>
       </standard-document>
    OUTPUT
  end

  it "processes all-parts ISO reference" do
    #stub_fetch_ref(all_parts: true)

    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp( <<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:1066 (all parts)]]] _Standard_
    INPUT
      #{BLANK_HDR}
      <sections>
      </sections><bibliography><references id="_" obligation="informative">
        <title>Normative References</title>
        #{NORM_REF_BOILERPLATE}
        <bibitem id="iso123" type="standard">
         <title format="text/plain">Standard</title>
         <docidentifier>ISO 123:1066 (all parts)</docidentifier>
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
      </references>
      </bibliography>
      </standard-document>
    OUTPUT
  end

  it "processes RFC reference in Normative References" do
    # mock_rfcbib_get_rfc8341
    VCR.use_cassette "rfcbib_get_rfc8341" do
      expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp( <<~"OUTPUT")
        #{ISOBIB_BLANK_HDR}
        [bibliography]
        == Normative References

        * [[[iso123,IETF(RFC 8341)]]], _Standard_

        == Clause 4

        <<iso123>>
      INPUT
  #{BLANK_HDR}
  <sections>
  <clause id="_" inline-header="false" obligation="normative">
    <title>Clause 4</title>
    <p id="_">
    <eref type="inline" bibitemid="iso123" citeas="RFC 8341"/>
  </p>
  </clause>
  </sections><bibliography><references id="_" obligation="informative">
  <title>Normative References</title>
        #{NORM_REF_BOILERPLATE}
  <bibitem id="iso123" type="standard">
    <fetched>#{Date.today}</fetched>
    <title format="text/plain" language="en" script="Latn">Network Configuration Access Control Model</title>
    <uri type='xml'>https://xml2rfc.tools.ietf.org/public/rfc/bibxml/reference.RFC.8341.xml</uri>
    <uri type="src">https://www.rfc-editor.org/info/rfc8341</uri>
    <docidentifier type="IETF">RFC 8341</docidentifier>
    <docidentifier type="DOI">10.17487/RFC8341</docidentifier>
    <date type="published">
      <on>2018-03</on>
    </date>
    <contributor>
      <role type="author"/>
      <person>
        <name>
          <completename language="en">A. Bierman</completename>
        </name>
        <affiliation>
          <organization>
            <name>IETF</name>
            <abbreviation>IETF</abbreviation>
          </organization>
        </affiliation>
      </person>
    </contributor>
    <contributor>
      <role type="author"/>
      <person>
        <name>
          <completename language="en">M. Bjorklund</completename>
        </name>
        <affiliation>
          <organization>
            <name>IETF</name>
            <abbreviation>IETF</abbreviation>
          </organization>
        </affiliation>
      </person>
    </contributor>
    <language>en</language>
    <script>Latn</script>
    <abstract format="text/plain" language="en" script="Latn">The standardization of network configuration interfaces for use with the Network Configuration Protocol (NETCONF) or the RESTCONF protocol requires a structured and secure operating environment that promotes human usability and multi-vendor interoperability.  There is a need for standard mechanisms to restrict NETCONF or RESTCONF protocol access for particular users to a preconfigured subset of all available NETCONF or RESTCONF protocol operations and content.  This document defines such an access control model.This document obsoletes RFC 6536.</abstract>
    <series type="main">
      <title format="text/plain" language="en" script="Latn">STD</title>
      <number>91</number>
    </series>
    <series type="main">
      <title format="text/plain" language="en" script="Latn">RFC</title>
      <number>8341</number>
    </series>
  </bibitem>
        </references>
        </bibliography>
        </standard-document>
      OUTPUT
    end
  end

  it "processes non-ISO reference in Normative References" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp( <<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,XYZ 123:1066 (all parts)]]] _Standard_
    INPUT
       #{BLANK_HDR}
              <sections>

       </sections><bibliography><references id="_" obligation="informative">
         <title>Normative References</title>
        #{NORM_REF_BOILERPLATE}
         <bibitem id="iso123">
         <formattedref format="application/x-isodoc+xml">
           <em>Standard</em>
         </formattedref>
         <docidentifier>XYZ 123:1066 (all parts)</docidentifier>
       </bibitem>
       </references>
       </bibliography>
       </standard-document>
    OUTPUT
  end

  it "processes non-ISO reference in Bibliography" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp( <<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Bibliography

      * [[[iso123,2]]] _Standard_
      * [[[iso124,(B)]]] _Standard_
      * [[[iso125,1]]] _Standard_
      * [[[iso126,(A)]]] _Standard_
    INPUT
       #{BLANK_HDR}
              <sections>

       </sections>
       <bibliography><references id="_" obligation="informative">
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
         <docidentifier type="metanorma">[A]</docidentifier>
       </bibitem>
       </references>
       </bibliography>
       </standard-document>
    OUTPUT
  end

  it "process ISO reference without an Internet connection" do
    expect(RelatonIso::IsoBibliography).to receive(:search).with("ISO 123") do
      raise RelatonBib::RequestError.new "getaddrinfo"
    end.at_least :once
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)))).to be_equivalent_to xmlpp( <<~"OUTPUT")
      #{ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123]]] _Standard_
    INPUT
      <?xml version="1.0" encoding="UTF-8"?>
      <standard-document xmlns="http://riboseinc.com/isoxml">
      <bibdata type="standard">
      <title language="en" format="text/plain">Document title</title>
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
      <sections>

      </sections><bibliography><references id="_" obligation="informative">
        <title>Normative References</title>
        #{NORM_REF_BOILERPLATE}
        <bibitem id="iso123" type="standard">
        <title format="text/plain">Standard</title>
        <docidentifier type="ISO">ISO 123</docidentifier>
        <contributor>
          <role type="publisher"/>
          <organization>
            <name>ISO</name>
          </organization>
        </contributor>
      </bibitem>
      </references></bibliography>
      </standard-document>
    OUTPUT
  end

  private

      private

    def mock_isobib_get_123
      expect(RelatonIso::IsoBibliography).to receive(:get).with("ISO 123", nil, {}) do
        IsoBibItem::XMLParser.from_xml(<<~"OUTPUT")
        <bibitem type=\"standard\" id=\"ISO123\">\n  <title format=\"text/plain\" language=\"en\" script=\"Latn\">Rubber latex -- Sampling</title>\n  <title format=\"text/plain\" language=\"fr\" script=\"Latn\">Latex de caoutchouc -- ?chantillonnage</title>\n  <uri type=\"src\">https://www.iso.org/standard/23281.html</uri>\n  <uri type=\"obp\">https://www.iso.org/obp/ui/#!iso:std:23281:en</uri>\n  <uri type=\"rss\">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>\n  <docidentifier>ISO 123</docidentifier>\n  <date type=\"published\">\n    <on>2001</on>\n  </date>\n  <contributor>\n    <role type=\"publisher\"/>\n    <organization>\n      <name>International Organization for Standardization</name>\n      <abbreviation>ISO</abbreviation>\n      <uri>www.iso.org</uri>\n    </organization>\n  </contributor>\n  <edition>3</edition>\n  <language>en</language>\n  <language>fr</language>\n  <script>Latn</script>\n  <status>Published</status>\n  <copyright>\n    <from>2001</from>\n    <owner>\n      <organization>\n        <name>ISO</name>\n        <abbreviation></abbreviation>\n      </organization>\n    </owner>\n  </copyright>\n  <relation type=\"obsoletes\">\n    <bibitem type="standard">\n      <formattedref format="text/plain">ISO 123:1985</formattedref>\n      </bibitem>\n  </relation>\n  <relation type=\"updates\">\n    <bibitem type="standard">\n      <formattedref format="text/plain">ISO 123:2001</formattedref>\n      </bibitem>\n  </relation>\n</bibitem>
        OUTPUT
      end
    end

    def mock_isobib_get_123_no_docid
      expect(RelatonIso::IsoBibliography).to receive(:get).with("ISO 123", nil, {:title=>"<em>Standard</em>"}) do
        RelatonBib::XMLParser.from_xml(<<~"OUTPUT")
        <bibitem type=\"standard\" id=\"ISO123\">\n  <uri type=\"src\">https://www.iso.org/standard/23281.html</uri>\n  <uri type=\"obp\">https://www.iso.org/obp/ui/#!iso:std:23281:en</uri>\n  <uri type=\"rss\">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>\n  <date type=\"published\">\n    <on>2001</on>\n  </date>\n  <contributor>\n    <role type=\"publisher\"/>\n    <organization>\n      <name>International Organization for Standardization</name>\n      <abbreviation>ISO</abbreviation>\n      <uri>www.iso.org</uri>\n    </organization>\n  </contributor>\n  <edition>3</edition>\n  <language>en</language>\n  <language>fr</language>\n  <script>Latn</script>\n  <status><stage>Published</stage></status>\n  <copyright>\n    <from>2001</from>\n    <owner>\n      <organization>\n        <name>ISO</name>\n        <abbreviation></abbreviation>\n      </organization>\n    </owner>\n  </copyright>\n  <relation type=\"obsoletes\">\n    <bibitem type="standard">\n      <formattedref format="text/plain">ISO 123:1985</formattedref>\n      </bibitem>\n  </relation>\n  <relation type=\"updates\">\n    <bibitem type="standard">\n      <formattedref format="text/plain">ISO 123:2001</formattedref>\n      </bibitem>\n  </relation>\n</bibitem>
        OUTPUT
      end.exactly(2).times
    end

    def mock_isobib_get_124
      expect(RelatonIso::IsoBibliography).to receive(:get).with("ISO 124", "2014", {}) do
        IsoBibItem::XMLParser.from_xml(<<~"OUTPUT")
                 <bibitem type="standard" id="iso124">
         <title format="text/plain" language="en" script="Latn">Latex, rubber -- Determination of total solids content</title>
         <title format="text/plain" language="fr" script="Latn">Latex de caoutchouc -- Détermination des matières solides totales</title>
         <uri type="src">https://www.iso.org/standard/61884.html</uri>
         <uri type="obp">https://www.iso.org/obp/ui/#!iso:std:61884:en</uri>
         <uri type="rss">https://www.iso.org/contents/data/standard/06/18/61884.detail.rss</uri>
         <docidentifier>ISO 124</docidentifier>
         <date type="published">
           <on>2014</on>
         </date>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>International Organization for Standardization</name>
             <abbreviation>ISO</abbreviation>
             <uri>www.iso.org</uri>
           </organization>
         </contributor>
         <edition>7</edition>
         <language>en</language>
         <language>fr</language>
         <script>Latn</script>
         <abstract format="text/plain" language="en" script="Latn">ISO 124:2014 specifies methods for the determination of the total solids content of natural rubber field and concentrated latices and synthetic rubber latex. These methods are not necessarily suitable for latex from natural sources other than the Hevea brasiliensis, for vulcanized latex, for compounded latex, or for artificial dispersions of rubber.</abstract>
         <status>Published</status>
         <copyright>
           <from>2014</from>
           <owner>
             <organization>
               <name>ISO</name>
               <abbreviation/>
             </organization>
           </owner>
         </copyright>
         <relation type="obsoletes">
           <bibitem type="standard">
             <formattedref format="text/plain">ISO 124:2011</formattedref>
           </bibitem>
         </relation>
        <ics>
          <code>83.040.10</code>
          <text>Latex and raw rubber</text>
        </ics>
      </bibitem>
        OUTPUT
      end
    end

    def mock_isobib_get_iec12382
      expect(RelatonIso::IsoBibliography).to receive(:get).with("ISO/IEC TR 12382", "1992", {}) do
      IsoBibItem::XMLParser.from_xml(<<~"OUTPUT")
      <bibitem type="standard" id="iso123">
         <title format="text/plain" language="en" script="Latn">Permuted index of the vocabulary of information technology</title>
         <title format="text/plain" language="fr" script="Latn">Index permuté du vocabulaire des technologies de l'information</title>
         <uri type="src">https://www.iso.org/standard/21071.html</uri>
         <uri type="obp">https://www.iso.org/obp/ui/#!iso:std:21071:en</uri>
         <uri type="rss">https://www.iso.org/contents/data/standard/02/10/21071.detail.rss</uri>
         <docidentifier>ISO/IEC 12382</docidentifier>
         <date type="published">
           <on>1992</on>
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
         <edition>2</edition>
         <language>en</language>
         <language>fr</language>
         <script>Latn</script>
         <abstract format="text/plain" language="en" script="Latn">Contains a permuted index of all terms included in the parts 1 – 28 of ISO 2382. If any of these parts has been revised, the present TR refers to the revision.</abstract>
         <status>Published</status>
         <copyright>
           <from>1992</from>
           <owner>
             <organization>
               <name>ISO/IEC</name>
               <abbreviation/>
             </organization>
           </owner>
         </copyright>
         <relation type="updates">
           <bibitem type="standard">
             <formattedref format="text/plain">ISO/IEC TR 12382:1992</formattedref>
           </bibitem>
         </relation>
        <ics>
          <code>35.020</code>
          <text>Information technology (IT) in general</text>
        </ics>
        <ics>
          <code>01.040.35</code>
          <text>Information technology (Vocabularies)</text>
        </ics>
       </bibitem>
OUTPUT
    end
end

    def mock_rfcbib_get_rfc8341
      expect(IETFBib::RfcBibliography).to receive(:get).with("RFC 8341", nil, {}) do
        IsoBibItem::XMLParser.from_xml(<<~"OUTPUT")
      <bibitem id="RFC8341">
  <title format="text/plain" language="en" script="Latn">Network Configuration Access Control Model</title>
  <docidentifier type="DOI">10.17487/RFC8341</docidentifier>
  <docidentifier type="IETF">RFC 8341</docidentifier>
  <date type="published">
    <on>2018</on>
  </date>
  <status>published</status>
</bibitem>
        OUTPUT
      end
    end

end
