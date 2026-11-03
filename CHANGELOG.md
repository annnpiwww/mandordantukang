# Changelog

## 0.3.0 — 2026-11-03
### Added
- Multi-Agent Squad Orchestration (v2): launcher `orca-squad` untuk 1 Mandor (`omp`) + 3 Tukang Spesialis (`agy`: UI/UX, Coder, Security).
- Targeted worker routing di `orca-bridge`: `delegate --to <ui|coder|sec>`, `pair bind <role> <handle>`, dan support `target_worker` di JSON spec.
- Aturan spesialis Tukang: `rules/tukang-ui.md` (UI/UX & micro-motion), `rules/tukang-coder.md` (logic & minimal diff), `rules/tukang-sec.md` (7 OWASP guards & QA).
- Bilingual Token Optimization Protocol (Ponytail Lever 3): spec Mandor $\rightarrow$ Tukang wajib English (~30–40% token saving); output Mandor $\rightarrow$ User tetap Indo Gaul Caveman Ultra.
- Dedicated skill definition `mandortukangv2` (`SKILL_V2.md`).
- On-demand Mandor skills: `skills/principal-workflow.md` (DISCOVER sampai LEARN, routing per kelas, planning arsitektur), `skills/product-intelligence.md`, `skills/uiux-intelligence.md`. Hasil planning dipetakan langsung ke field spec yang sudah ada; kontrak bridge tidak berubah.
- Test `t_routing_squad_workers` dan `t_skill_refs_resolve`: verifikasi binding multi-worker dan integritas referensi file.

### Changed
- `rules/mandor.md`, `CLAUDE.md`, `SKILL.md`: Mandor wajib memahami masalah asli dan membantah usulan user yang lemah (risiko + bukti + alternatif); routing ke skill on-demand. SIMPLE tidak memuat apa pun.

### Limitations
- Skill baru berupa instruksi prompt, tidak di-enforce bridge. Dampak ke kualitas dan token belum dibenchmark.

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
- Global activation: `install.sh --global-rules` writes marker-delimited Mandor rules (`rules/mandor.md`) into `~/.omp/agent/RULES.md` and Tukang rules (`rules/tukang.md`) into `~/.gemini/GEMINI.md`, links the skill for agy; idempotent, backed up, removed by `--uninstall`. Unbalanced markers abort instead of truncating.
- Upgrade from v0.1 installs: skill files identical to any released version are upgraded in place (no manifest needed); edited ones still become `.new`.
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
