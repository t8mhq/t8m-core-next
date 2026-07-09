# S1-G0 · D8 — Money lint (first version).
#
# Money is always integer cents (ADR-0001, core conventions). This lint fails CI
# on schema/migration column definitions that violate that rule:
#
#   * a column ending in `_cents` that is NOT an integer type
#   * a money-named column (token price|amount|fee|total) that is NOT `_cents`
#
# It scans committed migrations (db/migrate/*.rb) and db/schema.rb / db/*_schema.rb
# so both the durable schema and the change that introduces a violation are caught.
# G2 extends this lint; G0 creates it.

namespace :lint do
  desc "Fail on money columns that are not integer cents (D8)"
  task :money do
    require_relative "../money_lint"
    root = defined?(Rails) ? Rails.root : Pathname.new(Dir.pwd)
    violations = MoneyLint.scan(root)

    if violations.empty?
      puts "money lint: OK — no money columns violate the integer-cents rule"
    else
      warn "money lint: #{violations.size} violation(s) — money must be integer cents\n\n"
      violations.each { |v| warn "  #{v.location}\n    #{v.column} (#{v.type}) — #{v.reason}" }
      warn "\nFix: store monetary values as integer cents in a `*_cents` column (bigint/integer)."
      abort "money lint failed"
    end
  end
end
