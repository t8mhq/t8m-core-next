require "test_helper"

# S1-G1 · I1 — the middleware sets context at the connection lease and the ensure-block
# resets it on release, even on error. This is what makes the I1.2 leak impossible.
class RlsContextMiddlewareTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def conn = ActiveRecord::Base.connection

  setup do
    Rls.reset(connection: conn)
    @tenant = Tenant.create!(name: "Host tenant", host: "shop.example")
  end

  teardown do
    Rls.reset(connection: conn)
    Tenant.where(id: @tenant.id).delete_all
  end

  test "sets tenant context during the request and resets after" do
    observed = nil
    app = ->(_env) { observed = Rls.current_scope(connection: conn); [ 200, {}, [ "ok" ] ] }

    RlsContextMiddleware.new(app).call(Rack::MockRequest.env_for("http://shop.example/"))

    assert_equal "tenant", observed, "scope must be set while the request runs"
    assert_nil Rls.current_scope(connection: conn), "context must be reset on release"
  end

  test "resets context even when the app raises (ensure)" do
    app = ->(_env) { raise "boom" }

    assert_raises(RuntimeError) do
      RlsContextMiddleware.new(app).call(Rack::MockRequest.env_for("http://shop.example/"))
    end
    assert_nil Rls.current_scope(connection: conn), "ensure-block must reset even on error"
  end

  test "unknown host leaves no context set (default deny)" do
    app = ->(_env) { [ 200, {}, [ "ok" ] ] }
    RlsContextMiddleware.new(app).call(Rack::MockRequest.env_for("http://nobody.example/"))
    assert_nil Rls.current_scope(connection: conn)
  end
end
