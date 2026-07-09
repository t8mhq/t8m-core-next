module Fiscal
  # S1-G2 · I5 / D8 — temporal fiscal parameters. Overlap is unrepresentable at the
  # schema level; historical margin reads the rate in force at sale time.
  class TenantParameter < ApplicationRecord
    self.table_name = "tenant_fiscal_parameters"

    # The only read path: the row whose validity window contains `date`
    # ([valid_from, valid_to) half-open; valid_to NULL = open-ended).
    def self.parameters_at(tenant_id, date)
      where(tenant_id: tenant_id)
        .where(valid_from: ..date)
        .where("valid_to IS NULL OR valid_to > ?", date)
        .order(valid_from: :desc)
        .first
    end
  end
end
