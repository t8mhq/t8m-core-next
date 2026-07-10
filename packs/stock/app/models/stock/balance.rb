module Stock
  # S1-G2 · I4 — derived balance, upserted in the same transaction as its movement.
  class Balance < ApplicationRecord
    self.table_name = "stock_balances"
  end
end
