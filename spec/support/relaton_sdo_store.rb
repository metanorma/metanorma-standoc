# The Relaton SDO store (Relaton.organization) consults a network-published
# index manifest. The standoc suite must not depend on the network: unless an
# example says otherwise, the store is pointed at a path that resolves to no
# index at all, so every lookup quietly returns nil. (Sdo::Fetcher#download
# reads file:// URLs straight off disk and returns nil when the file is
# missing.) The specs exercising authoritative copublisher logos
# (copublisher_logo_spec) re-point these settings at local fixtures.
RSpec.configure do |config|
  config.before do
    Relaton::Sdo.configure do |c|
      c.url = "file:///relaton-sdo-spec-neutral/index.yaml"
      c.storage_dir = File.join(Dir.tmpdir, "relaton-sdo-spec-neutral")
      c.ttl = 24 * 60 * 60
    end
    Relaton::Sdo::Store.instance.reset!
  end
end
