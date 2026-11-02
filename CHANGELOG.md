# Changelog

## 0.2.0 — 2026-11-02
### Added
- Structured handoff: `orca-bridge delegate --spec <file|->` / `task new` with JSON schema validation (`task_id`, `task_type`, `objective`, `allowed_files`, `required_changes`, `acceptance_criteria`, `verification_command`, `constraints`, `expected_report`, optional `isolate`, `max_retries`, `verify_timeout`, `allow_sensitive`, `mode`, `scenario`, `tukang_model`).
- Task state machine (PENDING, ASSIGNED, EXECUTING, VERIFYING, REVIEWING, APPROVED, REJECTED, FAILED) stored outside the repo, per-task lock, event log; `task assign|check|approve|reject|resume|revert|amend|fail|discard|diff|status|list|log`.
- Bridge-side verification on `report DONE --task`: runs the Mandor's verify command with timeout, records real exit code, checks the diff against the allowlist and sensitive-file patterns (including gitignored secrets), attaches compact `CHECK {...}` evidence to the report.
- Approval gate: refuses on scope violation, failed verify, no changes, BLOCKED state, or files changed after verification.
- Optional git-worktree isolation per task (`isolate: true`); changes reach the main tree only on approve.
- Verify-command detection (npm/pnpm/yarn/bun/cargo/go/pytest/deno/make) when the spec omits it; no detection = spec rejected.
- Deterministic routing: `pair bind|show|clear`, bindings written by `orca-pair`; unique title match or Orca split layout otherwise; ambiguous/missing = error. Self-send refused.
- Token tracker: `usage add|collect|report|compare`; omp session usage collected automatically as `actual`; estimates always labelled `estimated`.
- Benchmark harness (`bench/`), test suite (`tests/run.sh`, fake Orca CLI), `VERSION`, `orca-bridge version`.
- Installer: dependency checks, staged syntax validation, backups, symlink-safe replace, rollback on failure, user-edited skill files preserved (`.new`), `--force`, `--uninstall`.

### Changed
- `wait` exits 1 when idle is not confirmed (previously always printed "ready").
- `send`/`delegate`/`report` fail with non-zero exit when delivery fails.
- Legacy `delegate` no longer tells Tukang to run `npm test`; it requires `Allowed Files:` and `Verify Command:` unless `--force`; literal `\n` becomes a newline.
- `report` accepts `--task <id>` (or uses the single active task).
- `orca-pair`: generates `AGENTS.md` from the installed canonical `AGENTS.md` instead of an inline template that had drifted (it lacked the Anti-Handoff-Leak contract); binds pane handles; waits for spawned panes; retries Orca startup; background indexers fully silenced.
- Docs: removed the unmeasured ">85%" savings claim; documented the new protocol.

### Removed
- Arbitrary terminal fallbacks (`pool[0]`/`pool[1]`, fuzzy `/pi/` match that hit paths like `annnpii`).
