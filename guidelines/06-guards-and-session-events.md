# 06. Guards and session events

## Intent

Guards enforce what must never depend on an agent's memory. A pre-action check inspects each shell command, file write or specialist launch, then has four outcomes: allow it, advise (add context without blocking), block it with the fix, or ask (force a permission prompt). Session-event handlers inject live state at start, name sessions, and checkpoint before context compaction.

## Rules

1. **Guide, don't just block.** Every block message carries the exact fix, ready to run, names the rule it enforces, and starts with a fixed, searchable prefix so blocks can be counted.
2. **Ask vs block.** Decisions that belong to a human get an ask with a reason. Things that are never right get a block.
3. **Guards backstop permission tiers.** Literal prefix rules miss `cd x && ...`, pipes and wrappers. Plain verbs live in the permission tiers; shapes a prefix cannot separate live in a guard. Keep the two paired and lint the pairing.
4. **Fail open on unreadable state; fail safe on the one dangerous verb.** A missing dependency or broken helper never blocks work, but an unparseable merge asks. The stop flag is the exception: an unreadable flag counts as set.
5. **Parse, don't grep.** Strip heredocs, match at command position, follow directory changes and nested shells. A quoted mention is not a call.
6. **Explicit escape hatches.** Each override is named, documented with its legitimate use, and typed deliberately.
7. **Log decisions** so thresholds can be retuned from evidence.
8. A malformed input, or a stray field of the wrong type, never changes a verdict.
9. Run each guard independently, so a block from any one stands.
10. Keep guards fast. A slow guard gets bypassed by reflex.
11. Enforce on observed state, not assumptions. An unconditional guard breaks legitimate workflows.
12. **Production-write verbs never fall to the allow tier.** Whatever the permission tiers say, a production write reaches a human ask or a block.

## Architecture

**Stop flag (read by every write guard):**
- While the emergency-stop flag is set, every write guard blocks every write: commits, pushes, merges, deploys, applies, tracker writes and outward messages. An unreadable flag counts as set. This deliberately breaks the fail-open rule, because a kill switch that fails open is no kill switch ([19](19-security-trust-and-incidents.md)).

**Pre-action guards on shell commands:**
- **Repo-safety guard.** Blocks: sidecar dev servers (backgrounded or on a non-standard port); remote login to a forbidden host; auto-approved IaC apply against production; force-push without a lease; resetting the primary branch hard; any push that writes a protected branch, parsing every refspec form, delete pushes, push-all and mirror, and a bare push while on a protected branch; deleting or force-pushing a rolling branch. Asks: any production IaC apply or production deploy trigger, always, even when wrapped. Allows: applies and deploys to staging targets. An unknown target is treated as production.
- **Secret-scan guard.** Before commit and push, scans the staged changes for credentials. Blocks with the fix (remove the value, load it from the secret store, rotate it if it was ever pushed) and never prints the secret itself ([19](19-security-trust-and-incidents.md)).
- **Heavy-command guard.** Blocks test runners, typecheck, builds and dependency installs not wrapped in the CPU-slot wrapper, and prints the original command rewritten with the wrapper ([11](11-capacity-and-admission.md)).
- **Peer guard.** Blocks destructive git (branch switches, stash, hard reset, and on a shared branch rebase and force-push) over a repo another live session has claimed. Exempt: a peer in a separate worktree, path-only checkouts. Advises on commit and push when a peer shares the branch. Nudges an unclaimed session with the claim step. A named override applies after the peer agrees. The message names the peer, branch, issue and intent and includes a ready-to-send note ([08](08-peer-sessions-and-handoffs.md)).
- **Push-check guard.** On push, runs the repo's fast lint or format check, blocks on failure with the autofix and output tail. Lint only, not typecheck, build or tests. Fails open when tools are missing or time out. A named bypass exists for work-in-progress pushes to a draft.
- **Code-host write guard.** Always asks, never blocks. A quote-aware tokenizer follows subshells, nested shells, eval and common wrappers.
  - Asks: raw API writes, mutations it cannot inspect, review approvals, workflow and run control, and secret, variable, ruleset, repo and release writes.
  - Free: reads, creating and editing pull requests, issue commands, commenting on an issue.
  - Merge policy reads the real base: listed repos into their primary branch merge freely; the stamp-gated repo needs the full head SHA pinned and an `APPLIED <prefix>` comment; a rolling branch needs a merge commit, a pinned head and no branch deletion; merging a fleet-proposal pull request always asks ([15](15-scheduled-ops-and-governance.md)); anything unparseable, admin-forced, wrapped or for an unknown repo asks.

**Pre-action guard on tracker writes:**
- **Tracker write guard.** Applies the tracker write policy to every business-tracker write, however it is issued. Allows status transitions, links and progress comments on items already linked to a task. By default asks on creating or closing items and on scope, priority, assignee or due-date changes, unless the manifest records the owner's choice to allow them. Always blocks deletes and bulk edits. Scheduled and headless runs get the same policy through a least-privilege tracker identity ([18](18-task-management-and-tracker-sync.md)).

