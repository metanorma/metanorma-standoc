require "spec_helper"

RSpec.describe Asciidoctor::Standoc do
it "warns when missing a title" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/Table should have title/).to_stderr
  #{VALIDATING_BLANK_HDR}
  |===
  |A |B |C

  h|1 |2 |3
  |===
  INPUT
end


it "warns that introduction may contain requirement" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/Introduction may contain requirement/).to_stderr
  #{VALIDATING_BLANK_HDR}
  == Introduction

  The widget is required not to be larger than 15 cm.
  INPUT
end

it "warns that foreword may contain recommendation" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/Foreword may contain recommendation/).to_stderr
  #{VALIDATING_BLANK_HDR}

  It is not recommended that widgets should be larger than 15 cm.

  == Clause
  INPUT
end

it "warns that foreword may contain permission" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/Foreword may contain permission/).to_stderr
  #{VALIDATING_BLANK_HDR}

  No widget is required to be larger than 15 cm.

  == Clause
  INPUT
end

it "warns that scope may contain recommendation" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/Scope may contain recommendation/).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Scope
  It is not recommended that widgets should be larger than 15 cm.
  INPUT
end

it "warns that definition may contain requirement" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/Definition may contain requirement/).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Terms and Definitions

  === Term1

  It is required that there is a definition.

  INPUT
end

it "warns that term example may contain recommendation" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/Term Example may contain recommendation/).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Terms and Definitions

  === Term

  [example]
  It is not recommended that widgets should be larger than 15 cm.
  INPUT
end

it "warns that note may contain recommendation" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/Note may contain recommendation/).to_stderr
  #{VALIDATING_BLANK_HDR}

  NOTE: It is not recommended that widgets should be larger than 15 cm.
  INPUT
end

it "warns that footnote may contain recommendation" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/Footnote may contain recommendation/).to_stderr
  #{VALIDATING_BLANK_HDR}

  footnote:[It is not recommended that widgets should be larger than 15 cm.]
  INPUT
end

it "warns that term source is not in expected format" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/term reference not in expected format/).to_stderr
  #{VALIDATING_BLANK_HDR}

  [.source]
  I am a generic paragraph
  INPUT
end

it "warns that figure does not have title" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/Figure should have title/).to_stderr
  #{VALIDATING_BLANK_HDR}

  image::spec/examples/rice_images/rice_image1.png[]
  INPUT
end

it "warns that callouts do not match annotations" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/mismatch of callouts and annotations/).to_stderr
      #{VALIDATING_BLANK_HDR}
      [source,ruby]
      --
      puts "Hello, world." <1>
      %w{a b c}.each do |x|
        puts x
      end
      --
      <1> This is one callout
      <2> This is another callout
      INPUT
end

it "warns that term source is not a real reference" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/iso123 is not a real reference/).to_stderr
  #{VALIDATING_BLANK_HDR}

  [.source]
  <<iso123>>
  INPUT
end

it "warns that ndated reference has locality" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/undated reference ISO 123 should not contain specific elements/).to_stderr
  #{VALIDATING_BLANK_HDR}
  
  == Scope
  <<iso123,clause=1>>

  [bibliography]
  == Normative References
  * [[[iso123,ISO 123]]] _Standard_
  INPUT
end

it "warns of Non-reference in bibliography" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(/no anchor on reference/).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Normative References
  * I am not a reference
  INPUT
end

it "warns of Non-ISO reference in Normative References" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{non-ISO/IEC reference not expected as normative}).to_stderr
  #{VALIDATING_BLANK_HDR}

  [bibliography]
  == Normative References
  * [[[XYZ,IESO 121]]] _Standard_
  INPUT
end

it "warns that Scope contains subclauses" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Scope contains subclauses: should be succint}).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Scope
  
  === Scope subclause
  INPUT
end


it "warns that Table should have title" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Table should have title}).to_stderr
  #{VALIDATING_BLANK_HDR}     

  |===
  |a |b |c
  |===
  INPUT
end

it "gives Style warning if number not broken up in threes" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{number not broken up in threes}).to_stderr
  #{VALIDATING_BLANK_HDR}     

  == Clause
  12121
  INPUT
end

