require "spec_helper"

RSpec.describe Asciidoctor::Standoc do
  it "processes simple lists" do
    output = Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{ASCIIDOC_BLANK_HDR}
      * List 1
      * List 2
      * List 3

      * [*] checked
      * [x] also checked
      * [ ] not checked

      . List A
      . List B
      . List C

      List D:: List E
      List F:: List G

    INPUT
    expect(xmlpp(strip_guid(output))).to be_equivalent_to xmlpp(<<~"OUTPUT")
        #{BLANK_HDR}
        <sections>
          <ul id='_'>
            <li>
              <p id='_'>List 1</p>
            </li>
            <li>
              <p id='_'>List 2</p>
            </li>
            <li>
              <p id='_'>List 3</p>
            </li>
            <li uncheckedcheckbox='false' checkedcheckbox='true'>
              <p id='_'>checked</p>
            </li>
            <li uncheckedcheckbox='false' checkedcheckbox='true'>
              <p id='_'>also checked</p>
            </li>
            <li uncheckedcheckbox='true' checkedcheckbox='false'>
              <p id='_'>not checked</p>
              <ol id='_' type='arabic'>
                <li>
                  <p id='_'>List A</p>
                </li>
                <li>
                  <p id='_'>List B</p>
                </li>
                <li>
                  <p id='_'>List C</p>
                  <dl id='_'>
                    <dt>List D</dt>
                    <dd>
                      <p id='_'>List E</p>
                    </dd>
                    <dt>List F</dt>
                    <dd>
                      <p id='_'>List G</p>
                    </dd>
                  </dl>
                </li>
              </ol>
            </li>
          </ul>
        </sections>
      </standard-document>
    OUTPUT
  end

  it "processes complex lists" do
    output = Asciidoctor.convert(<<~"INPUT", *OPTIONS)
      #{ASCIIDOC_BLANK_HDR}
      [[id]]
      [keep-with-next=true,keep-lines-together=true,tag=X,multilingual-rendering=common]
      * First
      * Second
      +
      --
      entry1

      entry2
      --

      [[id1]]
      [keep-with-next=true,keep-lines-together=true,tag=X,multilingual-rendering=common]
      [loweralpha]
      . First
      . Second
      [upperalpha]
      .. Third
      .. Fourth
      . Fifth
      . Sixth

      [lowerroman]
      . A
      . B
      [upperroman]
      .. C
      .. D
      [arabic]
      ... E
      ... F
      [keep-with-next=true,keep-lines-together=true,tag=X,multilingual-rendering=common]
      Notes1::
      Notes::  Note 1.
      +
      Note 2.
      +
      Note 3.

      [%key]
      a:: b

    INPUT
    expect(xmlpp(strip_guid(output))).to be_equivalent_to xmlpp(<<~"OUTPUT")
                  #{BLANK_HDR}
             <sections><ul id="id" keep-with-next="true" keep-lines-together="true" tag='X' multilingual-rendering='common' >
               <li>
                 <p id="_">First</p>
               </li>
               <li><p id="_">Second</p><p id="_">entry1</p>
             <p id="_">entry2</p></li>
             </ul>
             <ol id="id1" type="alphabet"  keep-with-next="true" keep-lines-together="true" tag='X' multilingual-rendering='common' >
               <li>
                 <p id="_">First</p>
               </li>
               <li>
                 <p id="_">Second</p>
                 <ol id="_" type="alphabet_upper">
               <li>
                 <p id="_">Third</p>
               </li>
               <li>
                 <p id="_">Fourth</p>
               </li>
             </ol>
               </li>
               <li>
                 <p id="_">Fifth</p>
               </li>
               <li>
                 <p id="_">Sixth</p>
               </li>
             </ol>
             <ol id="_" type="roman">
               <li>
                 <p id="_">A</p>
               </li>
               <li>
                 <p id="_">B</p>
                 <ol id="_" type="roman_upper">
               <li>
                 <p id="_">C</p>
               </li>
               <li>
                 <p id="_">D</p>
                 <ol id="_" type="arabic">
               <li>
                 <p id="_">E</p>
               </li>
               <li>
                 <p id="_">F</p>
                 <dl id="_"  keep-with-next="true" keep-lines-together="true" tag='X' multilingual-rendering='common'>
               <dt>Notes1</dt>
               <dd/>
               <dt>Notes</dt>
               <dd><p id="_">Note 1.</p><p id="_">Note 2.</p>
             <p id="_">Note 3.</p></dd>
             </dl>
               </li>
             </ol>
               </li>
             </ol>
               </li>
             </ol><dl id='_' key='true'>
        <dt>a</dt>
        <dd>
          <p id='_'>b</p>
        </dd>
      </dl>
      </sections>
             </standard-document>
    OUTPUT
  end

  it "anchors lists and list items" do
    input = <<~INPUT
      #{ASCIIDOC_BLANK_HDR}
      [[id1]]
      * [[id2]] List item
      * Hello [[id3]] List item

      [[id4]]
      [[id5]]a:: [[id6]]b
    INPUT
    output = <<~OUTPUT
      #{BLANK_HDR}
      <sections>
      <ul id="id1">
        <li id="id2">
          <p id="_">List item</p>
        </li>
        <li>
          <p id="_">Hello <bookmark id="id3"/> List item</p>
        </li>
      </ul>
      <dl id='id4'>
          <dt id='id5'>a</dt>
          <dd>
            <p id='_'>
              <bookmark id='id6'/>
              b
            </p>
          </dd>
        </dl>
      </sections>
      </standard-document>
    OUTPUT
    expect(xmlpp(strip_guid(Asciidoctor.convert(input, *OPTIONS))))
      .to be_equivalent_to xmlpp(output)
  end
end
