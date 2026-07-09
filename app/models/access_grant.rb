# S1-G1 · I2 — a grant of read access from a grantor tenant to a grantee user.
# Grant scope is read-only in Stage 1 (D5). RLS: grantor manages its own; grantee
# reads only its own (D6).
class AccessGrant < ApplicationRecord
  belongs_to :grantor_tenant, class_name: "Tenant"

  scope :active, -> { where(revoked_at: nil) }
end
