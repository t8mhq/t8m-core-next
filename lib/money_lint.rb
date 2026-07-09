# S1-G0 · D8 — Money lint scanner (plain Ruby, no Rails dependency).
#
# Rules (money is always integer cents):
#   A. A money-named column (snake_case token in {price, amount, fee, total})
#      that does NOT end in `_cents` is a violation (naming: use *_cents).
#   B. A column ending in `_cents` whose type is not an integer type
#      (integer/bigint) is a violation (type: cents must be integer).
#
# Scans db/migrate/*.rb and db/schema.rb / db/*_schema.rb. Recognizes:
#   t.decimal "unit_price"      /  t.integer :total_cents
#   add_column :orders, :fee, :decimal
require "pathname"

module MoneyLint
  MONEY_TOKENS = %w[price amount fee total].freeze
  INTEGER_TYPES = %w[integer bigint].freeze
  CENTS_SUFFIX = /_cents\z/

  Violation = Struct.new(:file, :line, :column, :type, :reason) do
    def location = "#{file}:#{line}"
  end

  # `t.<type> "name"` / `t.<type> :name`  (schema.rb and change-block migrations)
  TABLE_COL = /\bt\.(\w+)\s+["':]([a-z0-9_]+)/
  # `add_column :table, :name, :type`
  ADD_COL = /\badd_column\s+[:"'][a-z0-9_]+["']?\s*,\s*["':]([a-z0-9_]+)["']?\s*,\s*[:"']([a-z0-9_]+)/

  # Column definition helpers that are not real types — skip them.
  NON_TYPES = %w[index timestamps references belongs_to check_constraint].freeze

  def self.scan(root)
    root = Pathname.new(root)
    files = Dir[root.join("db/migrate/*.rb")] + Dir[root.join("db/*schema.rb")]
    files.uniq.sort.flat_map { |path| scan_file(Pathname.new(path)) }
  end

  def self.scan_file(path)
    violations = []
    path.each_line.with_index(1) do |line, lineno|
      each_column(line) do |name, type|
        reason = violation_for(name, type)
        violations << Violation.new(rel(path), lineno, name, type, reason) if reason
      end
    end
    violations
  end

  def self.each_column(line)
    if (m = ADD_COL.match(line))
      name, type = m[1], m[2]
      yield(name, type) unless NON_TYPES.include?(type)
    elsif (m = TABLE_COL.match(line))
      type, name = m[1], m[2]
      yield(name, type) unless NON_TYPES.include?(type)
    end
  end

  # Returns a reason string if (name, type) violates the rule, else nil.
  def self.violation_for(name, type)
    money_named = (name.split("_") & MONEY_TOKENS).any?
    cents = CENTS_SUFFIX.match?(name)

    if cents && !INTEGER_TYPES.include?(type)
      "columns ending in _cents must be an integer type, got #{type}"
    elsif money_named && !cents
      "money-named column must be stored as integer cents (rename to #{name}_cents, type bigint)"
    end
  end

  def self.rel(path)
    path.to_s.sub(%r{\A.*/(db/)}, '\1')
  end
end
