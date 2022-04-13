require "spec_helper"
require "relaton_iso"

RSpec.describe Metanorma::Standoc do
    it "processes simple dl reference" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      [%bibitem]
      === Standard
      id:: iso123
      docid::
        type::: ISO
        id::: ISO 123
      type:: standard
      contributor::
        role::: publisher
        organization:::
          name:::: ISO
      contributor::
        role::: author
        person:::
          name::::
      +
      --
      completename::
        language::: en
        content::: Fred
      --
      contributor::
        role::: author
        person:::
        name::::
          completename::::: Jack

    INPUT
      #{BLANK_HDR}
      <sections>
      </sections><bibliography><references id="_" obligation="informative" normative="true">
        <title>Normative references</title>
        #{NORM_REF_BOILERPLATE}
        <bibitem id="iso123" type="standard">
        <fetched/>
        <title type='title-main' format='text/plain'>Standard</title>
        <title type='main' format='text/plain'>Standard</title>
         <docidentifier type="ISO">ISO 123</docidentifier>
         <contributor>
           <role type="publisher"/>
           <organization>
             <name>ISO</name>
           </organization>
         </contributor>
         <contributor>
           <role type="author"/>
           <person>
             <name><completename language="en">Fred</completename></name>
           </person>
         </contributor>
         <contributor>
           <role type="author"/>
           <person>
             <name><completename>Jack</completename></name>
           </person>
         </contributor>
       </bibitem>
      </references>
      </bibliography>
      </standard-document>
    OUTPUT
  end

  it "processes complex dl reference" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      == Clause

      <<ISOTC211>>

      [bibliography]
      == Normative References

      [[ISOTC211]]
      [%bibitem]
      === Other Title
      fetched:: 2019-06-30
      title::
        type::: main
        content::: Geographic information
      title::
        type::: subtitle
        content::: Geographic information subtitle
        language::: en
        script::: Latn
        format::: text/plain
      type:: standard
      docid::
        type::: ISO
        id::: TC211
      docnumber:: 211
      edition:: 1
      language::
        . en
        . fr
      script:: Latn
      version::
        revision_date::: 2019-04-01
        draft::: draft
      biblionote::
        type::: bibnote
        content:::
      +
      --
      Mark set a major league
      home run record in 1998.
      --
      docstatus::
        stage::: stage
        substage::: substage
        iteration::: iteration
      date::
        type::: issued
        value::: 2014
      date::
        type::: published
        from::: 2014-04
        to::: 2014-05
      date::
        type::: accessed
        value::: 2015-05-20
      abstract::
        content:::
      +
      --
      ISO 19115-1:2014 defines the schema required for ...
      --
      abstract::
        content::: L'ISO 19115-1:2014 définit le schéma requis pour ...
        language::: fr
        script::: Latn
        format::: text/plain
      copyright::
         owner:::
           name:::: International Organization for Standardization
           abbreviation:::: ISO
           url:::: www.iso.org
         from::: 2014
         to::: #{Time.now.year}
      link::
        type::: src
        content::: https://www.iso.org/standard/53798.html
      link::
        type::: obp
        content::: https://www.iso.org/obp/ui/#!iso:std:53798:en
      link::
        type::: rss
        content::: https://www.iso.org/contents/data/standard/05/37/53798.detail.rss
      medium::
        form::: medium form
        size::: medium size
        scale::: medium scale
      place:: bib place
      extent::
        locality:::
          type:::: section
          reference_from:::: 7
      accesslocation::
        . accesslocation1
        . accesslocation2
      classification::
        type::: type
        value::: value
      validity::
        begins::: 2010-10-10 12:21
        ends::: 2011-02-03 18:30


      ==== Contributor
      organization::
        name::: International Organization for Standardization
        url::: www.iso.org
        abbreviation::: ISO
        subdivision::: division
      role::
        type::: publisher
        description::: Publisher role

      ==== Contributor
      person::
        name:::
          completename::::
      +
      --
      content:: A. Bierman
      language:: en
      --
        affiliation:::
          organization::::
      +
      --
      name:: IETF
      abbreviation:: IETF
      identifier::
      type::: uri
      id::: www.ietf.org
      --
          description:::: Affiliation description
        contact:::
          street::::
            . 8 Street St
          city:::: City
          postcode:::: 123456
          country:::: Country
          state:::: State
        contact:::
          type:::: phone
          value:::: 223322
      role:: author

      ==== Contributor
      organization::
        name::: IETF
        abbreviation::: IETF
        identifier:::
          type:::: uri
          id:::: www.ietf.org
      role:: publisher

      ==== Contributor
      person::
        name:::
          language:::: en
          initial:::: A.
          surname:::: Bierman
        affiliation:::
      +
      --
      organization::
        name::: IETF
        abbreviation::: IETF
      description::
        content::: Affiliation description
        language::: en
        script::: Latn
      --
        identifier:::
          type:::: uri
          id:::: www.person.com
      role:: author

      ==== Relation
      type:: updates
      bibitem::
        formattedref::: ISO 19115:2003
        bib_locality:::
          type:::: page
          reference_from:::: 7
          reference_to:::: 10

      ==== Relation
      type:: updates
      bibitem::
        type::: standard
        formattedref::: ISO 19115:2003/Cor 1:2006

      ==== Series
      type:: main
      title::
        type::: original
        content::: ISO/IEC FDIS 10118-3
        language::: en
        script::: Latn
        format::: text/plain
      place:: Serie's place
      organization:: Serie's organization
      abbreviation::
        content::: ABVR
        language::: en
        script::: Latn
      from:: 2009-02-01
      to:: 2010-12-20
      number:: serie1234
      partnumber:: part5678

      ==== Series
      type:: alt
      formattedref::
        content::: serieref
        language::: en
        script::: Latn

    INPUT
            #{BLANK_HDR}
            <sections>
        <clause id='_' inline-header='false' obligation='normative'>
          <title>Clause</title>
          <p id='_'>
            <eref type='inline' bibitemid='ISOTC211' citeas='TC211'/>
          </p>
        </clause>
            </sections>
      <bibliography><references id="_" obligation="informative" normative="true">
              <title>Normative references</title>
              #{NORM_REF_BOILERPLATE}
              <bibitem id="ISOTC211" type="standard">
        <fetched/>
        <title type="main" format="text/plain">Geographic information</title>
        <title type="subtitle" format="text/plain" language="en" script="Latn">Geographic information subtitle</title>
        <title type='title-main' format='text/plain'>Other Title</title>
      <title type='main' format='text/plain'>Other Title</title>
        <uri type="src">https://www.iso.org/standard/53798.html</uri>
        <uri type="obp">https://www.iso.org/obp/ui/#!iso:std:53798:en</uri>
        <uri type="rss">https://www.iso.org/contents/data/standard/05/37/53798.detail.rss</uri>
        <docidentifier type="ISO">TC211</docidentifier>
        <docnumber>211</docnumber>
        <date type="issued">
          <on>2014</on>
        </date>
        <date type="published">
          <from>2014-04</from>
          <to>2014-05</to>
        </date>
        <date type="accessed">
          <on>2015-05-20</on>
        </date>
        <contributor>
          <role type="publisher"><description>Publisher role</description></role>
          <organization>
            <name>International Organization for Standardization</name>
            <subdivision>division</subdivision>
            <abbreviation>ISO</abbreviation>
            <uri>www.iso.org</uri>
          </organization>
        </contributor>
        <contributor>
          <role type="author"/>
          <person>
            <name>
              <completename language="en">A. Bierman</completename>
            </name>
            <affiliation>
              <description format="text/plain">Affiliation description</description>
              <organization>
                <name>IETF</name>
                <abbreviation>IETF</abbreviation>
                <identifier type="uri">www.ietf.org</identifier>
              </organization>
            </affiliation>
             <address>
         <street>8 Street St</street>
         <city>City</city>
         <state>State</state>
         <country>Country</country>
         <postcode>123456</postcode>
       </address>
       <phone>223322</phone>
          </person>
        </contributor>
        <contributor>
         <role type="publisher"/>
          <organization>
            <name>IETF</name>
            <abbreviation>IETF</abbreviation>
            <identifier type="uri">www.ietf.org</identifier>
          </organization>
        </contributor>
        <contributor>
          <role type="author"/>
          <person>
            <name>
              <initial language="en">A.</initial>
              <surname language="en">Bierman</surname>
            </name>
            <affiliation>
              <description language="en" script="Latn">Affiliation description</description>
              <organization>
                <name>IETF</name>
                <abbreviation>IETF</abbreviation>
              </organization>
            </affiliation>
            <identifier type="uri">www.person.com</identifier>
          </person>
        </contributor>
        <edition>1</edition>
        <version>
          <revision-date>2019-04-01</revision-date>
          <draft>draft</draft>
        </version>
        <note type="bibnote">Mark set a major league
      home run record in 1998.</note>
        <language>en</language>
        <language>fr</language>
        <script>Latn</script>
        <abstract format="text/plain">ISO 19115-1:2014 defines the schema required for …​</abstract>
        <abstract format="text/plain" language="fr" script="Latn">L’ISO 19115-1:2014 définit le schéma requis pour …​</abstract>
        <status>
          <stage>stage</stage>
          <substage>substage</substage>
          <iteration>iteration</iteration>
        </status>
        <copyright>
          <from>2014</from>
          <to>#{Time.now.year}</to>
          <owner>
            <organization>
              <name>International Organization for Standardization</name>
              <abbreviation>ISO</abbreviation>
              <uri>www.iso.org</uri>
            </organization>
          </owner>
        </copyright>
        <relation type="updates">
          <bibitem>
            <formattedref format="text/plain">ISO 19115:2003</formattedref>
            </bibitem>
        </relation>
        <relation type="updates">
          <bibitem type="standard">
            <formattedref format="text/plain">ISO 19115:2003/Cor 1:2006</formattedref>
          </bibitem>
        </relation>
        <series type="main">
          <title type="original" format="text/plain" language="en" script="Latn">ISO/IEC FDIS 10118-3</title>
          <place>Serie’s place</place>
          <organization>Serie’s organization</organization>
          <abbreviation language="en" script="Latn">ABVR</abbreviation>
          <from>2009-02-01</from>
          <to>2010-12-20</to>
          <number>serie1234</number>
          <partnumber>part5678</partnumber>
        </series>
        <series type="alt">
          <formattedref format="text/plain" language="en" script="Latn">serieref</formattedref>
        </series>
        <medium>
          <form>medium form</form>
          <size>medium size</size>
          <scale>medium scale</scale>
        </medium>
        <place>bib place</place>
        <extent>
          <locality type="section">
          <referenceFrom>7</referenceFrom>
          </locality>
        </extent>
        <accesslocation>accesslocation1</accesslocation>
        <accesslocation>accesslocation2</accesslocation>
        <classification type="type">value</classification>
        <validity>
          <validityBegins>2010-10-10 12:21</validityBegins>
          <validityEnds>2011-02-03 18:30</validityEnds>
        </validity>
      </bibitem></references></bibliography>
      </standard-document>
    OUTPUT
  end

  it "processes complex dl reference with dot path keys" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      [[ISOTC211]]
      [%bibitem]
      === {blank}
      fetched:: 2019-06-30
      title::
      title.type:: main
      title.content:: Geographic information
      title::
      title.type:: subtitle
      title.content:: Geographic information subtitle
      title.language:: en
      title.script:: Latn
      title.format:: text/plain
      type:: standard
      docid::
      docid.type:: ISO
      docid.id:: TC211
      docnumber:: 211
      edition:: 1
      language:: en
      language:: fr
      script:: Latn
      version.revision_date:: 2019-04-01
      version.draft:: draft
      biblionote.type:: bibnote
      biblionote.content::
      +
      --
      Mark set a major league
      home run record in 1998.
      --
      docstatus.stage:: stage
      docstatus.substage:: substage
      docstatus.iteration:: iteration
      date::
      date.type:: issued
      date.value:: 2014
      date::
      date.type:: published
      date.from:: 2014-04
      date.to:: 2014-05
      date::
      date.type:: accessed
      date.value:: 2015-05-20
      abstract::
      abstract.content::
      +
      --
      ISO 19115-1:2014 defines the schema required for ...
      --
      abstract::
      abstract.content:: L'ISO 19115-1:2014 définit le schéma requis pour ...
      abstract.language:: fr
      abstract.script:: Latn
      abstract.format:: text/plain
      copyright.owner.name:: International Organization for Standardization
      copyright.owner.abbreviation:: ISO
      copyright.owner.url:: www.iso.org
      copyright.from:: 2014
      copyright.to:: #{Time.now.year}
      link::
      link.type:: src
      link.content:: https://www.iso.org/standard/53798.html
      link::
      link.type:: obp
      link.content:: https://www.iso.org/obp/ui/#!iso:std:53798:en
      link::
      link.type:: rss
      link.content:: https://www.iso.org/contents/data/standard/05/37/53798.detail.rss
      medium::
      medium.form:: medium form
      medium.size:: medium size
      medium.scale:: medium scale
      place:: bib place
      extent.locality.type:: section
      extent.locality.reference_from:: 7
      accesslocation:: accesslocation1
      accesslocation:: accesslocation2
      classification.type:: type
      classification.value:: value
      validity.begins:: 2010-10-10 12:21
      validity.ends:: 2011-02-03 18:30
      contributor::
      contributor.organization.name:: International Organization for Standardization
      contributor.organization.url:: www.iso.org
      contributor.organization.abbreviation:: ISO
      contributor.organization.subdivision:: division
      contributor.role.type:: publisher
      contributor.role.description:: Publisher role
      contributor::
      contributor.person.name.completename.content:: A. Bierman
      contributor.person.name.completename.language:: en
      contributor.person.affiliation.organization.name:: IETF
      contributor.person.affiliation.organization.abbreviation:: IETF
      contributor.person.affiliation.organization.identifier.type:: uri
      contributor.person.affiliation.organization.identifier.id:: www.ietf.org
      contributor.person.affiliation.description:: Affiliation description
      contributor.person.contact::
      contributor.person.contact.street:: 8 Street St
      contributor.person.contact.city:: City
      contributor.person.contact.postcode:: 123456
      contributor.person.contact.country:: Country
      contributor.person.contact.state:: State
      contributor.person.contact::
      contributor.person.contact.type:: phone
      contributor.person.contact.value:: 223322
      contributor.role:: author
      contributor::
      contributor.organization.name:: IETF
      contributor.organization.abbreviation:: IETF
      contributor.organization.identifier.type:: uri
      contributor.organization.identifier.id:: www.ietf.org
      contributor.role:: publisher
      contributor::
      contributor.person.name.language:: en
      contributor.person.name.initial:: A.
      contributor.person.name.surname:: Bierman
      contributor.person.affiliation.organization.name:: IETF
      contributor.person.affiliation.organization.abbreviation:: IETF
      contributor.person.affiliation.description.content:: Affiliation description
      contributor.person.affiliation.description.language:: en
      contributor.person.affiliation.description.script:: Latn
      contributor.person.identifier.type:: uri
      contributor.person.identifier.id:: www.person.com
      contributor.role:: author
      relation::
      relation.type:: updates
      relation.bibitem.formattedref:: ISO 19115:2003
      relation.bibitem.bib_locality.type:: page
      relation.bibitem.bib_locality.reference_from:: 7
      relation.bibitem.bib_locality.reference_to:: 10
      relation::
      relation.type:: updates
      relation.bibitem.type:: standard
      relation.bibitem.formattedref:: ISO 19115:2003/Cor 1:2006
      series::
      series.type:: main
      series.title.type:: original
      series.title.content:: ISO/IEC FDIS 10118-3
      series.title.language:: en
      series.title.script:: Latn
      series.title.format:: text/plain
      series.place:: Serie's place
      series.organization:: Serie's organization
      series.abbreviation.content:: ABVR
      series.abbreviation.language:: en
      series.abbreviation.script:: Latn
      series.from:: 2009-02-01
      series.to:: 2010-12-20
      series.number:: serie1234
      series.partnumber:: part5678
      series::
      series.type:: alt
      series.formattedref.content:: serieref
      series.formattedref.language:: en
      series.formattedref.script:: Latn

    INPUT
            #{BLANK_HDR}
            <sections>
            </sections><bibliography><references id="_" obligation="informative" normative="true">
              <title>Normative references</title>
              #{NORM_REF_BOILERPLATE}
              <bibitem id="ISOTC211" type="standard">
        <fetched/>
        <title type="main" format="text/plain">Geographic information</title>
        <title type="subtitle" format="text/plain" language="en" script="Latn">Geographic information subtitle</title>
        <uri type="src">https://www.iso.org/standard/53798.html</uri>
        <uri type="obp">https://www.iso.org/obp/ui/#!iso:std:53798:en</uri>
        <uri type="rss">https://www.iso.org/contents/data/standard/05/37/53798.detail.rss</uri>
        <docidentifier type="ISO">TC211</docidentifier>
        <docnumber>211</docnumber>
        <date type="issued">
          <on>2014</on>
        </date>
        <date type="published">
          <from>2014-04</from>
          <to>2014-05</to>
        </date>
        <date type="accessed">
          <on>2015-05-20</on>
        </date>
        <contributor>
          <role type="publisher"><description>Publisher role</description></role>
          <organization>
            <name>International Organization for Standardization</name>
            <subdivision>division</subdivision>
            <abbreviation>ISO</abbreviation>
            <uri>www.iso.org</uri>
          </organization>
        </contributor>
        <contributor>
          <role type="author"/>
          <person>
            <name>
              <completename language="en">A. Bierman</completename>
            </name>
            <affiliation>
              <description format="text/plain">Affiliation description</description>
              <organization>
                <name>IETF</name>
                <abbreviation>IETF</abbreviation>
                <identifier type="uri">www.ietf.org</identifier>
              </organization>
            </affiliation>
             <address>
         <street>8 Street St</street>
         <city>City</city>
         <state>State</state>
         <country>Country</country>
         <postcode>123456</postcode>
       </address>
       <phone>223322</phone>
          </person>
        </contributor>
        <contributor>
         <role type="publisher"/>
          <organization>
            <name>IETF</name>
            <abbreviation>IETF</abbreviation>
            <identifier type="uri">www.ietf.org</identifier>
          </organization>
        </contributor>
        <contributor>
          <role type="author"/>
          <person>
            <name>
              <initial language="en">A.</initial>
              <surname language="en">Bierman</surname>
            </name>
            <affiliation>
              <description language="en" script="Latn">Affiliation description</description>
              <organization>
                <name>IETF</name>
                <abbreviation>IETF</abbreviation>
              </organization>
            </affiliation>
            <identifier type="uri">www.person.com</identifier>
          </person>
        </contributor>
        <edition>1</edition>
        <version>
          <revision-date>2019-04-01</revision-date>
          <draft>draft</draft>
        </version>
        <note type="bibnote">Mark set a major league
      home run record in 1998.</note>
        <language>en</language>
        <language>fr</language>
        <script>Latn</script>
        <abstract format="text/plain">ISO 19115-1:2014 defines the schema required for …​</abstract>
        <abstract format="text/plain" language="fr" script="Latn">L’ISO 19115-1:2014 définit le schéma requis pour …​</abstract>
        <status>
          <stage>stage</stage>
          <substage>substage</substage>
          <iteration>iteration</iteration>
        </status>
        <copyright>
          <from>2014</from>
          <to>#{Time.now.year}</to>
          <owner>
            <organization>
              <name>International Organization for Standardization</name>
              <abbreviation>ISO</abbreviation>
              <uri>www.iso.org</uri>
            </organization>
          </owner>
        </copyright>
        <relation type="updates">
          <bibitem>
            <formattedref format="text/plain">ISO 19115:2003</formattedref>
          </bibitem>
        </relation>
        <relation type="updates">
          <bibitem type="standard">
            <formattedref format="text/plain">ISO 19115:2003/Cor 1:2006</formattedref>
          </bibitem>
        </relation>
        <series type="main">
          <title type="original" format="text/plain" language="en" script="Latn">ISO/IEC FDIS 10118-3</title>
          <place>Serie’s place</place>
          <organization>Serie’s organization</organization>
          <abbreviation language="en" script="Latn">ABVR</abbreviation>
          <from>2009-02-01</from>
          <to>2010-12-20</to>
          <number>serie1234</number>
          <partnumber>part5678</partnumber>
        </series>
        <series type="alt">
          <formattedref format="text/plain" language="en" script="Latn">serieref</formattedref>
        </series>
        <medium>
          <form>medium form</form>
          <size>medium size</size>
          <scale>medium scale</scale>
        </medium>
        <place>bib place</place>
        <extent>
        <locality type="section">
          <referenceFrom>7</referenceFrom>
          </locality>
        </extent>
        <accesslocation>accesslocation1</accesslocation>
        <accesslocation>accesslocation2</accesslocation>
        <classification type="type">value</classification>
        <validity>
          <validityBegins>2010-10-10 12:21</validityBegins>
          <validityEnds>2011-02-03 18:30</validityEnds>
        </validity>
      </bibitem></references></bibliography>
      </standard-document>
    OUTPUT
  end

  it "processes mix of dl and default references" do
    expect(xmlpp(strip_guid(Asciidoctor.convert(<<~"INPUT", *OPTIONS)))).to be_equivalent_to xmlpp(<<~"OUTPUT")
      #{ASCIIDOC_BLANK_HDR}

      == Section

      === Subsection

      [bibliography]
      === Normative References

      * [[[A, B]]], Title

      [%bibitem]
      ==== Standard
      id:: iso123
      docid::
        type::: ISO
        id::: ISO 123
      type:: standard
      contributor::
        role::: publisher
        organization:::
          name:::: ISO
      contributor::
        role::: author
        person:::
          name::::
      +
      --
      completename::
        language::: en
        content::: Fred
      --
      contributor::
        role::: author
        person:::
        name::::
          completename::::: Jack

    INPUT
                #{BLANK_HDR}
           <sections>
         <clause id='_' inline-header='false' obligation='normative'>
           <title>Section</title>
           <clause id='_' inline-header='false' obligation='normative'>
             <title>Subsection</title>
           </clause>
           <references id='_' obligation='informative'  normative="true">
             <title>Normative References</title>
             <bibitem id='A'>
               <formattedref format='application/x-isodoc+xml'>Title</formattedref>
               <docidentifier>B</docidentifier>
             </bibitem>
             <bibitem id='iso123' type='standard'>
               <fetched/>
               <title type='title-main' format='text/plain'>Standard</title>
               <title type='main' format='text/plain'>Standard</title>
               <docidentifier type='ISO'>ISO 123</docidentifier>
               <contributor>
                 <role type='publisher'/>
                 <organization>
                   <name>ISO</name>
                 </organization>
               </contributor>
               <contributor>
                 <role type='author'/>
                 <person>
                   <name>
                     <completename language='en'>Fred</completename>
                   </name>
                 </person>
               </contributor>
               <contributor>
                 <role type='author'/>
                 <person>
                   <name>
                     <completename>Jack</completename>
                   </name>
                 </person>
               </contributor>
             </bibitem>
           </references>
         </clause>
       </sections>
      </standard-document>
    OUTPUT
  end
end
