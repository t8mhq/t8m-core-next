require "test_helper"

# S1-G0 · D5 — the suite must connect as app_user, the runtime role that
# G1's RLS policies are enforced against. If this ever reverts to a superuser
# or an RLS-bypassing role, G1's guarantees become untestable — fail loudly.
class DatabaseRoleTest < ActiveSupport::TestCase
  test "test suite connects as app_user" do
    role = ActiveRecord::Base.connection.select_value("SELECT current_user")
    assert_equal "app_user", role,
      "expected the suite to connect as app_user (D5), got #{role.inspect}"
  end

  test "app_user is not a superuser and does not bypass RLS" do
    attrs = ActiveRecord::Base.connection.select_one(<<~SQL)
      SELECT rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user
    SQL
    assert_equal false, attrs["rolsuper"], "app_user must not be a superuser (D5)"
    assert_equal false, attrs["rolbypassrls"], "app_user must not bypass RLS (D5, G1 relies on this)"
  end
end
