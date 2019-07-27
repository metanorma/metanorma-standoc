require "spec_helper"
require "relaton_iso"

RSpec.describe Asciidoctor::Standoc do
    it "processes simple dl reference" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
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
      </sections><bibliography><references id="_" obligation="informative">
        <title>Normative References</title>
        <bibitem id="iso123" type="standard">
        <fetched>#{Date.today}</fetched>
         <title type="main" format="text/plain" language="en" script="Latn">Standard</title>
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
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
#{ASCIIDOC_BLANK_HDR}
[bibliography]
== Normative References

[[ISO/TC211]]
[%bibitem]
=== {blank}
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
   to::: 2020
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
  type::: section
  reference_from::: 7
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
//. {blank}
//.. publisher
//.. Publisher role

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
      </sections><bibliography><references id="_" obligation="informative">
        <title>Normative References</title>
        <bibitem id="TC211" type="standard">
  <fetched>2019-06-30</fetched>
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
    <from>2014</from>
    <to>2014</to>
  </date>
  <date type="accessed">
    <on>2015</on>
  </date>
  <contributor>
    <!--<role type="publisher">Publisher role</role>-->
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
    <to>2020</to>
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
  <locality type="section">
    <referenceFrom>7</referenceFrom>
  </locality>
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

end
