# S1-G1 · I3 / D7 — marketplace placeholder (satellite context, outside core packs).
module Marketplace
  class SellerProfile < ApplicationRecord
    self.table_name = "seller_profiles"
    belongs_to :seller_tenant, class_name: "Tenant"
  end
end
