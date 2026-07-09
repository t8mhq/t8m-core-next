module Payments
  # S1-G2 · I5 — tenant-scoped payment leg (private to packs/payments).
  class Payment < ApplicationRecord
    self.table_name = "payments"
  end
end
