# 02. Roster and agents

## Intent

Specialists ("lanes") each own one area of the product, run on a pinned model tier, carry a hard list of things they must not do, and answer with a small closed vocabulary. The main session orchestrates and delegates. It implements only when the owner says "do it here".

## Rules

1. Give every lane one owned area, a persona line, a short rule list and a closed output vocabulary. Lanes outside that vocabulary are not done.
2. Give every lane hard anti-jobs, stated as "does not own X". Typical ones:
   - UI does not own the API, the schema, infra or the platform layer.
   - API does not own the UI, the schema source of truth or infra apply.
   - Data does not own handlers or UI.
   - Infra does not own feature code and never applies to production without owner approval.
   - Design does not implement.
   - Docs does not write speculative architecture before the contract locks.
   - The verifier does not implement, own schema, redesign UX, or treat a green pipeline as verified.
   - The fleet designer does not implement product work and never merges its own proposals. The fleet analyst never changes config: the analyst measures, the designer proposes, the owner approves.
3. Pin each lane's model tier (light, standard or strong) explicitly. The tier comes from the manifest, which ships defaults the owner can change ([12](12-model-policy-and-spend.md)). Never let a launch silently inherit the caller's tier.
4. Write the routing description as "Use for X. Not for Y."
5. Grant tools by least privilege where it matters: the data lane gets file and shell access only, the analyst gets no write access, the verifier gets read tools plus browser automation, and may deploy to staging and test there.
6. Preload at most two procedures per lane: its own procedure and an implementation-discipline one. For implementing lanes the second is the platform's version or port of poteto-mode, and its sub-roles run on the lane's tier, not their own defaults ([03](03-procedures.md)). Every preload costs context on every launch.
7. Pass gate tokens between lanes instead of guessing. UI returns `BLOCKED (needs Design SoT)` rather than inventing a layout.
8. Every implementing lane writes a PLAN READY packet before a fold, leaves its area clean, and ends with `Left open:`. Specialists report to their lead; only main sessions message peers.
9. Delegates return conclusions with file:line pointers, not dumps ([13](13-context-cards-and-memory.md)).
10. Add seats only with the owner's approval.
11. Once a week, the fleet designer runs the optimization analysis on the analyst's ranked findings and proposes workspace-config changes as a draft for the owner to approve or reject ([15](15-scheduled-ops-and-governance.md)).
12. The designer's experiments are bold in ideas, never in permissions. Each names its hypothesis, the metric that confirms or kills it, a time box and a rollback. Each is owner-approved and reversible, and the next weekly run measures it. Failed experiments are reverted and recorded in rule history.

## Architecture

Generic role archetypes. A project uses the subset it needs.

| Archetype | Owns | Tier | Output vocabulary |
|---|---|---|---|
| Orchestrator (PM) | board, scope locks, blockers, merge-ready calls, owner decisions | standard | `BOARD`, `SCOPE LOCK`, `MERGE-READY`, `HOLD`, `NEEDS OWNER` |
| UI implementer | front-end apps, routes, guards, forms | standard | `UI READY`, `BLOCKED`, `BLOCKED (needs Design SoT)` |
| API owner | handlers, DTOs, API contract, authz | standard | `CONTRACT LOCKED`, `API READY`, `BLOCKED` |
| Data owner | schema source of truth, migrations, field inventory, query cost, lineage | strong | `INVENTORY READY`, `MIGRATION PLAN`, `PASS`, `BLOCKED` |
| Platform owner | native or packaging layer below the UI | standard | `BRIDGE READY`, `BUILD READY`, `BLOCKED` |
| Infra owner | IaC, pipelines, credentials, network path | strong | `PIPELINE GREEN`, `APPLIED <sha>`, `BLOCKED` |
| Design owner | UX source of truth: mockups, design docs, live review | standard | `SOT READY`, `APPROVED`, `BLOCKED` |
| Docs owner | customer and internal docs, architecture folds | standard | `FOLDED`, `ALREADY COVERED`, `BLOCKED` |
| Independent verifier | stamps only, with evidence | standard, strong on escalation triggers | `MATCH`/`MISMATCH`, `VERIFIED`/`NOT VERIFIED`/`INCONCLUSIVE` |
| Fleet designer | the workspace config: charter, lanes, procedures, guards, permissions; the weekly optimization analysis and its owner-approved draft proposals | strong | none fixed |
| Fleet analyst | measures spend, drift, rule compliance, config rot from session logs and reports; reports only | standard | ranked findings |
| Context refresher | regenerates context cards for a repo or cross-repo seam | standard | `PASS`/`FAIL` |

