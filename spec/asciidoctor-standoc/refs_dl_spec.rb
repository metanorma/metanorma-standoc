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
      contributors:: 
        roles::: publisher
        entity:::
          name:::: ISO
      contributors::
        roles::: author
        entity:::
          name::::
      +
      --
      completename::
        language::: en
        content::: Fred
      --
      contributors::
        roles::: author
        entity:::
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

end
