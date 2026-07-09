module Fiscal
  # S1-G2 — per-pack abstract base record. Packs are self-contained: no reference to
  # the root ApplicationRecord, so no cross-pack privacy exception is needed.
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
