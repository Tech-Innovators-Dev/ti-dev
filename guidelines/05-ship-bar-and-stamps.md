# 05. Ship bar and stamps

## Intent

The ship bar lets work become mergeable without the owner reviewing every change. Independent verdicts ("stamps") are posted on the tracking issue or pull request, each bound to an exact commit. The orchestrator composes them into one MERGE-READY call. Stamps never substitute for each other, and a green pipeline is never verification.

## Rules

1. Every stamp names the tip SHA it covers. When the tip moves, the stamp is stale.
2. Compose, never substitute. Data PASS, Verify VERIFIED and Infra PIPELINE GREEN are separate boxes.
3. Order: Data (when schema is at risk), Verify, Docs (once final), lane evidence if needed, then the orchestrator's MERGE-READY.
4. The orchestrator never invents another lane's stamp.
5. A skipped stamp is explicit: `VERIFY N/A (<reason>)` from the orchestrator. Silence is not N/A. A fleet-proposal pull request carries `VERIFY N/A (workspace config)` plus the workspace linter result ([15](15-scheduled-ops-and-governance.md)); the weekly run records it, and the orchestrator confirms it before any merge.
6. Stamp required for UI behavior, authz, schema, joined or reported data, and novel cross-lane behavior. Not required for docs-only, byte-comparable asset swaps, CI or config-only, and comment- or type-only diffs.
7. **Carry rule:** if the diff between the stamped SHA and the new tip touches no file in the stamped surface, record `RE-STAMP CARRIED` instead of relaunching the verifier.
8. **Delta re-stamp:** give the verifier the old stamp, old SHA and new SHA; it checks only the delta.
9. **Round cap:** after a second `NOT VERIFIED`, stop relaunching. Escalate or re-plan.
10. Stay quiet unless a stamp or hard blocker changed. No empty acks, no thread re-summaries.

## Architecture

**Closed stamp vocabulary:**

| Owner | Tokens |
|---|---|
| Verifier, visual | `MATCH`, `MISMATCH` (built UI vs design source of truth) |
| Verifier, behavior | `VERIFIED`, `NOT VERIFIED`, `INCONCLUSIVE` |
| Data | `PASS`, `BLOCKED` |
| Docs | `FOLDED`, `ALREADY COVERED`, `BLOCKED` |
| Infra | `PIPELINE GREEN`, `APPLIED <tip>` |
| Design | `SOT READY`, then `DESIGN APPROVED SoT: <link> @ <sha>` or `DESIGN N/A (<reason>)` |
| Orchestrator | `MERGE-READY`, `HOLD`, `NEEDS OWNER`, `RE-STAMP CARRIED`, `VERIFY N/A (<reason>)` |

**Verifier stamp template:** `VERIFY <change> @ <sha>`; Visual and Behavior lines; a CI line (the run's head SHA must equal the stamp's tip, and a red or absent run blocks); Evidence as commands the owner can re-run; Composes with; `Noticed, unfixed:`.

**Verifier economics:**
- Budget about 40 tool calls, then `INCONCLUSIVE`.
- Default to the standard tier. Before launch, the orchestrator escalates to the strong tier on triggers read from the diff paths: schema in play, an authz or security surface, novel cross-lane behavior. Important QA reviews, such as the deep-review gate and security reviews, run on strong ([12](12-model-policy-and-spend.md)).
- The launch prompt carries a literal `launched: <tier> (<trigger>)` line. If the platform does not let a session observe its own model, this line is the verifier's only evidence of its tier. Without it, a verifier that hits a trigger returns `INCONCLUSIVE needs <strong tier> (<trigger>)` instead of stamping weakly.
- A UI stamp without browser evidence is INCONCLUSIVE.
- A negative claim ("X does not happen") needs a positive control showing the probe can detect X.

**Design gate:** classes are mockup required, no mockup, or unsure (ask). Design drafts the source of truth and returns `SOT READY`; the main session sends one review ask; the owner approves; the main session posts `DESIGN APPROVED SoT: <link> @ <sha>`. `DESIGN N/A (<reason>)` is the explicit alternative. The backlog engine refuses a UI plan with no design line.

**MERGE-READY box list:** tip SHA named; verify stamp or N/A; design line; CI green for the tip; data PASS where relevant; lineage proof for joined data; docs spillover handled; residuals listed; `Left open:` line; deploy batching considered.

**Infra apply-then-merge:** the infra change applies from its own branch. Staging applies are agent work; production applies need owner approval. It merges only once `APPLIED <tip>` is recorded, pinned to that head SHA, so the primary branch always equals the live environment. A schema mirror change merges only once its paired migration is live.

**Deploy gate:** a merge only records history. After merge, the agent deploys to staging and verifies there; staging evidence can back a stamp. The production deploy starts only when the owner approves it. The ask prints the production deploy link, the pipeline link and the commit it deploys, after a read-only pipeline-state check. Batch production deploys so the owner gets one ask. With no staging environment, the agent's deploys stop at local ([04](04-rules.md)).

**Rolling branches:** a stamp covers one ledger row's surface. The change merges at tip T only when every row is `READY` at T; one unstamped row blocks the merge ([09](09-branching-and-cleanup.md)).

## Interactions

- Lanes produce the tokens ([02](02-roster-and-agents.md)); procedures define the formats ([03](03-procedures.md)).
- The code-host write guard turns stamps into machine gates: no-prompt merges only for listed repos into their primary branch, and infra merges only with `APPLIED` recorded and a head-pinned SHA ([06](06-guards-and-session-events.md)).
- Model policy picks the verifier's tier per call ([12](12-model-policy-and-spend.md)); capacity bounds verifier fan-out ([11](11-capacity-and-admission.md)).
- The board records MERGE-READY and the single production-deploy ask; the backlog engine's seal check lists the stamps a bundle needs ([10](10-board-and-backlog-engine.md)).
- A credential-free browser smoke helper lets the verifier drive the real app ([16](16-excluded-product-specific.md)).

## Adapting it

- **Generic:** the vocabulary and the compose, carry, round-cap, budget, escalation-trigger and positive-control rules.
- **Per project:** which stamp families are on (no UI, no visual stamps; no database, no Data PASS), the required-vs-not table, escalation trigger paths, the infra repo and its stamp word, deploy and pipeline links.
- **Detect at setup:** the CI provider and workflows, how deploys trigger (manual or on push), an IaC repo, UI and database presence.
- **Ask at setup:** who approves production writes; which staging target exists; whether stamped merges run without a prompt; which paths are security-sensitive; whether there is a design gate and where its artifacts live.
- Post stamps wherever your code host keeps durable, linkable comments on the change.

## Pitfalls

- Avoid defaulting the verifier to the strong tier; strong-tier stamps were a large share of spend in the source. Keep escalation path-based so the choice is made before launch, not after a bounce.
- Avoid unbounded verifier runs. Long runs were mostly the cost of re-reading accumulated context; the budget and delta re-stamps exist for this.
- Avoid treating a green pipeline, or a stamp on an older SHA, as verification of the current tip.
