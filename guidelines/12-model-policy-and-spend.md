# 12. Model policy and spend

## Intent

Model choice is the largest cost and quality lever in a fleet, and this area owns it. Every role runs on a named tier: light, standard or strong. Standard is the default; strong is for high-touch and critical work; light is an opt-in for mechanical volume. Guard against delegates silently landing on the wrong model, cap spend hard, and measure both spend and outcomes so policy rests on data.

## Rules

1. **Three tiers.** The manifest maps light, standard and strong to the platform's concrete models; setup detects what is available. The default is standard, a mid-size model.
2. **Every role has a tier in the manifest:** each lane, built-in delegate, procedure step, scheduled-run step and the main session. Setup shows the shipped defaults and asks only for changes; the owner can change them later.
3. **Shipped defaults.**
   - **Standard:** the main session and most lanes (UI, API, platform, design, docs, context refresher, fleet analyst), built-in search and general delegates, and the verifier's routine stamps.
   - **Strong:** data and infrastructure lanes; the fleet designer; planning (plan-ready packets, cross-lane scope locks, the backlog planner, architecture decisions); important QA (the verifier on escalation triggers such as schema, authz or security, or novel cross-lane behavior; the deep-review gate; security reviews); and anything that needs extra thinking, escalated per call.
   - **Light:** off by default. Setup may enable it only for mechanical, high-volume steps (log extraction, backlog scout, scans).
4. **Escalate per call.** A standard lane escalates to strong on named triggers; the launch names the tier and the trigger ([05](05-ship-bar-and-stamps.md)).
5. **Collect, then judge.** Gather on standard (or light if enabled), decide on strong.
6. The main session runs standard. If it cannot change its own model mid-turn, it tells the owner when a task needs strong.
7. **Inheritance trap.** On some platforms a delegate launched without an explicit model inherits the caller's model and ignores both the lane's pin and any default setting. Test this on yours. Either way, pass a tier on every launch.
8. Guard on observed state only: block a launch only when the omission would actually land on the wrong model, judged from the caller's real current model. Exempt launch types meant to inherit.
9. Implementation-discipline (poteto-mode) sub-roles, and any third-party procedure pack's sub-roles, run on the calling lane's tier, not on their own defaults ([03](03-procedures.md)).
10. **Hard spend caps.** The manifest sets daily and monthly caps for all fleet work: interactive, delegated and scheduled. At a threshold (for example 80%), alert through the owner notification channel ([19](19-security-trust-and-incidents.md)). At the cap, new delegate launches ask and headless runs stop. The admission guard ([06](06-guards-and-session-events.md)) enforces this where the platform exposes usage; otherwise the cap is report-only and says so.
11. **Outcome metrics.** Track quality as well as cost: reverts and escaped defects, rework rounds (a second NOT VERIFIED), lead time from claim to merge, owner-wait count and time, and blocked time.
12. **Measure, then change.** The designer turns findings into experiments for the owner, citing spend, drift and outcome reports. Kill metrics come from the caps and outcome metrics. A tier change is measured the following week and reverted if it fails.

## Architecture

- **Tier map** in the manifest: role to tier, tier to model.
- **Model-drift guard**, a pre-action check on specialist launches ([06](06-guards-and-session-events.md)).
- **Spend report.** Reads main and delegate session logs. Deduplicates usage by message identity before pricing. Counts and shows unpriced models. Splits by main vs delegate, by lane and by tier, and shows spend against the caps. A drift view lists runs on a model their tier does not map to, with a reason: inherited, explicitly requested, or unexplained.
- **Outcome report** for the metrics in rule 11.
- **Usage report.** Guard blocks per guard; procedure invocations, including procedures never used.
- **Snapshots.** Session logs are short-lived, so periodic snapshots keep the trend: totals, per lane and tier, drift, outcomes, guard fires, procedure usage.
- **Weekly review loop.** The fleet analyst ranks findings and never edits config. The fleet designer turns them into time-boxed, reversible experiments for the owner to approve ([15](15-scheduled-ops-and-governance.md)).

## Interactions

- Lane definitions: [02](02-roster-and-agents.md). Guards: [06](06-guards-and-session-events.md). Default setting: [07](07-permission-tiers.md).
- Verifier escalation: [05](05-ship-bar-and-stamps.md). Backlog routing by tier: [10](10-board-and-backlog-engine.md).
- The weekly fleet optimization run executes the review loop and reports outcomes and spend against caps ([15](15-scheduled-ops-and-governance.md)).
- The linter checks that every role has a tier, every tier maps to an available model, and the strong set matches the manifest ([14](14-self-verification-and-tests.md)).

## Adapting it

- **Per project:** the tier-to-model map, role overrides, spend caps and alert threshold, a refreshable price table, the session-log location.
- **Ask at setup:** changes to the shipped defaults, whether to enable light, and the caps.
- If your platform has no default-delegate-model setting, the explicit-tier rule and the guard are the only defense. If it does not expose usage, caps are report-only.

## Pitfalls

- Avoid hard-coded price tables and lane signatures. Derive lane identity from lane definitions, or a rename silently breaks attribution.
- Avoid pricing usage before deduplicating it by message identity.
- Avoid reporting an unknown model as free.
- Avoid optimizing cost alone; a cheaper tier that raises rework or reverts is a regression.
- Avoid letting the analyst apply its own findings, or the designer merge its own proposals.
- Avoid trusting pins alone. In the source, about a third of one week's spend drifted to the wrong model this way.
