require "spec_helper"

RSpec.describe Metanorma::Requirements::Modspec do
  it "does not warn if no linkage issues" do
    FileUtils.rm_f "test.err"
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :requirements-model: ogc

      [[A1]]
      [.requirement,type=requirement]
      ====
      [%metadata]
      identifier:: A
      ====

      [[B1]]
      [.requirement,type=recommendation]
      ====
      [%metadata]
      identifier:: B
      ====

      [[C1]]
      [.requirement,type=permission]
      ====
      [%metadata]
      identifier:: C
      ====

      [[D1]]
      [.requirement,type=conformance_test]
      ====
      [%metadata]
      identifier:: D
      classification:: target:A
      ====

      [[E1]]
      [.recommendation,type=conformance_test]
      ====
      [%metadata]
      identifier:: E
      classification:: target:B
      ====

      [[F1]]
      [.permission,type=conformance_test]
      ====
      [%metadata]
      identifier:: F
      target:: C
      ====

      [[G1]]
      [.requirement,type=requirements_class]
      ====
      [%metadata]
      identifier:: G
      requirement:: A
      ====

      [[H1]]
      [.recommendation,type=requirements_class]
      ====
      [%metadata]
      identifier:: H
      requirement:: A
      ====

      [[I1]]
      [.permission,type=requirements_class]
      ====
      [%metadata]
      identifier:: I
      requirement:: A
      ====

      [[J1]]
      [.requirement,type=conformance_class]
      ====
      [%metadata]
      classification:: target:G
      requirement:: D
      ====

      [[K1]]
      [.recommendation,type=conformance_class]
      ====
      [%metadata]
      classification:: target:H
      requirement:: E
      ====

      [[L1]]
      [.permission,type=conformance_class]
      ====
      [%metadata]
      classification:: target:I
      requirement:: F
      ====

    INPUT
    expect(File.read("test.err"))
      .not_to include "no corresponding Requirement"
    expect(File.read("test.err"))
      .not_to include "has no corresponding Conformance test"
    expect(File.read("test.err"))
      .not_to include "has no corresponding Requirement class"
    expect(File.read("test.err"))
      .not_to include "has no corresponding Conformance class"
  end

  it "warns of disconnect between requirements and conformance tests, #1" do
    FileUtils.rm_f "test.err"
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :requirements-model: ogc

      [[A]]
      [.requirement,type=requirement]
      ====
      ====

      [[B]]
      [.requirement,type=recommendation]
      ====
      ====

      [[C]]
      [.requirement,type=permission]
      ====
      ====

      [[D]]
      [.requirement,type=conformance_test]
      ====
      ====

      [[E]]
      [.recommendation,type=conformance_test]
      ====
      ====

      [[F1]]
      [.permission,type=conformance_test]
      ====
      [%metadata]
      identifier:: F
      ====

      [[G1]]
      [.requirement,type=requirements_class]
      ====
      [%metadata]
      identifier:: G
      ====

      [[H1]]
      [.recommendation,type=requirements_class]
      ====
      [%metadata]
      identifier:: H
      ====

      [[I1]]
      [.permission,type=requirements_class]
      ====
      [%metadata]
      identifier:: I
      ====

      [[J1]]
      [.requirement,type=conformance_class]
      ====
      [%metadata]
      identifier:: J
      ====

      [[K1]]
      [.recommendation,type=conformance_class]
      ====
      [%metadata]
      identifier:: K
      ====

      [[L1]]
      [.permission,type=conformance_class]
      ====
      [%metadata]
      identifier:: L
      ====

    INPUT

    expect(File.read("test.err"))
      .to include "Conformance test D has no corresponding Requirement"
    expect(File.read("test.err"))
      .to include "Requirement A has no corresponding Conformance test"
    expect(File.read("test.err"))
      .to include "Conformance class J has no corresponding Requirement class"
    expect(File.read("test.err"))
      .to include "Requirement class G has no corresponding Conformance class"
  end

  it "warns of disconnect between requirements and conformance tests, #2" do
    FileUtils.rm_f "test.err"
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :requirements-model: ogc

      [[A1]]
      [.requirement]
      ====
      [%metadata]
      identifier:: A
      ====

      [[B1]]
      [.requirement,type=recommendation]
      ====
      ====

      [[C1]]
      [.requirement,type=permission]
      ====
      ====

      [[D1]]
      [.requirement,type=conformance_test]
      ====
      [%metadata]
      identifier:: D
      target:: A
      ====
    INPUT

    expect(File.read("test.err"))
      .not_to include "Conformance test D has no corresponding Requirement"
  end

  it "warns of disconnect between requirement classes and requirements" do
    FileUtils.rm_f "test.err"
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :requirements-model: ogc

      [[A]]
      [.requirement,type=requirement]
      ====
      ====

      [[B]]
      [.requirement,type=recommendation]
      ====
      ====

      [[C]]
      [.requirement,type=permission]
      ====
      ====

      [[G1]]
      [.requirement,type=requirements_class]
      ====
      [%metadata]
      identifier:: G
      ====

      [[H1]]
      [.recommendation,type=requirements_class]
      ====
      [%metadata]
      identifier:: H
      ====

      [[I1]]
      [.permission,type=requirements_class]
      ====
      [%metadata]
      identifier:: I
      ====
    INPUT
    expect(File.read("test.err"))
      .to include "Requirement class G has no corresponding Requirement"
    expect(File.read("test.err"))
      .to include "Requirement class H has no corresponding Requirement"
    expect(File.read("test.err"))
      .to include "Requirement class I has no corresponding Requirement"
  end


  it "warns of disconnect between conformance classes and conformance tests" do
    FileUtils.rm_f "test.err"
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :requirements-model: ogc

      [[A]]
      [.requirement,type=conformance_test]
      ====
      ====

      [[B]]
      [.requirement,type=conformance_class]
      ====
      ====

    INPUT
    expect(File.read("test.err"))
      .to include "Conformance class B has no corresponding Conformance test"
    expect(File.read("test.err"))
      .to include "Conformance test A has no corresponding Conformance class"
  end
end
