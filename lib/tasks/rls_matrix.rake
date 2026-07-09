# S1-G1 · I5 — the named RLS policy matrix suite. Runs the tenant/grant/marketplace
# and job-guard tests as app_user and fails on any failure, error, OR skip — so a
# matrix test can never be "temporarily" pended out of the required check.
namespace :rls do
  desc "Run the RLS policy matrix suite (S1-G1 I5); fails on any skip"
  task :matrix do
    out = `bin/rails test test/rls test/jobs/scoped_job_test.rb 2>&1`
    puts out

    m = out.match(/(\d+) runs, \d+ assertions, (\d+) failures, (\d+) errors, (\d+) skips/)
    if m.nil?
      abort "rls:matrix: could not parse test results"
    elsif m[2].to_i.positive? || m[3].to_i.positive? || m[4].to_i.positive?
      abort "rls:matrix: #{m[2]} failures, #{m[3]} errors, #{m[4]} skips — the matrix must be all-green with zero skips"
    else
      puts "rls:matrix: OK — #{m[1]} tests, 0 failures, 0 errors, 0 skips"
    end
  end
end
