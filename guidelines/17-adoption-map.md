# 17. Adoption map

The build plan: one config manifest, the modules in order, the setup flow, and the source's mistakes. Implement it natively on your platform.

## Shape of the kit

- Guards, tools, procedures, templates and the workspace linter ship **inside the kit** and read the project's manifest at runtime, so a kit update fixes every project.
- Projects receive generated, editable files: manifest, charter, router, lanes, rules, board, handoff index, policy entries.
- Two commands: **setup** (analyze, ask, generate, verify) and **verify** (workspace linter and guard tests against the manifest).

## The manifest

One per-project manifest replaces every hard-coded list. Conceptual keys:

- **owner**: name, title, timezone, production approver.
- **humans**: the approvers registry; each listed human with a role (owner, production approver, reviewer, on-call), identified by platform identity ([19](19-security-trust-and-incidents.md)).
- **notification channel**: the one owner notification channel for "waiting on you" and incidents.
- **outward channels**: pre-approved channel and message type pairs; every other outward communication asks.
- **emergency stop**: stop command and stop-flag location.
- **spend caps**: daily and monthly caps for all fleet work, and the alert threshold ([12](12-model-policy-and-spend.md)).
- **kit version**: kit version and manifest schema version.
- **capability map**: for each role (session events, pre-action checks, delegates with tier pins, scheduled headless runs, inter-session messaging, secret store), whether the platform supports it natively and the fallback if not.
- **project**: name, codename, deadline (optional).
- **code host**: organization, issue-reference pattern.
- **repos**: per repo, path, primary branch, branch model (rolling or per-issue), rolling branch, whether it hosts the nest, apply-before-merge, and push checks (command, fix hint, prerequisite).
- **protected branches**.
- **merge policy**: repos that merge without asking, stamp-gated repos, human-only workflows.
- **nest**: start command and ports.
- **forbidden remote hosts**.
- **ask commands**: patterns that always need the owner, with reasons.
- **heavy commands and capacity thresholds**.
- **models**: the tier map (light, standard and strong to the platform's concrete models); a tier for every role (each lane, built-in delegate, procedure step, scheduled-run step and the main session) with shipped defaults ([12](12-model-policy-and-spend.md)); escalation triggers that move a call to strong.
- **naming guard**: optional data naming convention and exceptions.
- **lanes**: name, archetype, ownership, persona.
- **stamps**: families in use; verifier escalation uses the triggers under **models**.
- **board**: location and sections omitted at session start.
- **backlog**: enabled, classifier (path pattern, reason, tier), caps.
- **peers**: enabled, max sessions, multiplexer.
- **environments**: for each of local, staging and production, its name, how to run or deploy it, and its access. Local and staging: full, including staging deploy workflows (allowed without asking); each allowed staging form must be pinned to the staging target. Production: none (default) or read-only through a read path (for example a read-only database role or replica) with allowed read commands. Production writes are always human-approved and not configurable. A missing staging environment is recorded, and agent deploys then stop at local.
- **modules**: on/off per optional module.
- **optimization run**: enabled, day and time, per-run cap (turns, cost), monthly spend limit, proposal branch pattern.
- **discipline**: playbook name (default poteto-mode), auto-load on/off, port location.
- **context**: per-session and per-lane context budgets, handoff threshold.
- **trackers**: code host, business tracker (if any), project mapping, status map, field ownership, write policy (default: linked items only), tracker identity ([18](18-task-management-and-tracker-sync.md)).
- **state location and environment prefix**.

## Modules, in ship order

1. **Core.** Charter and router templates; poteto-mode auto-load at the first implementation prompt; context management ([13](13-context-cards-and-memory.md)); process procedures (plan-then-implement, scope-lock, needs-owner-decision, board, handoff, new-session, merge-ready-checklist, verify-ship-gate, lane-handoffs); rules (leave-it-clean, environment-access, trust-boundary, code-host writes, workspace search); repo-safety guard, code-host write guard, model-drift guard, secret-scan guard and the session-start event, on one shell parser; emergency stop (stop command, stop flag read by every write guard); owner notification channel; incident procedure ([19](19-security-trust-and-incidents.md)); permission tiers; the fleet ledger with its approval log; workspace linter.
2. **Roster.** Archetype lane generator, verifier, fleet designer, analyst.
3. **Model and spend.** Tier map and per-role tiers, model-drift guard config, spend caps, spend and usage reports, outcome metrics, fleet-review.
4. **Peers.** Claims, peer guard, session titles, launcher, safe close.
5. **Branching.** Rolling or per-issue model, PR ledger, cleanup.
6. **Backlog engine.** The backlog engine, plan format, seal and drift checks, worker contract.
7. **Capacity.** Admission guard, heavy-command guard and slots, calibration, optional OS resource limits.
8. **Optional.** Push-check guard with checks derived from CI, naming guard, compaction checkpoint, context cards, scheduled ops (including the weekly fleet optimization run), business tracker sync, governance as code, alert triage, project engineering disciplines (authorization parity, error matrix, mockup parity, data ship audit, docs fold).

## Setup flow

1. **Analyze**, read-only: repos and nesting, languages, scripts, CI checks and order, deploy workflows, environments (staging config, deploy targets), IaC/migration/schema/UI/docs directories, branch protection, code ownership, existing agent config (merge, never clobber), whether the platform has a poteto-mode version or port, OS, CPU, RAM, multiplexer, scheduler, trackers in use, available models, the secret store and secret scanning, and the platform capability map.
2. **Propose** one screen: roster, modules, branch model, push checks, stamps, and the tier per role with its default, each marked "detected" or "assumed".
3. **Ask** only what analysis cannot settle, 2–4 options, recommendation first: owner and approvers (production approvers, reviewers, on-call); stop list; tier changes (default standard; strong for data, infra, planning, important QA reviews and fleet design) and light-tier opt-in for mechanical steps; spend caps; the owner notification channel; pre-approved outward channels; production read access (opt-in, default off) and through what path; confirm the staging target or note that there is none; solo or parallel sessions; branch model; roster trims; cost posture; naming lock; design gate and artifact location; scheduled ops and governance; whether to enable the weekly optimization run (recommended), its schedule and budget; whether to enable poteto-mode (recommended) or port it where none exists; context budgets; which business tracker (if any), its project mapping, and the write policy (recommended: linked items only).
4. **Generate** manifest, charter (about 150 lines), router, lanes, rules, empty-backlog board, handoff index, merged policy entries; scheduler units only on request.
5. **Verify**: run verify and all enabled guard tests; print generated, skipped (and why), and `Left open:`.
6. **Re-run idempotently**: diff against the manifest and propose; never overwrite hand edits unseen.

## Versioning, upgrade, uninstall and retirement

- Version the kit semantically and keep a changelog. The manifest records its schema version.
- A setup re-run migrates the manifest, shows the diff and asks. Projects can pin and roll back a kit version.
- **Uninstall** removes the generated files the manifest lists and flags any that were hand-edited.
- **Retiring a project:** archive its board and ledger entries, revoke its identities, remove its scheduled jobs and tracker mapping, and record the retirement in rule history.

## Interactions

- Each area's "Adapting it" items become manifest keys or generated files.
- The workspace linter ([14](14-self-verification-and-tests.md)) checks that each enabled module exists, is wired, and agrees with the manifest, including the platform capability map.
- Security, trust boundaries and incidents are owned by [19](19-security-trust-and-incidents.md); model tiers and spend caps by [12](12-model-policy-and-spend.md).

## Pitfalls

- Avoid copies of one list; the manifest is the only list.
- Avoid several shell tokenizers; one parser in every guard.
- Avoid code defaults that differ from shipped config.
- Avoid hand-mirrored CI; derive push checks and re-check them.
- Avoid hand-kept docs about loading; generate guard and layer tables.
- Avoid narrative in always-loaded files; cap sizes in the workspace linter.
- Avoid board and memory bloat; lint thresholds and archive.
- Avoid traces of retired features; scan templates for retired commands.
- Avoid hard-coded paths, identities and prices in kit code.
- Avoid model names in kit code; roles name a tier, and the manifest maps tiers to models.
- Avoid an untested kill switch; drill the emergency stop on a schedule.
- Avoid attribution lines in procedures; the platform owns attribution.
- Avoid untested meta-tools; test the workspace linter, launcher and session start from day one.
- Avoid listing tests by hand; discover them.
