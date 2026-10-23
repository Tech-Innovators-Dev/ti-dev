# 14. Self-verification and tests

## Intent

Fleet configuration drifts like code: a rule loses a load-bearing phrase, a guard is never wired, a roster row points at a deleted lane. A workspace linter and per-guard tests catch this mechanically, and CI runs them on every workspace change.

## Rules

1. Drive the linter from the manifest ([17](17-adoption-map.md)): every enabled module's pieces exist, are wired, and match it.
2. Prefer structural checks over literal phrase pins. Pin a phrase only where a measured fix has no structural signal.
3. Assert that retired features stay retired.
4. Write guard tests as tables of (case, command or payload, expected verdict).
5. Every guard suite covers a malformed payload, a stray field of the wrong type, a heredoc mentioning a forbidden command (must pass), and a quoted mention (must pass). Suites for deploy-capable guards also cover an unknown deploy target, which is treated as production and asks, and a shared deploy verb with a production target, which asks even though the staging form is allowed. Write-guard suites block every write when the stop flag is set or unreadable. The secret-scan guard blocks a secret in a staged diff without echoing it. An outward message asks ([19](19-security-trust-and-incidents.md)). Tracker-write suites ([18](18-task-management-and-tracker-sync.md)) cover a status change on a linked item (allowed), create (asks), delete (blocks), and malformed tracker text, which cannot change a verdict.
6. Use fakes, never live systems: fake OS metrics, fake session logs, fake claims held by a live process, a fake code-host CLI, a fake tracker endpoint, a fake message sink, throwaway git repos. Product test data follows [19](19-security-trust-and-incidents.md) rule 12.
7. The umbrella verify step discovers test suites instead of listing them.
8. Test the linter itself.
9. Send findings to the fleet designer, not product lanes. The designer runs the workspace linter after every change and on every proposal.

## Architecture

- **Workspace linter.**
  - Layout: no stray config from retired tools; the charter references the router.
  - Metadata: rule and procedure metadata is valid and names match.
  - Tiers ([12](12-model-policy-and-spend.md)): every role has a tier, every tier maps to an available model, and the strong set matches the manifest.
  - Lanes: preloads exist and respect the two-procedure cap; every roster row has a lane.
  - Context ([13](13-context-cards-and-memory.md)): always-loaded content stays within its size cap.
  - Wiring: every guard is runnable and wired; policy entries stay paired; the hygiene rule stays always loaded; the poteto-mode auto-load is wired to the session-start or first-prompt event where the platform supports it, otherwise the charter instructs it ([03](03-procedures.md)).
  - Fleet proposals ([15](15-scheduled-ops-and-governance.md)): fleet-proposal pull requests are not on the no-prompt merge list, the code-host write guard asks before merging one, and the headless run's tool allow-list has no merge or approve.
  - Tracker sync ([18](18-task-management-and-tracker-sync.md)): tracker create, close and field changes are never in allow unless the manifest's write policy records the owner's explicit choice; tracker deletes and bulk edits are always denied; the status map covers every internal task and bundle state; the field-ownership map is present.
  - Security ([19](19-security-trust-and-incidents.md)): no outward channel is in allow unless the manifest pre-approves it; every write guard reads the stop flag; the secret-scan guard is wired.
  - Platform capability map ([17](17-adoption-map.md)) is present.
  - Environment access ([04](04-rules.md)): no allow entry can match a production or unknown deploy, apply or data-write target (staging allow entries must be pinned to the staging target), except a shared deploy or apply verb whose repo-safety guard is wired, which the linter must confirm ([07](07-permission-tiers.md) rule 5); production reads appear in allow only when the manifest grants them.
  - Phrase pins on measured fixes, for example the code-host write guard's full-tip merge check, the repo-safety guard's protected-branch push parser, and no hard-coded home paths.
- **Table-driven suites**, one per guard and per stateful tool.
- **Umbrella verify step.** The context check, all suites, a lint of the real board, then the workspace linter.
- **CI job** running the umbrella step on every pull request to the workspace.
- **Emergency-stop drill**, scheduled ([15](15-scheduled-ops-and-governance.md)): set the stop flag in a sandbox and confirm every write guard blocks.

## Interactions

- Asserts the overview's wiring: guards ([06](06-guards-and-session-events.md)), tiers ([07](07-permission-tiers.md)), roster ([02](02-roster-and-agents.md)), rule phrases ([04](04-rules.md)), model policy ([12](12-model-policy-and-spend.md)), cards ([13](13-context-cards-and-memory.md)).
- Run by the fleet designer after every change and on every proposal, including those from the weekly fleet optimization run, by CI, and by the scheduled hygiene run ([15](15-scheduled-ops-and-governance.md)).

## Adapting it

- **Per project:** phrase pins generated from enabled modules, required cards, the CI provider.
- **Generate at setup:** one suite per enabled guard and an umbrella step. **Ask:** whether to add the CI job.

## Pitfalls

- Avoid an untested linter; a broken check passes silently.
- Avoid a hand-maintained suite list; the source skipped several suites and CI ran only part of the coverage.
- Avoid brittle phrase pins that break on harmless rewording.
- Avoid leaving launchers, reports and session-start content untested because they are not guards.
