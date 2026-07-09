module Payments
  # Public API surface for the payments pack — the only constants reachable across
  # pack boundaries (D3). No-op in G0; domain entry points arrive with the domain.
  module Api
    module_function

    # Placeholder entry point so privacy enforcement has a real public surface
    # to check from day one.
    def noop = nil
  end
end
