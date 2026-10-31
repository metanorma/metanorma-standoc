# This file contains a helper method to mock Metanorma::Utils.random_uuid
# to return an incrementing number (1, 2, 3, 4, etc.) 
# each time it's called within a test.
# It also overrides the contenthash generation, 
# so that the tracked GUIDs can be seen as they are used
# in generated ids and cross-references

module UuidMock
  # Mock UUIDTools::UUID.random_create to return an incrementing counter
  # Mock the identifier generator to return an incrementing counter
  def mock_uuid_increment
    counter = 0

    # Mock the identifier generator to return an incrementing counter;
    # production identifiers come from Metanorma::Utils.random_uuid
    # (buffered SecureRandom), so that is the seam under test.
    allow(Metanorma::Utils).to receive(:random_uuid) do
      counter += 1
      counter.to_s
    end

    # Mock content hashing, preserving these GUIDs instead
    allow_any_instance_of(Metanorma::Standoc::Cleanup)
      .to receive(:contenthash_id_make) do |_instance, doc, *_args|
      ret = doc.xpath("//*[@id]").each_with_object({}) do |x, m|
        # should always be true
        m[x["id"]] = x["id"]
        x["anchor"] and m[x["anchor"]] = m[x["id"]]
      end
      warn ret
      ret
    end
  end
end

RSpec.configure do |config|
  config.include UuidMock
end
