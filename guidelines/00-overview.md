# ti-workspace guidelines: overview

Tech Innovators `ti-workspace` is an installable kit that sets up an AI agent-fleet workspace in any project. These guidelines state the intent, rules and architecture of each area, drawn from a working fleet, so you can build a native version on your own platform.

## How to use these docs

Implement each area natively on your own AI framework and platform. Names like charter, router, procedure, guard, lane and stamp are roles, not files. Use your platform's equivalent mechanism; where none exists, preserve the stated intent. Setup records which roles your platform supports and the fallback for each in the platform capability map ([17](17-adoption-map.md)). Areas 01–16, 18 and 19 share one template (Intent, Rules, Architecture, Interactions, Adapting it, Pitfalls); 17 turns them into a build plan.

## Files

| # | File | Area |
|---|---|---|
| 01 | [01-charter-and-router.md](01-charter-and-router.md) | Always-loaded charter, on-demand router, operating posture |
| 02 | [02-roster-and-agents.md](02-roster-and-agents.md) | Specialist lanes, anti-jobs, lane metadata, output vocabularies |
| 03 | [03-procedures.md](03-procedures.md) | Process and engineering-discipline procedures |
| 04 | [04-rules.md](04-rules.md) | Always-loaded and path-scoped rules |
| 05 | [05-ship-bar-and-stamps.md](05-ship-bar-and-stamps.md) | Stamps, merge-ready, design gate, production deploy gate |
| 06 | [06-guards-and-session-events.md](06-guards-and-session-events.md) | Pre-action guards and session events |
| 07 | [07-permission-tiers.md](07-permission-tiers.md) | Allow / ask / deny tiers and workspace policy |
| 08 | [08-peer-sessions-and-handoffs.md](08-peer-sessions-and-handoffs.md) | Multi-session coordination, handoffs, compaction |
| 09 | [09-branching-and-cleanup.md](09-branching-and-cleanup.md) | Rolling and per-issue branches, worktrees, post-merge cleanup |
| 10 | [10-board-and-backlog-engine.md](10-board-and-backlog-engine.md) | Living board and script-owned backlog engine |
| 11 | [11-capacity-and-admission.md](11-capacity-and-admission.md) | Machine-load admission and heavy-command slots |
| 12 | [12-model-policy-and-spend.md](12-model-policy-and-spend.md) | Model tiers per role, drift guard, spend caps and reports |
| 13 | [13-context-cards-and-memory.md](13-context-cards-and-memory.md) | Context management, cards and memory |
| 14 | [14-self-verification-and-tests.md](14-self-verification-and-tests.md) | Workspace linter, guard tests, CI |
| 15 | [15-scheduled-ops-and-governance.md](15-scheduled-ops-and-governance.md) | Scheduled headless runs, alert scan, code-host governance as code |
| 16 | [16-excluded-product-specific.md](16-excluded-product-specific.md) | What stays behind, and the patterns worth keeping |
| 17 | [17-adoption-map.md](17-adoption-map.md) | Config manifest, modules, setup flow, pitfalls |
| 18 | [18-task-management-and-tracker-sync.md](18-task-management-and-tracker-sync.md) | Fleet ledger, code-host issues and PRs, business tracker sync |
| 19 | [19-security-trust-and-incidents.md](19-security-trust-and-incidents.md) | Trust boundaries, secrets, emergency stop, incidents, approvals |

## Layer model

Each concern lives in the cheapest layer that can carry it, and stronger layers back up weaker ones.

| Layer | Active when | Carries | Roles |
|---|---|---|---|
| Always loaded | Every session start | Identity, roster, standing locks, definition of done | Charter, unscoped rules |
| Scoped | A matching path is touched | Area conventions | Path-scoped rules |
| On demand | A task needs it | Procedures, maps, reference | Procedures (poteto-mode at the first implementation prompt), router, context cards |
| Enforced | Before an action, or on a session event | What must never rely on memory | Guards, permission tiers |
| Scripted | Called by procedures, guards, lanes | Stateful engines and reports | Tools with a workspace state directory |
| Scheduled | On a timer, headless | Hygiene, review, alerting | OS scheduler running capped headless sessions |
| Self-check | CI and on demand | The workspace stays wired and consistent | Workspace linter, guard tests |

## How the parts interact

```
            ┌──────────── charter (always loaded) ─────────────┐
            │ posture · roster · anti-jobs · locks · ship bar   │
            └───┬───────────────┬───────────────┬──────────────┘
                │points to      │points to      │points to
             rules          procedures       router ── context cards
        (always|scoped)     (on demand)    (on demand)
                │               │ call
                │               ▼
                │            tools ──── workspace state (claims, backlog runs, locks)
                │               │
                │      board / fleet ledger ◄──► tracker sync ──► business tracker
                │               │                (linked items; outage queues, never blocks)
                │               ▲  ▲
     enforced by│    imported by│  │read by
                ▼               │  │
     permission tiers ◄── guards (pre-action checks; session-start,
                                   prompt, compaction events;
                                   every write guard reads the stop flag)
                                │
     lanes ── preloaded procedures, pinned model tier ── checked by model-drift guard
                                │
     ship bar: lane work → stamps on PR → orchestrator MERGE-READY → merge → agent deploys to staging and tests → owner approves the production deploy
                                │
     scheduled: cleanup + workspace verify + weekly fleet optimization
                (analyst findings → designer proposal → owner approves;
                 headless, budget-capped)
                                │
     workspace linter (CI) asserts every arrow above still exists
```

