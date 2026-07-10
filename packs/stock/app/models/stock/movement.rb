module Stock
  # S1-G2 · I4 — an append-only stock movement. Immutability is enforced at the DB
  # (REVOKE + trigger), not by this class; the tests exercise the DB, not AR readonly.
  class Movement < ApplicationRecord
    self.table_name = "stock_movements"
  end
end
