# 13. Context management, cards and memory

## Intent

Context is a budget, and this area owns it; other areas point here. Load as little as possible by default, keep the main session's window for decisions, and push bulk reading to delegates. Context cards are short pointer notes that say what a repo or boundary is, where its entry points are, and who owns it, pinned to a source revision so staleness is detectable. Memory keeps lessons across sessions without becoming a second copy of the repo. A context audit measures what every session pays.

## Rules

1. **Layered loading.** Keep always-loaded content minimal and capped (the charter is about 150 lines). Scoped rules load on path match. Procedures, the router and cards load on demand.
2. **Guard the main context window.** Route bulk reads, wide searches, log analysis and fan-out to delegates. Give each delegate a self-contained brief; it returns conclusions with file and line pointers, not dumps. The main session keeps decisions and summaries.
3. **Read narrowly.** Read the slice you need, do not re-read unchanged files, and refer to content by path and line.
4. **Context budget.** Each session and lane has a context budget and a handoff threshold, both from the manifest ([17](17-adoption-map.md)). Near the threshold, write a handoff and start a fresh session ([08](08-peer-sessions-and-handoffs.md)) rather than compacting. The compaction checkpoint is the backstop.
5. **Preload cap.** A lane preloads at most two procedures ([02](02-roster-and-agents.md)).
6. Read in order: router, system map, only the cards it names, then source only at the cited entry points.
7. Keep cards small and uniform: purpose, location, remote, ownership, relation to sibling or legacy repos, entry files, key levers. Mark each as a living pointer, not an inventory.
8. Pin each card to a source revision that must be an ancestor of the current tip. A missing pin fails; commits since the pin are reported as drift, not failed. Assert each card still mentions its key levers, so renames are caught.
9. If answering a question needed a repo-wide search, update the card.
10. **Memory hygiene.** Memory is a pointer index with a size cap, pruned when stale. Do not copy facts the repo already records. Notes share one shape: the rule, why, how to apply. Keep evidence out of memory. Secrets and real customer data never go into memory, handoffs or cards ([19](19-security-trust-and-incidents.md)).
11. When a lesson recurs, promote it into a procedure, rule, lint or guard, and delete the note.
12. **Measure it.** Audit context cost regularly and before charter changes; the weekly optimization run reviews context bloat from session logs ([15](15-scheduled-ops-and-governance.md)).

## Architecture

- **Loading layers.** Always loaded (charter, unscoped rules, memory index), path-scoped rules, on-demand procedures, router and cards, and per-lane preloads.
- **Delegation for reading.** Delegates absorb bulk context and hand back pointers and conclusions.
- **Handoff at threshold.** A handoff note plus a fresh session; the compaction checkpoint saves decisions if compaction happens anyway.
- **System map.** Repos, runtime topology, cross-repo seams, and which card answers which question.
- **Repo and seam cards.** One per repo, plus cards for confusing boundaries (auth families, who writes which tables).
- **Source-revision record**, one row per repo.
- **Context check.** Required cards, lever mentions, revision ancestry and drift. The umbrella verify step ([14](14-self-verification-and-tests.md)) runs it first.
- **Context audit.** Always-loaded cost, per-lane preload cost, duplicated topics across always-loaded files, and dead references.
- **Memory.** Per-lane notes typed as feedback, project or reference. The owner's personal memory uses the same shape for preferences and corrections.

## Interactions

- Charter and router point to the read protocol ([01](01-charter-and-router.md)); the workspace-search rule is in [04](04-rules.md).
- Handoffs: [08](08-peer-sessions-and-handoffs.md). Preload cap and the verifier lane's memory-scope rule: [02](02-roster-and-agents.md).
- The context check runs in CI and on schedule ([14](14-self-verification-and-tests.md), [15](15-scheduled-ops-and-governance.md)); the linter enforces the always-loaded and preload caps. The audit feeds the weekly fleet optimization run ([12](12-model-policy-and-spend.md), [15](15-scheduled-ops-and-governance.md)).

## Adapting it

- **Per project:** context budget and handoff threshold, card list and levers, which seams get cards, memory locations, audit topics.
- **Detect at setup:** repos, entry files, cross-repo calls, owners; generate a first card set and system map. **Ask:** which seams deserve cards and whether lanes keep memory.
- Map "always loaded", "path-scoped" and "preloaded" onto what your platform injects into every session or lane. If it cannot report context usage, estimate from session-log size.

## Pitfalls

- Avoid main-session context bloat from bulk reads and wide searches; delegate them.
- Avoid relying on compaction. It loses decisions; hand off before the threshold.
- Avoid checking only one repo's pin while other rows rot. Check every row or drop it.
- Avoid memory as a dumping ground for screenshots, scripts or facts the repo already holds.
- Avoid burying generic lessons in lane memory. Examples worth promoting: a negative claim needs a positive control; verify under a moving tip; parity tests can hide a shared defect; the design source of truth can be wrong; a preload cap overrides a literal request.
