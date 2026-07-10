module Payments
  # S1-G4 · I5 — a per-leg settlement fact for a seller.
  class Settlement < ApplicationRecord
    self.table_name = "settlements"
  end
end
