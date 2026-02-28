require "spec_helper"

RSpec.describe Metanorma::Standoc::Validate do
  it "uses the location of the inheriting class's file for schema_location" do
    # Create a test class that inherits from Standoc::Validate
    # This class will be defined in this file, so _file should point to this file
    test_class = Class.new(Metanorma::Standoc::Validate) do
      def schema_file
        "test-schema.rng"
      end
    end

    # Set _file manually since we're not using class inheritance syntax
    test_class._file = __FILE__

    # Create an instance of the test class
    converter = Metanorma::Standoc::Converter.new("standoc", {})
    validator = test_class.new(converter)

    # Get the schema location
    schema_location = validator.schema_location

    # Expected location should be relative to this file, not the original module's file
    expected_location = File.join(File.dirname(__FILE__), "test-schema.rng")

    # Verify that the schema location is correct
    expect(schema_location).to eq(expected_location)
  end
end