it "gives No style warning if number not broken up in threes is ISO reference" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to_not output(%r{number not broken up in threes}).to_stderr
  #{VALIDATING_BLANK_HDR}     

  == Clause
  ISO 12121
  INPUT
end

it "Style warning if decimal point" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{possible decimal point}).to_stderr
  #{VALIDATING_BLANK_HDR}     

  == Clause
  8.1
  INPUT
end

it "Style warning if billion used" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{ambiguous number}).to_stderr
  #{VALIDATING_BLANK_HDR}     

  == Clause
  "Billions" are a term of art.
  INPUT
end

it "Style warning if no space before percent sign" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{no space before percent sign}).to_stderr
  #{VALIDATING_BLANK_HDR}     

  == Clause
  95%
  INPUT
end

it "Style warning if unbracketed tolerance before percent sign" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{unbracketed tolerance before percent sign}).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Clause
  95 ± 5 %
  INPUT
end

it "Style warning if dots in abbreviation" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{no dots in abbreviation}).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Clause
  r.p.m.
  INPUT
end

it "No Style warning if dots in abbreviation are e.g." do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to_not output(%r{no dots in abbreviation}).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Clause
  e.g. 5
  INPUT
end

it "Style warning if ppm used" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{language-specific abbreviation}).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Clause
  5 ppm
  INPUT
end

it "Style warning if space between number and degree" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{space between number and degrees/minutes/seconds}).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Clause
  5 °
  INPUT
end

it "Style warning if no space between number and SI unit" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{no space between number and SI unit}).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Clause
  A measurement of 5Bq was taken.
  INPUT
end

it "Style warning if mins used" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{non-standard unit}).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Clause
  5 mins
  INPUT
end

# can't test: our asciidoc template won't allow this to be generated
# it "Style warning if foreword contains subclauses" do
  # expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{non-standard unit}).to_stderr
  #  #{VALIDATING_BLANK_HDR}
# 
  # INPUT
# end

# can't test: we strip out any such content from Normative references preemptively
#it "Style warning if Normative References contains subclauses" do
  #expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{normative references contains subclauses}).to_stderr
  ##{VALIDATING_BLANK_HDR}
#
  #[bibliography]
  #== Normative References
  #
  #=== Subsection
  #INPUT
#end

it "Style warning if two Symbols and Abbreviated Terms sections" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{only one Symbols and Abbreviated Terms section in the standard}).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Terms and Abbreviations

  === Symbols and Abbreviated Terms

  == Symbols and Abbreviated Terms
  INPUT
end

it "Style warning if Symbols and Abbreviated Terms contains extraneous matter" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Symbols and Abbreviated Terms can only contain a definition list}).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Symbols and Abbreviated Terms

  Paragraph
  INPUT
end

it "Warning if do not start with scope or introduction" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Prefatory material must be followed by \(clause\) Scope}).to_stderr
  #{VALIDATING_BLANK_HDR}

  == Symbols and Abbreviated Terms

  Paragraph
  INPUT
end

it "Warning if introduction not followed by scope" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Prefatory material must be followed by \(clause\) Scope}).to_stderr
  #{VALIDATING_BLANK_HDR}

  .Foreword 
  Foreword

  == Introduction

  == Symbols and Abbreviated Terms

  Paragraph
  INPUT
end

it "Warning if normative references not followed by terms and definitions" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Normative References must be followed by Terms and Definitions}).to_stderr
  #{VALIDATING_BLANK_HDR}

  .Foreword 
  Foreword

  == Scope

  [bibliography]
  == Normative References

  == Symbols and Abbreviated Terms

  Paragraph
  INPUT
end

it "Warning if there are no clauses in the document" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Document must contain clause after Terms and Definitions}).to_stderr
  #{VALIDATING_BLANK_HDR}

  .Foreword 
  Foreword

  == Scope

  [bibliography]
  == Normative References

  == Terms and Definitions

  == Symbols and Abbreviated Terms

  INPUT
end

it "Warning if scope occurs after Terms and Definitions" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Scope must occur before Terms and Definitions}).to_stderr
  #{VALIDATING_BLANK_HDR}

  .Foreword
  Foreword

  == Scope

  [bibliography]
  == Normative References

  == Terms and Definitions

  == Scope

  INPUT