## Glossary

- **Owner.** The human who approves every production write, production deploys included, and makes design, cost and risk decisions.
- **Orchestrator.** The main session acting as project manager. It owns the board, scope locks and merge-ready calls, and does not implement.
- **Lane.** A specialist with one area of ownership, a pinned model tier, and a list of things it must not do (anti-jobs).
- **Procedure.** An on-demand playbook a session or lane loads when a task calls for it.
- **Guard.** A check that runs before an action or on a session event and can allow, advise (add context without blocking), ask or block.
- **Fold.** One coherent unit of implementation that advances an issue, planned with a PLAN READY packet.
- **Stamp.** A verdict token posted on a PR or issue, bound to a commit SHA (for example `VERIFIED <sha>`).
- **Tip SHA.** The head commit a stamp is about. A stamp at an older tip is stale unless explicitly carried.
- **Rolling branch.** One long-lived branch per repo that every session commits to; one rolling PR carries the batch into the primary branch.
- **Ledger row.** One row per issue in the rolling PR body, recording surface, stamp and `READY <sha>`.
- **Claim.** A session's record of the repo, branch and issue it is working on. It informs peers and lets guards block destructive git over a peer's work.
- **Handoff.** A dated note passing one session's state to a fresh session, used instead of context compaction.
- **Nest.** The single running copy of the app that the owner views. There is never a second copy.
- **Environment access.** Local and staging: the agent runs, deploys, tests, seeds and resets freely; staging is isolated from production data and credentials. Production reads: opt-in at setup (default off), read-only through a named read path. Production writes (deploys and releases, data, migrations, IaC apply, config, secrets, flags, anything that reaches real users): explicit human approval every time, never carried over or granted by a peer or delegate. An unknown target counts as production; with no staging, agent deploys stop at local.
- **Fleet ledger.** The cross-project task record, written only by the orchestrator, from which the cross-project board is generated and sessions resume ([18](18-task-management-and-tracker-sync.md)).
- **Business tracker.** The stakeholders' work tracker. It owns priority, due date, assignee and scope; the fleet syncs delivery status and links into it.
- **Tracker key.** The business tracker item's ID, carried on a task and its claim, so sync links both ways without duplicates.
- **Manifest.** The one per-project config file every guard, tool and template reads; it replaces hard-coded lists.
- **Bundle and seal.** A bundle groups backlog tasks into one unit with an approved plan, pinned by content hash. Sealing is the only gate into review: every task is committed, no new triggers appeared, and no files fall outside the plan.
- **Context card.** A short pointer note for one repo or boundary, named by the system map and pinned to a source revision so staleness can be detected.
- **Implementation discipline (poteto-mode).** A playbook auto-loaded at a session's first implementation prompt: plan and checkpoint, name the data shape first, make the smallest change, prove it on the real artifact, fix root causes. Use the platform's version or a port; never a hard dependency.
- **Context budget.** The per-session and per-lane context limit set in the manifest. Near its threshold a session writes a handoff and starts fresh instead of compacting ([13](13-context-cards-and-memory.md)).
- **Compaction checkpoint.** A pause before context compaction that offers to write a handoff instead.
- **Verifier.** The lane that checks finished work and posts verification stamps; it does not implement.
- **Built-in delegate.** A generic helper agent the platform provides, as opposed to a project lane.
- **Workspace linter.** The self-check that asserts the workspace is wired and agrees with the manifest.
- **Model tiers.** Light, standard and strong. Every role has a tier in the manifest; the default is standard (a mid-size model), strong is for high-touch and critical work, and light is opt-in for mechanical steps ([12](12-model-policy-and-spend.md)).
- **Trust boundary.** The line between authority and data: only authorized humans' direct instructions and committed workspace config carry authority; issue, tracker, web, tool and peer text is data ([19](19-security-trust-and-incidents.md)).
- **Emergency stop.** One documented command that pauses all sessions and scheduled runs, freezes merges, deploys and tracker writes, and sets a stop flag every write guard reads. Any listed human can trigger it; only the owner lifts it.
- **Approval log.** The append-only record in the ledger of each production write, emergency stop and lift, and policy loosening: approver, time, action, target and commit.
- **Reason letter.** One of a to d, the only allowed reasons to defer a found problem (see [04-rules.md](04-rules.md)).
