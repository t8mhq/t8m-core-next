module Payments
  # S1-G4 · I3 — a seller's Pagar.me recipient. KYC status gates split targeting (I4)
  # and seller activation (ADR-0004).
  class Recipient < ApplicationRecord
    self.table_name = "pagarme_recipients"
    KYC_STATUSES = %w[pending approved refused].freeze

    validates :kyc_status, inclusion: { in: KYC_STATUSES }

    def approved?
      kyc_status == "approved"
    end
  end
end
