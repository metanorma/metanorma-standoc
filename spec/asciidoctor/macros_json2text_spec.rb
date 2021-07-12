require "spec_helper"

RSpec.describe "Json2Text macros" do
  it_behaves_like "structured data 2 text preprocessor" do
    let(:extention) { "json" }
    def transform_to_type(data)
      data.to_json
    end
  end
end
