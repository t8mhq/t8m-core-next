module Orders
  # S1-G5 · I2 — an order in any channel (private to packs/orders).
  class Order < ApplicationRecord
    self.table_name = "orders"
  end
end
