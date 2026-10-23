# 15. Scheduled ops and governance

## Intent

Some upkeep should run without anyone starting a session: hygiene, the weekly fleet optimization run, load sampling, alert triage. Scripts do the work; a model runs only when something needs judgment. Repository governance (branch and deploy-environment protection) is kept as code with dry-run, verify and apply modes.

## Rules

1. Every headless run has a turn cap, a budget cap and an explicit tool allow-list. Each step runs on the tier the manifest assigns it ([12](12-model-policy-and-spend.md)): standard by default, light only if enabled.
2. Quiet runs cost nothing: a script decides first, and the model runs only on new input.
3. Headless runs use a dedicated least-privilege code-host identity, not the owner's credentials. The optimization run's identity can push only a named fleet-proposal branch pattern (for example `fleet-<date>`) and create pull requests: no merge, no approve.
4. Mint short-lived tokens fail-closed: never read the private key into the process, pass secrets over stdin, require strict key-file permissions.
5. Save scan state only after triage succeeds, so a failure retries.
6. Scheduled runs produce findings and draft proposals, never applied config changes. The owner approves or rejects every proposal and merges it, or an interactive session merges only after the owner's explicit approval on the pull request. The headless allow-list contains no merge or approve, and fleet-proposal pull requests are never on the no-prompt merge list.
7. Give scheduled jobs priority over interactive agents.
8. Governance tools own only prefix-named rules, read back every write, and refuse features the plan lacks.
9. Ship scheduler definitions; the owner installs them.
10. Session logs stay on the machine. Redact secrets before analysis, share logs only with the model the run already uses, and quote only redacted excerpts as evidence.
11. The optimization run has two budgets: a per-run cap (turns, cost) and a monthly spend limit. If there are no new logs or either budget is exhausted, record a skip on the board instead of running.
12. Scheduled runs follow the tracker write policy through their least-privilege tracker identity ([18](18-task-management-and-tracker-sync.md)).
13. The emergency stop pauses every scheduled run ([19](19-security-trust-and-incidents.md)).
14. Scheduled runs never write to production. They read production only if production reads were granted at setup; otherwise they use staging and the logs the owner exposes.

## Architecture

- **Hygiene run** at a fixed local time: safe-class workspace cleanup (branches, worktrees, scratch, old handoffs, expired locks; [09](09-branching-and-cleanup.md) rules 30-34), board archive when over a limit ([10](10-board-and-backlog-engine.md)), then the verify step.
- **Weekly fleet optimization run**, its own capped headless job, following collect-then-judge:
  1. Save a snapshot first, because session logs are short-lived.
  2. The fleet analyst (standard, or light if enabled; read-only) reads the week's session logs and the spend, drift, guard-fire, procedure-usage and context-audit reports, and ranks findings: spend and drift, rule compliance, wasted work, config rot, context quality including context bloat ([13](13-context-cards-and-memory.md)), unused procedures. It also reports outcome metrics and spend against the caps ([12](12-model-policy-and-spend.md)).
  3. The fleet designer (strong tier) first measures last run's approved experiments and proposes reverting the ones that failed. It then frames new changes (charter, lanes, procedures, guards, policy, model tiers) as experiments, each with a hypothesis, the metric that confirms or kills it, a time box and a rollback. It is bold in ideas, never in permissions. It runs the workspace linter, pushes to a fleet-proposal branch and opens a draft pull request carrying `VERIFY N/A (workspace config)` plus the linter result ([05](05-ship-bar-and-stamps.md)).
  4. The owner approves or rejects. The owner merges, or a session merges after the owner's explicit approval. Failed experiments are reverted and recorded in rule history. Nothing touches production.
- **Alert scan.** Read-only, against production only when production reads were granted, otherwise against staging and exposed logs. Alarms in alarm state (minus autoscaling noise) and failed pipeline runs. Reports only new keys or changed fingerprints. Fails distinctly when the cloud is unreadable. Triaged P1 alerts feed the incident procedure ([19](19-security-trust-and-incidents.md)).
- **Alert triage.** A capped run classifies P1, P2 or noise, then posts one issue comment and one board line. It runs plain cloud commands so the allow-list matches.
- **Ledger and tracker drift check**, part of the weekly optimization run or the hygiene run. It reports mismatches between the fleet ledger and the business tracker on the board and fixes nothing silently ([18](18-task-management-and-tracker-sync.md)).
- **Emergency-stop drill** on a schedule ([14](14-self-verification-and-tests.md), [19](19-security-trust-and-incidents.md)).
- **Load sampler**, low priority, feeding capacity tuning.
- **Governance as code.** Desired-state files for branch rules (repos, branches, required checks pinned to the CI identity, rolling branches exempt from pull requests) and environment protection (live or planned, branches, reviewers). Production deployments require a human reviewer; staging is not gated. Dry run by default; verify fails on drift, and a stricter launch-readiness verify treats a missing planned environment as drift; apply is scoped to a group or repo. Clean, drift and refused are distinct results.

## Interactions

- Hygiene calls cleanup ([09](09-branching-and-cleanup.md)) and verify ([14](14-self-verification-and-tests.md)).
- The optimization run uses the reports, snapshots and analyst/designer split from [12](12-model-policy-and-spend.md), the context audit from [13](13-context-cards-and-memory.md), and the workspace linter from [14](14-self-verification-and-tests.md); skips go to the board ([10](10-board-and-backlog-engine.md)).
- Triage and every scheduled run obey environment access ([04](04-rules.md)); triage writes to the board ([10](10-board-and-backlog-engine.md)).
- Tracker writes and the drift check follow task management and tracker sync ([18](18-task-management-and-tracker-sync.md)).
- Governance enforces no direct pushes, exempts rolling branches ([09](09-branching-and-cleanup.md)), and human-gates production deploys (staging stays ungated) to match the deploy gate ([05](05-ship-bar-and-stamps.md)).
- Job priority and sampling belong to capacity ([11](11-capacity-and-admission.md)).

## Adapting it

- **Per project:** OS scheduler (CI scheduled jobs as fallback), schedule and timezone, caps, identity, cloud provider, repos and checks.
- **Optional:** alert triage needs a cloud provider; governance needs code-host plan support.
- **Ask at setup:** enable hygiene and triage; enable the weekly fleet optimization run, its day and time, its per-run cap and monthly limit, and its proposal branch pattern (all in the manifest's optimization-run key, [17](17-adoption-map.md)); whether scheduled runs may read production (default off); which headless identity (creating it is an owner step); import current protection into desired state first.

## Pitfalls

- Avoid hard-coded identity constants and toolchain paths; resolve them at install.
- Avoid shipping governance data. Ship the tools and an importer that reads current code-host settings.
- Avoid saving scan state before triage succeeds; alerts would be silently lost.
- Avoid a review that only reports. Findings with no owner-gated proposal go stale.
