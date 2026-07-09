module Catalog
  # S1-G2 · I5 — tenant-scoped catalog product (private to packs/catalog).
  class Product < ApplicationRecord
    self.table_name = "products"
  end
end
