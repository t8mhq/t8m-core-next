module Api
  module V1
    # S1-G3 · I4 — the POS sync boundary (stub implementation for the contract).
    # Auth (device token → RLS tenant scope) is established by RlsContextMiddleware;
    # this controller just refuses when there is no scope, and is idempotent by POS UUID.
    class SyncController < ActionController::API
      before_action :require_tenant

      # Batch up-sync. First sight of a uuid → processed; a replay → the original result.
      def sales
        sales = params.to_unsafe_h.fetch(:sales, [])
        render json: { results: sales.map { |sale| upsert(sale[:uuid] || sale["uuid"]) } }
      end

      # Down-sync snapshot: deltas + typed configuration (compiled promotion rulesets, etc.).
      def down
        render json: {
          contract_version: "1.0.0",
          updated_since: params[:updated_since],
          catalog: [],
          promotion_ruleset_version: "0",
          config: {}
        }
      end

      private

      def upsert(uuid)
        return { uuid: uuid, status: "replayed" } if SyncReceipt.exists?(uuid: uuid)

        SyncReceipt.create!(tenant_id: current_tenant, uuid: uuid, result: { status: "processed" })
        { uuid: uuid, status: "processed" }
      rescue ActiveRecord::RecordNotUnique
        { uuid: uuid, status: "replayed" } # concurrent replay — the unique index won
      end

      def current_tenant
        @current_tenant ||= ActiveRecord::Base.connection.select_value("SELECT app_tenant_id()")
      end

      def require_tenant
        return if current_tenant.present?

        render json: { code: "unauthorized", message: "device token required" }, status: :unauthorized
      end
    end
  end
end
