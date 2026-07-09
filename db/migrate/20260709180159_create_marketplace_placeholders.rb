# S1-G1 · I3 / D7 — marketplace placeholder tables so the three marketplace policies
# are real code against real tables. Columns grow in G5; the policies survive unchanged.
# Marketplace is a satellite (ADR-0004): these tables live outside the core packs.
class CreateMarketplacePlaceholders < ActiveRecord::Migration[8.1]
  include Rls::MigrationHelpers

  def change
    create_table :seller_profiles, id: :uuid do |t|
      t.references :seller_tenant, type: :uuid, null: false, foreign_key: { to_table: :tenants }
      t.string :listing_status, null: false, default: "draft"
      t.string :display_name
      t.timestamps
    end
    enable_marketplace_rls :seller_profiles, published_column: :listing_status

    create_table :marketplace_orders, id: :uuid do |t|
      t.references :seller_tenant, type: :uuid, null: false, foreign_key: { to_table: :tenants }
      t.uuid :buyer_id
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
    # No public predicate: buyer-facing reads go through projections later (D7).
    enable_marketplace_rls :marketplace_orders
  end
end
