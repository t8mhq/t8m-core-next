require "test_helper"

# S1-G0 · I3.3 — every pack exposes a loadable public entry point under app/public/,
# and keeps at least one private constant outside that public surface. Cross-pack
# reachability of the private constants is enforced statically by Packwerk
# (see bin/packwerk check and the I3.2 red test); this smoke test proves the
# surfaces are real and correctly classified.
class PackBoundariesTest < ActiveSupport::TestCase
  PACKS = %w[catalog stock orders customers payments fiscal shipping promotions].freeze

  test "every pack exposes a public Api under app/public/" do
    PACKS.each do |pack|
      const_name = "#{pack.camelize}::Api"
      const = const_name.constantize
      assert const, "#{const_name} should be reachable (public entry point)"

      source = Object.const_source_location(const_name)&.first
      assert source, "#{const_name} should have a source location"
      assert_includes source, "packs/#{pack}/app/public/",
        "#{const_name} must live under packs/#{pack}/app/public/ (D3)"
    end
  end

  test "every pack keeps a private constant outside its public surface" do
    PACKS.each do |pack|
      const_name = "#{pack.camelize}::Internal"
      const = const_name.constantize
      assert const, "#{const_name} should be defined (private constant)"

      source = Object.const_source_location(const_name)&.first
      refute_includes source, "/app/public/",
        "#{const_name} must NOT live under app/public/ — it is private to packs/#{pack}"
    end
  end
end
