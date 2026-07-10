module Orders
  # S1-G5 — per-pack abstract base record.
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
