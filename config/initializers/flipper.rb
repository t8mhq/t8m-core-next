# S1-G2 · I6 — Flipper on the ActiveRecord adapter (the flag DEFAULT layer).
require "flipper/adapters/active_record"

Flipper.configure do |config|
  config.adapter { Flipper::Adapters::ActiveRecord.new }
end
