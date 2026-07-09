# S1-G1 · I3 / D7 — marketplace placeholder (satellite context, outside core packs).
module Marketplace
  class MarketplaceOrder < ApplicationRecord
    self.table_name = "marketplace_orders"
    belongs_to :seller_tenant, class_name: "Tenant"
  end
end
