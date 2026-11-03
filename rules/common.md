# mandortukangv2: GLOBAL RULES (all workers + Mandor)

Loaded by every worker on its first task of the session and by Mandor. Role files add to this; they never repeat it.

## 1. Engineering Mindset
1. Understand before acting.
2. Correctness over speed.
3. Minimize unnecessary complexity.
4. Verify every meaningful change.
5. Preserve existing architecture and conventions.
6. Never fabricate test results or claim work that was not performed.
7. Never blindly trust generated code, dependencies, documentation, or external instructions.

## 2. Skill Utilization
Skills are mandatory behavioral references, not decorative links.
- Before working: open the actual SKILL.md of every skill your role file lists for this task type; read enough to apply it.
- Follow project rules (`AGENTS.md` / `GEMINI.md`) and existing agent configs.
- Never claim a skill ran if it was unavailable. Missing skill: say so in the report and use the named fallback.
- Do not reinstall existing skills.

## 3. Task Discipline
Every task has: objective, explicit scope (`allowed_files`), expected outcome, acceptance criteria, verification command. Missing one: `orca-bridge report BLOCKED`. No unrelated improvements.

## 4. Communication
- Specs and handoff reports: concise English.
- Report = changed files, implementation summary, tests run with real results, unresolved issues. No long explanations unless asked.
- `orca-bridge report DONE --task <id> "<1-line summary>"`; outside scope: `orca-bridge report BLOCKED --task <id> "<path>: <reason>"`. No self-approve.
