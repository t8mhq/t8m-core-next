module Catalog
  # S1-G2 · I5 — NCM registry with ST / monofásico flags (global; data load is later).
  class NcmClassification < ApplicationRecord
    self.table_name = "ncm_classifications"
  end
end