end

it "Warning if scope occurs after Terms and Definitions" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Scope must occur before Terms and Definitions}).to_stderr
  #{VALIDATING_BLANK_HDR}

  .Foreword
  Foreword

  == Scope

  [bibliography]
  == Normative References

  == Terms and Definitions

  == Clause

  == Scope

  INPUT
end

it "Warning if Symbols and Abbreviated Terms does not occur immediately after Terms and Definitions" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Only annexes and references can follow clauses}).to_stderr
  #{VALIDATING_BLANK_HDR}

  .Foreword
  Foreword

  == Scope

  [bibliography]
  == Normative References

  == Terms and Definitions

  == Clause

  == Symbols and Abbreviated Terms

  INPUT
end

it "Warning if no normative references" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Document must include \(references\) Normative References}).to_stderr
  #{VALIDATING_BLANK_HDR}

  .Foreword
  Foreword

  == Scope

  == Terms and Definitions

  == Clause

  [appendix]
  == Appendix A

  [appendix]
  == Appendix B

  [appendix]
  == Appendix C

  INPUT
end

it "Warning if final section is not named Bibliography" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{There are sections after the final Bibliography}).to_stderr
  #{VALIDATING_BLANK_HDR}

  .Foreword
  Foreword

  == Scope

  [bibliography]
  == Normative References

  == Terms and Definitions

  == Clause

  [appendix]
  == Appendix A

  [appendix]
  == Appendix B

  [bibliography]
  == Bibliography

  [bibliography]
  == Appendix C

  INPUT
end

it "Warning if final section is not styled Bibliography" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Section not marked up as \[bibliography\]!}).to_stderr
  #{VALIDATING_BLANK_HDR}

  .Foreword
  Foreword

  == Scope

  [bibliography]
  == Normative References

  == Terms and Definitions

  == Clause

  [appendix]
  == Appendix A

  [appendix]
  == Appendix B

  == Bibliography

  INPUT
end

it "Warning if English title intro and no French title intro" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{No French Title Intro!}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :title-intro-en: Title
  :no-isobib:

  INPUT
end

it "Warning if French title intro and no English title intro" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{No English Title Intro!}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :title-intro-fr: Title
  :no-isobib:

  INPUT
end


it "Warning if English title and no French intro" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{No French Title!}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :title-main-en: Title
  :no-isobib:

  INPUT
end

it "Warning if French title and no English title" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{No English Title!}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :title-main-fr: Title
  :no-isobib:

  INPUT
end

it "Warning if English title part and no French title part" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{No French Title Part!}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :title-part-en: Title
  :no-isobib:

  INPUT
end

it "Warning if French title part and no English title part" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{No English Title Part!}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :title-part-fr: Title
  :no-isobib:

  INPUT
end

it "Warning if non-IEC document with subpart" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Subpart defined on non-IEC document!}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :partnumber: 1-1
  :publisher: ISO
  :no-isobib:

  INPUT
end

it "No warning if joint IEC/non-IEC document with subpart" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.not_to output(%r{Subpart defined on non-IEC document!}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :partnumber: 1-1
  :publisher: ISO,IEC
  :no-isobib:

  INPUT
end

it "Warning if main title contains document type" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Main Title may name document type}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :title-main-en: A Technical Specification on Widgets
  :no-isobib:

  INPUT
end

it "Warning if intro title contains document type" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Title Intro may name document type}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :title-intro-en: A Technical Specification on Widgets
  :no-isobib:

  INPUT
end

it "Each first-level subclause must have a title" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{each first-level subclause must have a title}).to_stderr
  #{VALIDATING_BLANK_HDR}
  == Clause

  === {blank}
  INPUT
end

it "All subclauses must have a title, or none" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{all subclauses must have a title, or none}).to_stderr
  #{VALIDATING_BLANK_HDR}
  == Clause

  === Subclause

  ==== {blank}

  ==== Subsubclause
  INPUT
end

it "Warning if subclause is only child of its parent, or none" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{subclause is only child}).to_stderr
  #{VALIDATING_BLANK_HDR}
  == Clause

  === Subclause

  INPUT
end

