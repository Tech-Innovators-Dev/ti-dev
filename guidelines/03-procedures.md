# 03. Procedures

## Intent

Procedures are on-demand playbooks that hold formats and step lists. They keep the charter thin: the charter says a rule exists, the procedure says how to carry it out. Where a procedure fronts a script, the procedure and the state engine stay in step.

## Rules

1. Load procedures on demand, not always. Each has a name and a trigger sentence ("Use when ...") that lists the situations and alternative phrasings where it applies.
2. Keep bodies short and lane-agnostic. Move long sub-procedures and templates into references loaded only when the body points to them.
3. Keep a rule index mapping each standing rule to the procedure that holds its format, so agents load it instead of improvising.
4. Never let a procedure mutate script-owned state by hand; it calls the script.
5. Keep current repo state out of procedures. Open items belong on the board.
6. Never hard-code attribution or model identity in a procedure. That comes from the platform.
7. Ship a small core and let setup enable the rest. Measure invocations and prune what is never used.

## Architecture

**Process core:**

| Procedure | Produces | Key rules |
|---|---|---|
| plan-then-implement | PLAN READY packet: Scope (in/out, one owner, tracking issue), Contracts (frozen or a named wait), Touch list (repos and paths), Acceptance (tests, authz parity, local-stack smoke, staging smoke), Implement prompt (one fold, success criteria) | The planning step escalates to the strong tier ([12](12-model-policy-and-spend.md)). One fold per pass. A wait is a named blocker, not a vague dependency. |
| scope-lock | SCOPE LOCK block: In, Out, Owners (exactly one per item), Owner decides, Done when | A re-lock is a new comment. Lanes stop renegotiating mid-build. |
| needs-owner-decision | One question, 2–4 real options, one recommendation, what stays blocked, "if you agree, next action is X" | Only for product, cost, risk or irreversible choices. Replaces hedging. |
| lane-handoffs | Boundary matrix of who owns what; the parallel-kick rule; the design gate | Kick Design and API in the same turn once gates lock. Only visual UI work waits on design approval. |
| merge-ready-checklist | MERGE-READY / NOT READY / MERGE BATCH with the box list | See [05](05-ship-bar-and-stamps.md). |
| verify-ship-gate | Stamp template and evidence bar | See [05](05-ship-bar-and-stamps.md). |
| board | Board read and update | End each status with one next step. Escalate a blocker older than two days. Collapse resolved items. See [10](10-board-and-backlog-engine.md). |
| closeout | Merge, switch, pull and cleanup record, plus the `Left open:` list | Verify, merge by the branch model, fast-forward only, safe-class cleanup, release, board, archive check. Never force; idempotent; always reports. Use when a session's work completes or the owner asks to clean up, close out or wrap up. See [09](09-branching-and-cleanup.md). |
| handoff | Dated handoff note, index line, peer note | Replaces context compaction for long sessions. See [08](08-peer-sessions-and-handoffs.md). |
| new-session | Brief from a template, launched planning-only | Capacity and duplicate refusals; safe close. See [08](08-peer-sessions-and-handoffs.md). |
| backlog-engine | Add, triage, bundle, plan, dispatch, seal (flows: add, tick, build) | Every mutation goes through the engine. See [10](10-board-and-backlog-engine.md). |
| tracker-sync | Idempotent status and link updates to code-host issues and the business tracker, driven by task state changes | Business language only. Follows the tracker write policy for linked items. Fails open: a tracker outage queues the sync for retry and never blocks work. See [18](18-task-management-and-tracker-sync.md). |
| fleet-review | Ranked findings on spend, drift, compliance, wasted work, config rot, context quality | Never a config change. Findings go to the fleet designer, who drafts an owner-approved proposal in the weekly optimization run ([15](15-scheduled-ops-and-governance.md)). See [12](12-model-policy-and-spend.md). |
| deep-review gate | Rare, owner-gated harsh maintainability review run by the verifier on the strong tier | Never substitutes for ordinary stamps. |
| implementation-discipline (poteto-mode) | The platform's version or port, auto-loaded at the first implementation prompt | Plan and checkpoint; data shape first; smallest change; prove it on the real artifact; fix root causes. On by default when available, never a hard dependency. Preload: [02](02-roster-and-agents.md); wiring: [06](06-guards-and-session-events.md); no port: setup offers one; a port checks the source license and keeps attribution ([19](19-security-trust-and-incidents.md)). |
| emergency-stop | Pause every session and scheduled run, freeze writes, set the stop flag | One documented command with manual fallback. See [19](19-security-trust-and-incidents.md). |
| incident-response | Declare, gather evidence read-only, propose rollback or fix, postmortem | Rollback is a production write; the owner approves. See [19](19-security-trust-and-incidents.md). |

**Project engineering disciplines (enabled at setup to fit the stack):**
- **authz-parity.** One role × action × scope matrix, frozen before either side builds. A hidden button over an open endpoint is a security defect; every hidden control needs a proven API denial.
- **api-error-matrix.** Each endpoint declares status and code, mapped to a kind and then a message. Network and 5xx rows are always present. The server throws coded errors, the client maps them once in one table, pages branch on kind, no catch-all. Test both ends and fault the browser with request interception.
- **mockup-parity.** The built UI matches the named design source of truth at a named SHA, including empty and error states. Screenshots go on a pull request only after design is final.
- **data-ship-audit.** Field inventory, expand/contract migration plan, query cost, end-to-end lineage proof (storage, contract, payload, consumer).
- **docs-fold-report.** Verdict `FOLDED`, `ALREADY COVERED` or `BLOCKED`. Check for duplicate docs changes. Stay quiet when nothing merged.
- **admin-page-rules.** Inventory fields before inventing any. Status is required on create and edit. Structured metadata is exposed only as named keys.

## Interactions

- Script-backed procedures: backlog-engine, handoff, new-session, merge-ready-checklist, closeout and fleet-review call the workspace's state tools rather than editing state ([08](08-peer-sessions-and-handoffs.md), [09](09-branching-and-cleanup.md), [10](10-board-and-backlog-engine.md)).
- The handoff procedure pairs with the compaction checkpoint and the session-start handoff listing ([06](06-guards-and-session-events.md)).
- Lanes preload at most two procedures ([02](02-roster-and-agents.md)). Rules point here for procedure ([04](04-rules.md)).
- The usage report counts invocations and lists procedures never used ([12](12-model-policy-and-spend.md)).

## Adapting it

- **Generic:** every process-core body, the PLAN READY and SCOPE LOCK formats, the decision-ask format, the stamp templates.
- **Per project:** the owner's title, the board location and section names, lane names in the boundary matrix, error registry locations, the deploy pipeline table, whether the design gate applies.
- **Detect at setup:** a UI (design gate, mockup-parity), an API (authz-parity, error matrix), a database (data-ship-audit), a docs site (docs-fold-report).
- **Ask at setup:** which project engineering disciplines to enable, whether to install or port poteto-mode when the platform has no version, the issue tracker, where design source-of-truth artifacts live. Generate an index of enabled procedures and why.
- Map procedures onto whatever on-demand instruction mechanism your platform has. If it has none, keep them as files the charter tells agents to read.
- Product smoke, screenshot, hardware and legacy-orientation procedures are not generic ([16](16-excluded-product-specific.md)).

## Pitfalls

- Avoid "known gaps" sections inside procedures; they describe repo state and go stale.
- Avoid shipping every procedure by default; many go unused.
- Avoid model-specific attribution lines inside worker contracts.
