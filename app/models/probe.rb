# S1-G1 · I1 — tenant-scoped probe (RLS test target; not a domain table).
class Probe < ApplicationRecord
  belongs_to :tenant
end
