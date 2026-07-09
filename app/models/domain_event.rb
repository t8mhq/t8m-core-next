# S1-G2 · I1 — a row in the transactional outbox (app/ glue: event backbone infra).
class DomainEvent < ApplicationRecord
  scope :unpublished, -> { where(published_at: nil) }
end
