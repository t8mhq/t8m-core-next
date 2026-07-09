# S1-G2 · I6 — flag governance metadata. Release flags are temporary by contract, so
# they must name an owner and an expiry (I6.2); other kinds may omit them.
class FeatureFlag < ApplicationRecord
  KINDS = %w[release ops experiment permission].freeze

  validates :key, presence: true, uniqueness: true
  validates :kind, inclusion: { in: KINDS }
  validates :owner, presence: true, if: :release?
  validates :expires_at, presence: true, if: :release?

  scope :expired, -> { where.not(expires_at: nil).where(expires_at: ..Time.current) }

  def release?
    kind == "release"
  end
end
