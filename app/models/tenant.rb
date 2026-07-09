# S1-G1 · I1 — tenant registry (app/ glue: application-wide, not a bounded context).
class Tenant < ApplicationRecord
  has_many :probes, dependent: :restrict_with_exception
end
