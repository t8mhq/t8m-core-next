# S1-G4 · I2 — process a recorded gateway event off the request path (enqueue-never-inline).
# G4-I5 wires settlement ingestion (payment_settled → settlements) behind this; here it
# marks the event processed so replays stay no-ops.
class PaymentWebhookJob < ApplicationJob
  def perform(gateway_event_id)
    event = GatewayEvent.find_by(gateway_event_id: gateway_event_id)
    return if event.nil? || event.processed_at.present?

    # I5: dispatch by event.event_type (charge.paid → confirm; recipient.kyc → approve; …).
    event.update!(processed_at: Time.current)
  end
end
