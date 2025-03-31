# This file contains a helper method to mock UUIDTools::UUID.random_create
# to return an incrementing number (1, 2, 3, 4, etc.) each time it's called within a test.

module UuidMock
  # Mock UUIDTools::UUID.random_create to return an incrementing counter
  # @return [Object] A mock UUID object with a to_s method that returns the counter value
  def mock_uuid_increment
    counter = 0
    
    # Create a mock UUID class that responds to to_s with the counter value
    uuid_double = double("UUID")
    allow(uuid_double).to receive(:to_s) do
      counter.to_s
    end
    
    # Allow the mock UUID to be used in string interpolation
    allow(uuid_double).to receive(:to_str) do
      counter.to_s
    end
    
    # Mock the random_create method to increment counter and return the mock UUID
    allow(UUIDTools::UUID).to receive(:random_create) do
      counter += 1
      uuid_double
    end
  end
end

RSpec.configure do |config|
  config.include UuidMock
end
