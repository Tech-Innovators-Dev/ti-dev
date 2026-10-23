# 10. Board and backlog engine

## Intent

One living board holds current state: in flight, blocked, needs the owner, next ask. A script owns its backlog section. The backlog engine triages loose work into tiers, bundles it, pins plans, dispatches workers, checks drift and seals bundles before a pull request. Status stays out of chat and deferred work stays durable.

## Rules

**Board**
1. Keep fixed sections: priorities, in flight, blocked, needs owner, deferred, backlog, next ask, decided, orphans.
2. End every status with one next step: what was done plus at most one owner action, or "nothing is waiting".
3. Check who holds a repo before editing its entries. Stay quiet when nothing moved.
4. Escalate blockers older than two days. Collapse resolved items to one line and archive the narrative.
5. Inject a trimmed board at session start.
6. Keep code-host issues at user-story level ([18](18-task-management-and-tracker-sync.md)). Development steps live on the board. File a defect once.

**Backlog**
7. Only the engine writes the backlog. Add work through it with a deferral reason ([04](04-rules.md)). Lint fails on hand edits, and a diff check keeps board edits inside their sections.
8. An entry shows title, repo, date, why, where to pick up, and the engine's task id, tier and reasons, state and bundle.

**Engine**
9. Classify each task as **clear**, **plan-required** or **human-only**, with reasons. The strictest trigger wins. Triggers are path patterns (schemas, migrations, IaC, signing) and text (keys, apply, hardware).
10. Bundle by evidence only: shared paths or issue. Cap tasks per bundle and active bundles. An exclusive repo takes one bundle; a rolling repo is shared, one commit per task.
11. Pin each plan by content hash; approval fails if it changed. A plan opens with a user story, bounds scope with repo-scoped file patterns, states design status for UI work, and ends with acceptance and an implementation prompt.
12. **Drift check:** re-classify each task's actual diff against its tier.
13. **Seal** is the only gate into review: every task committed, no new triggers, no files outside the plan. It prints the required stamps.
14. Hold a bundle while a live session claims one of its repos on another branch.
15. Engine state transitions emit tracker-sync events through the status map ([18](18-task-management-and-tracker-sync.md)).
16. One engine run at a time, under a session lock that goes stale. Dispatch can be restored to prior branches.

**Flows**
17. **Tick.** A scout reads the backlog on the light tier if enabled, otherwise standard; the engine clusters; a planner drafts on the strong tier; and one approval question goes to the owner.
18. **Build** (main session only). Dispatch workers, drift-check, seal, open a draft pull request, collect stamps, merge. Workers never merge. The main session deploys to staging and tests there; production deploys stay the owner's approval ([05](05-ship-bar-and-stamps.md)).
19. Route each repo to a lane and model tier. Retry a blocked worker on the strong tier.
20. **Worker contract:** a fixed prompt, and a structured report of status, commit, files and items left open, handled by fixed rules.

## Architecture

- **Board** plus a verbatim archive. Per-project boards stay living documents, and their task state feeds the fleet ledger. The cross-project board is generated from the ledger. The backlog engine writes ledger task records on the orchestrator's behalf ([18](18-task-management-and-tracker-sync.md)).
- **Backlog engine.** A deterministic script owning the classifier, task and bundle state machines, clustering, plans, dispatch, drift, seal and restore. Tasks move from triaged through awaiting approval, ready, in progress, committed and PR open to resolved, with blocked and parked as side states. Bundles move from proposed through building, sealed and PR open to merged or abandoned.
- **Run history.** A locked, untracked sidecar.
- **Procedures** for the board and the engine, with rubric, routing and worker contract ([03](03-procedures.md)).

## Interactions

- Reads peer claims ([08](08-peer-sessions-and-handoffs.md)) and the branch registry ([09](09-branching-and-cleanup.md)).
- Seal names stamps ([05](05-ship-bar-and-stamps.md)). Routing uses the roster and model policy ([02](02-roster-and-agents.md), [12](12-model-policy-and-spend.md)).
- CI tests the engine and lints the real board ([14](14-self-verification-and-tests.md)).
- An approved bundle that names a dev-environment branch switch approves that switch.

## Adapting it

- Agents call the engine; the engine owns state.
- **Per project:** board sections, classifier triggers, repo map, issue pattern, routing table, stamp policy, UI directories. Keep triggers and stamp policy in the manifest ([17](17-adoption-map.md)).
- **At setup,** detect schema, migration, IaC, signing and UI paths. Tracker detection belongs to [18](18-task-management-and-tracker-sync.md). Ask for the project name, whether to enable the engine or just the board, bundle caps, and which tasks are human-only.

## Pitfalls

- Avoid an unbounded board. Add a size limit to lint that prompts archiving.
- Avoid a classifier in code. Use config.
