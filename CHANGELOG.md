# Changelog

All notable changes to the ti-workspace kit. The kit uses semantic versioning.

## 0.1.3 (2026-10-23)

### Task closeout and workspace cleanup
- Guideline 09 gains a task closeout sequence (verify, merge by the branch model, fast-forward switch, safe-class cleanup, release, board and tracker, archive check), an outstanding items log (`Left open:`) and a workspace cleanup routine.
- Closeout may switch a root checkout only when it is clean, unclaimed by a live peer and the owner's dev-server view is undisturbed; rules 12 and 15 carry the pointer.
- Guideline 03 adds the closeout procedure; guideline 08 rule 12 points to it; guidelines 15 and 17 mention the cleanup and the new key.
- The manifest template gains `closeout.scratch_retention_days` and `closeout.handoff_retention_days`; `scripts/check.sh` checks them.
- The cleanup sweep is scoped to enumerated, git-ignored or generated paths inside the root, never follows symlinks or removes git locks, and names come from repo listings, never from untrusted text (rules 35-36).
- Closeout and its cleanup run automatically when a session's work completes or the owner asks to clean up, close out or wrap up (charter, guideline 09 trigger, procedure trigger sentence).
- Cleanup reports locks and never removes one; worktree removal lists git-ignored files first and a worktree a live claim owns is never removed.

## 0.1.2 (2026-10-23)

### Board bounding
- Guideline 10 gains bounding rules: size limit (150 lines), resolved rows kept (10), resolved-age days (14), an archive trigger, verbatim dated archives with one-line board rows, and items that never archive.
- Archiving keeps references resolvable and is not owner acceptance; the session-start board counts toward the limit.
- Guideline 18 adds ledger retention; guidelines 15 and 17 mention the archive step and the new keys.
- The manifest template gains `board.max_lines`, `max_resolved_rows`, `resolved_age_days` and `archive_location`.
- `scripts/check.sh` checks that the manifest template carries the new board keys.

## 0.1.1 (2026-10-23)

- Released under the MIT License (`LICENSE`).
- README credits poteto-mode (MIT) as the referenced implementation-discipline source.

## 0.1.0 (2026-10-23)

### Framework-agnostic rewrite
- Rewrote every area as platform-neutral guidelines: Intent, Rules, Architecture, Interactions, Adapting it, Pitfalls.
- Replaced tool and product names with roles (code host, multiplexer, OS scheduler, IaC tool, browser automation).
- Dropped CLI flags, exit codes, schemas and source paths; kept the load-bearing behaviors.
- Renamed areas 03, 06, 07 and 17 to neutral names.

### Environment access
- Local and staging are routine: run, deploy, test, seed and reset without asking.
- Production reads are opt-in at setup, default off, read-only through a named read path.
- Every production write, deploys included, needs explicit human approval each time; an unknown target counts as production.

### Weekly optimization run
- The analyst ranks findings from redacted, local session logs.
- The fleet designer drafts time-boxed, reversible experiments as a draft pull request; the owner approves and merges.
- Per-run and monthly budget caps; a least-privilege identity that cannot merge or approve.

### Context management and poteto-mode
- Area 13 owns context: layered loading, delegated bulk reads, per-session and per-lane context budgets, handoff instead of compaction.
- poteto-mode implementation discipline auto-loads at the first implementation prompt; setup offers a port where none exists.

### Task and tracker sync
- New area 18: one fleet ledger across projects, code-host issues and PRs, and business tracker sync.
- Tracker write policy defaults to linked items only; deletes and bulk edits are never allowed.
- Sync is idempotent and event-driven, and fails open on tracker outages.

### Model tiers per role
- Three tiers (light, standard, strong) mapped to concrete models in the manifest.
- Standard by default; strong for data, infra, planning, important QA reviews and fleet design; light only by opt-in.
- Hard daily and monthly spend caps, and outcome metrics alongside cost.

### Security, trust and incidents
- New area 19: trust boundaries, secrets handling, pinned third-party packs, and identities.
- An emergency stop with a stop flag every write guard reads; an unreadable flag counts as set.
- Incident procedures, outward-communication approvals, an approvers registry and an append-only approval log.

### Packaging
- Renamed `audit/` to `guidelines/`; added README, BOOTSTRAP prompt, manifest template, VERSION and this changelog.
- `scripts/check.sh` checks banned terms, links, area headings and bundle freshness.
- `scripts/build-bundle.sh` builds the single-file bundle `ti-workspace-kit.md` in `dist/`.
