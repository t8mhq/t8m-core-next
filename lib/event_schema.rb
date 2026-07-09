# S1-G2 · I3 / D6 — payload schema registry. One JSON Schema per event_type@vN under
# docs/events/. publish validates against the declared schema in dev/test.
#
# Stage-1 posture: validation applies to event types that HAVE a registered schema;
# unregistered types are skipped (a mandatory-registration check is follow-up debt).
# A payload that violates its registered schema RAISES (I3.2).
module EventSchema
  class Invalid < StandardError; end

  module_function

  def dir
    (defined?(Rails) ? Rails.root : Pathname.new(Dir.pwd)).join("docs/events")
  end

  def registered?(event_type)
    dir.join("#{event_type}.json").exist?
  end

  def validate!(event_type, payload)
    return unless registered?(event_type)

    schema = JSONSchemer.schema(JSON.parse(dir.join("#{event_type}.json").read))
    errors = schema.validate(payload.deep_stringify_keys).map { |e| e["error"] || e.to_s }
    return if errors.empty?

    raise Invalid, "payload for #{event_type} violates its schema: #{errors.join('; ')}"
  end

  # Enforced in dev/test; production trusts validated producers (perf).
  def enabled?
    defined?(Rails) && Rails.env.local?
  end
end
