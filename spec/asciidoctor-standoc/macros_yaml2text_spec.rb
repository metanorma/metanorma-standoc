require "spec_helper"

RSpec.describe 'Yaml2Text macros' do
  it_behaves_like "structured data 2 text preprocessor" do
    let(:extention) { "yaml" }
    def transform_to_type(data)
      data.to_yaml
    end
  end
end
