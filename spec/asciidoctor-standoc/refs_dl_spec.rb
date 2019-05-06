require "spec_helper"
require "isobib"
require "ietfbib"

RSpec.describe Asciidoctor::Standoc do
    it "processes simple dl reference" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      [%bibitem]
      === Standard
      ref:: iso123
      docidentifier:: ISO 123
      doctype:: standard
      publisher:: ISO

    INPUT
      #{BLANK_HDR}
      <sections>
      </sections><bibliography><references id="_" obligation="informative">
        <title>Normative References</title>
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

end
