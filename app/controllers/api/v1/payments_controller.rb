module Api
  module V1
    # S1-G4 · I2 — the Pagar.me webhook (ADR-0005 §webhook truth). Signature-verified,
    # idempotent by gateway event id, processed via the queue — NEVER inline. The browser
    # redirect is UX; this is the truth.
    class PaymentsController < ActionController::API
      WEBHOOK_SECRET = ENV.fetch("PAGARME_WEBHOOK_SECRET", "test-secret")

      def webhook
        return head(:unauthorized) unless valid_signature?

        payload = params.to_unsafe_h
        inserted = GatewayEvent.insert_all(
          [ { gateway_event_id: payload["event_id"], event_type: payload["type"] || "unknown",
              payload: payload, received_at: Time.current } ],
          unique_by: :gateway_event_id, returning: %w[id]
        )
        # Enqueue only on first sight — a replay hit the unique index and does nothing.
        PaymentWebhookJob.perform_later(payload["event_id"]) if inserted.rows.any?
        head :ok
      end

      private

      def valid_signature?
        expected = OpenSSL::HMAC.hexdigest("SHA256", WEBHOOK_SECRET, request.raw_post)
        ActiveSupport::SecurityUtils.secure_compare(expected, request.headers["X-Pagarme-Signature"].to_s)
      end
    end
  end
end
