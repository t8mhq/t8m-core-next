# S1-G1 · I1/D3 — set the RLS context at the HTTP connection lease and GUARANTEE a
# reset on release. The ensure-block is the whole point: no context survives a request
# boundary, so a pooled connection reused by the next request starts clean (I1.2).
#
# Lives under lib/middleware (excluded from autoloading) and is required by
# config/application.rb, so the constant exists while the middleware stack is still
# mutable — referencing an autoloaded app/ constant there races Zeitwerk.
class RlsContextMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    ctx = RlsContextResolver.call(env)
    return @app.call(env) if ctx.nil?

    Rls.set(**ctx, local: false)
    begin
      @app.call(env)
    ensure
      Rls.reset
    end
  end
end
