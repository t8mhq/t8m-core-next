# S1-G2 · I6 — monthly expired-flag report. Release flags are temporary; this surfaces
# the ones past their expiry so they get removed instead of rotting.
namespace :flags do
  desc "Report expired feature flags (S1-G2 I6)"
  task expired: :environment do
    expired = FeatureFlag.expired.order(:expires_at)
    if expired.empty?
      puts "flags: no expired flags"
    else
      warn "flags: #{expired.count} expired flag(s) — remove or renew:"
      expired.each { |f| warn "  #{f.key} (#{f.kind}, owner #{f.owner || '?'}, expired #{f.expires_at})" }
    end
  end
end
