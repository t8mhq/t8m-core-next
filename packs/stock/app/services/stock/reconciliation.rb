module Stock
  # S1-G2 · I4 — nightly reconciliation. Compares SUM(movements) to the derived
  # balances and reports divergences. It ALERTS, it never fixes (a fix would hide the
  # bug that produced the divergence). Runs under the tenant's scope.
  class Reconciliation
    Divergence = Struct.new(:product_id, :expected, :actual, keyword_init: true)

    def self.run
      sums = Stock::Movement.group(:product_id).sum(:delta)
      Stock::Balance.all.filter_map do |balance|
        expected = sums[balance.product_id] || 0
        next if expected == balance.balance

        Divergence.new(product_id: balance.product_id, expected: expected, actual: balance.balance)
      end
    end
  end
end
