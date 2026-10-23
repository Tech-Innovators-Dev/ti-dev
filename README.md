# ti-workspace kit

`ti-workspace` sets up an AI agent-fleet workspace in any project, on any AI framework. It gives one orchestrating session and a roster of specialist lanes a charter, standing rules, pre-action guards, a ship bar of verdict stamps, task tracking, spend control and a weekly self-improvement loop. The kit is a set of platform-neutral guidelines plus a setup prompt. Your agent reads them, analyzes your project, asks what it cannot detect, and generates a native configuration for your framework.

## Who it's for

- Teams and solo developers who run AI agents on real codebases and want them to work autonomously without touching production unsupervised.
- Builders porting the fleet to a new agent framework. Start with [HANDOFF.md](HANDOFF.md).

## Quick start (any AI framework)

1. **Add the kit.** Copy this folder into your project, or keep it alongside and point your agent at it.
2. **Bootstrap.** Paste the prompt in [BOOTSTRAP.md](BOOTSTRAP.md) into your agent. It reads the guidelines and runs setup read-only first.
3. **Answer, review, verify.** Answer the setup questions, review the generated config and the filled manifest, then run the verify step it generates.

If your framework lacks a mechanism (session events, pre-action checks, scheduled runs), setup records the fallback in the platform capability map.

## Contents

| Path | What it holds |
|---|---|
| `guidelines/` | One file per area (01–19). Start at [guidelines/00-overview.md](guidelines/00-overview.md); the build plan is [guidelines/17-adoption-map.md](guidelines/17-adoption-map.md). |
| `templates/` | `manifest.template.yaml`, the commented per-project manifest with every key and default. |
| `scripts/` | `check.sh` checks the docs; `build-bundle.sh` builds the single-file bundle. |
| `dist/` | `ti-workspace-kit.md`, everything in one file for agents that take a single document. |
| [HANDOFF.md](HANDOFF.md) | The builder brief for turning the guidelines into an installable kit. |
| [BOOTSTRAP.md](BOOTSTRAP.md) | The copy-paste setup prompt. |

## Key defaults

- **Environment access.** Local and staging: the agent runs, deploys, tests, seeds and resets freely. Production reads: off unless granted at setup, then read-only through a named read path. Production writes, deploys included: explicit human approval every time. An unknown target counts as production ([19](guidelines/19-security-trust-and-incidents.md), [04](guidelines/04-rules.md)).
- **Model tiers.** Every role has a tier. Standard (a mid-size model) by default; strong for data, infra, planning, important QA reviews and fleet design; light only by opt-in ([12](guidelines/12-model-policy-and-spend.md)).
- **Tracker write policy.** Linked items only: status, links and progress comments go through; creating, closing and field changes ask; deletes and bulk edits are never allowed ([18](guidelines/18-task-management-and-tracker-sync.md)).
- **Weekly optimization run.** The analyst ranks findings from the week's redacted session logs; the fleet designer drafts reversible config experiments as a draft pull request; the owner approves and merges ([15](guidelines/15-scheduled-ops-and-governance.md)).
- **Emergency stop.** One command pauses every session and scheduled run and freezes merges, deploys and tracker writes. Every write guard reads the stop flag, and an unreadable flag counts as set ([19](guidelines/19-security-trust-and-incidents.md)).

## Checking and building

Run from the repo root:

```sh
scripts/build-bundle.sh   # rebuild the bundle in dist/ from the sources
scripts/check.sh          # banned terms, links, area headings, bundle freshness
```

`check.sh` exits non-zero on any failure. Rebuild the bundle before committing doc changes.

## Versioning

The kit uses semantic versioning. The current version is in `VERSION`, and changes are listed in [CHANGELOG.md](CHANGELOG.md). The manifest records the kit and schema versions; a setup re-run migrates the manifest and shows the diff before writing.

## Ownership

Copyright (c) 2026 Tech Innovators. Released under the [MIT License](LICENSE).

The implementation-discipline guidance references poteto-mode by Lauren Tan (MIT License); the kit names it and summarizes its principles but does not include its text.