**Pre-action check on outward communications:**
- **Outward-communications check.** Email, shared-channel posts, publishing and messages to people outside the team ask every time, unless the manifest pre-approves that channel and message type ([19](19-security-trust-and-incidents.md)).

**Pre-action guard on file writes:**
- **Naming guard.** On writes to schema or migration files, blocks column names that break the convention, lists up to ten offenders with the corrected name, covers every edit form, and exempts legacy paths.

**Pre-action guards on specialist launches:**
- **Model-drift guard.** Blocks a launch only when the tier is omitted, an expected tier is known (the tier from the manifest for that lane or delegate), and the caller's actual tier, read from its session log, differs. Exempts inheriting lanes, third-party specialist types and unreadable state. The message prescribes the tier and names where the pin lives ([12](12-model-policy-and-spend.md)).
- **Admission guard.** Blocks launches when CPU pressure, load per core or free memory crosses its threshold, or a cross-session burst limit is hit. Where the platform exposes usage, it also enforces the manifest's spend caps: at the cap, new launches ask and headless runs stop; otherwise the caps are report-only and say so ([12](12-model-policy-and-spend.md)). Logs every decision and supports a dry run ([11](11-capacity-and-admission.md)).

**Session events:**
- **Session start** (never blocks). Injects workspace branch, SHA and dirty state; nags when the main session's tier differs from the manifest's main-session tier; shows each nested repo's state; registers the session and lists live peers; lists up to five open handoffs; shows a trimmed board; optionally reports context-budget use ([13](13-context-cards-and-memory.md)). Each block is isolated so one broken helper cannot break start.
- **Implementation discipline.** Where the platform has a session-start or first-prompt event, wire it to auto-load the platform's version or port of poteto-mode at the session's first implementation prompt. Otherwise the charter tells the main session and every implementing lane to load it first ([03](03-procedures.md)).
- **Session title.** Sets the title once from the first claim (`<issue>-<slug>`), only while the default name stands. Never overrides a human rename. Fires on start and when the user sends a message, not on compaction.
- **Compaction checkpoint.** If the platform cannot prompt from a guard, block the first compaction attempt, leave a short-lived marker (about ten minutes), and allow the retry. The message offers "retry" or "write a handoff". Logs each call and fails open on any error.

## Interactions

- Enforces charter locks ([01](01-charter-and-router.md)), the environment-access, code-host writes, tracker writes, trust-boundaries and outward-communications rules ([04](04-rules.md)), branching ([09](09-branching-and-cleanup.md)), peers ([08](08-peer-sessions-and-handoffs.md)), capacity ([11](11-capacity-and-admission.md)) and model policy ([12](12-model-policy-and-spend.md)).
- Paired with the permission tiers ([07](07-permission-tiers.md)).
- Reads the peer and rolling-branch registries, capacity config, lane definitions, session logs and OS load/pressure metrics.
- The usage report counts blocks per guard from session logs ([12](12-model-policy-and-spend.md)). Each guard has its own tests ([14](14-self-verification-and-tests.md)).
- Session start lists handoffs written by the handoff procedure ([03](03-procedures.md)).

## Adapting it

- **Generic:** the stop flag, the secret-scan guard, the outward-communications check, the shell parser, protected-push parsing, the code-host write guard's tokenizer, the tracker write guard, the model-drift and admission guards, the heavy-command guard with its slot wrapper, the peer guard with its claim protocol, the compaction checkpoint, session title, and all the rules above.
- **Per project:** protected branches; reserved dev ports; forbidden remote hosts; the ask list (pattern and reason); heavy-command patterns; per-repo push checks, timeout and bypass name; merge policy (no-prompt repos, stamp-gated repos, human-only workflows); the tracker write policy and tracker identity; pre-approved outward channels; spend caps; naming convention, file filter and exemptions; session-start repo set and board sections; state directory; the approver's name in messages.
- **Detect at setup:** default branch and protection rules from the code host, CI lint commands from workflow definitions (derive push checks from them), dev-server ports, the IaC tool, migration paths and the existing column convention, and whether a business tracker is in use.
- **Ask at setup:** which guards to enable (core: the stop flag, repo-safety, secret-scan, code-host write and model-drift guards, and the outward-communications check; optional: peer, heavy-command, admission, push-check, naming and tracker write guards, and the compaction checkpoint), confirm derived push checks, the naming convention.
- Map each guard onto your platform's pre-action hook if it has one. If it does not, wrap the risky tools or commands so the check runs before them. If your platform can prompt natively from a guard, use that instead of the block-then-retry compaction trick.

## Pitfalls

- Avoid several shell tokenizers. A simpler splitter misses forms like a push inside a nested shell that a fuller one catches. Use one parser.
- Avoid code defaults that differ from shipped config; a missing config then silently becomes very strict.
- Avoid a hand-kept mirror of CI checks. Derive it at setup and verify it in the workspace linter.
- Avoid stale guard documentation that names the wrong trigger.
- Avoid untested session-start content and parsers.