it "Warning if invalid technical committee type" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{invalid technical committee type}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :technical-committee-type: X
  :no-isobib:

  INPUT
end

it "Warning if invalid subcommittee type" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{invalid subcommittee type}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :subcommittee-type: X
  :no-isobib:

  INPUT
end

it "Warning if invalid subcommittee type" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{invalid subcommittee type}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :subcommittee-type: X
  :no-isobib:

  INPUT
end

it "Warning if 'see' crossreference points to normative section" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{'see terms' is pointing to a normative section}).to_stderr
  #{VALIDATING_BLANK_HDR}
  [[terms]]
  == Terms and Definitions

  == Clause
  See <<terms>>
  INPUT
end

it "Warning if 'see' reference points to normative reference" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{is pointing to a normative reference}).to_stderr
  #{VALIDATING_BLANK_HDR}
  [bibliography]
  == Normative References
  * [[[terms,ISO 1]]] _References_

  == Clause
  See <<terms>>
  INPUT
end

it "Warning if term definition starts with article" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{term definition starts with article}).to_stderr 
  #{VALIDATING_BLANK_HDR}
  == Terms and Definitions
  
  === Term

  The definition of a term is a part of the specialized vocabulary of a particular field
  INPUT
end

it "Warning if term definition ends with period" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{term definition ends with period}).to_stderr
  #{VALIDATING_BLANK_HDR}
  == Terms and Definitions
  
  === Term

  Part of the specialized vocabulary of a particular field.
  INPUT
end

it "validates document against ISO XML schema" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{value of attribute "align" is invalid; must be equal to}).to_stderr
  #{VALIDATING_BLANK_HDR}

  [align=mid-air]
  Para
  INPUT
end


it "Warning if terms mismatches IEV" do
  system "mv ~/.iev.pstore ~/.iev.pstore1"
  system "rm test.iev.pstore"
  mock_open_uri('103-01-02')
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Term "automation" does not match IEV 103-01-02 "functional"}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  
  [bibliography]
  == Normative References
  * [[[iev,IEV]]], _iev_

  == Terms and definitions
  === Automation

  [.source]
  <<iev,clause="103-01-02">>
  INPUT
  system "mv ~/.iev.pstore1 ~/.iev.pstore"
end

it "No warning if English term matches IEV" do
  system "mv ~/.iev.pstore ~/.iev.pstore1"
  system "rm test.iev.pstore"
  mock_open_uri('103-01-02')
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.not_to output(%r{does not match IEV 103-01-02}).to_stderr
  = Document title
  Author
  :docfile: test.adoc

  [bibliography]
  == Normative References
  * [[[iev,IEV]]], _iev_

  == Terms and definitions
  === Functional

  [.source]
  <<iev,clause="103-01-02">>
  INPUT
  system "mv ~/.iev.pstore1 ~/.iev.pstore"
end

it "No warning if French term matches IEV" do
  system "mv ~/.iev.pstore ~/.iev.pstore1"
  system "rm test.iev.pstore"
  mock_open_uri('103-01-02')
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.not_to output(%r{does not match IEV 103-01-02}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :language: fr

  [bibliography]
  == Normative References
  * [[[iev,IEV]]], _iev_

  == Terms and definitions
  === Fonctionnelle, f

  [.source]
  <<iev,clause="103-01-02">>
  INPUT
  system "mv ~/.iev.pstore1 ~/.iev.pstore"
end

it "Warn if more than 7 levels of subclause" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.to output(%r{Exceeds the maximum clause depth of 7}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :no-isobib:
  :language: fr

  == Clause

  === Clause

  ==== Clause

  ===== Clause

  ====== Clause

  [level=6]
  ====== Clause

  [level=7]
  ====== Clause

  [level=8]
  ====== Clause

  INPUT
end

it "Do not warn if not more than 7 levels of subclause" do
  expect { Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true) }.not_to output(%r{exceeds the maximum clause depth of 7}).to_stderr
  = Document title
  Author
  :docfile: test.adoc
  :nodoc:
  :no-isobib:
  :language: fr

  == Clause

  === Clause

  ==== Clause

  ===== Clause

  ====== Clause

  [level=6]
  ====== Clause

  [level=7]
  ====== Clause

  INPUT
end
end
