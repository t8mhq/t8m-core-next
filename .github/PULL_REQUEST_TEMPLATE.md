<!-- S1-G0 · process — every PR traces to the issue/ADR it implements. -->

## Implements
<!-- Required. The issue and/or ADR section this PR implements, e.g.
     Implements: #123 (ADR-0001 §decision). One issue per PR — never grouped. -->
Implements:

## Summary
<!-- What changed and why. -->

## Evidence
<!-- CI run links; for gate work, the red-test run(s) captured then reverted;
     screenshots for board/protection changes. -->

## Checklist
- [ ] Conventional Commit title
- [ ] Packwerk `check` + `validate` green; no `package_todo.yml`
- [ ] Money lint green
- [ ] Tests green (suite connects as `app_user`)