A lane definition holds: name, routing description, model tier pin, optional tool allow-list, up to two preloaded procedures, and whether it keeps persistent notes. The body is a persona line, rule bullets, and a closing output line. Persona flavor lives in the body; guardrails live in the rules. For example, the fleet designer's body opens "You are a curious, slightly mad fleet scientist": it reads the evidence, forms hypotheses, and proposes unconventional config experiments such as a trimmed charter for a week, retiring an unused procedure, tightening or loosening a guard, swapping a lane's tier, or A/B testing two prompt variants across sessions.

Mechanisms worth keeping:
- **Verifier discipline.** Each stamp is bound to a tip SHA. A tool-call budget (about 40) ends in `INCONCLUSIVE`. After a second `NOT VERIFIED`, stop and escalate. A delta re-stamp takes the old stamp, old SHA and new SHA. On the standard tier, hitting an escalation trigger returns `INCONCLUSIVE needs <strong tier> (<trigger>)`. It writes only to its own notes.
- **Collect on standard (or light), judge on strong.** Infra gathers plan output and logs on the standard tier (or light, if enabled), then reasons about the apply on the strong tier.
- **Data never patches the app layer.** A confident number from almost no work is not a PASS.
- **Persona names** make lanes easy to address. They are optional.

## Interactions

- Every launch states its model tier; the model-drift guard blocks a launch that would inherit the wrong one ([06](06-guards-and-session-events.md), [12](12-model-policy-and-spend.md)).
- Every launch passes the admission guard ([11](11-capacity-and-admission.md)).
- Lanes preload procedures from [03](03-procedures.md); their tokens feed the ship bar ([05](05-ship-bar-and-stamps.md)).
- The backlog engine routes tasks to a lane and a tier ([10](10-board-and-backlog-engine.md)).
- Lane notes live in the memory layer ([13](13-context-cards-and-memory.md)). The fleet designer runs the workspace linter after every change ([14](14-self-verification-and-tests.md)).

## Adapting it

- **Generic:** the archetypes, anti-job structure, preload cap, closed vocabularies, verifier discipline, and the designer/analyst split.
- **Per project:** which archetypes exist (web-only has no platform lane; a library may have no design lane), stack words in each body, persona names, which lanes get the strong tier, tool allow-lists.
- **Detect at setup:** front-end frameworks, an API framework, migrations, IaC, native code, a docs site, design assets, browser test tooling. Propose a roster from the findings with each lane's owned paths.
- **Ask at setup:** confirm or trim the roster, persona names, changes to the manifest's tier defaults (strong: data, infra, fleet designer; standard: the rest), whether to have a verifier and which stamp families.
- **Always include** the orchestrator, verifier, fleet designer and fleet analyst. They are process lanes, not stack lanes.
- If your platform has no per-specialist tool restrictions, state the anti-jobs in the lane text and back them with guards.

## Pitfalls

- Avoid declaring persistent notes for a lane without the store existing, and the reverse. Lint both directions.
- Avoid product-specific refresher lanes; ship one generic refresher parameterized by repo.
- Avoid renaming a persona without updating whatever attributes spend to lanes by their prompt signature.
- Avoid lane rules that cite product files, hardware, scripts or dated anecdotes.
