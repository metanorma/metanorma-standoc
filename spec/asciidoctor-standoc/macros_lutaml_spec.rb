require "spec_helper"

RSpec.describe 'Lutaml macros' do
  let(:example_file) { fixtures_path("test.exp") }

  context "Array of hashes" do
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        [lutaml,#{example_file},my_context]
        ----

        {% for schema in my_context.schemas %}
        == {{schema.id}}

        {% for entity in schema.entities %}
        === {{entity.id}}
        supertypes -> {{entity.supertypes.id}}
        explicit -> {{entity.explicit.first.id}}

        {% endfor %}

        {% endfor %}
        ----
      TEXT
    end
    let(:output) do
      <<~TEXT
        #{BLANK_METANORMA_HDR}
        <sections>
        <clause id="_" inline-header="false" obligation="normative"><title>annotated_3d_model_data_quality_criteria_schema</title>
        <clause id="_" inline-header="false" obligation="normative">
        <title>a3m_data_quality_criteria_representation</title>
        <p id="_">supertypes →
        explicit → </p>
        </clause>
        <clause id="_" inline-header="false" obligation="normative">
        <title>a3m_data_quality_criterion</title>
        <p id="_">supertypes →
        explicit → assessment_specification</p>
        </clause>
        <clause id="_" inline-header="false" obligation="normative">
        <title>a3m_data_quality_criterion_specific_applied_value</title>
        <p id="_">supertypes →
        explicit → criterion_to_assign_the_value</p>
        </clause>
        <clause id="_" inline-header="false" obligation="normative">
        <title>a3m_data_quality_target_accuracy_association</title>
        <p id="_">supertypes →
        explicit → id</p>
        </clause>
        <clause id="_" inline-header="false" obligation="normative">
        <title>a3m_detailed_report_request</title>
        <p id="_">supertypes →
        explicit → value_type_requested</p>
        </clause>
        <clause id="_" inline-header="false" obligation="normative">
        <title>a3m_summary_report_request_with_representative_value</title>
        <p id="_">supertypes →
        explicit → value_type_requested</p>
        </clause></clause>
        </sections>
        </standard-document>
        </body></html>
      TEXT
    end

    it "correctly renders input" do
      expect(xml_string_conent(metanorma_process(input)))
        .to(be_equivalent_to(output))
    end
  end
end
