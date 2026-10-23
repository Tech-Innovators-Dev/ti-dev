# 07. Permission tiers

## Intent

The platform's policy config decides what an agent may do without asking. With the guards it forms a two-layer gate: tiers handle plain command prefixes, and guards handle shapes a prefix cannot separate, such as a push's target branch or a merge's repo. The tiers enforce environment access: local and staging are routine, production reads are opt-in, and production writes always need the human.

## Rules

1. **Allow** enumerated reads and routine work in local and staging: workspace tools, tests, lint, build, git reads and local writes, IaC plan and validate, and running and testing local and staging. Deploy and IaC apply are allowed only in forms pinned to a staging target (rule 5). List reads command by command; never wildcard a whole tool or service. Tracker reads, and status, link and comment writes on tracker items already linked to a task, are allowed under the tracker write policy ([18](18-task-management-and-tracker-sync.md)).
2. Allow production reads only if the user granted them at setup (default off). Enumerate them command by command, through the named read-only path.
3. Allow pushes only to named branch patterns, including the fleet-proposal pattern. Never allow a push wildcard. The headless optimization run uses a least-privilege identity that may push only the fleet-proposal pattern and open draft pull requests; it cannot merge or approve ([15](15-scheduled-ops-and-governance.md)). Scheduled and headless runs use the same tracker write policy through their own least-privilege tracker identity ([18](18-task-management-and-tracker-sync.md)).
4. **Ask** for every production write verb, every time: deploy, IaC apply, migration, data write, config, secret or feature-flag change, release and publish. Also ask for other writes to shared or remote state: CI workflow runs (except staging deploy workflows named in the manifest), branch rules, repo settings, auth, interactive remote sessions, and outward communications unless the manifest pre-approves the channel ([19](19-security-trust-and-incidents.md)). By default, ask before creating or closing tracker items or changing their scope, priority, assignee or due date (unless the manifest records the owner's choice to allow them; see rule 13). Production writes never appear in allow.
5. When staging and production share a deploy or apply verb, allow only forms pinned to a staging target. Otherwise route the verb through the repo-safety guard, which asks for production or unknown targets. That guard is mandatory whenever any deploy or apply form is allowed. In that case the verb may sit in allow only under rule 8, and only when the repo-safety guard is wired for it; the linter accepts such an entry on that condition.
6. Treat a command whose target environment cannot be determined as production.
7. **Deny** IaC destroy, reads of secret files (env files, private keys, credentials), and deleting or bulk-editing tracker items. If your platform can express it, also deny echoing or dumping secrets and environment variables; otherwise rely on the secret-scan guard ([19](19-security-trust-and-incidents.md)).
8. When a guard must decide, allow the command in policy and let the guard ask or block, so there is one prompt. A guard's ask wins over a broad allow.
9. Start every session in a planning-only state: no edits or mutations until a plan is approved.
10. Let peer messages arrive without being held, if the platform gates them.
11. The default delegate tier is standard. Pass a tier on every launch; tiers come from the manifest, and the inheritance trap is described in [12](12-model-policy-and-spend.md).
12. Commit shared policy. Keep per-machine additions in an uncommitted local layer, and never ship it.
13. Check the policy in the workspace linter: dangerous verbs are in ask; no allow entry can match a production or unknown deploy, apply or data-write target, except a shared verb whose repo-safety guard is wired (rule 5); allow has no raw code-host API, no code-host or push wildcards, and no secret or release verbs; fleet-proposal pull requests never sit on a no-prompt merge path; tracker create, close and field changes are never in allow unless the manifest's write policy records the owner's explicit choice; tracker deletes and bulk edits are always denied; no outward channel sits in allow unless the manifest pre-approves it; every guard exists and is wired.

## Architecture

- **Shared policy.** Planning-only default, default model, tiers, guard wiring, tool integrations.
- **Local layer.** Per-machine allow additions.
- **Guards.** Backstop the tiers ([06](06-guards-and-session-events.md)).
- **Side configs.** Capacity ([11](11-capacity-and-admission.md)) and the branch registry ([09](09-branching-and-cleanup.md)), read by guards and tools.
- **Policy checks in the workspace linter** ([14](14-self-verification-and-tests.md)).

## Interactions

- Environment-access and code-host-write rules use these tiers as enforcement points ([04](04-rules.md)).
- The tracker write policy and tracker sync are owned by [18](18-task-management-and-tracker-sync.md).
- Peer sessions need inbound messaging allowed ([08](08-peer-sessions-and-handoffs.md)).

## Adapting it

- Map the tiers onto your platform's permission system. With no ask tier, use a guard that prompts.
- **Per project:** default model, policy entries for workspace tools, push patterns (including fleet-proposal), staging target, production read verbs per provider (if granted), IaC tool, publish verbs.
- **At setup,** detect the package manager, IaC tool, cloud CLI and any existing policy (merge, never overwrite). Ask whether to start planning-only (recommended), the default model, the staging target, whether to grant production reads (default off) and if so the provider and read-only path, the publish verbs, and the tracker write policy (default: linked items only; [18](18-task-management-and-tracker-sync.md)). With no staging, deploy rights stop at local; record the gap. Keep rationale in the operator guide, not the config.

## Pitfalls

- Avoid a local layer that collects risky one-offs (broad API globs, recursive deletes). Check it in the workspace linter and warn.
- Avoid hand-kept production read lists. Generate them from a known list of read verbs per provider.
- Avoid machine-specific paths in shared config. Resolve them at setup.
