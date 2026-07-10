require "test_helper"

# S1-G4 · I2 — the payment webhook through the full Rack stack.
class PaymentWebhookTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  self.use_transactional_tests = false

  teardown { ActiveRecord::Base.connection.execute("DELETE FROM gateway_events") }

  def signed(body)
    { "Content-Type" => "application/json",
      "X-Pagarme-Signature" => OpenSSL::HMAC.hexdigest("SHA256", "test-secret", body) }
  end

  test "duplicate webhook delivery processes exactly once (I2)" do
    body = { event_id: "evt_#{SecureRandom.hex(4)}", type: "charge.paid" }.to_json

    assert_enqueued_jobs 1, only: PaymentWebhookJob do
      post "/api/v1/payments/webhook", params: body, headers: signed(body)
      assert_response :ok
      post "/api/v1/payments/webhook", params: body, headers: signed(body) # replay
      assert_response :ok
    end

    assert_equal 1, GatewayEvent.count, "the event is recorded once"
  end

  test "an invalid signature is rejected and nothing is recorded" do
    body = { event_id: "evt_x", type: "charge.paid" }.to_json
    post "/api/v1/payments/webhook", params: body,
      headers: { "Content-Type" => "application/json", "X-Pagarme-Signature" => "deadbeef" }
    assert_response :unauthorized
    assert_equal 0, GatewayEvent.count
  end
end
