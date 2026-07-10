module Stock
  # S1-G2 — per-pack abstract base record (self-contained; no root privacy exception).
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
